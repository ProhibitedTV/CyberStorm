draw_rect_outline:
    push ax
    push bx
    push cx
    push dx
    push bp
    mov [rect_w], cx
    mov [rect_h], bp

    push bx
    push dx
    mov bp, 1
    mov cx, [rect_w]
    call fill_rect
    pop dx
    pop bx

    push bx
    push dx
    add dx, [rect_h]
    dec dx
    mov bp, 1
    mov cx, [rect_w]
    call fill_rect
    pop dx
    pop bx

    push bx
    push dx
    mov cx, 1
    mov bp, [rect_h]
    call fill_rect
    pop dx
    pop bx

    add bx, [rect_w]
    dec bx
    mov cx, 1
    mov bp, [rect_h]
    call fill_rect
    pop bp
    pop dx
    pop cx
    pop bx
    pop ax
    ret

fill_rect:
    cmp byte ptr [machine_kernel_active], 0
    je fill_rect_reference
    push ax
    push bx
    push cx
    push dx
    push si
    push di
    push bp
    mov word ptr [machine_kernel_param_block + 0], bx
    mov word ptr [machine_kernel_param_block + 2], dx
    mov word ptr [machine_kernel_param_block + 4], cx
    mov word ptr [machine_kernel_param_block + 6], bp
    mov [machine_kernel_param_block + 8], al
    lea si, machine_kernel_param_block
    mov ax, MC_KERNEL_SHADOW_DECAL_BLIT_OFFSET
    call machine_call_far_kernel
    pop bp
    pop di
    pop si
    pop dx
    pop cx
    pop bx
    pop ax
    ret

fill_rect_reference:
    push ax
    push bx
    push cx
    push dx
    push si
    push di
    push bp
    mov si, cx
    call compute_offset

fill_rect_row:
    or bp, bp
    jz fill_rect_done
    push di
    mov cx, si
    rep stosb
    pop di
    add di, SCREEN_W
    sub di, si
    dec bp
    jmp fill_rect_row

fill_rect_done:
    pop bp
    pop di
    pop si
    pop dx
    pop cx
    pop bx
    pop ax
    ret

put_pixel:
    push bx
    push dx
    push di
    call compute_offset
    mov es:[di], al
    pop di
    pop dx
    pop bx
    ret

compute_offset:
    ; Map (bx, dx) onto the current linear framebuffer selected in ES.
    push ax
    mov ax, dx
    shl ax, 6
    mov di, ax
    mov ax, dx
    shl ax, 8
    add di, ax
    add di, bx
    pop ax
    ret
