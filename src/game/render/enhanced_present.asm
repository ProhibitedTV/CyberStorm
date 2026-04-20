.386p

init_video_output:
    push ax
    push bx
    push es

    mov byte ptr [video_output_mode], ENHANCED_OUTPUT_MODE_OFF
    mov word ptr [video_pitch], SCREEN_W
    mov word ptr [video_output_w], SCREEN_W
    mov word ptr [video_output_h], SCREEN_H
    mov dword ptr [video_lfb_addr], 0

    mov ax, BOOTSTRAP_SEG
    mov es, ax
    mov bx, ENHANCED_HANDOFF_OFFSET
    mov ax, word ptr es:[bx + ENHANCED_HANDOFF_SIG0_OFF]
    cmp ax, ENHANCED_HANDOFF_SIG0
    jne init_video_output_legacy
    mov ax, word ptr es:[bx + ENHANCED_HANDOFF_SIG1_OFF]
    cmp ax, ENHANCED_HANDOFF_SIG1
    jne init_video_output_legacy
    mov ax, word ptr es:[bx + ENHANCED_HANDOFF_FLAGS_OFF]
    test ax, ENHANCED_HANDOFF_FLAG_VBE
    jz init_video_output_legacy

    mov byte ptr [video_output_mode], ENHANCED_OUTPUT_MODE_VBE
    mov ax, word ptr es:[bx + ENHANCED_HANDOFF_PITCH_OFF]
    mov word ptr [video_pitch], ax
    mov ax, word ptr es:[bx + ENHANCED_HANDOFF_WIDTH_OFF]
    mov word ptr [video_output_w], ax
    mov ax, word ptr es:[bx + ENHANCED_HANDOFF_HEIGHT_OFF]
    mov word ptr [video_output_h], ax
    mov eax, dword ptr es:[bx + ENHANCED_HANDOFF_LFB_OFF]
    mov dword ptr [video_lfb_addr], eax
    jmp init_video_output_done

init_video_output_legacy:
    mov ax, 0013h
    int 10h

init_video_output_done:
    pop es
    pop bx
    pop ax
    ret

refresh_vbe_flat_fs:
    push ax
    push bx
    push ds
    cli
    push cs
    pop ds

    xor eax, eax
    mov ax, cs
    shl eax, 4
    mov word ptr [vbe_flat_gdt_code + 2], ax
    shr eax, 16
    mov byte ptr [vbe_flat_gdt_code + 4], al
    mov byte ptr [vbe_flat_gdt_code + 7], ah

    xor eax, eax
    mov ax, cs
    shl eax, 4
    add eax, OFFSET vbe_flat_gdt_start
    mov dword ptr [vbe_flat_gdt_descriptor + 2], eax

    lgdt fword ptr [vbe_flat_gdt_descriptor]
    mov eax, cr0
    or eax, 1
    mov cr0, eax
    push VBE_FLAT_CODE_SEL
    push OFFSET refresh_vbe_flat_fs_protected
    retf

refresh_vbe_flat_fs_protected:
    mov ax, VBE_FLAT_DATA_SEL
    mov fs, ax

    mov eax, cr0
    and eax, 0FFFFFFFEh
    mov cr0, eax
    push STAGE2_SEG
    push OFFSET refresh_vbe_flat_fs_real
    retf

refresh_vbe_flat_fs_real:
    sti
    pop ds
    pop bx
    pop ax
    ret

present_frame_vbe:
    push eax
    push ebx
    push ecx
    push edx
    push esi
    push edi
    push ds
    call refresh_vbe_flat_fs
    call wait_for_vblank
    mov ax, BACKBUFFER_SEG
    mov ds, ax
    xor ebx, ebx
    xor dx, dx
    mov edi, dword ptr [video_lfb_addr]
    mov cx, word ptr [video_output_h]

present_frame_vbe_row:
    push cx
    mov si, bx
    mov cx, SCREEN_W

present_frame_vbe_pixel:
    xor bx, bx
    mov bl, [si]
    inc si
    shl bx, 1
    mov ax, [palette_rgb565_table + bx]
    mov word ptr fs:[edi], ax
    mov word ptr fs:[edi + 2], ax
    add edi, 4
    loop present_frame_vbe_pixel

    movzx eax, word ptr [video_pitch]
    movzx ecx, word ptr [video_output_w]
    shl ecx, 1
    sub eax, ecx
    add edi, eax

    add dx, SCREEN_H
    cmp dx, word ptr [video_output_h]
    jb present_frame_vbe_same_source
    sub dx, word ptr [video_output_h]
    add bx, SCREEN_W

present_frame_vbe_same_source:
    pop cx
    loop present_frame_vbe_row

    pop ds
    pop edi
    pop esi
    pop edx
    pop ecx
    pop ebx
    pop eax
    ret

VBE_FLAT_CODE_SEL equ 08h
VBE_FLAT_DATA_SEL equ 10h

even
vbe_flat_gdt_start label byte
vbe_flat_gdt_null dq 0
vbe_flat_gdt_code dw 0FFFFh, 0000h
                  db 00h, 09Ah, 00h, 00h
vbe_flat_gdt_data dw 0FFFFh, 0000h
                  db 00h, 092h, 08Fh, 00h
vbe_flat_gdt_end label byte
vbe_flat_gdt_descriptor dw vbe_flat_gdt_end - vbe_flat_gdt_start - 1
                        dd 0
