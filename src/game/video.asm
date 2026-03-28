clear_backbuffer:
    push ax
    push cx
    push di
    xor di, di
    mov ax, PAL_BG0 + (PAL_BG0 shl 8)
    mov cx, 32000
    rep stosw
    pop di
    pop cx
    pop ax
    ret

draw_starfield:
    push ax
    push bx
    push cx
    push dx
    push si
    mov si, offset starfield
    mov cx, STAR_COUNT

draw_star_loop:
    mov bx, [si]
    mov dx, [si + 2]
    mov al, byte ptr [si + 4]
    call put_pixel
    add si, 6
    loop draw_star_loop
    pop si
    pop dx
    pop cx
    pop bx
    pop ax
    ret

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
    add di, 320
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

present_frame:
    push ax
    push cx
    push si
    push di
    push ds
    mov ax, BACKBUFFER_SEG
    mov ds, ax
    mov ax, VGA_SEG
    mov es, ax
    xor si, si
    xor di, di
    mov cx, 32000
    rep movsw
    pop ds
    pop di
    pop si
    pop cx
    pop ax
    ret
