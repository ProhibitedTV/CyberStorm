.386

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

present_frame_vbe:
    push eax
    push ebx
    push ecx
    push edx
    push esi
    push edi
    push ds
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
    mov al, [si]
    inc si
    mov ah, al
    mov word ptr fs:[edi], ax
    add edi, 2
    loop present_frame_vbe_pixel

    movzx eax, word ptr [video_pitch]
    movzx ecx, word ptr [video_output_w]
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
