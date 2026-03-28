render_game_effects:
    cmp byte ptr [message_id], MSG_PULSE
    jne check_hit_effect
    call draw_pulse_effect

check_hit_effect:
    cmp byte ptr [message_id], MSG_HIT
    jne effects_done
    mov bx, 4
    mov dx, 4
    mov cx, 312
    mov bp, 192
    test byte ptr [anim_phase], 1
    jz hit_effect_base
    mov al, PAL_RED2
    jmp hit_effect_ready

hit_effect_base:
    mov al, PAL_RED

hit_effect_ready:
    call draw_rect_outline

effects_done:
    ret

draw_pulse_effect:
    xor bx, bx
    mov bl, [player_x]
    shl bx, 3
    add bx, MAP_PIXEL_X
    sub bx, 4
    xor dx, dx
    mov dl, [player_y]
    shl dx, 3
    add dx, MAP_PIXEL_Y
    sub dx, 4
    mov cx, 16
    mov bp, 16
    test byte ptr [anim_phase], 1
    jz pulse_effect_base
    mov al, PAL_WHITE
    jmp pulse_effect_ready

pulse_effect_base:
    mov al, PAL_CYAN2

pulse_effect_ready:
    call draw_rect_outline
    test byte ptr [anim_phase], 1
    jz pulse_effect_done
    add bx, 2
    add dx, 2
    mov cx, 12
    mov bp, 12
    mov al, PAL_CYAN
    call draw_rect_outline

pulse_effect_done:
    ret
