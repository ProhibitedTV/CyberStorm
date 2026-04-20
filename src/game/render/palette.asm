PALETTE_ENV_STRIDE  equ 12
PALETTE_GATE_STRIDE equ 3

init_palette:
    push ax
    push cx
    push si
    xor al, al
    mov si, offset palette_data
    mov cx, PALETTE_BYTES / 3

init_palette_loop:
    push cx
    call set_palette_entry
    inc al
    pop cx
    loop init_palette_loop
    pop si
    pop cx
    pop ax
    ret

update_palette_animation:
    push ax
    push bx
    push si

    ; The environment palette steps on a slower 4-beat cadence than sprite
    ; frames so the sectors feel alive without turning floor/wall colors noisy.
    mov al, [anim_phase]
    shr al, 2
    and al, 03h
    mov bl, PALETTE_ENV_STRIDE
    mul bl
    mov bx, ax

    cmp byte ptr [game_state], STATE_PLAYING
    jne palette_cycle_scout
    mov al, [sector_num]
    cmp al, 2
    je palette_cycle_furnace
    cmp al, 3
    je palette_cycle_lock

palette_cycle_scout:
    mov si, offset palette_scout_cycle
    jmp palette_cycle_ready

palette_cycle_furnace:
    mov si, offset palette_furnace_cycle
    jmp palette_cycle_ready

palette_cycle_lock:
    mov si, offset palette_lock_cycle

palette_cycle_ready:
    add si, bx
    mov al, PAL_WALL
    call set_palette_entry
    mov al, PAL_WALL2
    call set_palette_entry
    mov al, PAL_FLOOR
    call set_palette_entry
    mov al, PAL_FLOOR2
    call set_palette_entry

    mov al, [anim_phase]
    shr al, 2
    and al, 03h
    mov bl, PALETTE_GATE_STRIDE
    mul bl
    mov bx, ax

    cmp byte ptr [game_state], STATE_PLAYING
    jne palette_gate_locked
    mov al, [data_count]
    cmp al, SHARD_COUNT
    jae palette_gate_open
    cmp al, SHARD_COUNT - 1
    jae palette_gate_primed

palette_gate_locked:
    mov si, offset palette_gate_locked_cycle
    jmp palette_gate_ready

palette_gate_primed:
    mov si, offset palette_gate_primed_cycle
    jmp palette_gate_ready

palette_gate_open:
    mov si, offset palette_gate_open_cycle

palette_gate_ready:
    add si, bx
    mov al, PAL_GATE
    call set_palette_entry

    cmp byte ptr [game_state], STATE_PLAYING
    jne palette_event_done
    cmp byte ptr [feedback_timer], 0
    je palette_event_done
    mov bl, [anim_phase]
    shr bl, 1
    and bl, 01h
    xor bh, bh
    mov ax, bx
    add bx, ax
    mov al, [message_id]
    cmp al, MSG_PULSE
    je palette_event_pulse
    cmp al, MSG_SURGE
    je palette_event_surge
    cmp al, MSG_TRAP
    je palette_event_surge
    cmp al, MSG_GATE
    jne palette_event_done
    mov si, offset palette_event_gate
    add si, bx
    mov al, PAL_GATE
    call set_palette_entry
    jmp palette_event_done

palette_event_pulse:
    mov si, offset palette_event_pulse_floor
    add si, bx
    mov al, PAL_FLOOR2
    call set_palette_entry
    mov si, offset palette_event_pulse_wall
    add si, bx
    mov al, PAL_WALL2
    call set_palette_entry
    jmp palette_event_done

palette_event_surge:
    mov si, offset palette_event_surge_floor
    add si, bx
    mov al, PAL_FLOOR2
    call set_palette_entry
    mov si, offset palette_event_surge_wall
    add si, bx
    mov al, PAL_WALL2
    call set_palette_entry

palette_event_done:

    pop si
    pop bx
    pop ax
    ret

set_palette_entry:
    push ax
    push bx
    push cx
    push dx
    xor bh, bh
    mov bl, al
    mov dx, 03C8h
    out dx, al
    inc dx
    lodsb
    out dx, al
    mov cl, al
    lodsb
    out dx, al
    mov ch, al
    lodsb
    out dx, al
    mov ah, al

    movzx ax, cl
    shr ax, 1
    shl ax, 11
    mov dx, ax

    movzx ax, ch
    shl ax, 5
    or dx, ax

    movzx ax, ah
    shr ax, 1
    or dx, ax

    shl bx, 1
    mov [palette_rgb565_table + bx], dx
    pop dx
    pop cx
    pop bx
    pop ax
    ret
