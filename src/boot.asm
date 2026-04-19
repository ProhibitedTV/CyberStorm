.model tiny
.code
org 0

include boot_config.inc

BOOTSTRAP_SEG  equ 0800h
BOOT_STACK_TOP equ 7C00h
BOOT_DATA_SEG  equ 07C0h
TEXT_MODE_80X25 equ 0003h

start:
    cli
    xor ax, ax
    mov ss, ax
    mov sp, BOOT_STACK_TOP
    mov ax, BOOT_DATA_SEG
    mov ds, ax
    sti
    cld

    mov [boot_drive], dl
    call verify_edd_support
    jc edd_error
    call load_bootstrap
    jc disk_error

    mov dl, [boot_drive]
    push BOOTSTRAP_SEG
    push 0000h
    retf

verify_edd_support:
    mov ax, BOOT_DATA_SEG
    mov ds, ax
    mov ah, 41h
    mov bx, 55AAh
    mov dl, [boot_drive]
    int 13h
    jc verify_edd_fail
    cmp bx, 0AA55h
    jne verify_edd_fail
    test cx, 1
    jz verify_edd_fail
    clc
    ret

verify_edd_fail:
    stc
    ret

load_bootstrap:
    mov ax, BOOT_DATA_SEG
    mov ds, ax
    mov ax, BOOTSTRAP_SEG
    mov es, ax
    xor bx, bx
    mov ah, 02h
    mov al, BOOTSTRAP_SECTORS
    xor ch, ch
    mov cl, 2
    xor dh, dh
    mov dl, [boot_drive]
    int 13h
    mov ax, BOOT_DATA_SEG
    mov ds, ax
    ret

edd_error:
    mov si, offset edd_error_text
    jmp print_error

disk_error:
    mov si, offset disk_error_text

print_error:
    mov ax, BOOT_DATA_SEG
    mov ds, ax
    mov ax, TEXT_MODE_80X25
    int 10h

print_error_loop:
    lodsb
    or al, al
    jz halt
    mov ah, 0Eh
    mov bh, 00h
    mov bl, 0Ch
    int 10h
    jmp print_error_loop

halt:
    cli
hang:
    hlt
    jmp hang

boot_drive    db 0
edd_error_text db 'CYBERSTORM EDD REQUIRED', 0
disk_error_text db 'CYBERSTORM BOOTSTRAP ERROR', 0

end start
