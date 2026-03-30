start:
    ; Stage two stays in a single tiny-model segment: code, data, and the IRQ1
    ; handler all expect DS = CS. SS:SP still points at the boot stack.
    push cs
    pop ds
    mov [boot_drive], dl
    call load_required_asset_banks

    mov ax, 0013h
    int 10h
    call init_palette
    call init_audio
    call reset_keyboard_state
    mov byte ptr [last_game_state], 0FFh
    mov byte ptr [feedback_timer], 0
    mov byte ptr [state_ticks], 0

IF DEBUG_FORCE_SEED
    mov word ptr [rng_state], DEBUG_SEED_VALUE
ELSE
    xor ah, ah
    int 1Ah
    mov [rng_state], dx
    cmp dx, 0
    jne seed_ready
    mov word ptr [rng_state], 0ACE1h

seed_ready:
ENDIF
    xor ah, ah
    int 1Ah
    mov [last_tick], dx
    mov byte ptr [anim_phase], 0
    mov byte ptr [splash_ticks], 0
    mov byte ptr [title_idle_ticks], 0
    mov byte ptr [demo_active], 0
    mov byte ptr [next_demo_index], 0
    mov byte ptr [demo_action_code], DEMO_ACTION_END
    mov byte ptr [demo_action_ticks], 0
    mov word ptr [demo_script_ptr], 0
IF DEBUG_START_IN_GAME
    call start_new_run
ELSE
    mov byte ptr [game_state], STATE_SPLASH
    mov byte ptr [message_id], MSG_SECTOR
ENDIF

main_loop:
    ; One BIOS timer tick drives animation, rendering, and then one round of
    ; state/input handling.
    call wait_frame_tick
    call poll_bios_keyboard
    call update_frontend_state
    call update_runtime_feedback
    call render_screen
    cmp byte ptr [game_state], STATE_PLAYING
    je handle_play_input

    cmp byte ptr [game_state], STATE_SPLASH
    je handle_splash_input

    cmp byte ptr [game_state], STATE_TITLE
    je handle_frontend_start_input

    cmp byte ptr [any_key_pending], 0
    je main_loop
    mov byte ptr [any_key_pending], 0
    call start_new_run
    jmp main_loop

handle_splash_input:
    cmp byte ptr [pressed_enter], 0
    je splash_check_skip
    mov byte ptr [pressed_enter], 0
    mov byte ptr [any_key_pending], 0
    call start_new_run
    jmp main_loop

splash_check_skip:
    cmp byte ptr [any_key_pending], 0
    je main_loop
    mov byte ptr [any_key_pending], 0

skip_splash:
    call reset_keyboard_state
    mov byte ptr [game_state], STATE_TITLE
    jmp main_loop

handle_frontend_start_input:
    ; Title/start flow consumes the same explicit latches as gameplay first,
    ; then falls back to the generic any-key flag for unknown BIOS keys.
    call title_input_pending
    cmp al, 0
    je main_loop

frontend_start_now:
    call start_new_run
    jmp main_loop

handle_play_input:
    cmp byte ptr [demo_active], 0
    je handle_live_play_input
    cmp byte ptr [any_key_pending], 0
    jne demo_takeover_now
    call process_demo_input
    jmp main_loop

demo_takeover_now:
    call start_new_run
    jmp main_loop

handle_live_play_input:
    call process_play_input
    jmp main_loop

wait_frame_tick:
wait_frame_tick_loop:
    ; BIOS tick count (~18.2 Hz) is the only global clock in the runtime.
    xor ah, ah
    int 1Ah
    cmp dx, [last_tick]
    je wait_frame_tick_loop
    mov [last_tick], dx
    inc byte ptr [anim_phase]
    cmp byte ptr [run_start_enter_guard], 0
    je wait_frame_tick_done
    dec byte ptr [run_start_enter_guard]

wait_frame_tick_done:
    ret

update_frontend_state:
    cmp byte ptr [game_state], STATE_SPLASH
    je frontend_update_splash
    cmp byte ptr [game_state], STATE_TITLE
    je frontend_update_title
    cmp byte ptr [demo_active], 0
    je frontend_state_done
    cmp byte ptr [game_state], STATE_WIN
    je frontend_update_demo_outro
    cmp byte ptr [game_state], STATE_LOSE
    jne frontend_state_done

frontend_update_demo_outro:
    cmp byte ptr [state_ticks], END_REVEAL_PROMPT + 24
    jb frontend_state_done
    call return_to_title
    jmp frontend_state_done

frontend_update_splash:
    inc byte ptr [splash_ticks]
    cmp byte ptr [splash_ticks], SPLASH_DURATION
    jb frontend_state_done
    call enter_title_screen
    jmp frontend_state_done

frontend_update_title:
    call title_input_pending
    cmp al, 0
    jne frontend_title_has_input
    cmp byte ptr [title_idle_ticks], 255
    je frontend_title_idle_ready
    inc byte ptr [title_idle_ticks]

frontend_title_idle_ready:
    cmp byte ptr [title_idle_ticks], TITLE_ATTRACT_DELAY
    jb frontend_state_done
    call start_demo_run
    jmp frontend_state_done

frontend_title_has_input:
    mov byte ptr [title_idle_ticks], 0

frontend_state_done:
    ret

title_input_pending:
    cmp byte ptr [pressed_enter], 0
    jne title_input_yes
    cmp byte ptr [pressed_w], 0
    jne title_input_yes
    cmp byte ptr [pressed_a], 0
    jne title_input_yes
    cmp byte ptr [pressed_s], 0
    jne title_input_yes
    cmp byte ptr [pressed_d], 0
    jne title_input_yes
    cmp byte ptr [pressed_c], 0
    jne title_input_yes
    cmp byte ptr [pressed_up], 0
    jne title_input_yes
    cmp byte ptr [pressed_left], 0
    jne title_input_yes
    cmp byte ptr [pressed_right], 0
    jne title_input_yes
    cmp byte ptr [pressed_down], 0
    jne title_input_yes
    cmp byte ptr [any_key_pending], 0
    jne title_input_yes
    xor al, al
    ret

title_input_yes:
    mov al, 1
    ret

enter_title_screen:
    call clear_demo_playback_state
    mov byte ptr [game_state], STATE_TITLE
    mov byte ptr [title_idle_ticks], 0
    ret

return_to_title:
    call reset_keyboard_state
    call enter_title_screen
    ret

clear_demo_playback_state:
    mov byte ptr [demo_active], 0
    mov byte ptr [demo_index], 0
    mov byte ptr [demo_action_code], DEMO_ACTION_END
    mov byte ptr [demo_action_ticks], 0
    mov word ptr [demo_script_ptr], 0
    ret

start_new_run:
    call reset_keyboard_state
    call clear_demo_playback_state
IF DEBUG_FORCE_SEED
    mov word ptr [rng_state], DEBUG_SEED_VALUE
ENDIF
    mov al, 1
IF DEBUG_START_SECTOR GT 1
    mov al, DEBUG_START_SECTOR
ENDIF
    call set_run_start_sector_and_pulses
    call initialize_run_state
    ret

start_demo_run:
    call reset_keyboard_state
    call clear_demo_playback_state
    mov bl, [next_demo_index]
    cmp bl, DEMO_COUNT
    jb demo_index_ready
    xor bl, bl

demo_index_ready:
    mov byte ptr [demo_index], bl
    xor bh, bh
    mov al, [demo_start_sector_table + bx]
    call set_run_start_sector_and_pulses
    shl bx, 1
    mov ax, [demo_seed_table + bx]
    mov [rng_state], ax
    mov ax, [demo_script_table + bx]
    mov [demo_script_ptr], ax
    mov byte ptr [demo_active], 1
    mov byte ptr [demo_action_code], DEMO_ACTION_END
    mov byte ptr [demo_action_ticks], 0
    mov al, [demo_index]
    inc al
    cmp al, DEMO_COUNT
    jb demo_next_index_ready
    xor al, al

demo_next_index_ready:
    mov byte ptr [next_demo_index], al
    call initialize_run_state
    ret

set_run_start_sector_and_pulses:
    cmp al, 1
    jae run_start_sector_min_ready
    mov al, 1

run_start_sector_min_ready:
    cmp al, TOTAL_SECTORS
    jbe run_start_sector_max_ready
    mov al, TOTAL_SECTORS

run_start_sector_max_ready:
    mov byte ptr [sector_num], al
    mov bl, START_PULSES
    cmp al, 1
    jbe run_start_pulse_ready
    add bl, al
    sub bl, 2
    cmp bl, MAX_PULSES
    jbe run_start_pulse_ready
    mov bl, MAX_PULSES

run_start_pulse_ready:
    mov byte ptr [pulse_count], bl
    ret

initialize_run_state:
    mov byte ptr [game_state], STATE_PLAYING
    mov byte ptr [title_idle_ticks], 0
    mov byte ptr [run_start_enter_guard], RUN_START_ENTER_GUARD_TICKS
    mov byte ptr [shield_count], START_SHIELDS
    mov byte ptr [data_count], 0
    mov byte ptr [kill_count], 0
    call reset_run_mastery
    call load_sector
    mov al, MSG_SECTOR
    call set_message_event
    ret

process_demo_input:
    cmp byte ptr [demo_action_ticks], 0
    jne demo_have_action
    call load_next_demo_action

demo_have_action:
    mov al, [demo_action_code]
    cmp al, DEMO_ACTION_END
    je demo_finished
    cmp byte ptr [demo_action_ticks], 0
    je demo_finished
    cmp al, DEMO_ACTION_WAIT
    je demo_consume_tick
    call clear_pressed_latches
    cmp al, DEMO_ACTION_LEFT
    je demo_press_left
    cmp al, DEMO_ACTION_RIGHT
    je demo_press_right
    cmp al, DEMO_ACTION_UP
    je demo_press_up
    cmp al, DEMO_ACTION_DOWN
    je demo_press_down
    cmp al, DEMO_ACTION_PULSE
    je demo_press_pulse
    jmp demo_finished

demo_press_left:
    mov byte ptr [pressed_a], 1
    jmp demo_run_action

demo_press_right:
    mov byte ptr [pressed_d], 1
    jmp demo_run_action

demo_press_up:
    mov byte ptr [pressed_w], 1
    jmp demo_run_action

demo_press_down:
    mov byte ptr [pressed_s], 1
    jmp demo_run_action

demo_press_pulse:
    mov byte ptr [pressed_c], 1

demo_run_action:
    call process_play_input

demo_consume_tick:
    dec byte ptr [demo_action_ticks]
    ret

demo_finished:
    call return_to_title
    ret

load_next_demo_action:
    push si
    mov si, [demo_script_ptr]
    mov al, [si]
    mov byte ptr [demo_action_code], al
    inc si
    mov al, [si]
    mov byte ptr [demo_action_ticks], al
    inc si
    mov [demo_script_ptr], si
    pop si
    ret
