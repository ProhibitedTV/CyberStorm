init_palette:
    push ax
    push cx
    push dx
    push si
    mov dx, 03C8h
    xor al, al
    out dx, al
    inc dx
    mov si, offset palette_data
    mov cx, PALETTE_BYTES

init_palette_loop:
    lodsb
    out dx, al
    loop init_palette_loop
    pop si
    pop dx
    pop cx
    pop ax
    ret
