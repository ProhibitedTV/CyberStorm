draw_text_small:
    mov [text_cursor_x], bx
    mov [text_cursor_y], dx
    mov [text_color], ah

draw_text_small_loop:
    lodsb
    or al, al
    jz draw_text_small_done
    cmp al, ' '
    je draw_text_small_space
    push si
    mov bx, [text_cursor_x]
    mov dx, [text_cursor_y]
    mov ah, [text_color]
    call draw_char_1x
    pop si

draw_text_small_space:
    add word ptr [text_cursor_x], 6
    jmp draw_text_small_loop

draw_text_small_done:
    ret

draw_text_big:
    mov [text_cursor_x], bx
    mov [text_cursor_y], dx
    mov [text_color], ah

draw_text_big_loop:
    lodsb
    or al, al
    jz draw_text_big_done
    cmp al, ' '
    je draw_text_big_space
    push si
    mov bx, [text_cursor_x]
    mov dx, [text_cursor_y]
    mov ah, [text_color]
    call draw_char_2x
    pop si

draw_text_big_space:
    add word ptr [text_cursor_x], 12
    jmp draw_text_big_loop

draw_text_big_done:
    ret

draw_digit_small:
    add al, '0'
    call draw_char_1x
    ret

draw_two_digit_small:
    mov [text_color], ah
    aam
    add ax, 3030h
    push ax
    mov al, ah
    mov ah, [text_color]
    call draw_char_1x
    pop ax
    add bx, 6
    mov ah, [text_color]
    call draw_char_1x
    ret

draw_char_1x:
    push ax
    push bx
    push cx
    push dx
    push si
    push di
    push bp
    mov [text_color], ah
    mov [glyph_base_x], bx
    mov [glyph_base_y], dx
    call get_glyph_ptr
    xor bp, bp

draw_char_1x_row:
    cmp bp, 7
    jae draw_char_1x_done
    mov al, [si]
    inc si
    mov [glyph_row_bits], al
    mov bx, [glyph_base_x]
    mov dx, [glyph_base_y]
    add dx, bp
    call compute_offset
    mov al, [glyph_row_bits]
    mov ah, [text_color]
    mov cx, 5

draw_char_1x_col:
    test al, 10h
    jz draw_char_1x_skip
    mov es:[di], ah
draw_char_1x_skip:
    inc di
    shl al, 1
    loop draw_char_1x_col
    inc bp
    jmp draw_char_1x_row

draw_char_1x_done:
    pop bp
    pop di
    pop si
    pop dx
    pop cx
    pop bx
    pop ax
    ret

draw_char_2x:
    push ax
    push bx
    push cx
    push dx
    push si
    push di
    push bp
    mov [text_color], ah
    mov [glyph_base_x], bx
    mov [glyph_base_y], dx
    call get_glyph_ptr
    xor bp, bp

draw_char_2x_row:
    cmp bp, 7
    jae draw_char_2x_done
    mov al, [si]
    inc si
    mov [glyph_row_bits], al
    xor di, di

draw_char_2x_col:
    cmp di, 5
    jae draw_char_2x_next_row
    mov al, [glyph_row_bits]
    test al, 10h
    jz draw_char_2x_skip
    push bp
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
    pop bp

draw_char_2x_skip:
    shl byte ptr [glyph_row_bits], 1
    inc di
    jmp draw_char_2x_col

draw_char_2x_next_row:
    inc bp
    jmp draw_char_2x_row

draw_char_2x_done:
    pop bp
    pop di
    pop si
    pop dx
    pop cx
    pop bx
    pop ax
    ret

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

get_glyph_ptr:
    cmp al, 'A'
    jb glyph_check_digit
    cmp al, 'Z'
    ja glyph_check_digit
    sub al, 'A'
    jmp glyph_index_ready

glyph_check_digit:
    cmp al, '0'
    jb glyph_check_period
    cmp al, '9'
    ja glyph_check_period
    sub al, '0'
    add al, 26
    jmp glyph_index_ready

glyph_check_period:
    cmp al, '.'
    jne glyph_space
    mov al, 36
    jmp glyph_index_ready

glyph_space:
    mov al, 37

glyph_index_ready:
    xor ah, ah
    mov si, ax
    shl ax, 3
    sub ax, si
    mov si, ax
    add si, offset font5x7
    ret

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
