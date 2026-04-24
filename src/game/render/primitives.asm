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
    cmp dx, GAMEPLAY_BACKBUFFER_SPLIT_Y
    jae fill_rect_reference
    mov ax, dx
    add ax, bp
    cmp ax, GAMEPLAY_BACKBUFFER_SPLIT_Y
    ja fill_rect_reference
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

fill_rect_row:
    or bp, bp
    jz fill_rect_done
    call compute_offset
    mov cx, si
    rep stosb
    inc dx
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

get_backbuffer_row_ptr:
    push bx
    push cx
    mov ax, BACKBUFFER_SEG
    mov cx, dx
    cmp cx, GAMEPLAY_BACKBUFFER_SPLIT_Y
    jb get_backbuffer_row_ptr_ready
    mov ax, BACKBUFFER_HIGH_SEG
    sub cx, GAMEPLAY_BACKBUFFER_SPLIT_Y

get_backbuffer_row_ptr_ready:
    mov di, cx
    shl di, 6
    mov bx, cx
    shl bx, 8
    add di, bx
    pop cx
    pop bx
    ret

get_backbuffer_row_dssi:
    push bx
    mov ax, BACKBUFFER_SEG
    mov si, dx
    cmp si, GAMEPLAY_BACKBUFFER_SPLIT_Y
    jb get_backbuffer_row_dssi_ready
    mov ax, BACKBUFFER_HIGH_SEG
    sub si, GAMEPLAY_BACKBUFFER_SPLIT_Y

get_backbuffer_row_dssi_ready:
    mov bx, si
    shl si, 6
    shl bx, 8
    add si, bx
    mov ds, ax
    pop bx
    ret

compute_offset:
    ; Map (bx, dx) onto the active gameplay-aware backbuffer row and select the
    ; correct backing segment before returning ES:DI.
    push ax
    call get_backbuffer_row_ptr
    mov es, ax
    add di, bx
    pop ax
    ret
