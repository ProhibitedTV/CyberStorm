render_map:
    mov si, offset map_tiles
    xor bh, bh
    mov cx, MAP_H

render_map_row:
    push cx
    xor bl, bl
    mov cx, MAP_W

render_map_col:
    push bx
    push cx
    push si
    xor ax, ax
    mov al, bl
    shl ax, 3
    add ax, MAP_PIXEL_X
    mov bx, ax
    xor ax, ax
    mov al, bh
    shl ax, 3
    add ax, MAP_PIXEL_Y
    mov dx, ax
    mov al, [si]
    call draw_tile
    pop si
    pop cx
    pop bx
    inc si
    inc bl
    loop render_map_col
    inc bh
    pop cx
    loop render_map_row
    ret

draw_tile:
    cmp al, TILE_WALL
    je draw_wall_tile
    cmp al, TILE_SHARD
    je draw_shard_tile
    cmp al, TILE_EXIT_LOCKED
    je draw_locked_tile
    cmp al, TILE_EXIT_OPEN
    je draw_open_tile
    jmp draw_floor_tile

draw_floor_tile:
    push ax
    push cx
    push bp
    mov cx, 8
    mov bp, 8
    mov al, PAL_FLOOR
    call fill_rect
    mov al, PAL_FLOOR2
    push bx
    push dx
    add bx, 1
    add dx, 1
    call put_pixel
    pop dx
    pop bx
    push bx
    push dx
    add bx, 5
    add dx, 6
    call put_pixel
    pop dx
    pop bx
    test byte ptr [anim_phase], 1
    jz floor_tile_done
    mov al, PAL_CYAN
    push bx
    push dx
    add bx, 2
    add dx, 2
    call put_pixel
    pop dx
    pop bx
    push bx
    push dx
    add bx, 6
    add dx, 3
    call put_pixel
    pop dx
    pop bx
    push bx
    push dx
    add bx, 3
    add dx, 5
    call put_pixel
    pop dx
    pop bx
floor_tile_done:
    pop bp
    pop cx
    pop ax
    ret

draw_wall_tile:
    push ax
    push cx
    push bp
    push bx
    push dx
    mov cx, 8
    mov bp, 8
    mov al, PAL_WALL
    call fill_rect
    pop dx
    pop bx
    push bx
    push dx
    mov cx, 8
    mov bp, 1
    mov al, PAL_WALL2
    call fill_rect
    pop dx
    pop bx
    push bx
    push dx
    mov cx, 1
    mov bp, 8
    mov al, PAL_WALL2
    call fill_rect
    pop dx
    pop bx
    add bx, 1
    test byte ptr [anim_phase], 1
    jz wall_pulse_low
    add dx, 2
    mov al, PAL_CYAN
    jmp wall_pulse_ready
wall_pulse_low:
    add dx, 5
    mov al, PAL_PANEL2
wall_pulse_ready:
    mov cx, 6
    mov bp, 1
    call fill_rect
    pop bp
    pop cx
    pop ax
    ret

draw_shard_tile:
    call draw_floor_tile
    call get_shard_sprite
    mov al, PAL_AMBER
    call draw_sprite8
    ret

draw_locked_tile:
    call draw_floor_tile
    push bx
    push dx
    add bx, 1
    add dx, 1
    mov cx, 2
    mov bp, 6
    test byte ptr [anim_phase], 1
    jz locked_gate_dim
    mov al, PAL_RED2
    jmp locked_gate_color_ready
locked_gate_dim:
    mov al, PAL_RED
locked_gate_color_ready:
    call fill_rect
    pop dx
    pop bx
    push bx
    push dx
    add bx, 5
    add dx, 1
    mov cx, 2
    mov bp, 6
    test byte ptr [anim_phase], 1
    jz locked_gate_dim2
    mov al, PAL_RED2
    jmp locked_gate_color_ready2
locked_gate_dim2:
    mov al, PAL_RED
locked_gate_color_ready2:
    call fill_rect
    pop dx
    pop bx
    add dx, 3
    mov cx, 8
    mov bp, 1
    test byte ptr [anim_phase], 1
    jz locked_gate_bar_dim
    mov al, PAL_RED
    jmp locked_gate_bar_ready
locked_gate_bar_dim:
    mov al, PAL_RED2
locked_gate_bar_ready:
    call fill_rect
    ret

draw_open_tile:
    call draw_floor_tile
    push bx
    push dx
    add bx, 1
    add dx, 1
    mov cx, 2
    mov bp, 6
    test byte ptr [anim_phase], 1
    jz open_gate_dim
    mov al, PAL_WHITE
    jmp open_gate_color_ready
open_gate_dim:
    mov al, PAL_CYAN2
open_gate_color_ready:
    call fill_rect
    pop dx
    pop bx
    push bx
    push dx
    add bx, 5
    add dx, 1
    mov cx, 2
    mov bp, 6
    test byte ptr [anim_phase], 1
    jz open_gate_dim2
    mov al, PAL_WHITE
    jmp open_gate_color_ready2
open_gate_dim2:
    mov al, PAL_CYAN2
open_gate_color_ready2:
    call fill_rect
    pop dx
    pop bx
    call get_gate_sprite
    test byte ptr [anim_phase], 1
    jz open_gate_sprite_dim
    mov al, PAL_WHITE
    jmp open_gate_sprite_ready
open_gate_sprite_dim:
    mov al, PAL_CYAN2
open_gate_sprite_ready:
    call draw_sprite8
    ret

get_shard_sprite:
    test byte ptr [anim_phase], 1
    jz get_shard_sprite_a
    mov si, offset sprite_shard_b
    ret
get_shard_sprite_a:
    mov si, offset sprite_shard_a
    ret

get_gate_sprite:
    test byte ptr [anim_phase], 1
    jz get_gate_sprite_a
    mov si, offset sprite_gate_b
    ret
get_gate_sprite_a:
    mov si, offset sprite_gate_a
    ret

get_enemy_sprite:
    test byte ptr [anim_phase], 1
    jz get_enemy_sprite_a
    mov si, offset sprite_enemy_b
    ret
get_enemy_sprite_a:
    mov si, offset sprite_enemy_a
    ret

get_player_sprite:
    test byte ptr [anim_phase], 1
    jz get_player_sprite_a
    mov si, offset sprite_player_b
    ret
get_player_sprite_a:
    mov si, offset sprite_player_a
    ret

render_enemies:
    mov si, offset enemies
    mov cx, MAX_ENEMIES

render_enemy_loop:
    cmp byte ptr [si], 0
    je render_enemy_next
    xor bx, bx
    mov bl, [si + 1]
    shl bx, 3
    add bx, MAP_PIXEL_X
    xor dx, dx
    mov dl, [si + 2]
    shl dx, 3
    add dx, MAP_PIXEL_Y
    test byte ptr [anim_phase], 1
    jz enemy_bob_ready
    inc dx
enemy_bob_ready:
    push si
    call get_enemy_sprite
    mov al, PAL_RED
    call draw_sprite8
    pop si

render_enemy_next:
    add si, ENEMY_SIZE
    loop render_enemy_loop
    ret

render_player:
    xor bx, bx
    mov bl, [player_x]
    shl bx, 3
    add bx, MAP_PIXEL_X
    xor dx, dx
    mov dl, [player_y]
    shl dx, 3
    add dx, MAP_PIXEL_Y
    test byte ptr [anim_phase], 1
    jz player_bob_ready
    dec dx
player_bob_ready:
    call get_player_sprite
    mov al, PAL_CYAN2
    call draw_sprite8
    ret

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
    mov al, PAL_RED
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
    mov al, PAL_CYAN2
    call draw_rect_outline
    ret
