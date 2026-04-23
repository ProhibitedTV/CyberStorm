scene3d_draw_triangle:
    call scene3d_sort_triangle_vertices

    mov ax, [scene3d_tri_y2]
    cmp ax, [scene3d_tri_y0]
    je scene3d_draw_triangle_done

    mov ax, [scene3d_tri_x2]
    sub ax, [scene3d_tri_x0]
    mov bx, [scene3d_tri_y2]
    sub bx, [scene3d_tri_y0]
    call scene3d_compute_fixed_step
    mov [scene3d_temp_l], ax

    mov ax, [scene3d_tri_x0]
    shl ax, 1
    shl ax, 1
    shl ax, 1
    shl ax, 1
    mov [scene3d_temp_x], ax

    mov cx, [scene3d_tri_y1]
    sub cx, [scene3d_tri_y0]
    jle scene3d_triangle_lower_setup

    mov ax, [scene3d_tri_x1]
    sub ax, [scene3d_tri_x0]
    mov bx, cx
    call scene3d_compute_fixed_step
    mov [scene3d_temp_r], ax

    mov ax, [scene3d_tri_x0]
    shl ax, 1
    shl ax, 1
    shl ax, 1
    shl ax, 1
    mov [scene3d_temp_y], ax

    mov dx, [scene3d_tri_y0]

scene3d_triangle_upper_loop:
    cmp dx, [scene3d_tri_y1]
    jge scene3d_triangle_lower_setup
    mov ax, [scene3d_temp_x]
    mov bx, [scene3d_temp_y]
    call scene3d_draw_fixed_span
    mov ax, [scene3d_temp_x]
    add ax, [scene3d_temp_l]
    mov [scene3d_temp_x], ax
    mov ax, [scene3d_temp_y]
    add ax, [scene3d_temp_r]
    mov [scene3d_temp_y], ax
    inc dx
    jmp scene3d_triangle_upper_loop

scene3d_triangle_lower_setup:
    mov cx, [scene3d_tri_y2]
    sub cx, [scene3d_tri_y1]
    jle scene3d_draw_triangle_done

    mov ax, [scene3d_tri_x2]
    sub ax, [scene3d_tri_x1]
    mov bx, cx
    call scene3d_compute_fixed_step
    mov [scene3d_temp_r], ax

    mov ax, [scene3d_tri_x1]
    shl ax, 1
    shl ax, 1
    shl ax, 1
    shl ax, 1
    mov [scene3d_temp_y], ax

    mov dx, [scene3d_tri_y1]

scene3d_triangle_lower_loop:
    cmp dx, [scene3d_tri_y2]
    jg scene3d_draw_triangle_done
    mov ax, [scene3d_temp_x]
    mov bx, [scene3d_temp_y]
    call scene3d_draw_fixed_span
    mov ax, [scene3d_temp_x]
    add ax, [scene3d_temp_l]
    mov [scene3d_temp_x], ax
    mov ax, [scene3d_temp_y]
    add ax, [scene3d_temp_r]
    mov [scene3d_temp_y], ax
    inc dx
    jmp scene3d_triangle_lower_loop

scene3d_draw_triangle_done:
    ret

scene3d_compute_fixed_step:
    ; Input: AX = delta X, BX = delta Y. Output: AX = 12.4 fixed slope.
    or bx, bx
    jnz scene3d_compute_fixed_step_do
    xor ax, ax
    ret

scene3d_compute_fixed_step_do:
    shl ax, 1
    shl ax, 1
    shl ax, 1
    shl ax, 1
    cwd
    idiv bx
    ret

scene3d_draw_fixed_span:
    ; Input: AX = xA in 12.4 fixed, BX = xB in 12.4 fixed, DX = y.
    push ax
    push bx
    push cx
    push dx
    push si
    push di
    push bp
    push ds

    cmp dx, [scene3d_clip_top]
    jl scene3d_draw_fixed_span_done
    cmp dx, [scene3d_clip_bottom]
    jg scene3d_draw_fixed_span_done

    mov cx, ax
    mov si, bx
    sar cx, 1
    sar cx, 1
    sar cx, 1
    sar cx, 1
    sar si, 1
    sar si, 1
    sar si, 1
    sar si, 1

    cmp cx, si
    jle scene3d_draw_fixed_span_ordered
    xchg cx, si

scene3d_draw_fixed_span_ordered:
    cmp cx, [scene3d_clip_right]
    jg scene3d_draw_fixed_span_done
    cmp si, [scene3d_clip_left]
    jl scene3d_draw_fixed_span_done

    cmp cx, [scene3d_clip_left]
    jge scene3d_draw_fixed_span_left_ready
    mov cx, [scene3d_clip_left]

scene3d_draw_fixed_span_left_ready:
    cmp si, [scene3d_clip_right]
    jle scene3d_draw_fixed_span_right_ready
    mov si, [scene3d_clip_right]

scene3d_draw_fixed_span_right_ready:
    mov bx, cx
    call compute_offset
    mov ax, cx
    cmp byte ptr [scene3d_temp_texture], SCENE3D_TEXTURE_NONE
    je scene3d_draw_fixed_span_loop

    xor bx, bx
    mov bl, [scene3d_temp_texture]
    mov cx, TEXTURE_BANK_SEG
    test bl, SCENE3D_TEXTURE_PAGE_B_BIT
    jz scene3d_draw_fixed_span_texture_page_ready
    mov cx, TEXTURE_BANK_B_SEG

scene3d_draw_fixed_span_texture_page_ready:
    mov ds, cx
    and bx, TEXTURE_ATLAS_TILE_INDEX_MASK
    mov cx, bx
    and bx, TEXTURE_ATLAS_TILE_COL_MASK
    shl bx, 5
    mov bp, bx
    mov bx, cx
    shr bx, TEXTURE_ATLAS_TILE_ROW_SHIFT
    shl bx, TEXTURE_ATLAS_TILE_OFFSET_SHIFT
    add bp, bx
    jmp scene3d_draw_textured_fixed_span_loop

scene3d_draw_fixed_span_loop:
    cmp ax, si
    jg scene3d_draw_fixed_span_done
    mov bx, ax
    xor bx, dx
    test bl, 1
    jz scene3d_draw_fixed_span_base
    mov bl, [scene3d_temp_dither]
    jmp scene3d_draw_fixed_span_color_ready

scene3d_draw_fixed_span_base:
    mov bl, [scene3d_temp_color]

scene3d_draw_fixed_span_color_ready:
    mov es:[di], bl
    inc di
    inc ax
    jmp scene3d_draw_fixed_span_loop

scene3d_draw_textured_fixed_span_loop:
    cmp ax, si
    jg scene3d_draw_fixed_span_done
    mov bl, dl
    and bl, 31
    xor bh, bh
    shl bx, TEXTURE_ATLAS_TEXEL_ROW_SHIFT
    mov cl, al
    and cl, 31
    xor ch, ch
    add bx, cx
    add bx, bp
    mov bl, ds:[bx]
    test bl, bl
    jnz scene3d_draw_textured_fixed_span_ready
    mov bl, cs:[scene3d_temp_color]

scene3d_draw_textured_fixed_span_ready:
    mov es:[di], bl
    inc di
    inc ax
    jmp scene3d_draw_textured_fixed_span_loop

scene3d_draw_fixed_span_done:
    pop ds
    pop bp
    pop di
    pop si
    pop dx
    pop cx
    pop bx
    pop ax
    ret

scene3d_sort_triangle_vertices:
    mov ax, [scene3d_tri_y0]
    cmp ax, [scene3d_tri_y1]
    jle scene3d_sort_triangle_y1_ready
    call scene3d_swap_v0_v1

scene3d_sort_triangle_y1_ready:
    mov ax, [scene3d_tri_y1]
    cmp ax, [scene3d_tri_y2]
    jle scene3d_sort_triangle_y2_ready
    call scene3d_swap_v1_v2

scene3d_sort_triangle_y2_ready:
    mov ax, [scene3d_tri_y0]
    cmp ax, [scene3d_tri_y1]
    jle scene3d_sort_triangle_done
    call scene3d_swap_v0_v1

scene3d_sort_triangle_done:
    ret

scene3d_swap_v0_v1:
    mov ax, [scene3d_tri_x0]
    xchg ax, [scene3d_tri_x1]
    mov [scene3d_tri_x0], ax
    mov ax, [scene3d_tri_y0]
    xchg ax, [scene3d_tri_y1]
    mov [scene3d_tri_y0], ax
    ret

scene3d_swap_v1_v2:
    mov ax, [scene3d_tri_x1]
    xchg ax, [scene3d_tri_x2]
    mov [scene3d_tri_x1], ax
    mov ax, [scene3d_tri_y1]
    xchg ax, [scene3d_tri_y2]
    mov [scene3d_tri_y1], ax
    ret

scene3d_prepare_face_texture:
    push ax
    push bx
    push cx
    push dx
    push di

    mov di, [scene3d_vertex_source]
    xor ax, ax
    mov al, [si]
    mov bl, SCENE3D_VERTEX_BYTES
    mul bl
    add di, ax
    mov ax, [di]
    mov [scene3d_temp_x], ax
    mov ax, [di + 2]
    mov [scene3d_temp_y], ax
    mov ax, [di + 4]
    mov [scene3d_temp_z], ax

    mov di, [scene3d_vertex_source]
    xor ax, ax
    mov al, [si + 1]
    mov bl, SCENE3D_VERTEX_BYTES
    mul bl
    add di, ax
    mov ax, [di]
    mov [scene3d_temp_u], ax
    mov ax, [di + 2]
    mov [scene3d_temp_v], ax
    mov ax, [di + 4]
    mov [scene3d_temp_w], ax

    mov di, [scene3d_vertex_source]
    xor ax, ax
    mov al, [si + 2]
    mov bl, SCENE3D_VERTEX_BYTES
    mul bl
    add di, ax
    mov ax, [di]
    mov [scene3d_temp_l], ax
    mov ax, [di + 2]
    mov [scene3d_temp_r], ax
    mov ax, [di + 4]
    mov [scene3d_temp_s], ax

    mov ax, [scene3d_temp_x]
    mov bx, ax
    mov dx, [scene3d_temp_u]
    cmp dx, ax
    jge scene3d_tex_x_min_ready_1
    mov ax, dx
scene3d_tex_x_min_ready_1:
    cmp dx, bx
    jle scene3d_tex_x_max_ready_1
    mov bx, dx
scene3d_tex_x_max_ready_1:
    mov dx, [scene3d_temp_l]
    cmp dx, ax
    jge scene3d_tex_x_min_ready_2
    mov ax, dx
scene3d_tex_x_min_ready_2:
    cmp dx, bx
    jle scene3d_tex_x_max_ready_2
    mov bx, dx
scene3d_tex_x_max_ready_2:
    sub bx, ax

    mov ax, [scene3d_temp_y]
    mov cx, ax
    mov dx, [scene3d_temp_v]
    cmp dx, ax
    jge scene3d_tex_y_min_ready_1
    mov ax, dx
scene3d_tex_y_min_ready_1:
    cmp dx, cx
    jle scene3d_tex_y_max_ready_1
    mov cx, dx
scene3d_tex_y_max_ready_1:
    mov dx, [scene3d_temp_r]
    cmp dx, ax
    jge scene3d_tex_y_min_ready_2
    mov ax, dx
scene3d_tex_y_min_ready_2:
    cmp dx, cx
    jle scene3d_tex_y_max_ready_2
    mov cx, dx
scene3d_tex_y_max_ready_2:
    sub cx, ax

    mov ax, [scene3d_temp_z]
    mov dx, ax
    mov di, [scene3d_temp_w]
    cmp di, ax
    jge scene3d_tex_z_min_ready_1
    mov ax, di
scene3d_tex_z_min_ready_1:
    cmp di, dx
    jle scene3d_tex_z_max_ready_1
    mov dx, di
scene3d_tex_z_max_ready_1:
    mov di, [scene3d_temp_s]
    cmp di, ax
    jge scene3d_tex_z_min_ready_2
    mov ax, di
scene3d_tex_z_min_ready_2:
    cmp di, dx
    jle scene3d_tex_z_max_ready_2
    mov dx, di
scene3d_tex_z_max_ready_2:
    sub dx, ax

    mov ax, cx
    cmp ax, bx
    jg scene3d_prepare_texture_not_xz
    cmp ax, dx
    jg scene3d_prepare_texture_not_xz
    jmp scene3d_prepare_texture_xz

scene3d_prepare_texture_not_xz:
    mov ax, bx
    cmp ax, dx
    jg scene3d_prepare_texture_xy

scene3d_prepare_texture_zy:
    mov ax, [scene3d_temp_z]
    call scene3d_coord_to_tex_fixed
    mov [scene3d_tri_u0], ax
    mov ax, [scene3d_temp_y]
    call scene3d_coord_to_tex_fixed
    mov [scene3d_tri_v0], ax

    mov ax, [scene3d_temp_w]
    sub ax, [scene3d_temp_z]
    shl ax, 1
    shl ax, 1
    shl ax, 1
    shl ax, 1
    shl ax, 1
    add ax, [scene3d_tri_u0]
    mov [scene3d_tri_u1], ax
    mov ax, [scene3d_temp_v]
    sub ax, [scene3d_temp_y]
    shl ax, 1
    shl ax, 1
    shl ax, 1
    shl ax, 1
    shl ax, 1
    add ax, [scene3d_tri_v0]
    mov [scene3d_tri_v1], ax

    mov ax, [scene3d_temp_s]
    sub ax, [scene3d_temp_z]
    shl ax, 1
    shl ax, 1
    shl ax, 1
    shl ax, 1
    shl ax, 1
    add ax, [scene3d_tri_u0]
    mov [scene3d_tri_u2], ax
    mov ax, [scene3d_temp_r]
    sub ax, [scene3d_temp_y]
    shl ax, 1
    shl ax, 1
    shl ax, 1
    shl ax, 1
    shl ax, 1
    add ax, [scene3d_tri_v0]
    mov [scene3d_tri_v2], ax
    jmp scene3d_prepare_face_texture_done

scene3d_prepare_texture_xy:
    mov ax, [scene3d_temp_x]
    call scene3d_coord_to_tex_fixed
    mov [scene3d_tri_u0], ax
    mov ax, [scene3d_temp_y]
    call scene3d_coord_to_tex_fixed
    mov [scene3d_tri_v0], ax

    mov ax, [scene3d_temp_u]
    sub ax, [scene3d_temp_x]
    shl ax, 1
    shl ax, 1
    shl ax, 1
    shl ax, 1
    shl ax, 1
    add ax, [scene3d_tri_u0]
    mov [scene3d_tri_u1], ax
    mov ax, [scene3d_temp_v]
    sub ax, [scene3d_temp_y]
    shl ax, 1
    shl ax, 1
    shl ax, 1
    shl ax, 1
    shl ax, 1
    add ax, [scene3d_tri_v0]
    mov [scene3d_tri_v1], ax

    mov ax, [scene3d_temp_l]
    sub ax, [scene3d_temp_x]
    shl ax, 1
    shl ax, 1
    shl ax, 1
    shl ax, 1
    shl ax, 1
    add ax, [scene3d_tri_u0]
    mov [scene3d_tri_u2], ax
    mov ax, [scene3d_temp_r]
    sub ax, [scene3d_temp_y]
    shl ax, 1
    shl ax, 1
    shl ax, 1
    shl ax, 1
    shl ax, 1
    add ax, [scene3d_tri_v0]
    mov [scene3d_tri_v2], ax
    jmp scene3d_prepare_face_texture_done

scene3d_prepare_texture_xz:
    mov ax, [scene3d_temp_x]
    call scene3d_coord_to_tex_fixed
    mov [scene3d_tri_u0], ax
    mov ax, [scene3d_temp_z]
    call scene3d_coord_to_tex_fixed
    mov [scene3d_tri_v0], ax

    mov ax, [scene3d_temp_u]
    sub ax, [scene3d_temp_x]
    shl ax, 1
    shl ax, 1
    shl ax, 1
    shl ax, 1
    shl ax, 1
    add ax, [scene3d_tri_u0]
    mov [scene3d_tri_u1], ax
    mov ax, [scene3d_temp_w]
    sub ax, [scene3d_temp_z]
    shl ax, 1
    shl ax, 1
    shl ax, 1
    shl ax, 1
    shl ax, 1
    add ax, [scene3d_tri_v0]
    mov [scene3d_tri_v1], ax

    mov ax, [scene3d_temp_l]
    sub ax, [scene3d_temp_x]
    shl ax, 1
    shl ax, 1
    shl ax, 1
    shl ax, 1
    shl ax, 1
    add ax, [scene3d_tri_u0]
    mov [scene3d_tri_u2], ax
    mov ax, [scene3d_temp_s]
    sub ax, [scene3d_temp_z]
    shl ax, 1
    shl ax, 1
    shl ax, 1
    shl ax, 1
    shl ax, 1
    add ax, [scene3d_tri_v0]
    mov [scene3d_tri_v2], ax

scene3d_prepare_face_texture_done:
    pop di
    pop dx
    pop cx
    pop bx
    pop ax
    ret

scene3d_coord_to_tex_fixed:
    sar ax, 1
    sar ax, 1
    sar ax, 1
    and ax, 31
    xchg al, ah
    ret

scene3d_draw_textured_triangle:
    call scene3d_sort_triangle_vertices_uv

    mov ax, [scene3d_tri_y2]
    cmp ax, [scene3d_tri_y0]
    je scene3d_draw_textured_triangle_done

    mov ax, [scene3d_tri_x2]
    sub ax, [scene3d_tri_x0]
    mov bx, [scene3d_tri_y2]
    sub bx, [scene3d_tri_y0]
    call scene3d_compute_fixed_step
    mov [scene3d_text_step_long_x], ax

    mov ax, [scene3d_tri_u2]
    sub ax, [scene3d_tri_u0]
    mov bx, [scene3d_tri_y2]
    sub bx, [scene3d_tri_y0]
    call scene3d_compute_step_88
    mov [scene3d_text_step_long_u], ax

    mov ax, [scene3d_tri_v2]
    sub ax, [scene3d_tri_v0]
    mov bx, [scene3d_tri_y2]
    sub bx, [scene3d_tri_y0]
    call scene3d_compute_step_88
    mov [scene3d_text_step_long_v], ax

    mov ax, [scene3d_tri_x0]
    shl ax, 1
    shl ax, 1
    shl ax, 1
    shl ax, 1
    mov [scene3d_text_left_x], ax
    mov ax, [scene3d_tri_u0]
    mov [scene3d_text_left_u], ax
    mov ax, [scene3d_tri_v0]
    mov [scene3d_text_left_v], ax

    mov cx, [scene3d_tri_y1]
    sub cx, [scene3d_tri_y0]
    jle scene3d_textured_triangle_lower_setup

    mov ax, [scene3d_tri_x1]
    sub ax, [scene3d_tri_x0]
    mov bx, cx
    call scene3d_compute_fixed_step
    mov [scene3d_text_step_short_x], ax

    mov ax, [scene3d_tri_u1]
    sub ax, [scene3d_tri_u0]
    mov bx, cx
    call scene3d_compute_step_88
    mov [scene3d_text_step_short_u], ax

    mov ax, [scene3d_tri_v1]
    sub ax, [scene3d_tri_v0]
    mov bx, cx
    call scene3d_compute_step_88
    mov [scene3d_text_step_short_v], ax

    mov ax, [scene3d_tri_x0]
    shl ax, 1
    shl ax, 1
    shl ax, 1
    shl ax, 1
    mov [scene3d_text_right_x], ax
    mov ax, [scene3d_tri_u0]
    mov [scene3d_text_right_u], ax
    mov ax, [scene3d_tri_v0]
    mov [scene3d_text_right_v], ax

    mov dx, [scene3d_tri_y0]

scene3d_textured_triangle_upper_loop:
    cmp dx, [scene3d_tri_y1]
    jge scene3d_textured_triangle_lower_setup
    call scene3d_draw_textured_span
    mov ax, [scene3d_text_left_x]
    add ax, [scene3d_text_step_long_x]
    mov [scene3d_text_left_x], ax
    mov ax, [scene3d_text_left_u]
    add ax, [scene3d_text_step_long_u]
    mov [scene3d_text_left_u], ax
    mov ax, [scene3d_text_left_v]
    add ax, [scene3d_text_step_long_v]
    mov [scene3d_text_left_v], ax
    mov ax, [scene3d_text_right_x]
    add ax, [scene3d_text_step_short_x]
    mov [scene3d_text_right_x], ax
    mov ax, [scene3d_text_right_u]
    add ax, [scene3d_text_step_short_u]
    mov [scene3d_text_right_u], ax
    mov ax, [scene3d_text_right_v]
    add ax, [scene3d_text_step_short_v]
    mov [scene3d_text_right_v], ax
    inc dx
    jmp scene3d_textured_triangle_upper_loop

scene3d_textured_triangle_lower_setup:
    mov cx, [scene3d_tri_y2]
    sub cx, [scene3d_tri_y1]
    jle scene3d_draw_textured_triangle_done

    mov ax, [scene3d_tri_x2]
    sub ax, [scene3d_tri_x1]
    mov bx, cx
    call scene3d_compute_fixed_step
    mov [scene3d_text_step_short_x], ax

    mov ax, [scene3d_tri_u2]
    sub ax, [scene3d_tri_u1]
    mov bx, cx
    call scene3d_compute_step_88
    mov [scene3d_text_step_short_u], ax

    mov ax, [scene3d_tri_v2]
    sub ax, [scene3d_tri_v1]
    mov bx, cx
    call scene3d_compute_step_88
    mov [scene3d_text_step_short_v], ax

    mov ax, [scene3d_tri_x1]
    shl ax, 1
    shl ax, 1
    shl ax, 1
    shl ax, 1
    mov [scene3d_text_right_x], ax
    mov ax, [scene3d_tri_u1]
    mov [scene3d_text_right_u], ax
    mov ax, [scene3d_tri_v1]
    mov [scene3d_text_right_v], ax

    mov dx, [scene3d_tri_y1]

scene3d_textured_triangle_lower_loop:
    cmp dx, [scene3d_tri_y2]
    jg scene3d_draw_textured_triangle_done
    call scene3d_draw_textured_span
    mov ax, [scene3d_text_left_x]
    add ax, [scene3d_text_step_long_x]
    mov [scene3d_text_left_x], ax
    mov ax, [scene3d_text_left_u]
    add ax, [scene3d_text_step_long_u]
    mov [scene3d_text_left_u], ax
    mov ax, [scene3d_text_left_v]
    add ax, [scene3d_text_step_long_v]
    mov [scene3d_text_left_v], ax
    mov ax, [scene3d_text_right_x]
    add ax, [scene3d_text_step_short_x]
    mov [scene3d_text_right_x], ax
    mov ax, [scene3d_text_right_u]
    add ax, [scene3d_text_step_short_u]
    mov [scene3d_text_right_u], ax
    mov ax, [scene3d_text_right_v]
    add ax, [scene3d_text_step_short_v]
    mov [scene3d_text_right_v], ax
    inc dx
    jmp scene3d_textured_triangle_lower_loop

scene3d_draw_textured_triangle_done:
    ret

scene3d_draw_textured_span:
    push ax
    push bx
    push cx
    push dx
    push si
    push di
    push bp
    push ds

    cmp dx, [scene3d_clip_top]
    jl scene3d_draw_textured_span_done
    cmp dx, [scene3d_clip_bottom]
    jg scene3d_draw_textured_span_done
    mov [scene3d_temp_x], dx

    mov ax, [scene3d_text_left_x]
    mov bx, [scene3d_text_right_x]
    sar ax, 1
    sar ax, 1
    sar ax, 1
    sar ax, 1
    sar bx, 1
    sar bx, 1
    sar bx, 1
    sar bx, 1

    mov [scene3d_temp_u], ax
    mov ax, [scene3d_text_left_u]
    mov [scene3d_temp_v], ax
    mov ax, [scene3d_text_left_v]
    mov [scene3d_temp_w], ax
    mov ax, [scene3d_text_right_u]
    mov [scene3d_temp_r], ax
    mov ax, [scene3d_text_right_v]
    mov [scene3d_temp_s], ax

    mov ax, [scene3d_temp_u]
    cmp ax, bx
    jle scene3d_draw_textured_span_ordered
    xchg ax, bx
    mov [scene3d_temp_u], ax
    mov cx, [scene3d_temp_v]
    xchg cx, [scene3d_temp_r]
    mov [scene3d_temp_v], cx
    mov cx, [scene3d_temp_w]
    xchg cx, [scene3d_temp_s]
    mov [scene3d_temp_w], cx

scene3d_draw_textured_span_ordered:
    mov [scene3d_temp_l], bx
    cmp ax, [scene3d_clip_right]
    jg scene3d_draw_textured_span_done
    cmp bx, [scene3d_clip_left]
    jl scene3d_draw_textured_span_done

    mov cx, [scene3d_temp_l]
    sub cx, ax
    jle scene3d_draw_textured_span_single

    mov ax, [scene3d_temp_r]
    sub ax, [scene3d_temp_v]
    mov bx, cx
    call scene3d_compute_step_88
    mov [scene3d_temp_r], ax

    mov ax, [scene3d_temp_s]
    sub ax, [scene3d_temp_w]
    mov bx, cx
    call scene3d_compute_step_88
    mov [scene3d_temp_s], ax
    jmp scene3d_draw_textured_span_clip

scene3d_draw_textured_span_single:
    mov word ptr [scene3d_temp_r], 0
    mov word ptr [scene3d_temp_s], 0

scene3d_draw_textured_span_clip:
    mov bx, [scene3d_temp_l]
    mov ax, [scene3d_temp_u]
    cmp ax, [scene3d_clip_left]
    jge scene3d_draw_textured_span_left_ready
    mov bx, [scene3d_clip_left]
    sub bx, ax
    mov ax, [scene3d_temp_r]
    imul bx
    add [scene3d_temp_v], ax
    mov ax, [scene3d_temp_s]
    imul bx
    add [scene3d_temp_w], ax
    mov ax, [scene3d_clip_left]
    mov [scene3d_temp_u], ax

scene3d_draw_textured_span_left_ready:
    mov ax, bx
    cmp ax, [scene3d_clip_right]
    jle scene3d_draw_textured_span_right_ready
    mov bx, [scene3d_clip_right]

scene3d_draw_textured_span_right_ready:
    mov ax, [scene3d_temp_u]
    cmp ax, bx
    jg scene3d_draw_textured_span_done

    push bx
    mov bx, ax
    mov dx, [scene3d_temp_x]
    call compute_offset
    pop bp

    xor ax, ax
    mov al, [scene3d_temp_texture]
    mov bx, ax
    mov dx, TEXTURE_BANK_SEG
    test bl, SCENE3D_TEXTURE_PAGE_B_BIT
    jz scene3d_draw_textured_span_texture_page_ready
    mov dx, TEXTURE_BANK_B_SEG

scene3d_draw_textured_span_texture_page_ready:
    mov ds, dx
    and bx, TEXTURE_ATLAS_TILE_INDEX_MASK
    mov ax, bx
    and ax, TEXTURE_ATLAS_TILE_COL_MASK
    shl ax, 5
    mov [scene3d_temp_l], ax
    mov ax, bx
    shr ax, TEXTURE_ATLAS_TILE_ROW_SHIFT
    shl ax, TEXTURE_ATLAS_TILE_OFFSET_SHIFT
    add [scene3d_temp_l], ax

    mov si, [scene3d_temp_u]
    mov dx, [scene3d_temp_v]
    mov cx, [scene3d_temp_w]

scene3d_draw_textured_span_loop:
    mov al, ch
    and al, 31
    xor ah, ah
    mov bl, al
    xor bh, bh
    shl bx, TEXTURE_ATLAS_TEXEL_ROW_SHIFT
    mov al, dh
    and al, 31
    xor ah, ah
    add bx, ax
    add bx, cs:[scene3d_temp_l]
    mov al, ds:[bx]
    test al, al
    jnz scene3d_draw_textured_span_color_ready
    mov al, cs:[scene3d_temp_color]

scene3d_draw_textured_span_color_ready:
    cmp byte ptr cs:[scene3d_temp_fog], 0
    je scene3d_draw_textured_span_store
    mov bx, si
    xor bl, byte ptr cs:[scene3d_temp_x]
    cmp byte ptr cs:[scene3d_temp_fog], 2
    je scene3d_draw_textured_span_far_fog
    test bl, 3
    jne scene3d_draw_textured_span_store
    mov al, cs:[scene3d_temp_dither]
    jmp scene3d_draw_textured_span_store

scene3d_draw_textured_span_far_fog:
    test bl, 1
    jnz scene3d_draw_textured_span_far_base
    mov al, cs:[scene3d_temp_dither]
    jmp scene3d_draw_textured_span_store

scene3d_draw_textured_span_far_base:
    mov al, cs:[scene3d_temp_color]

scene3d_draw_textured_span_store:
    mov es:[di], al
    inc di
    inc si
    mov ax, dx
    add ax, cs:[scene3d_temp_r]
    mov dx, ax
    mov ax, cx
    add ax, cs:[scene3d_temp_s]
    mov cx, ax
    cmp si, bp
    jle scene3d_draw_textured_span_loop

scene3d_draw_textured_span_done:
    pop ds
    pop bp
    pop di
    pop si
    pop dx
    pop cx
    pop bx
    pop ax
    ret

scene3d_compute_step_88:
    or bx, bx
    jnz scene3d_compute_step_88_do
    xor ax, ax
    ret

scene3d_compute_step_88_do:
    cwd
    idiv bx
    ret

scene3d_sort_triangle_vertices_uv:
    mov ax, [scene3d_tri_y0]
    cmp ax, [scene3d_tri_y1]
    jle scene3d_sort_triangle_uv_y1_ready
    call scene3d_swap_v0_v1_uv

scene3d_sort_triangle_uv_y1_ready:
    mov ax, [scene3d_tri_y1]
    cmp ax, [scene3d_tri_y2]
    jle scene3d_sort_triangle_uv_y2_ready
    call scene3d_swap_v1_v2_uv

scene3d_sort_triangle_uv_y2_ready:
    mov ax, [scene3d_tri_y0]
    cmp ax, [scene3d_tri_y1]
    jle scene3d_sort_triangle_vertices_uv_done
    call scene3d_swap_v0_v1_uv

scene3d_sort_triangle_vertices_uv_done:
    ret

scene3d_swap_v0_v1_uv:
    mov ax, [scene3d_tri_x0]
    xchg ax, [scene3d_tri_x1]
    mov [scene3d_tri_x0], ax
    mov ax, [scene3d_tri_y0]
    xchg ax, [scene3d_tri_y1]
    mov [scene3d_tri_y0], ax
    mov ax, [scene3d_tri_u0]
    xchg ax, [scene3d_tri_u1]
    mov [scene3d_tri_u0], ax
    mov ax, [scene3d_tri_v0]
    xchg ax, [scene3d_tri_v1]
    mov [scene3d_tri_v0], ax
    ret

scene3d_swap_v1_v2_uv:
    mov ax, [scene3d_tri_x1]
    xchg ax, [scene3d_tri_x2]
    mov [scene3d_tri_x1], ax
    mov ax, [scene3d_tri_y1]
    xchg ax, [scene3d_tri_y2]
    mov [scene3d_tri_y1], ax
    mov ax, [scene3d_tri_u1]
    xchg ax, [scene3d_tri_u2]
    mov [scene3d_tri_u1], ax
    mov ax, [scene3d_tri_v1]
    xchg ax, [scene3d_tri_v2]
    mov [scene3d_tri_v1], ax
    ret
