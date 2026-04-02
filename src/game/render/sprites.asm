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

draw_presentation_banner_2x:
    ; Banked scene banners are transparent 64x24 bitmaps scaled 2x at draw
    ; time so splash/title/end scenes can use richer art without spending more
    ; stage-two resident bytes on static presentation data.
    push ax
    push bx
    push cx
    push dx
    push si
    push di
    push bp
    push ds
    mov [glyph_base_x], bx
    mov [glyph_base_y], dx
    mov ax, PRESENT_BANK_SEG
    mov ds, ax
    xor bp, bp

draw_presentation_banner_row:
    cmp bp, PRESENT_BANNER_H
    jae draw_presentation_banner_done
    xor di, di

draw_presentation_banner_col:
    cmp di, PRESENT_BANNER_W
    jae draw_presentation_banner_next_row
    lodsb
    or al, al
    jz draw_presentation_banner_skip
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
    mov cx, PRESENT_BANNER_SCALE
    mov bp, PRESENT_BANNER_SCALE
    mov al, [text_color]
    call fill_rect
    pop di
    pop bp

draw_presentation_banner_skip:
    inc di
    jmp draw_presentation_banner_col

draw_presentation_banner_next_row:
    inc bp
    jmp draw_presentation_banner_row

draw_presentation_banner_done:
    pop ds
    pop bp
    pop di
    pop si
    pop dx
    pop cx
    pop bx
    pop ax
    ret
