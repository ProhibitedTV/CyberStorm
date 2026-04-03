game3d_mark_room_dirty:
    mov byte ptr [game3d_room_dirty], 1
    ret

game3d_reset_room_state:
    mov byte ptr [game3d_room_dirty], 1
    mov byte ptr [game3d_room_overflow], 0
    mov byte ptr [game3d_room_face_count], 0
    mov word ptr [game3d_room_vertex_count], 0
    call game3d_sync_camera_facing
    ret

game3d_sync_camera_facing:
    call game3d_get_facing_yaw
    mov [game3d_camera_yaw_current], al
    mov [game3d_camera_yaw_target], al
    ret

game3d_get_facing_yaw:
    cmp byte ptr [last_player_dx], 0
    jg game3d_return_yaw_east
    jl game3d_return_yaw_west
    cmp byte ptr [last_player_dy], 0
    jg game3d_return_yaw_south
    jl game3d_return_yaw_north
    mov al, GAME3D_YAW_DEFAULT
    ret

game3d_return_yaw_east:
    mov al, GAME3D_YAW_EAST
    ret

game3d_return_yaw_west:
    mov al, GAME3D_YAW_WEST
    ret

game3d_return_yaw_south:
    mov al, GAME3D_YAW_SOUTH
    ret

game3d_return_yaw_north:
    mov al, GAME3D_YAW_NORTH
    ret

game3d_update_camera_target:
    call game3d_get_facing_yaw
    mov [game3d_camera_yaw_target], al
    ret

game3d_ease_camera_yaw:
    push bx
    mov al, [game3d_camera_yaw_target]
    mov bl, [game3d_camera_yaw_current]
    cmp al, bl
    je game3d_ease_camera_done
    sub al, bl
    cmp al, 128
    jae game3d_ease_camera_negative
    cmp al, GAME3D_CAMERA_STEP
    jbe game3d_ease_camera_snap
    add bl, GAME3D_CAMERA_STEP
    mov [game3d_camera_yaw_current], bl
    jmp game3d_ease_camera_done

game3d_ease_camera_negative:
    neg al
    cmp al, GAME3D_CAMERA_STEP
    jbe game3d_ease_camera_snap
    sub bl, GAME3D_CAMERA_STEP
    mov [game3d_camera_yaw_current], bl
    jmp game3d_ease_camera_done

game3d_ease_camera_snap:
    mov al, [game3d_camera_yaw_target]
    mov [game3d_camera_yaw_current], al

game3d_ease_camera_done:
    pop bx
    ret

render_gameplay_3d:
    call game3d_build_room_if_dirty
    call game3d_setup_camera
    call game3d_render_room
    call render_gameplay_props_3d
    call render_gameplay_world_effects_3d
    call render_enemies_3d
    call render_player_3d
    call render_gameplay_overlay_effects_3d
    ret

game3d_build_room_if_dirty:
    cmp byte ptr [game3d_room_dirty], 0
    je game3d_build_room_done
    call game3d_compile_room_mesh
    mov byte ptr [game3d_room_dirty], 0

game3d_build_room_done:
    ret

game3d_setup_camera:
    push ax
    push bx
    push cx
    push dx

    call game3d_update_camera_target
    call game3d_ease_camera_yaw

    mov word ptr [scene3d_clip_left], GAME3D_VIEW_X
    mov word ptr [scene3d_clip_top], GAME3D_VIEW_Y
    mov word ptr [scene3d_clip_right], GAME3D_VIEW_X + GAME3D_VIEW_W - 1
    mov word ptr [scene3d_clip_bottom], GAME3D_VIEW_Y + GAME3D_VIEW_H - 1
    mov word ptr [scene3d_center_x], GAME3D_VIEW_X + (GAME3D_VIEW_W / 2)
    mov word ptr [scene3d_center_y], GAME3D_VIEW_Y + (GAME3D_VIEW_H / 2)
    mov word ptr [scene3d_project_scale], GAME3D_PROJECT_SCALE
    mov byte ptr [scene3d_pitch_angle], GAME3D_CAMERA_PITCH
    mov al, [game3d_camera_yaw_current]
    mov [scene3d_yaw_angle], al

    mov bl, [player_x]
    mov bh, [player_y]
    call game3d_get_tile_center_world
    mov [scene3d_temp_v], ax
    mov [scene3d_temp_l], dx

    mov al, [scene3d_yaw_angle]
    call scene3d_get_sin_cos

    mov ax, GAME3D_CAMERA_LOOK_AHEAD
    call scene3d_mul_ax_bx_fixed
    add ax, [scene3d_temp_v]
    mov [scene3d_temp_v], ax

    mov ax, GAME3D_CAMERA_LOOK_AHEAD
    mov bx, dx
    call scene3d_mul_ax_bx_fixed
    add ax, [scene3d_temp_l]
    mov [scene3d_temp_l], ax

    mov ax, GAME3D_CAMERA_DISTANCE
    call scene3d_mul_ax_bx_fixed
    mov cx, ax
    mov ax, [scene3d_temp_v]
    sub ax, cx
    mov [scene3d_cam_x], ax

    mov ax, GAME3D_CAMERA_DISTANCE
    mov bx, dx
    call scene3d_mul_ax_bx_fixed
    mov cx, ax
    mov ax, [scene3d_temp_l]
    sub ax, cx
    mov [scene3d_cam_z], ax

    mov word ptr [scene3d_cam_y], GAME3D_CAMERA_HEIGHT

    pop dx
    pop cx
    pop bx
    pop ax
    ret

game3d_render_room:
    mov byte ptr [game3d_rendering_active], 1
    mov word ptr [scene3d_vertex_source], offset game3d_room_vertex_raw
    mov word ptr [scene3d_face_source], offset game3d_room_face_raw
    mov ax, [game3d_room_vertex_count]
    mov [scene3d_vertex_count], ax
    mov al, [game3d_room_face_count]
    mov [scene3d_face_count], al
    cmp byte ptr [scene3d_face_count], 0
    je game3d_render_room_done
    call scene3d_project_vertices
    call scene3d_build_face_order
    call scene3d_draw_face_order

game3d_render_room_done:
    mov byte ptr [game3d_rendering_active], 0
    ret

game3d_compile_room_mesh:
    mov word ptr [game3d_room_vertex_count], 0
    mov byte ptr [game3d_room_face_count], 0
    mov byte ptr [game3d_room_overflow], 0
    call game3d_compile_floor_strips
    call game3d_compile_north_walls
    call game3d_compile_south_walls
    call game3d_compile_west_walls
    call game3d_compile_east_walls
    ret

game3d_compile_floor_strips:
    xor dh, dh

game3d_floor_row_loop:
    cmp dh, MAP_H
    jae game3d_compile_floor_done
    xor dl, dl

game3d_floor_scan_loop:
    cmp dl, MAP_W
    jae game3d_floor_next_row
    mov bl, dl
    mov bh, dh
    call get_tile
    cmp al, TILE_WALL
    je game3d_floor_skip_wall
    mov ch, dl

game3d_floor_run_loop:
    inc dl
    cmp dl, MAP_W
    jae game3d_floor_emit
    mov bl, dl
    mov bh, dh
    call get_tile
    cmp al, TILE_WALL
    jne game3d_floor_run_loop

game3d_floor_emit:
    mov al, ch
    call game3d_world_x_edge_from_al
    mov [scene3d_temp_x], ax
    mov al, dl
    call game3d_world_x_edge_from_al
    mov [scene3d_temp_y], ax
    mov word ptr [scene3d_temp_z], GAME3D_FLOOR_Y
    mov word ptr [scene3d_temp_u], GAME3D_FLOOR_Y
    mov al, dh
    call game3d_world_z_edge_from_al
    mov [scene3d_temp_v], ax
    mov al, dh
    inc al
    call game3d_world_z_edge_from_al
    mov [scene3d_temp_w], ax
    call game3d_get_floor_material
    mov [scene3d_temp_color], al
    mov [scene3d_temp_dither], ah
    mov byte ptr [scene3d_temp_face], GAME3D_FACE_FLAG_NONE
    call game3d_emit_quad_from_temps
    jmp game3d_floor_scan_loop

game3d_floor_skip_wall:
    inc dl
    jmp game3d_floor_scan_loop

game3d_floor_next_row:
    inc dh
    jmp game3d_floor_row_loop

game3d_compile_floor_done:
    ret

game3d_compile_north_walls:
    xor dh, dh

game3d_north_row_loop:
    cmp dh, MAP_H
    jae game3d_compile_north_done
    xor dl, dl

game3d_north_scan_loop:
    cmp dl, MAP_W
    jae game3d_north_next_row
    mov bl, dl
    mov bh, dh
    call game3d_should_emit_north_face
    cmp al, 0
    je game3d_north_skip
    mov ch, dl

game3d_north_run_loop:
    inc dl
    cmp dl, MAP_W
    jae game3d_north_emit
    mov bl, dl
    mov bh, dh
    call game3d_should_emit_north_face
    cmp al, 0
    jne game3d_north_run_loop

game3d_north_emit:
    mov al, ch
    call game3d_world_x_edge_from_al
    mov [scene3d_temp_x], ax
    mov al, dl
    call game3d_world_x_edge_from_al
    mov [scene3d_temp_y], ax
    mov word ptr [scene3d_temp_z], GAME3D_FLOOR_Y
    mov word ptr [scene3d_temp_u], GAME3D_WALL_TOP_Y
    mov al, dh
    call game3d_world_z_edge_from_al
    mov [scene3d_temp_v], ax
    mov [scene3d_temp_w], ax
    call game3d_get_wall_material
    mov [scene3d_temp_color], al
    mov [scene3d_temp_dither], ah
    mov byte ptr [scene3d_temp_face], GAME3D_FACE_FLAG_WALL
    call game3d_emit_quad_from_temps
    jmp game3d_north_scan_loop

game3d_north_skip:
    inc dl
    jmp game3d_north_scan_loop

game3d_north_next_row:
    inc dh
    jmp game3d_north_row_loop

game3d_compile_north_done:
    ret

game3d_compile_south_walls:
    xor dh, dh

game3d_south_row_loop:
    cmp dh, MAP_H
    jae game3d_compile_south_done
    xor dl, dl

game3d_south_scan_loop:
    cmp dl, MAP_W
    jae game3d_south_next_row
    mov bl, dl
    mov bh, dh
    call game3d_should_emit_south_face
    cmp al, 0
    je game3d_south_skip
    mov ch, dl

game3d_south_run_loop:
    inc dl
    cmp dl, MAP_W
    jae game3d_south_emit
    mov bl, dl
    mov bh, dh
    call game3d_should_emit_south_face
    cmp al, 0
    jne game3d_south_run_loop

game3d_south_emit:
    mov al, ch
    call game3d_world_x_edge_from_al
    mov [scene3d_temp_x], ax
    mov al, dl
    call game3d_world_x_edge_from_al
    mov [scene3d_temp_y], ax
    mov word ptr [scene3d_temp_z], GAME3D_FLOOR_Y
    mov word ptr [scene3d_temp_u], GAME3D_WALL_TOP_Y
    mov al, dh
    inc al
    call game3d_world_z_edge_from_al
    mov [scene3d_temp_v], ax
    mov [scene3d_temp_w], ax
    call game3d_get_wall_material
    mov [scene3d_temp_color], al
    mov [scene3d_temp_dither], ah
    mov byte ptr [scene3d_temp_face], GAME3D_FACE_FLAG_WALL
    call game3d_emit_quad_from_temps
    jmp game3d_south_scan_loop

game3d_south_skip:
    inc dl
    jmp game3d_south_scan_loop

game3d_south_next_row:
    inc dh
    jmp game3d_south_row_loop

game3d_compile_south_done:
    ret

game3d_compile_west_walls:
    xor dh, dh

game3d_west_col_loop:
    cmp dh, MAP_W
    jae game3d_compile_west_done
    xor dl, dl

game3d_west_scan_loop:
    cmp dl, MAP_H
    jae game3d_west_next_col
    mov bl, dh
    mov bh, dl
    call game3d_should_emit_west_face
    cmp al, 0
    je game3d_west_skip
    mov ch, dl

game3d_west_run_loop:
    inc dl
    cmp dl, MAP_H
    jae game3d_west_emit
    mov bl, dh
    mov bh, dl
    call game3d_should_emit_west_face
    cmp al, 0
    jne game3d_west_run_loop

game3d_west_emit:
    mov al, dh
    call game3d_world_x_edge_from_al
    mov [scene3d_temp_x], ax
    mov [scene3d_temp_y], ax
    mov word ptr [scene3d_temp_z], GAME3D_FLOOR_Y
    mov word ptr [scene3d_temp_u], GAME3D_WALL_TOP_Y
    mov al, ch
    call game3d_world_z_edge_from_al
    mov [scene3d_temp_v], ax
    mov al, dl
    call game3d_world_z_edge_from_al
    mov [scene3d_temp_w], ax
    call game3d_get_wall_material
    mov [scene3d_temp_color], al
    mov [scene3d_temp_dither], ah
    mov byte ptr [scene3d_temp_face], GAME3D_FACE_FLAG_WALL
    call game3d_emit_quad_from_temps
    jmp game3d_west_scan_loop

game3d_west_skip:
    inc dl
    jmp game3d_west_scan_loop

game3d_west_next_col:
    inc dh
    jmp game3d_west_col_loop

game3d_compile_west_done:
    ret

game3d_compile_east_walls:
    xor dh, dh

game3d_east_col_loop:
    cmp dh, MAP_W
    jae game3d_compile_east_done
    xor dl, dl

game3d_east_scan_loop:
    cmp dl, MAP_H
    jae game3d_east_next_col
    mov bl, dh
    mov bh, dl
    call game3d_should_emit_east_face
    cmp al, 0
    je game3d_east_skip
    mov ch, dl

game3d_east_run_loop:
    inc dl
    cmp dl, MAP_H
    jae game3d_east_emit
    mov bl, dh
    mov bh, dl
    call game3d_should_emit_east_face
    cmp al, 0
    jne game3d_east_run_loop

game3d_east_emit:
    mov al, dh
    inc al
    call game3d_world_x_edge_from_al
    mov [scene3d_temp_x], ax
    mov [scene3d_temp_y], ax
    mov word ptr [scene3d_temp_z], GAME3D_FLOOR_Y
    mov word ptr [scene3d_temp_u], GAME3D_WALL_TOP_Y
    mov al, ch
    call game3d_world_z_edge_from_al
    mov [scene3d_temp_v], ax
    mov al, dl
    call game3d_world_z_edge_from_al
    mov [scene3d_temp_w], ax
    call game3d_get_wall_material
    mov [scene3d_temp_color], al
    mov [scene3d_temp_dither], ah
    mov byte ptr [scene3d_temp_face], GAME3D_FACE_FLAG_WALL
    call game3d_emit_quad_from_temps
    jmp game3d_east_scan_loop

game3d_east_skip:
    inc dl
    jmp game3d_east_scan_loop

game3d_east_next_col:
    inc dh
    jmp game3d_east_col_loop

game3d_compile_east_done:
    ret

game3d_emit_quad_from_temps:
    push ax
    push bx
    push cx
    push dx
    push si
    push di
    push bp

    mov ax, [game3d_room_vertex_count]
    add ax, 4
    jc game3d_emit_quad_overflow
    cmp ax, SCENE3D_MAX_VERTICES
    ja game3d_emit_quad_overflow
    mov al, [game3d_room_face_count]
    add al, 2
    jc game3d_emit_quad_overflow
    cmp al, SCENE3D_MAX_FACES
    ja game3d_emit_quad_overflow

    mov al, [scene3d_temp_face]
    mov [game3d_emit_flags], al
    mov ax, [game3d_room_vertex_count]
    mov bl, al
    mov di, ax
    mov ax, SCENE3D_VERTEX_BYTES
    mul di
    mov di, offset game3d_room_vertex_raw
    add di, ax

    mov ax, [scene3d_temp_x]
    stosw
    mov ax, [scene3d_temp_z]
    stosw
    mov ax, [scene3d_temp_v]
    stosw

    mov ax, [scene3d_temp_y]
    stosw
    mov ax, [scene3d_temp_z]
    stosw
    mov ax, [scene3d_temp_v]
    stosw

    mov ax, [scene3d_temp_y]
    stosw
    mov ax, [scene3d_temp_u]
    stosw
    mov ax, [scene3d_temp_w]
    stosw

    mov ax, [scene3d_temp_x]
    stosw
    mov ax, [scene3d_temp_u]
    stosw
    mov ax, [scene3d_temp_w]
    stosw

    mov al, [game3d_room_face_count]
    xor ah, ah
    mov di, ax
    mov ax, SCENE3D_FACE_BYTES
    mul di
    mov di, offset game3d_room_face_raw
    add di, ax

    mov al, bl
    stosb
    mov al, bl
    inc al
    stosb
    mov al, bl
    add al, 2
    stosb
    mov al, [scene3d_temp_color]
    stosb
    mov al, [scene3d_temp_dither]
    stosb
    mov al, [game3d_emit_flags]
    stosb

    mov al, bl
    stosb
    mov al, bl
    add al, 2
    stosb
    mov al, bl
    add al, 3
    stosb
    mov al, [scene3d_temp_color]
    stosb
    mov al, [scene3d_temp_dither]
    stosb
    mov al, [game3d_emit_flags]
    stosb

    mov ax, [game3d_room_vertex_count]
    add ax, 4
    mov [game3d_room_vertex_count], ax
    mov al, [game3d_room_face_count]
    add al, 2
    mov [game3d_room_face_count], al
    jmp game3d_emit_quad_done

game3d_emit_quad_overflow:
    mov byte ptr [game3d_room_overflow], 1

game3d_emit_quad_done:
    pop bp
    pop di
    pop si
    pop dx
    pop cx
    pop bx
    pop ax
    ret

game3d_get_floor_material:
    mov al, [sector_num]
    cmp al, 2
    je game3d_floor_sector2
    cmp al, 3
    je game3d_floor_sector3
    mov al, PAL_FLOOR
    mov ah, PAL_FLOOR2
    ret

game3d_floor_sector2:
    mov al, PAL_FLOOR
    mov ah, PAL_AMBER
    ret

game3d_floor_sector3:
    mov al, PAL_PANEL2
    mov ah, PAL_CYAN2
    ret

game3d_get_wall_material:
    mov al, [sector_num]
    cmp al, 2
    je game3d_wall_sector2
    cmp al, 3
    je game3d_wall_sector3
    mov al, PAL_WALL
    mov ah, PAL_WALL2
    ret

game3d_wall_sector2:
    mov al, PAL_RED2
    mov ah, PAL_RED
    ret

game3d_wall_sector3:
    mov al, PAL_PANEL
    mov ah, PAL_GATE
    ret

game3d_should_emit_north_face:
    call game3d_is_wall_tile
    cmp al, 0
    je game3d_face_no
    cmp bh, 0
    je game3d_face_yes
    dec bh
    call game3d_is_wall_tile
    cmp al, 0
    je game3d_face_yes
    jmp game3d_face_no

game3d_should_emit_south_face:
    call game3d_is_wall_tile
    cmp al, 0
    je game3d_face_no
    cmp bh, MAP_H - 1
    je game3d_face_yes
    inc bh
    call game3d_is_wall_tile
    cmp al, 0
    je game3d_face_yes
    jmp game3d_face_no

game3d_should_emit_west_face:
    call game3d_is_wall_tile
    cmp al, 0
    je game3d_face_no
    cmp bl, 0
    je game3d_face_yes
    dec bl
    call game3d_is_wall_tile
    cmp al, 0
    je game3d_face_yes
    jmp game3d_face_no

game3d_should_emit_east_face:
    call game3d_is_wall_tile
    cmp al, 0
    je game3d_face_no
    cmp bl, MAP_W - 1
    je game3d_face_yes
    inc bl
    call game3d_is_wall_tile
    cmp al, 0
    je game3d_face_yes
    jmp game3d_face_no

game3d_face_yes:
    mov al, 1
    ret

game3d_face_no:
    xor al, al
    ret

game3d_is_wall_tile:
    push bx
    call get_tile
    pop bx
    cmp al, TILE_WALL
    jne game3d_is_wall_no
    mov al, 1
    ret

game3d_is_wall_no:
    xor al, al
    ret

game3d_world_x_edge_from_al:
    mov ah, al
    xor al, al
    sub ax, GAME3D_WORLD_ORIGIN_X
    ret

game3d_world_z_edge_from_al:
    mov ah, al
    xor al, al
    sub ax, GAME3D_WORLD_ORIGIN_Z
    ret

game3d_get_tile_center_world:
    xor ax, ax
    mov ah, bl
    add ax, 128
    sub ax, GAME3D_WORLD_ORIGIN_X
    xor dx, dx
    mov dh, bh
    add dx, 128
    sub dx, GAME3D_WORLD_ORIGIN_Z
    ret

game3d_project_world_point:
    ; Input: AX = world X, BX = world Y, DX = world Z
    ; Output: AX = screen X, DX = screen Y, CX = depth. Carry = visible.
    push si
    push di
    push bp

    sub ax, [scene3d_cam_x]
    mov [scene3d_temp_v], ax
    mov ax, bx
    sub ax, [scene3d_cam_y]
    mov [scene3d_temp_w], ax
    mov ax, dx
    sub ax, [scene3d_cam_z]
    mov [scene3d_temp_l], ax

    mov al, [scene3d_yaw_angle]
    call scene3d_get_sin_cos
    mov [scene3d_temp_x], bx
    mov [scene3d_temp_y], dx

    mov al, [scene3d_pitch_angle]
    call scene3d_get_sin_cos
    mov [scene3d_temp_z], bx
    mov [scene3d_temp_u], dx

    mov ax, [scene3d_temp_v]
    mov [scene3d_temp_r], ax
    mov ax, [scene3d_temp_v]
    mov bx, [scene3d_temp_y]
    call scene3d_mul_ax_bx_fixed
    mov di, ax
    mov ax, [scene3d_temp_l]
    mov bx, [scene3d_temp_x]
    call scene3d_mul_ax_bx_fixed
    sub di, ax
    mov [scene3d_temp_v], di

    mov ax, [scene3d_temp_r]
    mov bx, [scene3d_temp_x]
    call scene3d_mul_ax_bx_fixed
    mov [scene3d_temp_r], ax
    mov ax, [scene3d_temp_l]
    mov bx, [scene3d_temp_y]
    call scene3d_mul_ax_bx_fixed
    add ax, [scene3d_temp_r]
    mov [scene3d_temp_l], ax

    mov ax, [scene3d_temp_w]
    mov [scene3d_temp_r], ax
    mov ax, [scene3d_temp_w]
    mov bx, [scene3d_temp_u]
    call scene3d_mul_ax_bx_fixed
    mov di, ax
    mov ax, [scene3d_temp_l]
    mov bx, [scene3d_temp_z]
    call scene3d_mul_ax_bx_fixed
    sub di, ax
    mov [scene3d_temp_w], di

    mov ax, [scene3d_temp_r]
    mov bx, [scene3d_temp_z]
    call scene3d_mul_ax_bx_fixed
    mov [scene3d_temp_r], ax
    mov ax, [scene3d_temp_l]
    mov bx, [scene3d_temp_u]
    call scene3d_mul_ax_bx_fixed
    add ax, [scene3d_temp_r]
    mov [scene3d_temp_l], ax

    mov cx, [scene3d_temp_l]
    cmp cx, SCENE3D_NEAR_Z
    jg game3d_project_visible
    clc
    jmp game3d_project_done

game3d_project_visible:
    mov bx, [scene3d_project_scale]
    mov ax, [scene3d_temp_v]
    call scene3d_project_ax
    add ax, [scene3d_center_x]
    mov si, ax

    mov cx, [scene3d_temp_l]
    mov bx, [scene3d_project_scale]
    mov ax, [scene3d_temp_w]
    call scene3d_project_ax
    neg ax
    add ax, [scene3d_center_y]
    mov dx, ax
    mov ax, si
    stc

game3d_project_done:
    pop bp
    pop di
    pop si
    ret

game3d_project_tile_center:
    call game3d_get_tile_center_world
    mov bx, GAME3D_FLOOR_Y
    call game3d_project_world_point
    ret

game3d_get_scale_for_depth:
    mov al, 1
    cmp cx, 1400
    ja game3d_scale_ready
    mov al, 2

game3d_scale_ready:
    ret

game3d_draw_shadow_at_projected_point:
    push ax
    push bx
    push cx
    push dx
    push bp
    push si
    mov si, ax
    call game3d_get_scale_for_depth
    mov cl, 3
    cmp al, 2
    jne game3d_shadow_size_ready
    mov cl, 5

game3d_shadow_size_ready:
    xor ax, ax
    mov al, cl
    mov bx, si
    sub bx, ax
    sub dx, 1
    shl ax, 1
    inc ax
    mov cx, ax
    mov bp, 2
    mov al, PAL_PANEL2
    call fill_rect
    pop si
    pop bp
    pop dx
    pop cx
    pop bx
    pop ax
    ret

game3d_draw_marker_at_projected_point:
    push ax
    push bx
    push cx
    push dx
    push bp
    push si
    mov si, ax
    mov [text_color], bl
    call game3d_get_scale_for_depth
    mov cl, 2
    cmp al, 2
    jne game3d_marker_size_ready
    mov cl, 3

game3d_marker_size_ready:
    xor ax, ax
    mov al, cl
    mov bx, si
    sub bx, ax
    sub dx, ax
    shl ax, 1
    inc ax
    mov cx, ax
    mov bp, ax
    mov al, [text_color]
    call draw_rect_outline
    pop si
    pop bp
    pop dx
    pop cx
    pop bx
    pop ax
    ret

game3d_draw_sprite8_2x:
    push ax
    push bx
    push cx
    push dx
    push si
    push di
    push bp
    mov [glyph_base_x], bx
    mov [glyph_base_y], dx
    xor bp, bp

game3d_sprite2x_row:
    cmp bp, 8
    jae game3d_sprite2x_done
    xor di, di

game3d_sprite2x_col:
    cmp di, 8
    jae game3d_sprite2x_next_row
    lodsb
    or al, al
    jz game3d_sprite2x_skip
    push bp
    push di
    mov bx, [glyph_base_x]
    mov dx, [glyph_base_y]
    mov ax, di
    shl ax, 1
    add bx, ax
    mov ax, bp
    shl ax, 1
    add dx, ax
    mov cx, 2
    mov bp, 2
    call fill_rect
    pop di
    pop bp

game3d_sprite2x_skip:
    inc di
    jmp game3d_sprite2x_col

game3d_sprite2x_next_row:
    inc bp
    jmp game3d_sprite2x_row

game3d_sprite2x_done:
    pop bp
    pop di
    pop si
    pop dx
    pop cx
    pop bx
    pop ax
    ret

game3d_draw_sprite_billboard:
    ; Input: AX = projected X, DX = projected Y, CX = depth, SI = sprite.
    push ax
    push bx
    push cx
    push dx
    push bp
    mov bp, ax
    call game3d_get_scale_for_depth
    cmp al, 2
    jne game3d_draw_sprite_billboard_1x
    mov bx, bp
    sub bx, 8
    sub dx, 15
    call game3d_draw_sprite8_2x
    jmp game3d_draw_sprite_billboard_done

game3d_draw_sprite_billboard_1x:
    mov bx, bp
    sub bx, 4
    sub dx, 7
    call draw_sprite8

game3d_draw_sprite_billboard_done:
    pop bp
    pop dx
    pop cx
    pop bx
    pop ax
    ret

render_gameplay_props_3d:
    mov si, offset map_tiles
    xor dh, dh
    mov cx, MAP_H

game3d_prop_row_loop:
    push cx
    xor dl, dl
    mov cx, MAP_W

game3d_prop_col_loop:
    mov al, [si]
    cmp al, TILE_SHARD
    je game3d_prop_shard
    cmp al, TILE_TERMINAL
    je game3d_prop_terminal
    cmp al, TILE_SURGE
    je game3d_prop_surge
    cmp al, TILE_EXIT_LOCKED
    je game3d_prop_gate_locked
    cmp al, TILE_EXIT_OPEN
    je game3d_prop_gate_open
    jmp game3d_prop_next

game3d_prop_shard:
    mov bl, dl
    mov bh, dh
    call game3d_project_tile_center
    jnc game3d_prop_next
    push ax
    push cx
    push dx
    mov bl, PAL_CYAN2
    call game3d_draw_marker_at_projected_point
    pop dx
    pop cx
    pop ax
    push si
    push ax
    push cx
    push dx
    call get_shard_sprite
    pop dx
    pop cx
    pop ax
    call game3d_draw_sprite_billboard
    pop si
    jmp game3d_prop_next

game3d_prop_terminal:
    mov bl, dl
    mov bh, dh
    call game3d_project_tile_center
    jnc game3d_prop_next
    mov bl, PAL_CYAN2
    call game3d_draw_marker_at_projected_point
    jmp game3d_prop_next

game3d_prop_surge:
    mov bl, dl
    mov bh, dh
    call game3d_project_tile_center
    jnc game3d_prop_next
    mov bl, PAL_AMBER
    call game3d_draw_marker_at_projected_point
    jmp game3d_prop_next

game3d_prop_gate_locked:
    mov bl, dl
    mov bh, dh
    call game3d_project_tile_center
    jnc game3d_prop_next
    push ax
    push cx
    push dx
    mov bl, PAL_RED2
    call game3d_draw_marker_at_projected_point
    pop dx
    pop cx
    pop ax
    push si
    push ax
    push cx
    push dx
    call get_gate_sprite
    pop dx
    pop cx
    pop ax
    call game3d_draw_sprite_billboard
    pop si
    jmp game3d_prop_next

game3d_prop_gate_open:
    mov bl, dl
    mov bh, dh
    call game3d_project_tile_center
    jnc game3d_prop_next
    push ax
    push cx
    push dx
    mov bl, PAL_GATE
    call game3d_draw_marker_at_projected_point
    pop dx
    pop cx
    pop ax
    push si
    push ax
    push cx
    push dx
    call get_gate_sprite
    pop dx
    pop cx
    pop ax
    call game3d_draw_sprite_billboard
    pop si

game3d_prop_next:
    inc si
    inc dl
    dec cx
    jnz game3d_prop_col_loop
    inc dh
    pop cx
    dec cx
    jnz game3d_prop_row_loop
    ret

render_enemies_3d:
    mov si, offset enemies
    mov cx, MAX_ENEMIES

game3d_enemy_loop:
    cmp byte ptr [si + ENEMY_ALIVE], 0
    je game3d_enemy_next
    mov bl, [si + ENEMY_X]
    mov bh, [si + ENEMY_Y]
    call game3d_project_tile_center
    jnc game3d_enemy_next
    push si
    push ax
    push cx
    push dx
    call game3d_draw_shadow_at_projected_point
    pop dx
    pop cx
    pop ax
    cmp byte ptr [si + ENEMY_KIND], ENEMY_WARDEN
    jne game3d_enemy_no_aura
    push ax
    push cx
    push dx
    mov bl, PAL_RED2
    call game3d_draw_marker_at_projected_point
    pop dx
    pop cx
    pop ax

game3d_enemy_no_aura:
    push ax
    push cx
    push dx
    call get_enemy_sprite
    pop dx
    pop cx
    pop ax
    call game3d_draw_sprite_billboard
    pop si

game3d_enemy_next:
    add si, ENEMY_SIZE
    dec cx
    jnz game3d_enemy_loop
    ret

render_player_3d:
    mov bl, [player_x]
    mov bh, [player_y]
    call game3d_project_tile_center
    jnc render_player_3d_done
    push ax
    push cx
    push dx
    call game3d_draw_shadow_at_projected_point
    pop dx
    pop cx
    pop ax
    push ax
    push cx
    push dx
    call get_player_sprite
    pop dx
    pop cx
    pop ax
    call game3d_draw_sprite_billboard

render_player_3d_done:
    ret

render_gameplay_world_effects_3d:
    call game3d_draw_spoof_marker_3d
    call game3d_draw_threat_marker_3d
    cmp byte ptr [feedback_timer], 0
    je render_gameplay_world_effects_done
    mov al, [message_id]
    cmp al, MSG_PULSE
    je game3d_draw_pulse_effect_3d
    cmp al, MSG_GATE
    je game3d_draw_exit_marker_3d
    cmp al, MSG_SHARD
    je game3d_draw_focus_marker_3d
    cmp al, MSG_SPOOF
    je game3d_draw_spoof_marker_3d
    cmp al, MSG_HIT
    je game3d_draw_focus_marker_3d
    cmp al, MSG_SURGE
    je game3d_draw_focus_marker_3d
    cmp al, MSG_KILL
    je game3d_draw_focus_marker_3d
    cmp al, MSG_TRAP
    je game3d_draw_focus_marker_3d

render_gameplay_world_effects_done:
    ret

game3d_draw_focus_marker_3d:
    mov bl, [effect_x]
    mov bh, [effect_y]
    call game3d_project_tile_center
    jnc game3d_focus_marker_done
    mov bl, PAL_WHITE
    call game3d_draw_marker_at_projected_point

game3d_focus_marker_done:
    ret

game3d_draw_exit_marker_3d:
    mov bl, [exit_x]
    mov bh, [exit_y]
    call game3d_project_tile_center
    jnc game3d_exit_marker_done
    mov bl, PAL_GATE
    call game3d_draw_marker_at_projected_point

game3d_exit_marker_done:
    ret

game3d_draw_spoof_marker_3d:
    cmp byte ptr [spoof_timer], 0
    je game3d_spoof_marker_done
    mov bl, [spoof_x]
    mov bh, [spoof_y]
    call game3d_project_tile_center
    jnc game3d_spoof_exit_marker
    mov bl, PAL_CYAN2
    call game3d_draw_marker_at_projected_point

game3d_spoof_exit_marker:
    mov bl, [exit_x]
    mov bh, [exit_y]
    call game3d_project_tile_center
    jnc game3d_spoof_marker_done
    mov bl, PAL_WHITE
    call game3d_draw_marker_at_projected_point

game3d_spoof_marker_done:
    ret

game3d_draw_threat_marker_3d:
    cmp byte ptr [threat_level], THREAT_NONE
    je game3d_threat_marker_done
    mov bl, [threat_x]
    mov bh, [threat_y]
    call game3d_project_tile_center
    jnc game3d_threat_marker_done
    cmp byte ptr [threat_level], THREAT_ELITE
    jne game3d_threat_near
    mov bl, PAL_RED2
    jmp game3d_threat_color_ready

game3d_threat_near:
    mov bl, PAL_AMBER

game3d_threat_color_ready:
    call game3d_draw_marker_at_projected_point

game3d_threat_marker_done:
    ret

game3d_draw_pulse_effect_3d:
    mov bh, [player_y]
    mov bl, [player_x]
    call game3d_project_tile_center
    jnc game3d_pulse_effect_done
    mov bl, PAL_WHITE
    call game3d_draw_marker_at_projected_point
    mov bl, [player_x]
    dec bl
    mov bh, [player_y]
    call game3d_draw_neighbor_marker_3d
    mov bl, [player_x]
    inc bl
    mov bh, [player_y]
    call game3d_draw_neighbor_marker_3d
    mov bl, [player_x]
    mov bh, [player_y]
    dec bh
    call game3d_draw_neighbor_marker_3d
    mov bl, [player_x]
    mov bh, [player_y]
    inc bh
    call game3d_draw_neighbor_marker_3d

game3d_pulse_effect_done:
    ret

game3d_draw_neighbor_marker_3d:
    cmp bl, PLAY_MIN_X
    jb game3d_neighbor_done
    cmp bl, PLAY_MAX_X
    ja game3d_neighbor_done
    cmp bh, PLAY_MIN_Y
    jb game3d_neighbor_done
    cmp bh, PLAY_MAX_Y
    ja game3d_neighbor_done
    call game3d_project_tile_center
    jnc game3d_neighbor_done
    mov bl, PAL_CYAN2
    call game3d_draw_marker_at_projected_point

game3d_neighbor_done:
    ret

render_gameplay_overlay_effects_3d:
    cmp byte ptr [feedback_timer], 0
    je render_gameplay_overlay_done
    cmp byte ptr [message_id], MSG_SECTOR
    jne render_gameplay_overlay_done
    call draw_sector_entry_card

render_gameplay_overlay_done:
    ret

game3d_should_draw_face:
    ; Input: SI = face record in the active source buffer. Output: AL = 1/0.
    push bx
    push cx
    push dx
    push si
    push di
    push bp

    mov al, [si + 5]
    cmp al, GAME3D_FACE_FLAG_WALL
    jne game3d_should_draw_yes

    mov di, [scene3d_vertex_source]
    xor dx, dx
    xor bp, bp

    mov al, [si]
    xor ah, ah
    mov bx, SCENE3D_VERTEX_BYTES
    mul bx
    mov bx, di
    add bx, ax
    mov ax, [bx]
    add dx, ax
    mov ax, [bx + 4]
    add bp, ax

    mov al, [si + 1]
    xor ah, ah
    mov bx, SCENE3D_VERTEX_BYTES
    mul bx
    mov bx, di
    add bx, ax
    mov ax, [bx]
    add dx, ax
    mov ax, [bx + 4]
    add bp, ax

    mov al, [si + 2]
    xor ah, ah
    mov bx, SCENE3D_VERTEX_BYTES
    mul bx
    mov bx, di
    add bx, ax
    mov ax, [bx]
    add dx, ax
    mov ax, [bx + 4]
    add bp, ax

    mov ax, dx
    cwd
    mov cx, 3
    idiv cx
    mov [scene3d_temp_v], ax

    mov ax, bp
    cwd
    mov cx, 3
    idiv cx
    mov [scene3d_temp_w], ax

    mov bl, [player_x]
    mov bh, [player_y]
    call game3d_get_tile_center_world
    sub ax, [scene3d_temp_v]
    call game3d_abs_ax
    cmp ax, GAME3D_CUTAWAY_RADIUS
    jg game3d_should_draw_yes

    mov ax, dx
    sub ax, [scene3d_temp_w]
    call game3d_abs_ax
    cmp ax, GAME3D_CUTAWAY_RADIUS
    jg game3d_should_draw_yes
    jmp game3d_should_draw_no

game3d_should_draw_yes:
    mov al, 1
    jmp game3d_should_draw_done

game3d_should_draw_no:
    xor al, al

game3d_should_draw_done:
    pop bp
    pop di
    pop si
    pop dx
    pop cx
    pop bx
    ret

game3d_abs_ax:
    or ax, ax
    jns game3d_abs_done
    neg ax

game3d_abs_done:
    ret
