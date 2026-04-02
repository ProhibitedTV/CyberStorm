get_enemy_sprite:
    mov al, [si + ENEMY_KIND]
    cmp al, ENEMY_FLANKER
    je get_enemy_sprite_flanker
    cmp al, ENEMY_WARDEN
    je get_enemy_sprite_warden
    call get_visual_cycle_phase
    cmp al, 0
    je get_enemy_sprite_a
    cmp al, 3
    je get_enemy_sprite_a
    mov si, offset sprite_enemy_b
    ret

get_enemy_sprite_flanker:
    call get_visual_cycle_phase
    cmp al, 0
    je get_enemy_sprite_flanker_a
    cmp al, 3
    je get_enemy_sprite_flanker_a
    mov si, offset sprite_enemy_flanker_b
    ret

get_enemy_sprite_flanker_a:
    mov si, offset sprite_enemy_flanker_a
    ret

get_enemy_sprite_warden:
    call get_visual_cycle_phase
    test al, 2
    jz get_enemy_sprite_warden_a
    mov si, offset sprite_enemy_warden_b
    ret

get_enemy_sprite_a:
    mov si, offset sprite_enemy_a
    ret

get_enemy_sprite_warden_a:
    mov si, offset sprite_enemy_warden_a
    ret

get_player_sprite:
    call get_visual_cycle_phase
    cmp al, 0
    je get_player_sprite_a
    cmp al, 3
    je get_player_sprite_a
    mov si, offset sprite_player_b
    ret
get_player_sprite_a:
    mov si, offset sprite_player_a
    ret

render_enemies:
    mov si, offset enemies
    mov cx, MAX_ENEMIES

render_enemy_loop:
    cmp byte ptr [si + ENEMY_ALIVE], 0
    je render_enemy_next
    xor bx, bx
    mov bl, [si + ENEMY_X]
    shl bx, TILE_SHIFT
    add bx, MAP_PIXEL_X
    xor dx, dx
    mov dl, [si + ENEMY_Y]
    shl dx, TILE_SHIFT
    add dx, MAP_PIXEL_Y
    ; Four-beat motion keeps entities lively, but the 1px offsets are small
    ; enough that tile occupancy and threat positions stay immediately readable.
    call get_visual_cycle_phase
    mov ah, al
    mov al, [si + ENEMY_KIND]
    cmp al, ENEMY_WARDEN
    je enemy_bob_ready
    cmp al, ENEMY_FLANKER
    je enemy_bob_flanker
    cmp ah, 1
    je enemy_bob_rusher_down
    cmp ah, 3
    je enemy_bob_rusher_up
    jmp enemy_bob_ready

enemy_bob_rusher_down:
    inc dx
    jmp enemy_bob_ready

enemy_bob_rusher_up:
    dec dx
    jmp enemy_bob_ready

enemy_bob_flanker:
    cmp ah, 1
    je enemy_bob_flanker_left
    cmp ah, 3
    je enemy_bob_flanker_right
    jmp enemy_bob_ready

enemy_bob_flanker_left:
    dec bx
    jmp enemy_bob_ready

enemy_bob_flanker_right:
    inc bx

enemy_bob_ready:
    call draw_entity_shadow_blob
    call draw_enemy_motion_trail
    cmp al, ENEMY_WARDEN
    jne enemy_draw_ready
    cmp byte ptr [sector_num], 3
    jne enemy_draw_ready
    push ax
    push bx
    push dx
    mov cx, 10
    mov bp, 10
    test byte ptr [anim_phase], 1
    jz elite_warden_aura_base
    mov al, PAL_WHITE
    jmp elite_warden_aura_ready

elite_warden_aura_base:
    mov al, PAL_GATE

elite_warden_aura_ready:
    call draw_rect_outline
    pop dx
    pop bx
    pop ax

enemy_draw_ready:
    push si
    call get_enemy_sprite
    call draw_sprite8
    pop si

render_enemy_next:
    add si, ENEMY_SIZE
    dec cx
    jz render_enemies_done
    jmp render_enemy_loop
render_enemies_done:
    ret

render_player:
    xor bx, bx
    mov bl, [player_x]
    shl bx, TILE_SHIFT
    add bx, MAP_PIXEL_X
    xor dx, dx
    mov dl, [player_y]
    shl dx, TILE_SHIFT
    add dx, MAP_PIXEL_Y
    call get_visual_cycle_phase
    cmp al, 1
    je player_bob_up
    cmp al, 3
    je player_bob_down
    jmp player_bob_ready

player_bob_up:
    dec dx
    jmp player_bob_ready

player_bob_down:
    inc dx
player_bob_ready:
    call draw_entity_shadow_blob
    call draw_player_motion_trail
    call get_player_sprite
    call draw_sprite8
    ret

draw_entity_shadow_blob:
    push si
    push dx
    add dx, 5
    mov si, offset sprite_shadow_blob
    call draw_sprite8
    pop dx
    pop si
    ret

draw_enemy_motion_trail:
    cmp al, ENEMY_WARDEN
    jne enemy_motion_trail_done
    cmp byte ptr [sector_num], 3
    jne enemy_motion_trail_done
    test byte ptr [anim_phase], 1
    jz enemy_motion_trail_base
    mov al, PAL_WHITE
    jmp enemy_motion_trail_ready

enemy_motion_trail_base:
    mov al, PAL_RED2

enemy_motion_trail_ready:
    push ax
    push bx
    push dx
    push cx
    push bp
    sub bx, 2
    add dx, 3
    mov cx, 3
    mov bp, 1
    call fill_rect
    add bx, 9
    call fill_rect
    pop bp
    pop cx
    pop dx
    pop bx
    pop ax

enemy_motion_trail_done:
    ret

draw_player_motion_trail:
    cmp byte ptr [feedback_timer], 0
    je player_motion_trail_done
    mov al, [message_id]
    cmp al, MSG_PULSE
    je player_motion_trail_live
    cmp al, MSG_SHARD
    je player_motion_trail_live
    cmp al, MSG_GATE
    jne player_motion_trail_done

player_motion_trail_live:
    test byte ptr [anim_phase], 1
    jz player_motion_trail_base
    mov al, PAL_WHITE
    jmp player_motion_trail_ready

player_motion_trail_base:
    mov al, PAL_CYAN2

player_motion_trail_ready:
    push ax
    push bx
    push dx
    push cx
    push bp
    cmp byte ptr [last_player_dx], 0
    jg player_motion_right
    jl player_motion_left
    cmp byte ptr [last_player_dy], 0
    jg player_motion_down
    jl player_motion_up
    jmp player_motion_trail_exit

player_motion_right:
    sub bx, 3
    add dx, 3
    mov cx, 3
    mov bp, 2
    call fill_rect
    jmp player_motion_trail_exit

player_motion_left:
    add bx, 8
    add dx, 3
    mov cx, 3
    mov bp, 2
    call fill_rect
    jmp player_motion_trail_exit

player_motion_down:
    add bx, 3
    sub dx, 3
    mov cx, 2
    mov bp, 3
    call fill_rect
    jmp player_motion_trail_exit

player_motion_up:
    add bx, 3
    add dx, 8
    mov cx, 2
    mov bp, 3
    call fill_rect

player_motion_trail_exit:
    pop bp
    pop cx
    pop dx
    pop bx
    pop ax

player_motion_trail_done:
    ret
