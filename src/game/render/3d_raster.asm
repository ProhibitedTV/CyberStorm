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

scene3d_draw_fixed_span_done:
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
