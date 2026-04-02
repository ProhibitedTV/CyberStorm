render_game_effects:
    call draw_spoof_route
    call draw_enemy_pressure
    call draw_gate_tension
    cmp byte ptr [feedback_timer], 0
    je effects_done
    mov al, [message_id]
    cmp al, MSG_SECTOR
    je effect_draw_sector
    cmp al, MSG_SPOOF
    je effect_draw_spoof
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

effect_draw_sector:
    call draw_sector_entry_flash
    call draw_sector_entry_card
    jmp effects_done

effect_draw_spoof:
    call draw_spoof_flash
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

draw_spoof_route:
    cmp byte ptr [spoof_timer], 0
    je spoof_route_done
    test byte ptr [anim_phase], 1
    jz spoof_route_base
    mov al, PAL_WHITE
    jmp spoof_route_color_ready

spoof_route_base:
    mov al, PAL_CYAN2

spoof_route_color_ready:
    push ax
    mov bl, [spoof_x]
    mov bh, [spoof_y]
    call draw_tile_outline
    pop ax
    mov bx, MAP_PIXEL_X
    xor dx, dx
    mov dl, [spoof_y]
    shl dx, TILE_SHIFT
    add dx, MAP_PIXEL_Y
    add dx, 4
    mov cx, MAP_W * TILE_SIZE
    mov bp, 1
    call fill_rect
    xor bx, bx
    mov bl, [exit_x]
    shl bx, TILE_SHIFT
    add bx, MAP_PIXEL_X
    add bx, 3
    mov dx, MAP_PIXEL_Y
    mov cx, 1
    mov bp, MAP_H * TILE_SIZE
    call fill_rect

spoof_route_done:
    ret

draw_spoof_flash:
    call draw_spoof_route
    test byte ptr [anim_phase], 1
    jz spoof_flash_base
    mov al, PAL_WHITE
    jmp spoof_flash_ready

spoof_flash_base:
    mov al, PAL_CYAN

spoof_flash_ready:
    mov bx, 8
    mov dx, 32
    mov cx, 240
    mov bp, 136
    call draw_rect_outline
    call get_major_feedback_stage
    cmp al, 3
    jb spoof_flash_done
    mov bx, MAP_PIXEL_X
    xor dx, dx
    mov dl, [spoof_y]
    shl dx, TILE_SHIFT
    add dx, MAP_PIXEL_Y
    add dx, 2
    mov cx, MAP_W * TILE_SIZE
    mov bp, 4
    mov al, PAL_WHITE
    call fill_rect
    xor bx, bx
    mov bl, [exit_x]
    shl bx, TILE_SHIFT
    add bx, MAP_PIXEL_X
    sub bx, 2
    mov dx, MAP_PIXEL_Y
    mov cx, 6
    mov bp, MAP_H * TILE_SIZE
    mov al, PAL_CYAN2
    call fill_rect

spoof_flash_done:
    ret

draw_enemy_pressure:
    cmp byte ptr [threat_level], THREAT_NONE
    je enemy_pressure_done
    cmp byte ptr [threat_level], THREAT_ELITE
    je pressure_elite
    test byte ptr [anim_phase], 1
    jz pressure_near_base
    mov al, PAL_WHITE
    jmp pressure_color_ready

pressure_near_base:
    mov al, PAL_AMBER
    jmp pressure_color_ready

pressure_elite:
    test byte ptr [anim_phase], 1
    jz pressure_elite_base
    mov al, PAL_WHITE
    jmp pressure_color_ready

pressure_elite_base:
    mov al, PAL_RED2

pressure_color_ready:
    push ax
    mov bl, [player_x]
    mov bh, [player_y]
    call draw_tile_outline
    pop ax
    mov bl, [threat_x]
    mov bh, [threat_y]
    call draw_tile_outline
    ret

enemy_pressure_done:
    ret

draw_tile_outline:
    push ax
    push bx
    push cx
    push dx
    push bp
    shl bx, TILE_SHIFT
    add bx, MAP_PIXEL_X
    dec bx
    xor dx, dx
    mov dl, bh
    shl dx, TILE_SHIFT
    add dx, MAP_PIXEL_Y
    dec dx
    mov cx, 10
    mov bp, 10
    call draw_rect_outline
    pop bp
    pop dx
    pop cx
    pop bx
    pop ax
    ret

draw_effect_focus_outline:
    push ax
    mov bl, [effect_x]
    mov bh, [effect_y]
    call draw_tile_outline
    pop ax
    ret

get_major_feedback_stage:
    mov al, FEEDBACK_TICKS_MAJOR
    sub al, [feedback_timer]
    ret

draw_sector_ambient:
    ; Ambient marks are intentionally thin and tile-adjacent. They now render
    ; under entities so sectors can breathe without obscuring threats.
    mov al, [sector_num]
    cmp al, 2
    je sector_ambient_furnace
    cmp al, 3
    je sector_ambient_lock
    jmp sector_ambient_scout

sector_ambient_scout:
    call get_visual_cycle_phase
    test al, 1
    jz sector_scout_base
    mov al, PAL_WHITE
    jmp sector_scout_color_ready

sector_scout_base:
    mov al, PAL_CYAN2

sector_scout_color_ready:
    push ax
    mov bx, MAP_PIXEL_X
    xor dx, dx
    mov dl, [anim_phase]
    and dl, 0Eh
    shl dx, 3
    add dx, MAP_PIXEL_Y
    mov cx, MAP_W * TILE_SIZE
    mov bp, 1
    call fill_rect
    pop ax
    mov bx, MAP_PIXEL_X + 52
    add dx, 40
    cmp dx, MAP_PIXEL_Y + (MAP_H * TILE_SIZE)
    jb sector_scout_packet_ready
    sub dx, MAP_H * TILE_SIZE

sector_scout_packet_ready:
    mov cx, 88
    mov bp, 1
    call fill_rect
    ret

sector_ambient_furnace:
    test byte ptr [anim_phase], 1
    jz sector_furnace_base
    mov al, PAL_RED2
    jmp sector_furnace_ready

sector_furnace_base:
    mov al, PAL_AMBER

sector_furnace_ready:
    mov bx, MAP_PIXEL_X - 2
    mov dx, MAP_PIXEL_Y
    mov cx, 1
    mov bp, MAP_H * TILE_SIZE
    call fill_rect
    mov bx, MAP_PIXEL_X + (MAP_W * TILE_SIZE) + 1
    call fill_rect
    push ax
    xor dx, dx
    mov dl, [anim_phase]
    and dl, 0Fh
    shl dx, 3
    add dx, MAP_PIXEL_Y
    mov bx, MAP_PIXEL_X + 3
    mov cx, 2
    mov bp, 1
    call fill_rect
    add dx, 24
    cmp dx, MAP_PIXEL_Y + (MAP_H * TILE_SIZE)
    jb sector_furnace_ember_right
    sub dx, MAP_H * TILE_SIZE

sector_furnace_ember_right:
    mov bx, MAP_PIXEL_X + (MAP_W * TILE_SIZE) - 5
    call fill_rect
    pop ax
    ret

sector_ambient_lock:
    test byte ptr [anim_phase], 1
    jz sector_lock_base
    mov al, PAL_WHITE
    jmp sector_lock_ready

sector_lock_base:
    mov al, PAL_RED2

sector_lock_ready:
    xor bx, bx
    mov bl, [exit_x]
    shl bx, TILE_SHIFT
    add bx, MAP_PIXEL_X
    add bx, 3
    mov dx, MAP_PIXEL_Y
    mov cx, 1
    mov bp, MAP_H * TILE_SIZE
    call fill_rect
    push ax
    xor dx, dx
    mov dl, [exit_y]
    shl dx, TILE_SHIFT
    add dx, MAP_PIXEL_Y
    add dx, 3
    mov bx, MAP_PIXEL_X + (MAP_W * TILE_SIZE) - 52
    mov cx, 48
    mov bp, 1
    call fill_rect
    add dx, 16
    call fill_rect
    pop ax
    ret

draw_gate_tension:
    ; One shard away from unlock, the exit gets a persistent pulse so the board
    ; starts telegraphing the coming route change before the final pickup lands.
    cmp byte ptr [game_state], STATE_PLAYING
    jne gate_tension_done
    cmp byte ptr [data_count], SHARD_COUNT - 1
    jne gate_tension_done
    test byte ptr [anim_phase], 1
    jz gate_tension_base
    mov al, PAL_WHITE
    jmp gate_tension_ready

gate_tension_base:
    mov al, PAL_GATE

gate_tension_ready:
    mov bl, [exit_x]
    mov bh, [exit_y]
    call draw_tile_outline

gate_tension_done:
    ret

draw_sector_entry_flash:
    ; Sector entry now gets a short wipe that rides the same beat as the
    ; sector SFX, so loading a new breach feels like an arrival cue.
    cmp byte ptr [sound_id], SFX_SECTOR
    jne sector_entry_anim
    cmp byte ptr [sound_timer], 0
    je sector_entry_anim
    test byte ptr [sound_phase], 1
    jz sector_entry_base
    mov al, PAL_WHITE
    jmp sector_entry_outline_ready

sector_entry_anim:
    test byte ptr [anim_phase], 1
    jz sector_entry_base
    mov al, PAL_WHITE
    jmp sector_entry_outline_ready

sector_entry_base:
    call get_sector_accent_color

sector_entry_outline_ready:
    mov bx, 8
    mov dx, 32
    mov cx, 240
    mov bp, 136
    call draw_rect_outline
    mov al, [sector_num]
    cmp al, 2
    je sector_entry_furnace
    cmp al, 3
    je sector_entry_lock
    jmp sector_entry_scout

sector_entry_scout:
    mov bx, MAP_PIXEL_X
    xor dx, dx
    mov dl, [anim_phase]
    and dl, 0Eh
    shl dx, 3
    add dx, MAP_PIXEL_Y
    mov cx, MAP_W * TILE_SIZE
    mov bp, 2
    mov al, PAL_WHITE
    call fill_rect
    jmp sector_entry_wipe

sector_entry_furnace:
    mov bx, MAP_PIXEL_X - 4
    mov dx, MAP_PIXEL_Y - 2
    mov cx, (MAP_W * TILE_SIZE) + 8
    mov bp, 1
    mov al, PAL_WHITE
    call fill_rect
    mov dx, MAP_PIXEL_Y + (MAP_H * TILE_SIZE) + 1
    call fill_rect
    mov bx, MAP_PIXEL_X - 2
    mov dx, MAP_PIXEL_Y
    mov cx, 2
    mov bp, MAP_H * TILE_SIZE
    mov al, PAL_RED2
    call fill_rect
    mov bx, MAP_PIXEL_X + (MAP_W * TILE_SIZE)
    call fill_rect
    jmp sector_entry_wipe

sector_entry_lock:
    xor bx, bx
    mov bl, [exit_x]
    shl bx, TILE_SHIFT
    add bx, MAP_PIXEL_X
    add bx, 2
    mov dx, MAP_PIXEL_Y
    mov cx, 3
    mov bp, MAP_H * TILE_SIZE
    mov al, PAL_WHITE
    call fill_rect
    mov bx, MAP_PIXEL_X - 1
    mov dx, MAP_PIXEL_Y - 1
    mov cx, (MAP_W * TILE_SIZE) + 2
    mov bp, 1
    mov al, PAL_RED2
    call fill_rect
    jmp sector_entry_wipe

sector_entry_wipe:
    call get_major_feedback_stage
    mov bl, 20
    mul bl
    cmp ax, MAP_W * TILE_SIZE
    jbe sector_entry_wipe_ready
    mov ax, MAP_W * TILE_SIZE

sector_entry_wipe_ready:
    mov cx, ax
    mov bx, MAP_PIXEL_X
    mov dx, MAP_PIXEL_Y + 58
    mov bp, 2
    mov al, PAL_WHITE
    call fill_rect
    call get_sector_accent_color
    mov dx, MAP_PIXEL_Y + 62
    mov bp, 1
    call fill_rect
    ret

draw_sector_entry_card:
    ; The sector card rides the opening feedback window only, so it brands the
    ; breach without hiding the board for long once the run starts moving again.
    call get_major_feedback_stage
    cmp al, SECTOR_CARD_STAGE_LIMIT
    jae sector_entry_card_done
    push ax
    mov bx, 68
    mov dx, 48
    xor ah, ah
    add dx, ax
    call get_sector_card_asset_offset
    call draw_presentation_asset_2x
    mov bx, 108
    mov dx, 58
    call get_sector_name_ptr
    call get_sector_title_color
    mov ah, al
    call draw_text_small
    ; Scenario callouts sit on the existing sector-entry card so authored
    ; breach routes read as part of the same intro beat as the transition wipe.
    mov bx, 90
    mov dx, 72
    call get_current_template_scenario_name_ptr
    mov ah, PAL_WHITE
    call draw_text_small
    mov bx, 76
    mov dx, 84
    call get_current_template_scenario_entry_ptr
    mov ah, PAL_WHITE
    call draw_text_small
    pop ax

sector_entry_card_done:
    ret

get_sector_card_asset_offset:
    mov al, [sector_num]
    cmp al, 2
    je sector_card_furnace
    cmp al, 3
    je sector_card_lock
    mov si, PRESENT_BANNER_SECTOR1_CARD_OFFSET
    ret

sector_card_furnace:
    mov si, PRESENT_BANNER_SECTOR2_CARD_OFFSET
    ret

sector_card_lock:
    mov si, PRESENT_BANNER_SECTOR3_CARD_OFFSET
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
    test byte ptr [anim_phase], 1
    jz damage_focus_ready
    mov al, PAL_WHITE
damage_focus_ready:
    call draw_effect_focus_outline
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
    mov al, PAL_WHITE
    call draw_effect_focus_outline
    ret

draw_gate_flash:
    mov bx, 8
    mov dx, 32
    mov cx, 240
    mov bp, 136
    cmp byte ptr [sound_id], SFX_GATE
    jne gate_flash_anim
    cmp byte ptr [sound_timer], 0
    je gate_flash_anim
    test byte ptr [sound_phase], 1
    jz gate_flash_base
    mov al, PAL_WHITE
    jmp gate_flash_ready

gate_flash_anim:
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
    call get_major_feedback_stage
    cmp al, 2
    jb gate_flash_done
    xor bx, bx
    mov bl, [exit_x]
    shl bx, TILE_SHIFT
    add bx, MAP_PIXEL_X
    sub bx, 3
    xor dx, dx
    mov dl, [exit_y]
    shl dx, TILE_SHIFT
    add dx, MAP_PIXEL_Y
    sub dx, 3
    mov cx, 14
    mov bp, 14
    mov al, PAL_WHITE
    call draw_rect_outline
    call get_major_feedback_stage
    cmp al, 4
    jb gate_flash_done
    xor bx, bx
    mov bl, [exit_x]
    shl bx, TILE_SHIFT
    add bx, MAP_PIXEL_X
    sub bx, 5
    xor dx, dx
    mov dl, [exit_y]
    shl dx, TILE_SHIFT
    add dx, MAP_PIXEL_Y
    sub dx, 5
    mov cx, 18
    mov bp, 18
    mov al, PAL_GATE
    call draw_rect_outline
    call get_major_feedback_stage
    cmp al, 6
    jb gate_flash_done
    xor bx, bx
    mov bl, [exit_x]
    shl bx, TILE_SHIFT
    add bx, MAP_PIXEL_X
    add bx, 3
    mov dx, MAP_PIXEL_Y
    mov cx, 1
    mov bp, MAP_H * TILE_SIZE
    mov al, PAL_WHITE
    call fill_rect
    mov bx, 252
    mov dx, 124
    mov cx, 56
    mov bp, 34
    mov al, PAL_WHITE
    call draw_rect_outline

gate_flash_done:
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
    test byte ptr [anim_phase], 1
    jz kill_focus_ready
    mov al, PAL_WHITE
kill_focus_ready:
    call draw_effect_focus_outline
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
    xor dx, dx
    mov dl, [player_y]
    shl dx, 3
    add dx, MAP_PIXEL_Y
    xor ah, ah
    mov al, FEEDBACK_TICKS_STANDARD
    sub al, [feedback_timer]
    mov si, ax
    mov cx, 16
    mov bp, 16
    test byte ptr [anim_phase], 1
    jz pulse_effect_base
    mov al, PAL_WHITE
    jmp pulse_effect_ready

pulse_effect_base:
    mov al, PAL_CYAN2

pulse_effect_ready:
    push bx
    push dx
    sub bx, 4
    sub dx, 4
    call draw_rect_outline
    pop dx
    pop bx
    cmp si, 1
    jb pulse_effect_done
    call get_sector_accent_color
    push bx
    push dx
    sub bx, 6
    add dx, 3
    mov cx, 20
    mov bp, 1
    call fill_rect
    pop dx
    pop bx
    push bx
    push dx
    add bx, 3
    sub dx, 6
    mov cx, 1
    mov bp, 20
    call fill_rect
    pop dx
    pop bx
    cmp si, 3
    jb pulse_effect_done
    push bx
    push dx
    sub bx, 8
    sub dx, 8
    mov cx, 24
    mov bp, 24
    mov al, PAL_WHITE
    call draw_rect_outline
    pop dx
    pop bx
    cmp si, 5
    jb pulse_effect_done
    call get_sector_accent_color
    push bx
    push dx
    sub bx, 10
    add dx, 3
    mov cx, 28
    mov bp, 1
    call fill_rect
    pop dx
    pop bx
    push bx
    push dx
    add bx, 3
    sub dx, 10
    mov cx, 1
    mov bp, 28
    call fill_rect
    pop dx
    pop bx
    push bx
    push dx
    sub bx, 12
    sub dx, 12
    mov cx, 32
    mov bp, 32
    mov al, PAL_WHITE
    call draw_rect_outline
    pop dx
    pop bx

pulse_effect_done:
    ret
