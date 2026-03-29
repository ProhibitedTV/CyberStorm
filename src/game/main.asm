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
    cmp byte ptr [pressed_enter], 0
    jne frontend_start_now
    cmp byte ptr [pressed_w], 0
    jne frontend_start_now
    cmp byte ptr [pressed_a], 0
    jne frontend_start_now
    cmp byte ptr [pressed_s], 0
    jne frontend_start_now
    cmp byte ptr [pressed_d], 0
    jne frontend_start_now
    cmp byte ptr [pressed_c], 0
    jne frontend_start_now
    cmp byte ptr [pressed_up], 0
    jne frontend_start_now
    cmp byte ptr [pressed_left], 0
    jne frontend_start_now
    cmp byte ptr [pressed_right], 0
    jne frontend_start_now
    cmp byte ptr [pressed_down], 0
    jne frontend_start_now
    cmp byte ptr [any_key_pending], 0
    je main_loop

frontend_start_now:
    call start_new_run
    jmp main_loop

handle_play_input:
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
    ret

update_frontend_state:
    cmp byte ptr [game_state], STATE_SPLASH
    jne frontend_state_done
    inc byte ptr [splash_ticks]
    cmp byte ptr [splash_ticks], SPLASH_DURATION
    jb frontend_state_done
    mov byte ptr [game_state], STATE_TITLE

frontend_state_done:
    ret

start_new_run:
    call reset_keyboard_state
IF DEBUG_FORCE_SEED
    mov word ptr [rng_state], DEBUG_SEED_VALUE
ENDIF
    mov byte ptr [game_state], STATE_PLAYING
    mov byte ptr [sector_num], 1
    mov byte ptr [shield_count], START_SHIELDS
    mov byte ptr [pulse_count], START_PULSES
    mov byte ptr [data_count], 0
    mov byte ptr [kill_count], 0
IF DEBUG_START_SECTOR GT 1
    mov al, DEBUG_START_SECTOR
    cmp al, TOTAL_SECTORS
    jbe debug_start_sector_ready
    mov al, TOTAL_SECTORS
debug_start_sector_ready:
    mov byte ptr [sector_num], al
    add al, START_PULSES - 2
    cmp al, MAX_PULSES
    jbe debug_start_pulses_ready
    mov al, MAX_PULSES
debug_start_pulses_ready:
    mov byte ptr [pulse_count], al
ENDIF
    call reset_run_mastery
    call load_sector
    mov al, MSG_SECTOR
    call set_message_event
    ret
