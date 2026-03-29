render_game_effects:
    cmp byte ptr [feedback_timer], 0
    je effects_done
    mov al, [message_id]
    cmp al, MSG_PULSE
    je effect_draw_pulse
    cmp al, MSG_HIT
    je effect_draw_damage
    cmp al, MSG_SURGE
    je effect_draw_damage
    cmp al, MSG_SHARD
    je effect_draw_shard
    cmp al, MSG_GATE
    je effect_draw_gate
    cmp al, MSG_KILL
    je effect_draw_kill
    cmp al, MSG_TRAP
    je effect_draw_kill
    cmp al, MSG_RECHARGE
    je effect_draw_energy
    cmp al, MSG_NOPULSE
    je effect_draw_dry
    jmp effects_done

effect_draw_pulse:
    call draw_pulse_effect
    jmp effects_done

effect_draw_damage:
    call draw_damage_flash
    jmp effects_done

effect_draw_shard:
    call draw_shard_flash
    jmp effects_done

effect_draw_gate:
    call draw_gate_flash
    jmp effects_done

effect_draw_kill:
    call draw_kill_flash
    jmp effects_done

effect_draw_energy:
    call draw_energy_flash
    jmp effects_done

effect_draw_dry:
    call draw_dry_flash

effects_done:
    ret

draw_damage_flash:
    mov bx, 4
    mov dx, 4
    mov cx, 312
    mov bp, 192
    test byte ptr [anim_phase], 1
    jz damage_flash_base
    mov al, PAL_RED2
    jmp damage_flash_ready

damage_flash_base:
    mov al, PAL_RED

damage_flash_ready:
    call draw_rect_outline
    mov bx, 10
    mov dx, 8
    mov cx, 300
    mov bp, 4
    call fill_rect
    mov dx, 188
    call fill_rect
    ret

draw_shard_flash:
    mov bx, 8
    mov dx, 32
    mov cx, 240
    mov bp, 136
    test byte ptr [anim_phase], 1
    jz shard_flash_base
    mov al, PAL_WHITE
    jmp shard_flash_ready

shard_flash_base:
    mov al, PAL_CYAN2

shard_flash_ready:
    call draw_rect_outline
    ret

draw_gate_flash:
    mov bx, 8
    mov dx, 32
    mov cx, 240
    mov bp, 136
    test byte ptr [anim_phase], 1
    jz gate_flash_base
    mov al, PAL_WHITE
    jmp gate_flash_ready

gate_flash_base:
    mov al, PAL_GATE

gate_flash_ready:
    call draw_rect_outline
    xor bx, bx
    mov bl, [exit_x]
    shl bx, TILE_SHIFT
    add bx, MAP_PIXEL_X
    dec bx
    xor dx, dx
    mov dl, [exit_y]
    shl dx, TILE_SHIFT
    add dx, MAP_PIXEL_Y
    dec dx
    mov cx, 10
    mov bp, 10
    call draw_rect_outline
    ret

draw_kill_flash:
    mov bx, 12
    mov dx, 96
    mov cx, 232
    mov bp, 2
    test byte ptr [anim_phase], 1
    jz kill_flash_base
    mov al, PAL_WHITE
    jmp kill_flash_ready

kill_flash_base:
    mov al, PAL_CYAN

kill_flash_ready:
    call fill_rect
    mov bx, 126
    mov dx, 40
    mov cx, 2
    mov bp, 120
    call fill_rect
    ret

draw_energy_flash:
    mov bx, 252
    mov dx, 82
    mov cx, 56
    mov bp, 52
    test byte ptr [anim_phase], 1
    jz energy_flash_base
    mov al, PAL_WHITE
    jmp energy_flash_ready

energy_flash_base:
    mov al, PAL_AMBER

energy_flash_ready:
    call draw_rect_outline
    ret

draw_dry_flash:
    mov bx, 252
    mov dx, 82
    mov cx, 56
    mov bp, 52
    test byte ptr [anim_phase], 1
    jz dry_flash_base
    mov al, PAL_RED2
    jmp dry_flash_ready

dry_flash_base:
    mov al, PAL_RED

dry_flash_ready:
    call draw_rect_outline
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
    cmp byte ptr [feedback_timer], 3
    jb pulse_effect_done
    add bx, 2
    add dx, 2
    mov cx, 12
    mov bp, 12
    mov al, PAL_CYAN
    call draw_rect_outline
    cmp byte ptr [feedback_timer], 5
    jb pulse_effect_done
    sub bx, 4
    sub dx, 4
    mov cx, 20
    mov bp, 20
    mov al, PAL_WHITE
    call draw_rect_outline

pulse_effect_done:
    ret
