.model tiny
.code
org 0

include boot_config.inc

GAME_SEGMENT equ 1000h
BOOT_STACK_TOP           equ 7C00h
BOOT_DATA_SEG            equ 07C0h
FLOPPY_SECTOR_SIZE       equ 0200h
FLOPPY_SECTORS_PER_TRACK equ 18
FLOPPY_HEADS             equ 2
STAGE2_START_SECTOR      equ 2
TEXT_MODE_80X25          equ 0003h

start:
    cli
    xor ax, ax
    mov ss, ax
    mov sp, BOOT_STACK_TOP
    mov ax, BOOT_DATA_SEG
    mov ds, ax
    sti
    ; Stage two inherits the boot stack and the cleared direction flag.
    cld

    mov [boot_drive], dl

    ; The flattened stage-two payload is written immediately after the boot
    ; sector and must fit in one segment; scripts/build.ps1 validates both.
    mov ax, GAME_SEGMENT
    mov es, ax
    xor bx, bx
    mov ch, 0
    mov dh, 0
    mov cl, STAGE2_START_SECTOR
    mov si, GAME_SECTORS

load_loop:
    mov ah, 02h
    mov al, 01h
    mov dl, [boot_drive]
    int 13h
    jc disk_error

    add bx, FLOPPY_SECTOR_SIZE
    inc cl
    cmp cl, FLOPPY_SECTORS_PER_TRACK + 1
    jb next_sector
    mov cl, 1
    inc dh
    cmp dh, FLOPPY_HEADS
    jb next_sector
    mov dh, 0
    inc ch

next_sector:
    dec si
    jnz load_loop

    ; The boot contract is a far return to stage two offset 0000, so the first
    ; byte of src\game.asm must stay executable.
    push GAME_SEGMENT
    push 0000h
    retf

disk_error:
    mov ax, TEXT_MODE_80X25
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
