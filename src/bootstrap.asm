.model tiny
.386p
.code
org 0

include boot_config.inc
include generated_bank_layout.inc

BOOTSTRAP_SEG equ 0800h
STAGE2_SEG    equ 1000h
TEXT_MODE_80X25 equ 0003h
ENHANCED_VBE_MODE equ 0101h
ENHANCED_VBE_LINEAR_FLAG equ 4000h
CODE_BANK_SEG equ 6000h
TEXTURE_BANK_SEG equ 6800h
MAP_BANK_SEG equ 7000h
PRESENT_BANK_SEG equ 7800h
GEOMETRY_BANK_SEG equ 8000h

HANDOFF_OFFSET     equ 0400h
HANDOFF_SIG0       equ 4252h
HANDOFF_SIG1       equ 5645h
HANDOFF_VERSION    equ 1
HANDOFF_FLAG_VBE   equ 0001h
HANDOFF_SIG0_OFF   equ 0
HANDOFF_SIG1_OFF   equ 2
HANDOFF_VERSION_OFF equ 4
HANDOFF_FLAGS_OFF  equ 6
HANDOFF_MODE_OFF   equ 8
HANDOFF_WIDTH_OFF  equ 10
HANDOFF_HEIGHT_OFF equ 12
HANDOFF_PITCH_OFF  equ 14
HANDOFF_LFB_OFF    equ 16

FLAT_CODE_SEL equ 08h
FLAT_DATA_SEL equ 10h

start:
    cli
    mov ax, cs
    mov ds, ax
    mov es, ax
    mov ss, ax
    mov sp, 0FFFEh
    sti
    cld

    mov [boot_drive], dl
    call clear_handoff_block
    call load_stage2_and_banks
    call setup_vbe_mode
    call enter_unreal_mode
    call write_handoff_block

    mov dl, [boot_drive]
    push STAGE2_SEG
    push 0000h
    retf

clear_handoff_block:
    push ax
    push cx
    push di
    mov ax, cs
    mov es, ax
    mov di, HANDOFF_OFFSET
    xor ax, ax
    mov cx, 12
    rep stosw
    pop di
    pop cx
    pop ax
    ret

load_stage2_and_banks:
    mov ax, STAGE2_LBA
    mov cx, GAME_SECTORS
    mov dx, STAGE2_SEG
    lea si, text_stage2_error
    call load_payload_or_fail

    mov ax, CODE_BANK_LBA
    mov cx, CODE_BANK_SECTORS
    mov dx, CODE_BANK_SEG
    lea si, text_code_bank_error
    call load_payload_or_fail

    mov ax, TEXTURE_BANK_LBA
    mov cx, TEXTURE_BANK_SECTORS
    mov dx, TEXTURE_BANK_SEG
    lea si, text_texture_bank_error
    call load_payload_or_fail

    mov ax, MAP_BANK_LBA
    mov cx, MAP_BANK_SECTORS
    mov dx, MAP_BANK_SEG
    lea si, text_map_bank_error
    call load_payload_or_fail

    mov ax, PRESENT_BANK_LBA
    mov cx, PRESENT_BANK_SECTORS
    mov dx, PRESENT_BANK_SEG
    lea si, text_presentation_bank_error
    call load_payload_or_fail

    mov ax, GEOMETRY_BANK_LBA
    mov cx, GEOMETRY_BANK_SECTORS
    mov dx, GEOMETRY_BANK_SEG
    lea si, text_geometry_bank_error
    call load_payload_or_fail
    ret

load_payload_or_fail:
    or cx, cx
    jz load_payload_done
    push si
    call read_lba_payload
    pop si
    jnc load_payload_done
    call fatal_error
load_payload_done:
    ret

read_lba_payload:
    ; Read CX sectors starting at LBA AX into segment DX:0000 using BIOS EDD.
    push bx
    push di
    mov bx, ax
    mov ax, cs
    mov ds, ax

read_lba_payload_chunk:
    or cx, cx
    jz read_lba_payload_done

    mov di, cx
    cmp di, 127
    jbe read_lba_payload_chunk_ready
    mov di, 127

read_lba_payload_chunk_ready:
    mov word ptr [payload_dap + 2], di
    mov word ptr [payload_dap + 4], 0000h
    mov word ptr [payload_dap + 6], dx
    mov word ptr [payload_dap + 8], bx
    mov word ptr [payload_dap + 10], 0000h
    mov word ptr [payload_dap + 12], 0000h
    mov word ptr [payload_dap + 14], 0000h
    mov ah, 42h
    lea si, payload_dap
    mov dl, [boot_drive]
    int 13h
    jc read_lba_payload_fail

    mov ax, cs
    mov ds, ax
    sub cx, di
    add bx, di
    mov ax, di
    shl ax, 5
    add dx, ax
    jmp read_lba_payload_chunk

read_lba_payload_fail:
    mov ax, cs
    mov ds, ax
    pop di
    pop bx
    ret

read_lba_payload_done:
    clc
    pop di
    pop bx
    ret

setup_vbe_mode:
    push ax
    push bx
    push cx
    push dx
    push di
    push es

    mov ax, cs
    mov es, ax
    lea di, vbe_mode_info
    mov ax, 4F01h
    mov cx, ENHANCED_VBE_MODE
    int 10h
    cmp ax, 004Fh
    jne setup_vbe_fail

    mov ax, word ptr vbe_mode_info[0]
    test ax, 0001h
    jz setup_vbe_fail
    test ax, 0080h
    jz setup_vbe_lfb_fail
    cmp word ptr vbe_mode_info[12], 640
    jne setup_vbe_fail
    cmp word ptr vbe_mode_info[14], 480
    jne setup_vbe_fail
    cmp byte ptr vbe_mode_info[25], 8
    jne setup_vbe_fail
    mov al, byte ptr vbe_mode_info[27]
    cmp al, 4
    jne setup_vbe_fail

    mov ax, 4F02h
    mov bx, ENHANCED_VBE_MODE + ENHANCED_VBE_LINEAR_FLAG
    int 10h
    cmp ax, 004Fh
    jne setup_vbe_lfb_fail

    mov ax, cs
    mov ds, ax
    mov ax, word ptr vbe_mode_info[16]
    mov [handoff_pitch], ax
    mov ax, word ptr vbe_mode_info[12]
    mov [handoff_width], ax
    mov ax, word ptr vbe_mode_info[14]
    mov [handoff_height], ax
    mov eax, dword ptr vbe_mode_info[40]
    mov dword ptr [handoff_lfb], eax
    mov word ptr [handoff_flags], HANDOFF_FLAG_VBE
    mov word ptr [handoff_mode], ENHANCED_VBE_MODE
    jmp setup_vbe_done

setup_vbe_lfb_fail:
    lea si, text_vbe_lfb_error
    jmp setup_vbe_panic

setup_vbe_fail:
    lea si, text_vbe_error

setup_vbe_panic:
    call fatal_error

setup_vbe_done:
    pop es
    pop di
    pop dx
    pop cx
    pop bx
    pop ax
    ret

enter_unreal_mode:
    cli
    in al, 92h
    or al, 02h
    out 92h, al

    lgdt fword ptr gdt_descriptor
    mov eax, cr0
    or eax, 1
    mov cr0, eax
    push FLAT_CODE_SEL
    push OFFSET protected_entry
    retf

protected_entry:
    mov ax, FLAT_DATA_SEL
    mov ds, ax
    mov es, ax
    mov fs, ax
    mov gs, ax
    mov ss, ax

    mov eax, cr0
    and eax, 0FFFFFFFEh
    mov cr0, eax
    push BOOTSTRAP_SEG
    push OFFSET real_mode_entry
    retf

real_mode_entry:
    mov ax, cs
    mov ds, ax
    mov es, ax
    mov ss, ax
    mov sp, 0FFFEh
    sti
    ret

write_handoff_block:
    push ax
    push di
    mov ax, cs
    mov ds, ax
    mov ax, cs
    mov es, ax
    mov di, HANDOFF_OFFSET
    mov word ptr es:[di + HANDOFF_SIG0_OFF], HANDOFF_SIG0
    mov word ptr es:[di + HANDOFF_SIG1_OFF], HANDOFF_SIG1
    mov word ptr es:[di + HANDOFF_VERSION_OFF], HANDOFF_VERSION
    mov ax, [handoff_flags]
    mov word ptr es:[di + HANDOFF_FLAGS_OFF], ax
    mov ax, [handoff_mode]
    mov word ptr es:[di + HANDOFF_MODE_OFF], ax
    mov ax, [handoff_width]
    mov word ptr es:[di + HANDOFF_WIDTH_OFF], ax
    mov ax, [handoff_height]
    mov word ptr es:[di + HANDOFF_HEIGHT_OFF], ax
    mov ax, [handoff_pitch]
    mov word ptr es:[di + HANDOFF_PITCH_OFF], ax
    mov eax, dword ptr [handoff_lfb]
    mov dword ptr es:[di + HANDOFF_LFB_OFF], eax
    pop di
    pop ax
    ret

fatal_error:
    mov ax, cs
    mov ds, ax
    mov ax, TEXT_MODE_80X25
    int 10h

fatal_error_loop:
    lodsb
    or al, al
    jz fatal_halt
    mov ah, 0Eh
    mov bh, 00h
    mov bl, 0Ch
    int 10h
    jmp fatal_error_loop

fatal_halt:
    cli
fatal_spin:
    hlt
    jmp fatal_spin

db 0
payload_dap db 10h, 00h
            dw 0
            dw 0000h
            dw 0000h
            dd 0
            dd 0

boot_drive db 0
handoff_flags  dw 0
handoff_mode   dw 0
handoff_width  dw 640
handoff_height dw 480
handoff_pitch  dw 640
handoff_lfb    dd 0

even
gdt_start label byte
gdt_null dq 0
gdt_code dw 0FFFFh, 0000h
         db 00h, 09Ah, 08Fh, 00h
gdt_data dw 0FFFFh, 0000h
         db 00h, 092h, 08Fh, 00h
gdt_end label byte
gdt_descriptor dw gdt_end - gdt_start - 1
               dd OFFSET gdt_start

even
vbe_mode_info db 256 dup (0)

text_stage2_error db 'CYBERSTORM STAGE2 LOAD ERROR', 0
text_code_bank_error db 'CYBERSTORM CODE BANK ERROR', 0
text_texture_bank_error db 'CYBERSTORM TEXTURE BANK ERROR', 0
text_map_bank_error db 'CYBERSTORM MAP BANK ERROR', 0
text_presentation_bank_error db 'CYBERSTORM PRESENTATION BANK ERROR', 0
text_geometry_bank_error db 'CYBERSTORM GEOMETRY BANK ERROR', 0
text_vbe_error db 'CYBERSTORM VBE 640X480X8 REQUIRED', 0
text_vbe_lfb_error db 'CYBERSTORM VBE LFB REQUIRED', 0

end start
