draw_sprite8:
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

draw_sprite_row:
    cmp bp, 8
    jae draw_sprite_done
    mov bx, [glyph_base_x]
    mov dx, [glyph_base_y]
    add dx, bp
    call compute_offset
    mov cx, 8

draw_sprite_col:
    lodsb
    or al, al
    jz draw_sprite_skip
    mov es:[di], al
draw_sprite_skip:
    inc di
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

draw_bitmap8:
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

draw_bitmap8_row:
    cmp bp, 8
    jae draw_bitmap8_done
    mov bx, [glyph_base_x]
    mov dx, [glyph_base_y]
    add dx, bp
    call compute_offset
    mov cx, 8
    rep movsb
    inc bp
    jmp draw_bitmap8_row

draw_bitmap8_done:
    pop bp
    pop di
    pop si
    pop dx
    pop cx
    pop bx
    pop ax
    ret

draw_sprite16_2x:
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

draw_sprite16_2x_row:
    cmp bp, 16
    jae draw_sprite16_2x_done
    xor di, di

draw_sprite16_2x_col:
    cmp di, 16
    jae draw_sprite16_2x_next_row
    lodsb
    or al, al
    jz draw_sprite16_2x_skip
    mov [text_color], al
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
    mov al, [text_color]
    call fill_rect
    pop di
    pop bp

draw_sprite16_2x_skip:
    inc di
    jmp draw_sprite16_2x_col

draw_sprite16_2x_next_row:
    inc bp
    jmp draw_sprite16_2x_row

draw_sprite16_2x_done:
    pop bp
    pop di
    pop si
    pop dx
    pop cx
    pop bx
    pop ax
    ret
