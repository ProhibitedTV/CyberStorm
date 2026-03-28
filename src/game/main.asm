start:
    push cs
    pop ds

    mov ax, 0013h
    int 10h
    call init_palette

    xor ah, ah
    int 1Ah
    mov [rng_state], dx
    cmp dx, 0
    jne seed_ready
    mov word ptr [rng_state], 0ACE1h

seed_ready:
    xor ah, ah
    int 1Ah
    mov [last_tick], dx
    mov byte ptr [anim_phase], 0
    mov byte ptr [splash_ticks], 0
    mov byte ptr [game_state], STATE_SPLASH
    mov byte ptr [message_id], MSG_SECTOR

main_loop:
    call wait_frame_tick
    call update_frontend_state
    call render_screen
    call poll_key_event
    jnc main_loop

    cmp byte ptr [game_state], STATE_PLAYING
    je handle_play_input

    cmp byte ptr [game_state], STATE_SPLASH
    je handle_splash_input

    call start_new_run
    jmp main_loop

handle_splash_input:
    call is_enter_key
    jnc skip_splash
    call start_new_run
    jmp main_loop

skip_splash:
    mov byte ptr [game_state], STATE_TITLE
    call flush_key_buffer
    jmp main_loop

handle_play_input:
    call process_play_input
    jmp main_loop

wait_frame_tick:
wait_frame_tick_loop:
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
    mov byte ptr [game_state], STATE_PLAYING
    mov byte ptr [sector_num], 1
    mov byte ptr [shield_count], 5
    mov byte ptr [pulse_count], 3
    mov byte ptr [data_count], 0
    mov byte ptr [kill_count], 0
    call load_sector
    mov byte ptr [message_id], MSG_SECTOR
    call flush_key_buffer
    ret
