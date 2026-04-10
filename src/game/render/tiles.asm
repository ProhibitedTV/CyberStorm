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
    cmp al, TILE_TERMINAL
    je draw_terminal_tile
    cmp al, TILE_KEY
    je draw_key_tile
    jmp draw_floor_tile

draw_floor_tile:
    call get_floor_tile_frame
    call draw_bitmap8
    ret

draw_wall_tile:
    call get_wall_tile_frame
    call draw_bitmap8
    call draw_wall_depth
    ret

draw_shard_tile:
    call draw_floor_tile
    call draw_shard_glow
    call draw_shard_contact_light
    call get_shard_sprite
    call draw_sprite8
    ret

draw_locked_tile:
    call get_locked_tile_frame
    call draw_bitmap8
    call draw_locked_gate_charge
    call draw_gate_side_glow
    ret

draw_open_tile:
    call get_open_tile_frame
    call draw_bitmap8
    call draw_open_gate_glow
    call draw_gate_side_glow
    call get_gate_sprite
    call draw_sprite8
    ret

draw_surge_tile:
    call get_surge_tile_frame
    call draw_bitmap8
    call draw_surge_edge_light
    ret

draw_terminal_tile:
    call get_terminal_tile_frame
    call draw_bitmap8
    call draw_terminal_edge_light
    ret

draw_key_tile:
    call draw_floor_tile
    call draw_shard_glow
    call draw_terminal_edge_light
    call get_shard_sprite
    call draw_sprite8
    ret

get_floor_tile_frame:
    mov al, [sector_num]
    cmp al, 2
    je get_floor_tile_furnace
    cmp al, 3
    je get_floor_tile_lock
    test byte ptr [anim_phase], 4
    jz get_floor_tile_a
    mov si, offset tile_floor_b
    ret

get_floor_tile_furnace:
    test byte ptr [anim_phase], 4
    jz get_floor_tile_furnace_a
    mov si, offset tile_floor_furnace_b
    ret

get_floor_tile_lock:
    test byte ptr [anim_phase], 4
    jz get_floor_tile_lock_a
    mov si, offset tile_floor_lock_b
    ret

get_floor_tile_a:
    mov si, offset tile_floor_a
    ret

get_floor_tile_furnace_a:
    mov si, offset tile_floor_furnace_a
    ret

get_floor_tile_lock_a:
    mov si, offset tile_floor_lock_a
    ret

get_wall_tile_frame:
    mov al, [sector_num]
    cmp al, 2
    je get_wall_tile_furnace
    cmp al, 3
    je get_wall_tile_lock
    test byte ptr [anim_phase], 4
    jz get_wall_tile_a
    mov si, offset tile_wall_b
    ret

get_wall_tile_furnace:
    test byte ptr [anim_phase], 4
    jz get_wall_tile_furnace_a
    mov si, offset tile_wall_furnace_b
    ret

get_wall_tile_lock:
    test byte ptr [anim_phase], 4
    jz get_wall_tile_lock_a
    mov si, offset tile_wall_lock_b
    ret

get_wall_tile_a:
    mov si, offset tile_wall_a
    ret

get_wall_tile_furnace_a:
    mov si, offset tile_wall_furnace_a
    ret

get_wall_tile_lock_a:
    mov si, offset tile_wall_lock_a
    ret

get_locked_tile_frame:
    test byte ptr [anim_phase], 2
    jz get_locked_tile_a
    mov si, offset tile_locked_b
    ret
get_locked_tile_a:
    mov si, offset tile_locked_a
    ret

get_open_tile_frame:
    test byte ptr [anim_phase], 2
    jz get_open_tile_a
    mov si, offset tile_open_b
    ret
get_open_tile_a:
    mov si, offset tile_open_a
    ret

get_surge_tile_frame:
    test byte ptr [anim_phase], 2
    jz get_surge_tile_a
    mov si, offset tile_surge_b
    ret
get_surge_tile_a:
    mov si, offset tile_surge_a
    ret

get_terminal_tile_frame:
    test byte ptr [anim_phase], 2
    jz get_terminal_tile_a
    mov si, offset tile_terminal_b
    ret
get_terminal_tile_a:
    mov si, offset tile_terminal_a
    ret

get_shard_sprite:
    call get_visual_cycle_phase
    cmp al, 2
    je get_shard_sprite_c
    cmp al, 1
    je get_shard_sprite_b
    cmp al, 3
    je get_shard_sprite_b
get_shard_sprite_a:
    mov si, offset sprite_shard_a
    ret
get_shard_sprite_b:
    mov si, offset sprite_shard_b
    ret
get_shard_sprite_c:
    mov si, offset sprite_shard_c
    ret

get_gate_sprite:
    call get_visual_cycle_phase
    cmp al, 2
    je get_gate_sprite_c
    cmp al, 1
    je get_gate_sprite_b
    cmp al, 3
    je get_gate_sprite_b
get_gate_sprite_a:
    mov si, offset sprite_gate_a
    ret
get_gate_sprite_b:
    mov si, offset sprite_gate_b
    ret
get_gate_sprite_c:
    mov si, offset sprite_gate_c
    ret

get_visual_cycle_phase:
    ; Visual-only motion rides a slower four-step beat than anim_phase itself,
    ; which keeps tile/sprite changes energetic but still readable in 13h.
    mov al, [anim_phase]
    shr al, 1
    and al, 03h
    ret

draw_shard_glow:
    push ax
    push bx
    push dx
    call get_visual_cycle_phase
    test al, 1
    jz shard_glow_sector
    mov al, PAL_WHITE
    jmp shard_glow_color_ready

shard_glow_sector:
    call get_sector_accent_color

shard_glow_color_ready:
    push ax
    mov cx, ax
    call get_visual_cycle_phase
    cmp al, 1
    je shard_glow_lateral
    cmp al, 2
    je shard_glow_diagonal
    cmp al, 3
    je shard_glow_full

    mov ax, cx
    add bx, 3
    call put_pixel
    sub bx, 3
    add dx, 7
    add bx, 4
    call put_pixel
    jmp shard_glow_done

shard_glow_lateral:
    mov ax, cx
    add dx, 4
    call put_pixel
    sub dx, 1
    add bx, 7
    call put_pixel
    jmp shard_glow_done

shard_glow_diagonal:
    mov ax, cx
    inc bx
    inc dx
    call put_pixel
    add bx, 5
    add dx, 5
    call put_pixel
    jmp shard_glow_done

shard_glow_full:
    mov ax, cx
    add bx, 3
    call put_pixel
    sub bx, 3
    add dx, 4
    call put_pixel
    add bx, 7
    sub dx, 1
    call put_pixel
    sub bx, 3
    add dx, 4
    call put_pixel

shard_glow_done:
    pop ax
    pop dx
    pop bx
    pop ax
    ret

draw_locked_gate_charge:
    cmp byte ptr [data_count], SHARD_COUNT - 1
    jne locked_gate_charge_done
    push ax
    push bx
    push dx
    call get_visual_cycle_phase
    test al, 1
    jz locked_gate_charge_base
    mov al, PAL_WHITE
    jmp locked_gate_charge_ready

locked_gate_charge_base:
    mov al, PAL_AMBER

locked_gate_charge_ready:
    inc bx
    inc dx
    mov cx, 1
    mov bp, 6
    call fill_rect
    add bx, 5
    call fill_rect
    sub bx, 3
    add dx, 2
    mov cx, 1
    mov bp, 2
    call fill_rect
    pop dx
    pop bx
    pop ax

locked_gate_charge_done:
    ret

draw_open_gate_glow:
    push ax
    push bx
    push dx
    call get_visual_cycle_phase
    test al, 1
    jz open_gate_glow_base
    mov al, PAL_WHITE
    jmp open_gate_glow_ready

open_gate_glow_base:
    mov al, PAL_GATE

open_gate_glow_ready:
    inc bx
    inc dx
    mov cx, 6
    mov bp, 1
    call fill_rect
    add dx, 5
    call fill_rect
    sub dx, 5
    mov cx, 1
    mov bp, 6
    call fill_rect
    add bx, 5
    call fill_rect
    pop dx
    pop bx
    pop ax
    ret

draw_wall_depth:
    push ax
    push bx
    push dx
    push cx
    push bp
    call get_sector_accent_color
    mov cx, 8
    mov bp, 1
    call fill_rect
    mov cx, 1
    mov bp, 8
    call fill_rect
    mov al, PAL_PANEL2
    add dx, 7
    mov cx, 8
    mov bp, 1
    call fill_rect
    sub dx, 7
    add bx, 7
    mov cx, 1
    mov bp, 8
    call fill_rect
    pop bp
    pop cx
    pop dx
    pop bx
    pop ax
    ret

draw_shard_contact_light:
    push ax
    push bx
    push dx
    push cx
    push bp
    call get_visual_cycle_phase
    test al, 1
    jz shard_contact_base
    mov al, PAL_WHITE
    jmp shard_contact_ready

shard_contact_base:
    call get_sector_accent_color

shard_contact_ready:
    add bx, 2
    add dx, 6
    mov cx, 4
    mov bp, 1
    call fill_rect
    inc dx
    inc bx
    mov cx, 2
    call fill_rect
    pop bp
    pop cx
    pop dx
    pop bx
    pop ax
    ret

draw_gate_side_glow:
    push ax
    push bx
    push dx
    push cx
    push bp
    test byte ptr [anim_phase], 1
    jz gate_side_glow_base
    mov al, PAL_WHITE
    jmp gate_side_glow_ready

gate_side_glow_base:
    mov al, PAL_GATE

gate_side_glow_ready:
    sub bx, 1
    inc dx
    mov cx, 1
    mov bp, 6
    call fill_rect
    add bx, 9
    call fill_rect
    pop bp
    pop cx
    pop dx
    pop bx
    pop ax
    ret

draw_surge_edge_light:
    push ax
    push bx
    push dx
    push cx
    push bp
    test byte ptr [anim_phase], 1
    jz surge_edge_base
    mov al, PAL_RED2
    jmp surge_edge_ready

surge_edge_base:
    mov al, PAL_AMBER

surge_edge_ready:
    add bx, 1
    add dx, 1
    mov cx, 6
    mov bp, 1
    call fill_rect
    add dx, 5
    call fill_rect
    sub dx, 5
    add bx, 2
    mov cx, 2
    mov bp, 6
    call draw_rect_outline
    pop bp
    pop cx
    pop dx
    pop bx
    pop ax
    ret

draw_terminal_edge_light:
    push ax
    push bx
    push dx
    push cx
    push bp
    test byte ptr [anim_phase], 1
    jz terminal_edge_base
    mov al, PAL_WHITE
    jmp terminal_edge_ready

terminal_edge_base:
    call get_sector_accent_color

terminal_edge_ready:
    add bx, 1
    add dx, 1
    mov cx, 6
    mov bp, 1
    call fill_rect
    mov cx, 1
    mov bp, 6
    call fill_rect
    add bx, 5
    call fill_rect
    sub bx, 3
    add dx, 2
    mov cx, 2
    mov bp, 2
    mov al, PAL_WHITE
    call fill_rect
    pop bp
    pop cx
    pop dx
    pop bx
    pop ax
    ret
