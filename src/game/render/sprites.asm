draw_sprite8:
    push ax
    push bx
    push cx
    push dx
    push si
    push di
    push bp
    mov [text_color], al
    mov [glyph_base_x], bx
    mov [glyph_base_y], dx
    xor bp, bp

draw_sprite_row:
    cmp bp, 8
    jae draw_sprite_done
    mov al, [si]
    inc si
    mov [glyph_row_bits], al
    mov bx, [glyph_base_x]
    mov dx, [glyph_base_y]
    add dx, bp
    call compute_offset
    mov al, [glyph_row_bits]
    mov ah, [text_color]
    mov cx, 8

draw_sprite_col:
    test al, 80h
    jz draw_sprite_skip
    mov es:[di], ah
draw_sprite_skip:
    inc di
    shl al, 1
    loop draw_sprite_col
    inc bp
    jmp draw_sprite_row

draw_sprite_done:
    pop bp
    pop di
    pop si
    pop dx
    pop cx
    pop bx
    pop ax
    ret
