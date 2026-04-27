.386p

ENHANCED_VBE_MODE equ 0111h
BOOTSTRAP_VBE_INFO_OFFSET equ ENHANCED_HANDOFF_OFFSET + 16

init_video_output:
    push ax
    push bx
    push es

    mov byte ptr [video_output_mode], ENHANCED_OUTPUT_MODE_OFF
    mov word ptr [video_pitch], SCREEN_W
    mov word ptr [video_output_w], SCREEN_W
    mov word ptr [video_output_h], SCREEN_H
    mov dword ptr [video_lfb_addr], 0
    mov dword ptr [video_frame_bytes], 0
    mov word ptr [video_image_pages], 0
    mov word ptr [video_present_flags], 0
    mov byte ptr [video_gameplay_present_mode], ENHANCED_GAMEPLAY_PRESENT_DEGRADED_BLIT
    mov byte ptr [video_visible_page], 0

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
    mov eax, dword ptr es:[bx + ENHANCED_HANDOFF_FRAME_BYTES_OFF]
    mov dword ptr [video_frame_bytes], eax
    mov ax, word ptr es:[bx + ENHANCED_HANDOFF_IMAGE_PAGES_OFF]
    mov word ptr [video_image_pages], ax
    mov ax, word ptr es:[bx + ENHANCED_HANDOFF_PRESENT_FLAGS_OFF]
    mov word ptr [video_present_flags], ax
    cmp word ptr [video_output_w], ENHANCED_SCREEN_W
    jne init_video_output_done
    cmp word ptr [video_output_h], ENHANCED_SCREEN_H
    jne init_video_output_done
    test word ptr [video_present_flags], ENHANCED_PRESENT_FLAG_CAN_PAGE_FLIP
    jz init_video_output_done
    mov byte ptr [video_gameplay_present_mode], ENHANCED_GAMEPLAY_PRESENT_PAGE_FLIP
    jmp init_video_output_done

init_video_output_legacy:
    call try_init_video_output_from_current_vbe_mode
    cmp al, 0
    jne init_video_output_done
    mov ax, 0013h
    int 10h
    call reset_legacy_vga_display_origin

init_video_output_done:
    pop es
    pop bx
    pop ax
    ret

try_init_video_output_from_current_vbe_mode:
    push bx
    push cx
    push dx
    push es

    mov ax, 4F03h
    int 10h
    cmp ax, 004Fh
    jne try_init_video_output_from_current_vbe_mode_set
    mov ax, bx
    and ax, 01FFh
    cmp ax, ENHANCED_VBE_MODE
    je try_init_video_output_from_current_vbe_mode_query

try_init_video_output_from_current_vbe_mode_set:
    mov ax, 4F02h
    mov bx, ENHANCED_VBE_MODE
    or bx, 4000h
    int 10h
    cmp ax, 004Fh
    je try_init_video_output_from_current_vbe_mode_set_done
    mov ax, 4F02h
    mov bx, ENHANCED_VBE_MODE
    int 10h
    cmp ax, 004Fh
    jne try_init_video_output_from_current_vbe_mode_fail

try_init_video_output_from_current_vbe_mode_set_done:
    mov ax, 4F07h
    mov bx, 0080h
    xor cx, cx
    xor dx, dx
    int 10h

try_init_video_output_from_current_vbe_mode_query:

    mov ax, BOOTSTRAP_SEG
    mov es, ax
    mov di, BOOTSTRAP_VBE_INFO_OFFSET
    mov ax, 4F01h
    mov cx, ENHANCED_VBE_MODE
    int 10h
    cmp ax, 004Fh
    jne try_init_video_output_from_current_vbe_mode_fail

    cmp word ptr es:[di + 12], ENHANCED_SCREEN_W
    jne try_init_video_output_from_current_vbe_mode_fail
    cmp word ptr es:[di + 14], ENHANCED_SCREEN_H
    jne try_init_video_output_from_current_vbe_mode_fail
    cmp word ptr es:[di + 16], 0
    je try_init_video_output_from_current_vbe_mode_fail
    cmp byte ptr es:[di + 25], 16
    jne try_init_video_output_from_current_vbe_mode_fail
    mov eax, dword ptr es:[di + 40]
    test eax, eax
    jz try_init_video_output_from_current_vbe_mode_fail

    mov byte ptr [video_output_mode], ENHANCED_OUTPUT_MODE_VBE
    mov ax, word ptr es:[di + 16]
    mov word ptr [video_pitch], ax
    mov ax, word ptr es:[di + 12]
    mov word ptr [video_output_w], ax
    mov ax, word ptr es:[di + 14]
    mov word ptr [video_output_h], ax
    mov eax, dword ptr es:[di + 40]
    mov dword ptr [video_lfb_addr], eax
    mov ax, word ptr es:[di + 16]
    mov dx, word ptr es:[di + 14]
    mul dx
    mov word ptr [video_frame_bytes], ax
    mov word ptr [video_frame_bytes + 2], dx
    xor ax, ax
    mov al, byte ptr es:[di + 29]
    mov word ptr [video_image_pages], ax
    mov word ptr [video_present_flags], 0
    cmp word ptr [video_image_pages], 0
    jbe try_init_video_output_from_current_vbe_mode_ready
    or word ptr [video_present_flags], ENHANCED_PRESENT_FLAG_CAN_PAGE_FLIP

try_init_video_output_from_current_vbe_mode_ready:
    mov al, 1
    jmp try_init_video_output_from_current_vbe_mode_done

try_init_video_output_from_current_vbe_mode_fail:
    xor al, al

try_init_video_output_from_current_vbe_mode_done:
    pop es
    pop dx
    pop cx
    pop bx
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
    mov gs, ax

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
    cmp byte ptr [game_state], STATE_PLAYING
    jne present_frame_vbe_generic
    cmp word ptr [video_output_w], ENHANCED_SCREEN_W
    jne present_frame_vbe_generic
    cmp word ptr [video_output_h], ENHANCED_SCREEN_H
    jne present_frame_vbe_generic
    jmp present_frame_vbe_gameplay

present_frame_vbe_generic:
    push eax
    push ebx
    push ecx
    push edx
    push esi
    push edi
    push ds
    call wait_for_vblank
    xor al, al
    call present_frame_vbe_set_display_page
    mov byte ptr [video_visible_page], al

present_frame_vbe_generic_page_ready:
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
    mov ax, cs:[palette_rgb565_table + bx]
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

build_gameplay_compat_surface:
    push ax
    push bx
    push cx
    push dx
    push si
    push di
    push ds
    push es

    mov ax, BACKBUFFER_COMPAT_SEG
    mov es, ax
    xor bx, bx
    xor dx, dx
    xor di, di
    mov cx, SCREEN_H

build_gameplay_compat_surface_row:
    push cx
    push bx
    push dx
    mov dx, bx
    call get_backbuffer_row_dssi
    mov cx, SCREEN_W / 2
    rep movsw
    pop dx
    pop bx
    add dx, GAMEPLAY_SCREEN_H

build_gameplay_compat_surface_advance:
    cmp dx, SCREEN_H
    jb build_gameplay_compat_surface_next
    sub dx, SCREEN_H
    inc bx
    jmp build_gameplay_compat_surface_advance

build_gameplay_compat_surface_next:
    pop cx
    loop build_gameplay_compat_surface_row

    pop es
    pop ds
    pop di
    pop si
    pop dx
    pop cx
    pop bx
    pop ax
    ret

present_frame_vbe_gameplay:
IF DEBUG_FRONTEND_VERIFY
    jmp present_frame_vbe_generic
ELSE
    cmp byte ptr [video_gameplay_present_mode], ENHANCED_GAMEPLAY_PRESENT_PAGE_FLIP
    je present_frame_vbe_gameplay_page_flip
    jmp present_frame_vbe_gameplay_degraded

present_frame_vbe_gameplay_degraded:
    call build_gameplay_compat_surface
    push eax
    push ebx
    push ecx
    push edx
    push esi
    push edi
    push ds
    call wait_for_vblank
    mov byte ptr [video_visible_page], 0
    xor al, al
    call present_frame_vbe_set_display_page
    call refresh_vbe_flat_fs
    call wait_for_vblank
    mov edi, dword ptr [video_lfb_addr]
    xor bx, bx
    xor dx, dx
    mov ax, BACKBUFFER_COMPAT_SEG
    mov ds, ax
    mov cx, word ptr [video_output_h]

present_frame_vbe_gameplay_degraded_row:
    push cx
    mov si, bx
    mov cx, SCREEN_W

present_frame_vbe_gameplay_degraded_pixel:
    xor bx, bx
    mov bl, [si]
    inc si
    shl bx, 1
    mov ax, cs:[palette_rgb565_table + bx]
    mov word ptr fs:[edi], ax
    mov word ptr fs:[edi + 2], ax
    add edi, 4
    loop present_frame_vbe_gameplay_degraded_pixel

    movzx eax, word ptr [video_pitch]
    movzx ecx, word ptr [video_output_w]
    shl ecx, 1
    sub eax, ecx
    add edi, eax

    add dx, SCREEN_H
    cmp dx, word ptr [video_output_h]
    jb present_frame_vbe_gameplay_degraded_same_source
    sub dx, word ptr [video_output_h]
    add bx, SCREEN_W

present_frame_vbe_gameplay_degraded_same_source:
    pop cx
    loop present_frame_vbe_gameplay_degraded_row

present_frame_vbe_gameplay_degraded_done:

    pop ds
    pop edi
    pop esi
    pop edx
    pop ecx
    pop ebx
    pop eax
    ret

present_frame_vbe_gameplay_page_flip:
    push eax
    push ebx
    push ecx
    push edx
    push esi
    push edi
    push ds
    call refresh_vbe_flat_fs
    mov edi, dword ptr [video_lfb_addr]
    mov al, [video_visible_page]
    xor al, 1
    cmp al, 0
    je present_frame_vbe_gameplay_page_base_ready
    mov eax, dword ptr [video_frame_bytes]
    add edi, eax

present_frame_vbe_gameplay_page_base_ready:
    xor bx, bx
    mov cx, GAMEPLAY_SCREEN_H

present_frame_vbe_gameplay_page_flip_row:
    push cx
    push bx
    mov dx, bx
    call get_backbuffer_row_dssi
    push si
    call present_frame_vbe_emit_row_2x
    pop si
    call present_frame_vbe_emit_row_2x
    pop bx
    inc bx
    pop cx
    loop present_frame_vbe_gameplay_page_flip_row

    call wait_for_vblank
    mov al, [video_visible_page]
    xor al, 1
    call present_frame_vbe_set_display_page
    mov byte ptr [video_visible_page], al

    pop ds
    pop edi
    pop esi
    pop edx
    pop ecx
    pop ebx
    pop eax
    ret
ENDIF

present_frame_vbe_set_display_page:
    push bx
    push cx
    push dx
    xor bx, bx
    mov bl, al
    push bx
    mov ax, word ptr [video_output_h]
    mul bx
    mov dx, ax
    xor cx, cx
    mov ax, 4F07h
    mov bx, 0080h
    int 10h
    pop bx
    mov al, bl
    pop dx
    pop cx
    pop bx
    ret

present_frame_vbe_emit_row_2x:
    push eax
    push ebx
    push ecx

    mov cx, SCREEN_W

present_frame_vbe_emit_row_2x_pixel:
    xor bx, bx
    mov bl, [si]
    inc si
    shl bx, 1
    mov ax, cs:[palette_rgb565_table + bx]
    mov word ptr fs:[edi], ax
    mov word ptr fs:[edi + 2], ax
    add edi, 4
    loop present_frame_vbe_emit_row_2x_pixel

    movzx eax, word ptr [video_pitch]
    sub eax, SCREEN_W * 4
    add edi, eax

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
