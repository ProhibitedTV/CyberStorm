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
    mov al, PAL_GATE
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
    mov al, PAL_GATE
open_gate_color_ready2:
    call fill_rect
    pop dx
    pop bx
    call get_gate_sprite
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
