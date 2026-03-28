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
    shl ax, TILE_SHIFT
    add ax, MAP_PIXEL_X
    mov bx, ax
    xor ax, ax
    mov al, bh
    shl ax, TILE_SHIFT
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
    cmp al, TILE_SURGE
    je draw_surge_tile
    jmp draw_floor_tile

draw_floor_tile:
    call get_floor_tile_frame
    call draw_bitmap8
    ret

draw_wall_tile:
    call get_wall_tile_frame
    call draw_bitmap8
    ret

draw_shard_tile:
    call draw_floor_tile
    call get_shard_sprite
    call draw_sprite8
    ret

draw_locked_tile:
    call get_locked_tile_frame
    call draw_bitmap8
    ret

draw_open_tile:
    call get_open_tile_frame
    call draw_bitmap8
    ret

draw_surge_tile:
    call get_surge_tile_frame
    call draw_bitmap8
    ret

get_floor_tile_frame:
    test byte ptr [anim_phase], 1
    jz get_floor_tile_a
    mov si, offset tile_floor_b
    ret
get_floor_tile_a:
    mov si, offset tile_floor_a
    ret

get_wall_tile_frame:
    test byte ptr [anim_phase], 1
    jz get_wall_tile_a
    mov si, offset tile_wall_b
    ret
get_wall_tile_a:
    mov si, offset tile_wall_a
    ret

get_locked_tile_frame:
    test byte ptr [anim_phase], 1
    jz get_locked_tile_a
    mov si, offset tile_locked_b
    ret
get_locked_tile_a:
    mov si, offset tile_locked_a
    ret

get_open_tile_frame:
    test byte ptr [anim_phase], 1
    jz get_open_tile_a
    mov si, offset tile_open_b
    ret
get_open_tile_a:
    mov si, offset tile_open_a
    ret

get_surge_tile_frame:
    test byte ptr [anim_phase], 1
    jz get_surge_tile_a
    mov si, offset tile_surge_b
    ret
get_surge_tile_a:
    mov si, offset tile_surge_a
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
