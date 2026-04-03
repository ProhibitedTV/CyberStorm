draw_splash_scene_3d:
    mov bx, 0
    mov dx, 0
    mov cx, SCREEN_W
    mov bp, SCREEN_H
    mov al, PAL_BG0
    call fill_rect

    mov bx, 0
    mov dx, 92
    mov cx, SCREEN_W
    mov bp, 108
    mov al, PAL_BG1
    call fill_rect

    mov al, [splash_ticks]
    mov [scene3d_tick], al
    mov al, SCENE3D_SPLASH_INDEX
    call scene3d_render_scene
    call draw_splash_brand_stack
    cmp byte ptr [splash_ticks], SPLASH_REVEAL_UI
    jb draw_splash_scene_3d_done
    call draw_splash_ui
draw_splash_scene_3d_done:
    ret

draw_title_scene_3d:
    mov bx, 0
    mov dx, 0
    mov cx, SCREEN_W
    mov bp, SCREEN_H
    mov al, PAL_BG0
    call fill_rect

    mov bx, 0
    mov dx, 126
    mov cx, SCREEN_W
    mov bp, 74
    mov al, PAL_BG1
    call fill_rect

    mov al, [anim_phase]
    mov [scene3d_tick], al
    mov al, SCENE3D_TITLE_INDEX
    call scene3d_render_scene
    call draw_title_scene_overlay
    ret

draw_win_scene_3d:
    mov bx, 0
    mov dx, 0
    mov cx, SCREEN_W
    mov bp, SCREEN_H
    mov al, PAL_BG0
    call fill_rect
    mov al, [state_ticks]
    mov [scene3d_tick], al
    mov al, SCENE3D_WIN_INDEX
    call scene3d_render_scene
    call draw_win_scene_overlay
    ret

draw_lose_scene_3d:
    mov bx, 0
    mov dx, 0
    mov cx, SCREEN_W
    mov bp, SCREEN_H
    mov al, PAL_BG0
    call fill_rect
    mov al, [state_ticks]
    mov [scene3d_tick], al
    mov al, SCENE3D_LOSE_INDEX
    call scene3d_render_scene
    call draw_lose_scene_overlay
    ret

draw_sector_entry_card_3d:
    call get_major_feedback_stage
    cmp al, SECTOR_CARD_STAGE_LIMIT
    jae draw_sector_entry_card_3d_done

    push ax
    mov bx, 62
    mov dx, 44
    mov cx, 156
    mov bp, 68
    mov al, PAL_PANEL
    call fill_rect

    mov bx, 58
    mov dx, 40
    mov cx, 164
    mov bp, 76
    call get_sector_accent_color
    call draw_rect_outline

    pop ax
    mov [scene3d_tick], al
    mov al, [sector_num]
    dec al
    add al, SCENE3D_SECTOR1_INDEX
    call scene3d_render_scene
    call draw_sector_entry_card_overlay

draw_sector_entry_card_3d_done:
    ret

scene3d_render_scene:
    ; Input: AL = scene index
    push ax
    push bx
    push cx
    push dx
    push si
    push di
    push bp

    mov [scene3d_index], al
    mov byte ptr [game3d_rendering_active], 0
    call scene3d_copy_scene_payload
    call scene3d_setup_scene_camera
    call scene3d_project_vertices
    call scene3d_build_face_order
    call scene3d_draw_face_order

    pop bp
    pop di
    pop si
    pop dx
    pop cx
    pop bx
    pop ax
    ret

scene3d_copy_scene_payload:
    push ax
    push bx
    push cx
    push dx
    push si
    push di
    push ds
    push es

    xor bx, bx
    mov bl, [scene3d_index]
    xor ax, ax
    mov al, cs:[scene3d_vertex_count_table + bx]
    mov [scene3d_vertex_count], ax
    mov al, cs:[scene3d_face_count_table + bx]
    mov [scene3d_face_count], al

    mov si, bx
    shl si, 1
    mov si, cs:[scene3d_vertex_offset_table + si]
    xor ax, ax
    mov cx, [scene3d_vertex_count]
    mov ax, SCENE3D_VERTEX_BYTES
    mul cx
    mov cx, ax
    mov ax, GEOMETRY_BANK_SEG
    mov ds, ax
    push cs
    pop es
    mov di, offset scene3d_vertex_raw
    cld
    rep movsb

    mov ax, GEOMETRY_BANK_SEG
    mov ds, ax
    xor bx, bx
    mov bl, [scene3d_index]
    mov si, bx
    shl si, 1
    mov si, cs:[scene3d_face_offset_table + si]
    xor ax, ax
    mov al, [scene3d_face_count]
    mov cx, ax
    mov ax, SCENE3D_FACE_BYTES
    mul cx
    mov cx, ax
    push cs
    pop es
    mov di, offset scene3d_face_raw
    cld
    rep movsb

    mov word ptr [scene3d_vertex_source], offset scene3d_vertex_raw
    mov word ptr [scene3d_face_source], offset scene3d_face_raw

    pop es
    pop ds
    pop di
    pop si
    pop dx
    pop cx
    pop bx
    pop ax
    ret

scene3d_setup_scene_camera:
    push ax
    push bx

    xor bx, bx
    mov bl, [scene3d_index]
    shl bx, 1
    mov ax, cs:[scene3d_view_x_table + bx]
    mov [scene3d_clip_left], ax
    mov ax, cs:[scene3d_view_y_table + bx]
    mov [scene3d_clip_top], ax
    mov ax, cs:[scene3d_view_w_table + bx]
    mov [scene3d_temp_x], ax
    mov ax, cs:[scene3d_view_h_table + bx]
    mov [scene3d_temp_y], ax
    mov ax, [scene3d_clip_left]
    add ax, [scene3d_temp_x]
    dec ax
    mov [scene3d_clip_right], ax
    mov ax, [scene3d_clip_top]
    add ax, [scene3d_temp_y]
    dec ax
    mov [scene3d_clip_bottom], ax

    mov ax, [scene3d_temp_x]
    shr ax, 1
    add ax, [scene3d_clip_left]
    mov [scene3d_center_x], ax
    mov ax, [scene3d_temp_y]
    shr ax, 1
    add ax, [scene3d_clip_top]
    mov [scene3d_center_y], ax

    mov ax, cs:[scene3d_camera_x_table + bx]
    mov [scene3d_cam_x], ax
    mov ax, cs:[scene3d_camera_y_table + bx]
    mov [scene3d_cam_y], ax
    mov ax, cs:[scene3d_camera_z_table + bx]
    mov [scene3d_cam_z], ax

    shr bx, 1
    mov al, [scene3d_tick]
    mul byte ptr cs:[scene3d_yaw_step_table + bx]
    add al, byte ptr cs:[scene3d_yaw_base_table + bx]
    mov [scene3d_yaw_angle], al

    mov al, [scene3d_tick]
    mul byte ptr cs:[scene3d_pitch_step_table + bx]
    add al, byte ptr cs:[scene3d_pitch_base_table + bx]
    mov [scene3d_pitch_angle], al

    shl bx, 1
    mov ax, cs:[scene3d_project_scale_table + bx]
    mov [scene3d_project_scale], ax

    pop bx
    pop ax
    ret

scene3d_project_vertices:
    push ax
    push bx
    push cx
    push dx
    push si
    push di
    push bp

    mov al, [scene3d_yaw_angle]
    call scene3d_get_sin_cos
    mov [scene3d_temp_x], bx
    mov [scene3d_temp_y], dx

    mov al, [scene3d_pitch_angle]
    call scene3d_get_sin_cos
    mov [scene3d_temp_z], bx
    mov [scene3d_temp_u], dx

    xor bp, bp

scene3d_project_vertex_loop:
    mov ax, [scene3d_vertex_count]
    cmp bp, ax
    jae scene3d_project_vertices_done

    mov si, [scene3d_vertex_source]
    mov ax, bp
    mov bx, SCENE3D_VERTEX_BYTES
    mul bx
    add si, ax

    mov ax, [si]
    sub ax, [scene3d_cam_x]
    mov [scene3d_temp_v], ax
    mov ax, [si + 2]
    sub ax, [scene3d_cam_y]
    mov [scene3d_temp_w], ax
    mov ax, [si + 4]
    sub ax, [scene3d_cam_z]
    mov [scene3d_temp_l], ax

    mov ax, [scene3d_temp_v]
    mov [scene3d_temp_r], ax
    mov ax, [scene3d_temp_v]
    mov bx, [scene3d_temp_y]
    call scene3d_mul_ax_bx_fixed
    mov dx, ax
    mov ax, [scene3d_temp_l]
    mov bx, [scene3d_temp_x]
    call scene3d_mul_ax_bx_fixed
    sub dx, ax
    mov [scene3d_temp_v], dx

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
    mov dx, ax
    mov ax, [scene3d_temp_l]
    mov bx, [scene3d_temp_z]
    call scene3d_mul_ax_bx_fixed
    sub dx, ax
    mov [scene3d_temp_w], dx

    mov ax, [scene3d_temp_r]
    mov bx, [scene3d_temp_z]
    call scene3d_mul_ax_bx_fixed
    mov [scene3d_temp_r], ax
    mov ax, [scene3d_temp_l]
    mov bx, [scene3d_temp_u]
    call scene3d_mul_ax_bx_fixed
    add ax, [scene3d_temp_r]
    mov [scene3d_temp_l], ax

    mov di, bp
    shl di, 1
    mov ax, [scene3d_temp_l]
    mov [scene3d_vertex_z + di], ax
    cmp ax, SCENE3D_NEAR_Z
    jg scene3d_project_vertex_visible
    mov word ptr [scene3d_vertex_x + di], -320
    mov word ptr [scene3d_vertex_y + di], -200
    jmp scene3d_project_vertex_next

scene3d_project_vertex_visible:
    mov cx, [scene3d_temp_l]
    mov bx, [scene3d_project_scale]
    mov ax, [scene3d_temp_v]
    call scene3d_project_ax
    add ax, [scene3d_center_x]
    mov [scene3d_vertex_x + di], ax

    mov cx, [scene3d_temp_l]
    mov bx, [scene3d_project_scale]
    mov ax, [scene3d_temp_w]
    call scene3d_project_ax
    neg ax
    add ax, [scene3d_center_y]
    mov [scene3d_vertex_y + di], ax

scene3d_project_vertex_next:
    inc bp
    jmp scene3d_project_vertex_loop

scene3d_project_vertices_done:
    pop bp
    pop di
    pop si
    pop dx
    pop cx
    pop bx
    pop ax
    ret

scene3d_build_face_order:
    push ax
    push bx
    push cx
    push dx
    push si
    push di
    push bp

    xor di, di

scene3d_face_build_loop:
    mov al, [scene3d_face_count]
    xor ah, ah
    cmp di, ax
    jae scene3d_face_sort

    mov ax, di
    mov bx, SCENE3D_FACE_BYTES
    mul bx
    mov si, [scene3d_face_source]
    add si, ax

    mov al, [si]
    xor ah, ah
    shl ax, 1
    mov bx, ax
    mov ax, [scene3d_vertex_z + bx]
    mov [scene3d_temp_v], ax

    mov al, [si + 1]
    xor ah, ah
    shl ax, 1
    mov bx, ax
    mov ax, [scene3d_vertex_z + bx]
    add ax, [scene3d_temp_v]
    mov [scene3d_temp_v], ax

    mov al, [si + 2]
    xor ah, ah
    shl ax, 1
    mov bx, ax
    mov ax, [scene3d_vertex_z + bx]
    add ax, [scene3d_temp_v]
    cwd
    mov bx, 3
    idiv bx
    mov bx, di
    shl bx, 1
    mov [scene3d_face_depth + bx], ax

    mov ax, di
    mov byte ptr [scene3d_face_order + di], al
    inc di
    jmp scene3d_face_build_loop

scene3d_face_sort:
    mov cl, [scene3d_face_count]
    dec cl
    js scene3d_build_face_order_done

scene3d_face_sort_outer:
    xor ch, ch
    mov bp, cx
    xor di, di

scene3d_face_sort_inner:
    cmp di, bp
    jae scene3d_face_sort_next
    mov al, [scene3d_face_order + di]
    xor ah, ah
    mov bx, ax
    shl bx, 1
    mov al, [scene3d_face_order + di + 1]
    xor ah, ah
    mov si, ax
    shl si, 1
    mov ax, [scene3d_face_depth + bx]
    cmp ax, [scene3d_face_depth + si]
    jge scene3d_face_sort_keep
    mov al, [scene3d_face_order + di]
    xchg al, [scene3d_face_order + di + 1]
    mov [scene3d_face_order + di], al

scene3d_face_sort_keep:
    inc di
    jmp scene3d_face_sort_inner

scene3d_face_sort_next:
    dec cl
    jns scene3d_face_sort_outer

scene3d_build_face_order_done:
    pop bp
    pop di
    pop si
    pop dx
    pop cx
    pop bx
    pop ax
    ret

scene3d_draw_face_order:
    push ax
    push bx
    push cx
    push dx
    push si
    push di

    xor di, di

scene3d_draw_face_loop:
    mov al, [scene3d_face_count]
    xor ah, ah
    cmp di, ax
    jae scene3d_draw_face_done
    mov bl, [scene3d_face_order + di]
    call scene3d_draw_face_by_index
    inc di
    jmp scene3d_draw_face_loop

scene3d_draw_face_done:
    pop di
    pop si
    pop dx
    pop cx
    pop bx
    pop ax
    ret

scene3d_draw_face_by_index:
    push ax
    push bx
    push cx
    push dx
    push si
    push di

    xor bh, bh
    mov si, bx
    mov ax, SCENE3D_FACE_BYTES
    mul si
    mov si, [scene3d_face_source]
    add si, ax

    cmp byte ptr [game3d_rendering_active], 0
    je scene3d_draw_face_index_ready
    call game3d_should_draw_face
    cmp al, 0
    je scene3d_draw_face_by_index_done

scene3d_draw_face_index_ready:

    mov al, [si]
    xor ah, ah
    shl ax, 1
    mov di, ax
    mov ax, [scene3d_vertex_z + di]
    cmp ax, SCENE3D_NEAR_Z
    jle scene3d_draw_face_by_index_done
    mov ax, [scene3d_vertex_x + di]
    mov [scene3d_tri_x0], ax
    mov ax, [scene3d_vertex_y + di]
    mov [scene3d_tri_y0], ax

    mov al, [si + 1]
    xor ah, ah
    shl ax, 1
    mov di, ax
    mov ax, [scene3d_vertex_z + di]
    cmp ax, SCENE3D_NEAR_Z
    jle scene3d_draw_face_by_index_done
    mov ax, [scene3d_vertex_x + di]
    mov [scene3d_tri_x1], ax
    mov ax, [scene3d_vertex_y + di]
    mov [scene3d_tri_y1], ax

    mov al, [si + 2]
    xor ah, ah
    shl ax, 1
    mov di, ax
    mov ax, [scene3d_vertex_z + di]
    cmp ax, SCENE3D_NEAR_Z
    jle scene3d_draw_face_by_index_done
    mov ax, [scene3d_vertex_x + di]
    mov [scene3d_tri_x2], ax
    mov ax, [scene3d_vertex_y + di]
    mov [scene3d_tri_y2], ax

    mov al, [si + 3]
    mov [scene3d_temp_color], al
    mov al, [si + 4]
    mov [scene3d_temp_dither], al
    call scene3d_draw_triangle

scene3d_draw_face_by_index_done:
    pop di
    pop si
    pop dx
    pop cx
    pop bx
    pop ax
    ret
