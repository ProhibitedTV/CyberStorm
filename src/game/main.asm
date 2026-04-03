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
    mov byte ptr [scene_render_mode], DEBUG_SCENE_RENDER_MODE
    mov byte ptr [gameplay_render_mode], DEBUG_GAMEPLAY_RENDER_MODE

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
IF DEBUG_DEMO_BOOT
    call start_selected_demo_run
ELSEIF DEBUG_FRONTEND_VERIFY
    call start_frontend_verify_scenario
ELSEIF DEBUG_START_IN_GAME
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
    cmp byte ptr [game_state], STATE_WIN
    je handle_frontend_continue_input
    cmp byte ptr [game_state], STATE_LOSE
    je handle_frontend_continue_input
    cmp byte ptr [game_state], STATE_VERIFY_PASS
    je handle_verify_continue_input
    cmp byte ptr [game_state], STATE_VERIFY_FAIL
    je handle_verify_continue_input

    jmp main_loop

handle_splash_input:
    call frontend_start_key_pending
    cmp al, 0
    je splash_check_skip
    call clear_pressed_latches
    call start_new_run
    jmp main_loop

splash_check_skip:
    call frontend_activity_pending
    cmp al, 0
    je main_loop
    call clear_pressed_latches

skip_splash:
    call reset_keyboard_state
    mov byte ptr [game_state], STATE_TITLE
    jmp main_loop

handle_frontend_start_input:
    call frontend_start_key_pending
    cmp al, 0
    jne frontend_start_now
    call frontend_activity_pending
    cmp al, 0
    je main_loop
    call clear_pressed_latches
    jmp main_loop

handle_frontend_continue_input:
    call frontend_continue_key_pending
    cmp al, 0
    jne frontend_start_now
    call frontend_activity_pending
    cmp al, 0
    je main_loop
    call clear_pressed_latches
    jmp main_loop

handle_verify_continue_input:
    call frontend_continue_key_pending
    cmp al, 0
    jne verify_return_title
    call frontend_activity_pending
    cmp al, 0
    je main_loop
    call clear_pressed_latches
    jmp main_loop

verify_return_title:
    call return_to_title
    jmp main_loop

frontend_start_now:
    call start_new_run
    jmp main_loop

handle_play_input:
    cmp byte ptr [demo_active], 0
    je handle_live_play_input
IF DEBUG_DEMO_BOOT
    call process_demo_input
    jmp main_loop
ELSE
    call frontend_takeover_key_pending
    cmp al, 0
    jne demo_takeover_now
    call process_demo_input
    jmp main_loop
ENDIF

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
IF DEBUG_FRONTEND_VERIFY
    call update_frontend_verify_state
    cmp byte ptr [game_state], STATE_VERIFY_PASS
    je frontend_state_done
    cmp byte ptr [game_state], STATE_VERIFY_FAIL
    je frontend_state_done
ENDIF
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
IF DEBUG_RUNTIME_VERIFY
    call finalize_runtime_verify_demo
    jmp frontend_state_done
ENDIF
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
    call frontend_start_key_pending
    cmp al, 0
    jne frontend_state_done
    call frontend_activity_pending
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

frontend_start_key_pending:
    cmp byte ptr [frontend_action], FRONTEND_ACTION_START
    jne frontend_start_key_no
    mov al, 1
    ret

frontend_start_key_no:
    xor al, al
    ret

frontend_continue_key_pending:
    cmp byte ptr [frontend_action], FRONTEND_ACTION_CONTINUE
    jne frontend_continue_key_no
    mov al, 1
    ret

frontend_continue_key_no:
    xor al, al
    ret

frontend_takeover_key_pending:
    mov al, [frontend_action]
    cmp al, FRONTEND_ACTION_CONTINUE
    je frontend_takeover_yes
    cmp al, FRONTEND_ACTION_MOVE
    je frontend_takeover_yes
    cmp al, FRONTEND_ACTION_PULSE
    je frontend_takeover_yes
    cmp al, FRONTEND_ACTION_RESET
    je frontend_takeover_yes
    xor al, al
    ret

frontend_activity_pending:
    cmp byte ptr [frontend_action], FRONTEND_ACTION_NONE
    jne frontend_takeover_yes
    xor al, al
    ret

frontend_takeover_yes:
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

clear_runtime_verify_state:
    mov byte ptr [verify_action_pending], 0
    mov byte ptr [verify_action_index], 0
    mov byte ptr [verify_result_demo_index], 0
    mov word ptr [verify_expected_signature], 0
    mov word ptr [verify_observed_signature], 0
    mov byte ptr [verify_mode], VERIFY_MODE_REPLAY
    mov byte ptr [verify_frontend_scenario], FRONTEND_VERIFY_NONE
    mov byte ptr [verify_frontend_ticks], 0
    mov byte ptr [verify_frontend_event_fired], 0
    ret

start_new_run:
    call reset_keyboard_state
    call clear_demo_playback_state
    call clear_runtime_verify_state
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
    call clear_runtime_verify_state
    mov bl, [next_demo_index]
    cmp bl, DEMO_COUNT
    jb demo_index_ready
    xor bl, bl

demo_index_ready:
    call start_demo_by_index
    mov al, [demo_index]
    inc al
    cmp al, DEMO_COUNT
    jb demo_next_index_ready
    xor al, al

demo_next_index_ready:
    mov byte ptr [next_demo_index], al
    ret

start_selected_demo_run:
    call reset_keyboard_state
    call clear_demo_playback_state
    call clear_runtime_verify_state
    mov bl, DEBUG_DEMO_INDEX
    call start_demo_by_index
    ret

start_frontend_verify_scenario:
    call reset_keyboard_state
    call clear_demo_playback_state
    call clear_runtime_verify_state
    mov byte ptr [verify_mode], VERIFY_MODE_FRONTEND
    mov al, DEBUG_FRONTEND_SCENARIO
    cmp al, FRONTEND_VERIFY_SPLASH_TO_TITLE
    jb frontend_verify_default
    cmp al, FRONTEND_VERIFY_TITLE_TO_ATTRACT
    jbe frontend_verify_scenario_ready

frontend_verify_default:
    mov al, FRONTEND_VERIFY_TITLE_TO_START

frontend_verify_scenario_ready:
    mov byte ptr [verify_frontend_scenario], al
    mov byte ptr [game_state], STATE_TITLE
    mov byte ptr [title_idle_ticks], 0
    mov byte ptr [splash_ticks], 0
    cmp al, FRONTEND_VERIFY_SPLASH_TO_TITLE
    jne frontend_verify_check_attract
    mov byte ptr [game_state], STATE_SPLASH
    ret

frontend_verify_check_attract:
    cmp al, FRONTEND_VERIFY_TITLE_TO_ATTRACT
    jne frontend_verify_start_ready
    mov byte ptr [title_idle_ticks], TITLE_ATTRACT_DELAY - 4

frontend_verify_start_ready:
    ret

start_demo_by_index:
    cmp bl, DEMO_COUNT
    jb start_demo_index_ready
    xor bl, bl

start_demo_index_ready:
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
IF DEBUG_RUNTIME_VERIFY
    call finalize_runtime_verify_demo
ELSE
    call return_to_title
ENDIF
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

get_demo_name_ptr:
    xor bx, bx
    mov bl, [verify_result_demo_index]
    shl bx, 1
    mov si, word ptr [demo_name_table + bx]
    ret

get_frontend_verify_scenario_name_ptr:
    mov al, [verify_frontend_scenario]
    cmp al, FRONTEND_VERIFY_SPLASH_TO_TITLE
    je frontend_verify_name_splash
    cmp al, FRONTEND_VERIFY_TITLE_TO_ATTRACT
    je frontend_verify_name_attract
    mov si, offset frontend_verify_title_start_name
    ret

frontend_verify_name_splash:
    mov si, offset frontend_verify_splash_name
    ret

frontend_verify_name_attract:
    mov si, offset frontend_verify_title_attract_name
    ret

get_frontend_verify_detail_ptr:
    mov al, [verify_frontend_scenario]
    cmp al, FRONTEND_VERIFY_SPLASH_TO_TITLE
    je frontend_verify_detail_splash
    cmp al, FRONTEND_VERIFY_TITLE_TO_ATTRACT
    je frontend_verify_detail_attract
    mov si, offset frontend_verify_title_start_detail
    ret

frontend_verify_detail_splash:
    mov si, offset frontend_verify_splash_detail
    ret

frontend_verify_detail_attract:
    mov si, offset frontend_verify_title_attract_detail
    ret

update_frontend_verify_state:
    cmp byte ptr [verify_mode], VERIFY_MODE_FRONTEND
    jne frontend_verify_update_done
    cmp byte ptr [game_state], STATE_VERIFY_PASS
    je frontend_verify_update_done
    cmp byte ptr [game_state], STATE_VERIFY_FAIL
    je frontend_verify_update_done
    cmp byte ptr [verify_frontend_ticks], 255
    je frontend_verify_tick_ready
    inc byte ptr [verify_frontend_ticks]

frontend_verify_tick_ready:
    call maybe_fire_frontend_verify_event
    call maybe_finish_frontend_verify

frontend_verify_update_done:
    ret

maybe_fire_frontend_verify_event:
    cmp byte ptr [verify_frontend_event_fired], 0
    jne frontend_verify_event_done
    mov al, [verify_frontend_scenario]
    cmp al, FRONTEND_VERIFY_TITLE_TO_ATTRACT
    je frontend_verify_event_done
    cmp byte ptr [verify_frontend_ticks], 2
    jb frontend_verify_event_done
    cmp al, FRONTEND_VERIFY_SPLASH_TO_TITLE
    jne frontend_verify_event_start
    mov al, FRONTEND_ACTION_ACTIVITY
    call inject_frontend_verify_action
    ret

frontend_verify_event_start:
    mov al, FRONTEND_ACTION_START
    call inject_frontend_verify_action

frontend_verify_event_done:
    ret

inject_frontend_verify_action:
    mov byte ptr [verify_frontend_event_fired], 1
    mov [frontend_action], al
    mov [frontend_last_action], al
    cmp byte ptr [frontend_event_count], 99
    jae frontend_verify_action_done
    inc byte ptr [frontend_event_count]

frontend_verify_action_done:
    ret

maybe_finish_frontend_verify:
    mov al, [verify_frontend_scenario]
    cmp al, FRONTEND_VERIFY_SPLASH_TO_TITLE
    je frontend_verify_expect_title
    cmp al, FRONTEND_VERIFY_TITLE_TO_ATTRACT
    je frontend_verify_expect_attract
    cmp byte ptr [game_state], STATE_PLAYING
    jne frontend_verify_timeout_check
    cmp byte ptr [demo_active], 0
    jne frontend_verify_timeout_check
    jmp frontend_verify_finalize

frontend_verify_expect_title:
    cmp byte ptr [game_state], STATE_TITLE
    je frontend_verify_finalize
    jmp frontend_verify_timeout_check

frontend_verify_expect_attract:
    cmp byte ptr [game_state], STATE_PLAYING
    jne frontend_verify_timeout_check
    cmp byte ptr [demo_active], 0
    je frontend_verify_timeout_check
    jmp frontend_verify_finalize

frontend_verify_timeout_check:
    cmp byte ptr [verify_frontend_ticks], FRONTEND_VERIFY_TIMEOUT_TICKS
    jb frontend_verify_finish_done

frontend_verify_finalize:
    mov al, [frontend_event_count]
    mov [verify_action_index], al
    call get_frontend_verify_expected_signature
    mov [verify_expected_signature], ax
    call compute_frontend_verify_signature
    mov [verify_observed_signature], ax
    mov ax, [verify_expected_signature]
    cmp ax, [verify_observed_signature]
    jne frontend_verify_fail
    mov byte ptr [game_state], STATE_VERIFY_PASS
    ret

frontend_verify_fail:
    mov byte ptr [game_state], STATE_VERIFY_FAIL

frontend_verify_finish_done:
    ret

get_frontend_verify_expected_signature:
    mov ax, STATE_TITLE
    mov bl, [verify_frontend_scenario]
    cmp bl, FRONTEND_VERIFY_SPLASH_TO_TITLE
    je frontend_verify_expected_ready
    mov ax, STATE_PLAYING
    cmp bl, FRONTEND_VERIFY_TITLE_TO_ATTRACT
    jne frontend_verify_expected_start
    or ax, 0100h
    jmp frontend_verify_expected_ready

frontend_verify_expected_start:
    or ax, 0200h

frontend_verify_expected_ready:
    mov bl, DEBUG_FRONTEND_CORRUPT_SCENARIO
    cmp bl, [verify_frontend_scenario]
    jne frontend_verify_expected_done
    xor ax, 0001h

frontend_verify_expected_done:
    ret

compute_frontend_verify_signature:
    xor ax, ax
    mov al, [game_state]
    cmp byte ptr [demo_active], 0
    je frontend_verify_sig_guard
    or ax, 0100h

frontend_verify_sig_guard:
    cmp byte ptr [run_start_enter_guard], 0
    je frontend_verify_sig_done
    or ax, 0200h

frontend_verify_sig_done:
    ret

verify_runtime_checkpoint:
    mov byte ptr [verify_action_pending], 0
    xor bx, bx
    mov bl, [demo_index]
    mov al, [verify_action_index]
    cmp al, [verify_demo_checkpoint_count_table + bx]
    jb verify_checkpoint_in_range
    call compute_runtime_verify_signature
    mov [verify_observed_signature], ax
    shl bx, 1
    mov ax, [verify_demo_final_signature_table + bx]
    mov [verify_expected_signature], ax
    mov al, [demo_index]
    mov byte ptr [verify_result_demo_index], al
    mov byte ptr [demo_active], 0
    mov byte ptr [game_state], STATE_VERIFY_FAIL
    ret

verify_checkpoint_in_range:
    mov dl, [verify_action_index]
    inc byte ptr [verify_action_index]
    call compute_runtime_verify_signature
    mov [verify_observed_signature], ax
    xor bx, bx
    mov bl, [demo_index]
    shl bx, 1
    mov si, [verify_demo_checkpoint_table + bx]
    xor bx, bx
    mov bl, dl
    shl bx, 1
    mov ax, [si + bx]
    mov [verify_expected_signature], ax
    cmp ax, [verify_observed_signature]
    je verify_checkpoint_done
    mov al, [demo_index]
    mov byte ptr [verify_result_demo_index], al
    mov byte ptr [demo_active], 0
    mov byte ptr [game_state], STATE_VERIFY_FAIL

verify_checkpoint_done:
    ret

finalize_runtime_verify_demo:
    mov byte ptr [demo_active], 0
    mov byte ptr [verify_action_pending], 0
    mov al, [demo_index]
    mov byte ptr [verify_result_demo_index], al
    xor bx, bx
    mov bl, al
    mov al, [verify_action_index]
    cmp al, [verify_demo_checkpoint_count_table + bx]
    je verify_demo_action_count_ok
    call compute_runtime_verify_signature
    mov [verify_observed_signature], ax
    xor bx, bx
    mov bl, [verify_result_demo_index]
    shl bx, 1
    mov ax, [verify_demo_final_signature_table + bx]
    mov [verify_expected_signature], ax
    mov byte ptr [game_state], STATE_VERIFY_FAIL
    ret

verify_demo_action_count_ok:
    call compute_runtime_verify_signature
    mov [verify_observed_signature], ax
    xor bx, bx
    mov bl, [verify_result_demo_index]
    shl bx, 1
    mov ax, [verify_demo_final_signature_table + bx]
    mov [verify_expected_signature], ax
    cmp ax, [verify_observed_signature]
    jne verify_demo_fail
    mov byte ptr [game_state], STATE_VERIFY_PASS
    ret

verify_demo_fail:
    mov byte ptr [game_state], STATE_VERIFY_FAIL
    ret

compute_runtime_verify_signature:
    push bx
    push cx
    push dx
    push si
    mov ax, 0A55Ah
    mov bl, [game_state]
    call verify_sig_mix_byte
    mov bl, [sector_num]
    call verify_sig_mix_byte
    mov bl, [current_template_index]
    call verify_sig_mix_byte
    mov bl, [player_x]
    call verify_sig_mix_byte
    mov bl, [player_y]
    call verify_sig_mix_byte
    mov bl, [shield_count]
    call verify_sig_mix_byte
    mov bl, [pulse_count]
    call verify_sig_mix_byte
    mov bl, [data_count]
    call verify_sig_mix_byte
    mov bl, [kill_count]
    call verify_sig_mix_byte
    mov dx, [score_total]
    call verify_sig_mix_word
    mov bl, [sector_actions]
    call verify_sig_mix_byte
    mov bl, [sector_hits]
    call verify_sig_mix_byte
    mov bl, [sector_pulses_used]
    call verify_sig_mix_byte
    mov bl, [spoof_timer]
    call verify_sig_mix_byte
    mov dx, [rng_state]
    call verify_sig_mix_word
    mov si, offset enemies
    mov cx, MAX_ENEMIES

verify_sig_enemy_loop:
    mov bl, [si + ENEMY_ALIVE]
    call verify_sig_mix_byte
    mov bl, [si + ENEMY_X]
    call verify_sig_mix_byte
    mov bl, [si + ENEMY_Y]
    call verify_sig_mix_byte
    mov bl, [si + ENEMY_KIND]
    call verify_sig_mix_byte
    add si, ENEMY_SIZE
    loop verify_sig_enemy_loop
    pop si
    pop dx
    pop cx
    pop bx
    ret

verify_sig_mix_word:
    push bx
    mov bl, dl
    call verify_sig_mix_byte
    mov bl, dh
    call verify_sig_mix_byte
    pop bx
    ret

verify_sig_mix_byte:
    rol ax, 1
    xor al, bl
    add ax, 173Dh
    ret
