clear_backbuffer:
    push ax
    push cx
    push di
    push es
    mov ax, PAL_BG0 + (PAL_BG0 shl 8)
    push ax
    mov ax, BACKBUFFER_SEG
    mov es, ax
    pop ax
    xor di, di
    mov cx, SCREEN_WORDS
    rep stosw
    push ax
    mov ax, BACKBUFFER_HIGH_SEG
    mov es, ax
    pop ax
    xor di, di
    mov cx, GAMEPLAY_BACKBUFFER_HIGH_WORDS
    rep stosw
    pop es
    pop di
    pop cx
    pop ax
    ret

reset_legacy_vga_display_origin:
    push ax
    push dx

    ; VBox can occasionally preserve a non-zero VGA display start / panning
    ; origin across mode switches, which makes gameplay look horizontally
    ; wrapped like a bad tracking lock. Reassert a clean origin whenever we
    ; present through the legacy VGA path.
    mov dx, 03D4h
    mov al, 0Ch
    out dx, al
    inc dx
    xor al, al
    out dx, al
    dec dx
    mov al, 0Dh
    out dx, al
    inc dx
    xor al, al
    out dx, al

    mov dx, 03DAh
    in al, dx
    mov dx, 03C0h
    mov al, 13h
    out dx, al
    xor al, al
    out dx, al
    mov al, 20h
    out dx, al

    pop dx
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
    mov ah, [anim_phase]
    add ah, byte ptr [si]
    and ah, 03h
    jnz star_color_ready
    cmp al, PAL_WHITE
    je star_shift_cyan
    mov al, PAL_WHITE
    jmp star_color_ready

star_shift_cyan:
    mov al, PAL_CYAN2

star_color_ready:
    call put_pixel
    add si, 6
    loop draw_star_loop
    pop si
    pop dx
    pop cx
    pop bx
    pop ax
    ret

wait_for_vblank:
    push dx
    mov dx, 03DAh

wait_vblank_end:
    in al, dx
    test al, 08h
    jnz wait_vblank_end

wait_vblank_start:
    in al, dx
    test al, 08h
    jz wait_vblank_start
    pop dx
    ret

present_frame:
    cmp byte ptr [video_output_mode], ENHANCED_OUTPUT_MODE_VBE
    je present_frame_vbe
    cmp byte ptr [game_state], STATE_PLAYING
    je present_frame_gameplay_vga

    push ax
    push cx
    push si
    push di
    push ds
    call reset_legacy_vga_display_origin
    call wait_for_vblank
    mov ax, BACKBUFFER_SEG
    mov ds, ax
    mov ax, VGA_SEG
    mov es, ax
    xor si, si
    xor di, di
    mov cx, SCREEN_WORDS
    rep movsw
    pop ds
    pop di
    pop si
    pop cx
    pop ax
    ret

present_frame_gameplay_vga:
    push ax
    push cx
    push si
    push di
    push ds
    call build_gameplay_compat_surface
    call reset_legacy_vga_display_origin
    call wait_for_vblank
    mov ax, BACKBUFFER_COMPAT_SEG
    mov ds, ax
    mov ax, VGA_SEG
    mov es, ax
    xor si, si
    xor di, di
    mov cx, SCREEN_WORDS
    rep movsw

    pop ds
    pop di
    pop si
    pop cx
    pop ax
    ret
