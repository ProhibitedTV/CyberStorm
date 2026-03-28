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
    mov byte ptr [game_state], STATE_TITLE
    mov byte ptr [message_id], MSG_SECTOR

main_loop:
    call wait_frame_tick
    call render_screen
    mov ah, 01h
    int 16h
    jz main_loop
    xor ax, ax
    int 16h

    cmp byte ptr [game_state], STATE_PLAYING
    je handle_play_input

    cmp al, 0Dh
    jne main_loop
    call start_new_run
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

start_new_run:
    mov byte ptr [game_state], STATE_PLAYING
    mov byte ptr [sector_num], 1
    mov byte ptr [shield_count], 5
    mov byte ptr [pulse_count], 3
    mov byte ptr [data_count], 0
    mov byte ptr [kill_count], 0
    call load_sector
    mov byte ptr [message_id], MSG_SECTOR
    ret
