.model tiny
.code
org 0

include boot_config.inc

GAME_SEGMENT equ 1000h

start:
    cli
    xor ax, ax
    mov ss, ax
    mov sp, 7C00h
    mov ax, 07C0h
    mov ds, ax
    sti
    cld

    mov [boot_drive], dl

    mov ax, GAME_SEGMENT
    mov es, ax
    xor bx, bx
    mov ch, 0
    mov dh, 0
    mov cl, 2
    mov si, GAME_SECTORS

load_loop:
    mov ah, 02h
    mov al, 01h
    mov dl, [boot_drive]
    int 13h
    jc disk_error

    add bx, 0200h
    inc cl
    cmp cl, 19
    jb next_sector
    mov cl, 1
    inc dh
    cmp dh, 2
    jb next_sector
    mov dh, 0
    inc ch

next_sector:
    dec si
    jnz load_loop

    push GAME_SEGMENT
    push 0000h
    retf

disk_error:
    mov ax, 0003h
    int 10h
    mov si, offset disk_error_text

print_error:
    lodsb
    or al, al
    jz halt
    mov ah, 0Eh
    mov bh, 00h
    mov bl, 0Ch
    int 10h
    jmp print_error

halt:
    cli
hang:
    hlt
    jmp hang

boot_drive db 0
disk_error_text db 'CYBERSTORM BOOT ERROR', 0

end start
