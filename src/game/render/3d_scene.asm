draw_splash_scene_3d:
    mov bx, 0
    mov dx, 0
    mov cx, SCREEN_W
    mov bp, SCREEN_H
    mov al, PAL_BLACK
    call fill_rect

    mov bx, 0
    mov dx, 118
    mov cx, SCREEN_W
    mov bp, 82
    mov al, PAL_BG0
    call fill_rect

    mov bx, 0
    mov dx, 86
    mov cx, SCREEN_W
    mov bp, 1
    mov al, PAL_CYAN
    call fill_rect

IF DEBUG_RENDER_SENTINELS
    mov bx, 0
    mov dx, 8
    mov al, PAL_WHITE
    call draw_debug_render_sentinel_vga
ENDIF
    mov al, [splash_ticks]
    mov [scene3d_tick], al
    mov al, SCENE3D_SPLASH_INDEX
    call scene3d_render_scene
IF DEBUG_RENDER_SENTINELS
    mov bx, 8
    mov dx, 8
    mov al, PAL_AMBER
    call draw_debug_render_sentinel_vga
ENDIF
    cmp byte ptr [splash_ticks], SPLASH_REVEAL_LOGO
    jb draw_splash_scene_3d_ui_gate
    call draw_splash_brand_stack
draw_splash_scene_3d_ui_gate:
    cmp byte ptr [splash_ticks], SPLASH_REVEAL_UI
    jb draw_splash_scene_3d_done
    call draw_splash_ui
draw_splash_scene_3d_done:
IF DEBUG_RENDER_SENTINELS
    mov bx, 16
    mov dx, 8
    mov al, PAL_CYAN2
    call draw_debug_render_sentinel_vga
ENDIF
    ret

draw_title_scene_3d:
    mov bx, 0
    mov dx, 0
    mov cx, SCREEN_W
    mov bp, SCREEN_H
    mov al, PAL_BLACK
    call fill_rect

    mov bx, 0
    mov dx, 112
    mov cx, SCREEN_W
    mov bp, 88
    mov al, PAL_BG0
    call fill_rect

    mov bx, 0
    mov dx, 94
    mov cx, SCREEN_W
    mov bp, 1
    mov al, PAL_CYAN
    call fill_rect

IF DEBUG_RENDER_SENTINELS
    mov bx, 0
    mov dx, 12
    mov al, PAL_WHITE
    call draw_debug_render_sentinel_vga
ENDIF
    mov al, [anim_phase]
    mov [scene3d_tick], al
    mov al, SCENE3D_TITLE_INDEX
    call scene3d_render_scene
IF DEBUG_RENDER_SENTINELS
    mov bx, 8
    mov dx, 12
    mov al, PAL_AMBER
    call draw_debug_render_sentinel_vga
ENDIF
IF DEBUG_RENDER_SENTINELS
    mov bx, 16
    mov dx, 12
    mov al, PAL_CYAN2
    call draw_debug_render_sentinel_vga
ENDIF
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
    push ds
    push es

    mov [scene3d_index], al
    mov byte ptr [scene3d_active], 1
    mov byte ptr [game3d_rendering_active], 0
    call scene3d_resolve_timeline_tick
    call scene3d_copy_scene_payload
    call scene3d_setup_scene_camera
    call scene3d_project_vertices
    call scene3d_build_face_order
    call scene3d_draw_face_order
    mov byte ptr [scene3d_active], 0

    pop es
    pop ds
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

    mov word ptr [scene3d_vertex_count], 0
    mov byte ptr [scene3d_face_count], 0

    xor bx, bx
    mov bl, [scene3d_index]
    mov cl, cs:[scene3d_group_count_table + bx]
    mov bl, cs:[scene3d_group_start_table + bx]
    xor bh, bh

scene3d_copy_group_loop:
    or cl, cl
    jz scene3d_copy_scene_done
    push cx
    call scene3d_append_group_payload
    pop cx
    inc bx
    dec cl
    jmp scene3d_copy_group_loop

scene3d_copy_scene_done:

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

scene3d_resolve_timeline_tick:
    push ax
    push bx

    xor bx, bx
    mov bl, [scene3d_index]
    mov al, [scene3d_tick]
    mov ah, cs:[scene3d_timeline_loop_table + bx]
    or ah, ah
    jz scene3d_timeline_clamp

scene3d_timeline_wrap_loop:
    cmp al, ah
    jb scene3d_timeline_store
    sub al, ah
    jmp scene3d_timeline_wrap_loop

scene3d_timeline_clamp:
    mov ah, cs:[scene3d_timeline_length_table + bx]
    or ah, ah
    jnz scene3d_timeline_length_ready
    mov ah, 1

scene3d_timeline_length_ready:
    cmp al, ah
    jb scene3d_timeline_store
    mov al, ah
    dec al

scene3d_timeline_store:
    mov [scene3d_timeline_tick], al

    pop bx
    pop ax
    ret

scene3d_setup_scene_camera:
    push ax
    push bx
    push si

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

    shr bx, 1
    mov al, bl
    mov bl, SCENE3D_TIMELINE_TICKS
    mul bl
    xor bx, bx
    mov bl, [scene3d_timeline_tick]
    add ax, bx
    mov si, ax
    shl si, 1

    mov ax, cs:[scene3d_timeline_camera_x_table + si]
    mov [scene3d_cam_x], ax
    mov ax, cs:[scene3d_timeline_camera_y_table + si]
    mov [scene3d_cam_y], ax
    mov ax, cs:[scene3d_timeline_camera_z_table + si]
    mov [scene3d_cam_z], ax
    mov ax, cs:[scene3d_timeline_project_scale_table + si]
    mov [scene3d_project_scale], ax

    shr si, 1
    mov al, cs:[scene3d_timeline_yaw_table + si]
    mov [scene3d_yaw_angle], al
    mov al, cs:[scene3d_timeline_pitch_table + si]
    mov [scene3d_pitch_angle], al

    pop si
    pop bx
    pop ax
    ret

scene3d_append_group_payload:
    push ax
    push bx
    push cx
    push dx
    push si
    push di
    push bp
    push ds
    push es

    mov [scene3d_temp_face], bl
    mov al, [scene3d_timeline_tick]
    cmp al, cs:[scene3d_group_start_tick_table + bx]
    jb scene3d_append_group_done
    cmp al, cs:[scene3d_group_end_tick_table + bx]
    ja scene3d_append_group_done

    mov cl, [scene3d_timeline_tick]
    sub cl, cs:[scene3d_group_start_tick_table + bx]
    mov dl, cs:[scene3d_group_motion_ticks_table + bx]
    or dl, dl
    jz scene3d_group_motion_tick_ready
    cmp cl, dl
    jbe scene3d_group_motion_tick_ready
    mov cl, dl

scene3d_group_motion_tick_ready:
    xor ax, ax
    mov al, cs:[scene3d_group_vertex_count_table + bx]
    add ax, [scene3d_vertex_count]
    jc scene3d_append_group_overflow
    cmp ax, SCENE3D_MAX_VERTICES
    ja scene3d_append_group_overflow

    mov al, cs:[scene3d_group_face_count_table + bx]
    add al, [scene3d_face_count]
    jc scene3d_append_group_overflow
    cmp al, SCENE3D_MAX_FACES
    ja scene3d_append_group_overflow

    mov ax, [scene3d_vertex_count]
    mov [scene3d_temp_depth], ax
    mov [scene3d_temp_s], ax
    push ax

    mov si, bx
    shl si, 1

    mov ax, cs:[scene3d_group_offset_x_table + si]
    mov [scene3d_temp_x], ax
    mov ax, cs:[scene3d_group_offset_x_step_table + si]
    xor bx, bx
    mov bl, cl
    imul bx
    add ax, [scene3d_temp_x]
    mov [scene3d_temp_x], ax

    mov ax, cs:[scene3d_group_offset_y_table + si]
    mov [scene3d_temp_y], ax
    mov ax, cs:[scene3d_group_offset_y_step_table + si]
    xor bx, bx
    mov bl, cl
    imul bx
    add ax, [scene3d_temp_y]
    mov [scene3d_temp_y], ax

    mov ax, cs:[scene3d_group_offset_z_table + si]
    mov [scene3d_temp_z], ax
    mov ax, cs:[scene3d_group_offset_z_step_table + si]
    xor bx, bx
    mov bl, cl
    imul bx
    add ax, [scene3d_temp_z]
    mov [scene3d_temp_z], ax

    shr si, 1
    mov al, cs:[scene3d_group_yaw_step_table + si]
    cbw
    xor bx, bx
    mov bl, cl
    imul bx
    add al, cs:[scene3d_group_yaw_base_table + si]
    call scene3d_get_sin_cos
    mov [scene3d_temp_u], bx
    mov [scene3d_temp_v], dx

    mov ax, GEOMETRY_BANK_SEG
    mov ds, ax
    push cs
    pop es

    mov ax, [scene3d_vertex_count]
    mov bx, SCENE3D_VERTEX_BYTES
    mul bx
    mov di, offset scene3d_vertex_raw
    add di, ax

    xor bx, bx
    mov bl, [scene3d_temp_face]
    xor ax, ax
    mov al, cs:[scene3d_group_vertex_count_table + bx]
    mov bp, ax
    mov si, bx
    shl si, 1
    mov si, cs:[scene3d_group_vertex_offset_table + si]

scene3d_group_vertex_loop:
    or bp, bp
    jz scene3d_group_faces_begin

    mov ax, ds:[si]
    mov [scene3d_temp_l], ax
    mov ax, ds:[si + 4]
    mov [scene3d_temp_r], ax

    mov ax, [scene3d_temp_l]
    mov bx, [scene3d_temp_v]
    call scene3d_mul_ax_bx_fixed
    mov [scene3d_temp_w], ax
    mov ax, [scene3d_temp_r]
    mov bx, [scene3d_temp_u]
    call scene3d_mul_ax_bx_fixed
    mov dx, [scene3d_temp_w]
    sub dx, ax
    add dx, [scene3d_temp_x]
    mov ax, dx
    stosw

    mov ax, ds:[si + 2]
    add ax, [scene3d_temp_y]
    stosw

    mov ax, [scene3d_temp_l]
    mov bx, [scene3d_temp_u]
    call scene3d_mul_ax_bx_fixed
    mov [scene3d_temp_w], ax
    mov ax, [scene3d_temp_r]
    mov bx, [scene3d_temp_v]
    call scene3d_mul_ax_bx_fixed
    add ax, [scene3d_temp_w]
    add ax, [scene3d_temp_z]
    stosw

    add si, SCENE3D_VERTEX_BYTES
    dec bp
    jmp scene3d_group_vertex_loop

scene3d_group_faces_begin:
    xor ax, ax
    mov al, [scene3d_face_count]
    mov bx, SCENE3D_FACE_BYTES
    mul bx
    mov di, offset scene3d_face_raw
    add di, ax

    xor bx, bx
    mov bl, [scene3d_temp_face]
    xor ax, ax
    mov al, cs:[scene3d_group_face_count_table + bx]
    mov bp, ax
    mov si, bx
    shl si, 1
    mov si, cs:[scene3d_group_face_offset_table + si]

scene3d_group_face_loop:
    or bp, bp
    jz scene3d_group_face_done

    mov al, ds:[si]
    xor ah, ah
    add ax, [scene3d_temp_s]
    stosb
    mov al, ds:[si + 1]
    xor ah, ah
    add ax, [scene3d_temp_s]
    stosb
    mov al, ds:[si + 2]
    xor ah, ah
    add ax, [scene3d_temp_s]
    stosb
    mov al, ds:[si + 3]
    stosb
    mov al, ds:[si + 4]
    stosb
    mov al, ds:[si + 5]
    stosb
    mov al, ds:[si + 6]
    stosb
    add si, SCENE3D_FACE_BYTES
    dec bp
    jmp scene3d_group_face_loop

scene3d_group_face_done:
    xor bx, bx
    mov bl, [scene3d_temp_face]
    mov ax, [scene3d_temp_s]
    xor cx, cx
    mov cl, cs:[scene3d_group_vertex_count_table + bx]
    add ax, cx
    mov [scene3d_vertex_count], ax
    mov al, [scene3d_face_count]
    add al, cs:[scene3d_group_face_count_table + bx]
    mov [scene3d_face_count], al
    pop ax
    jmp scene3d_append_group_done

scene3d_append_group_overflow:
    mov word ptr [scene3d_vertex_count], 0
    mov byte ptr [scene3d_face_count], 0

scene3d_append_group_done:
    pop es
    pop ds
    pop bp
    pop di
    pop si
    pop dx
    pop cx
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

IF DEBUG_RENDER_SENTINELS
    mov bx, 48
    mov dx, 20
    mov al, PAL_WHITE
    call draw_debug_render_sentinel_vga
ENDIF
    mov al, [scene3d_yaw_angle]
    call scene3d_get_sin_cos
    mov [scene3d_temp_x], bx
    mov [scene3d_temp_y], dx

IF DEBUG_RENDER_SENTINELS
    mov bx, 56
    mov dx, 20
    mov al, PAL_CYAN
    call draw_debug_render_sentinel_vga
ENDIF
    mov al, [scene3d_pitch_angle]
    call scene3d_get_sin_cos
    mov [scene3d_temp_z], bx
    mov [scene3d_temp_u], dx

IF DEBUG_RENDER_SENTINELS
    mov bx, 64
    mov dx, 20
    mov al, PAL_AMBER
    call draw_debug_render_sentinel_vga
ENDIF
    xor bp, bp

scene3d_project_vertex_loop:
    mov ax, [scene3d_vertex_count]
    cmp bp, ax
    jae scene3d_project_vertices_done

IF DEBUG_RENDER_SENTINELS
    cmp bp, 0
    jne scene3d_project_vertex_loop_marker_1
    mov bx, 72
    mov dx, 20
    mov al, PAL_WHITE
    call draw_debug_render_sentinel_vga
scene3d_project_vertex_loop_marker_1:
ENDIF

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
    mov bx, cx
    cmp bx, 256
    jae scene3d_project_vertex_project
    shl bx, 1
    shl bx, 1
    shl bx, 1
    shl bx, 1
    shl bx, 1
    shl bx, 1
    shl bx, 1
    shl bx, 1

    mov ax, [scene3d_temp_v]
    or ax, ax
    jns scene3d_project_vertex_v_abs_ready
    neg ax

scene3d_project_vertex_v_abs_ready:
    cmp ax, bx
    jg scene3d_project_vertex_extreme
    mov ax, [scene3d_temp_w]
    or ax, ax
    jns scene3d_project_vertex_w_abs_ready
    neg ax

scene3d_project_vertex_w_abs_ready:
    cmp ax, bx
    jg scene3d_project_vertex_extreme

scene3d_project_vertex_project:
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
    jmp scene3d_project_vertex_next

scene3d_project_vertex_extreme:
    mov ax, [scene3d_temp_v]
    or ax, ax
    jns scene3d_project_vertex_extreme_right
    mov word ptr [scene3d_vertex_x + di], -320
    jmp scene3d_project_vertex_extreme_x_done

scene3d_project_vertex_extreme_right:
    mov word ptr [scene3d_vertex_x + di], SCREEN_W + 320

scene3d_project_vertex_extreme_x_done:
    mov ax, [scene3d_temp_w]
    or ax, ax
    jns scene3d_project_vertex_extreme_up
    mov word ptr [scene3d_vertex_y + di], SCREEN_H + 200
    jmp scene3d_project_vertex_next

scene3d_project_vertex_extreme_up:
    mov word ptr [scene3d_vertex_y + di], -200

scene3d_project_vertex_next:
    inc bp
IF DEBUG_RENDER_SENTINELS
    cmp bp, 1
    jne scene3d_project_vertex_next_done
    mov bx, 80
    mov dx, 20
    mov al, PAL_CYAN2
    call draw_debug_render_sentinel_vga
scene3d_project_vertex_next_done:
ENDIF
    jmp scene3d_project_vertex_loop

scene3d_project_vertices_done:
IF DEBUG_RENDER_SENTINELS
    mov bx, 88
    mov dx, 20
    mov al, PAL_AMBER
    call draw_debug_render_sentinel_vga
ENDIF
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

    mov [scene3d_temp_face], bl
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
    mov [scene3d_temp_depth], ax
    mov [scene3d_temp_s], ax
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
    add [scene3d_temp_depth], ax
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
    add [scene3d_temp_depth], ax
    mov ax, [scene3d_vertex_x + di]
    mov [scene3d_tri_x2], ax
    mov ax, [scene3d_vertex_y + di]
    mov [scene3d_tri_y2], ax

    mov al, [si + 3]
    mov [scene3d_temp_color], al
    mov al, [si + 4]
    mov [scene3d_temp_dither], al
    mov al, [si + 6]
    mov [scene3d_temp_texture], al
    cmp byte ptr [game3d_rendering_active], 0
    je scene3d_draw_face_scene_fx
    cmp byte ptr [gameplay_render_mode], GAMEPLAY_RENDER_MODE_3D_REFERENCE
    jne scene3d_draw_face_room_fx
    mov byte ptr [scene3d_temp_texture], SCENE3D_TEXTURE_NONE

scene3d_draw_face_room_fx:
    call game3d_apply_room_face_palette
    jmp scene3d_draw_face_fx_done

scene3d_draw_face_scene_fx:
    mov al, [si + 5]
    call scene3d_apply_face_fx
    call scene3d_apply_frontend_face_fog
    cmp byte ptr [scene3d_temp_texture], SCENE3D_TEXTURE_NONE
    je scene3d_draw_face_fx_done
    call scene3d_prepare_face_texture
    call scene3d_draw_textured_triangle
    jmp scene3d_draw_face_by_index_done

scene3d_draw_face_fx_done:
    call scene3d_draw_triangle

scene3d_draw_face_by_index_done:
    pop di
    pop si
    pop dx
    pop cx
    pop bx
    pop ax
    ret

scene3d_apply_frontend_face_fog:
    mov byte ptr [scene3d_temp_fog], 0
    cmp byte ptr [scene3d_temp_texture], SCENE3D_TEXTURE_NONE
    je scene3d_apply_frontend_face_fog_done

    xor bx, bx
    mov bl, [scene3d_temp_face]
    shl bx, 1
    mov ax, [scene3d_face_depth + bx]
    cmp ax, SCENE3D_FRONTEND_FOG_MID_Z
    jb scene3d_apply_frontend_face_fog_done
    mov byte ptr [scene3d_temp_color], PAL_PANEL2
    mov byte ptr [scene3d_temp_dither], PAL_PANEL
    mov byte ptr [scene3d_temp_fog], 1
    cmp ax, SCENE3D_FRONTEND_FOG_FAR_Z
    jb scene3d_apply_frontend_face_fog_done
    mov byte ptr [scene3d_temp_color], PAL_PANEL
    mov byte ptr [scene3d_temp_dither], PAL_BG1
    mov byte ptr [scene3d_temp_fog], 2

scene3d_apply_frontend_face_fog_done:
    ret

scene3d_apply_face_fx:
    cmp al, SCENE3D_FACEFX_PULSE_CYAN
    je scene3d_face_fx_pulse_cyan
    cmp al, SCENE3D_FACEFX_PULSE_AMBER
    je scene3d_face_fx_pulse_amber
    cmp al, SCENE3D_FACEFX_GLINT
    je scene3d_face_fx_glint
    ret

scene3d_face_fx_pulse_cyan:
    mov bl, [scene3d_timeline_tick]
    and bl, 3
    cmp bl, 0
    jne scene3d_face_fx_pulse_cyan_dim
    mov byte ptr [scene3d_temp_color], PAL_WHITE
    mov byte ptr [scene3d_temp_dither], PAL_CYAN2
    ret

scene3d_face_fx_pulse_cyan_dim:
    mov byte ptr [scene3d_temp_color], PAL_CYAN2
    mov byte ptr [scene3d_temp_dither], PAL_CYAN
    ret

scene3d_face_fx_pulse_amber:
    mov bl, [scene3d_timeline_tick]
    and bl, 3
    cmp bl, 0
    jne scene3d_face_fx_pulse_amber_dim
    mov byte ptr [scene3d_temp_color], PAL_WHITE
    mov byte ptr [scene3d_temp_dither], PAL_AMBER
    ret

scene3d_face_fx_pulse_amber_dim:
    mov byte ptr [scene3d_temp_color], PAL_AMBER
    mov byte ptr [scene3d_temp_dither], PAL_WHITE
    ret

scene3d_face_fx_glint:
    mov bl, [scene3d_timeline_tick]
    and bl, 1
    jz scene3d_face_fx_glint_bright
    mov byte ptr [scene3d_temp_color], PAL_AMBER
    mov byte ptr [scene3d_temp_dither], PAL_WHITE
    ret

scene3d_face_fx_glint_bright:
    mov byte ptr [scene3d_temp_color], PAL_WHITE
    mov byte ptr [scene3d_temp_dither], PAL_CYAN2
    ret
