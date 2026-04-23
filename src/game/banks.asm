load_required_asset_banks:
    ; Post-boot banks keep bulky read-only content off the stage-two segment.
    ; The generated bank layout include defines the on-disk LBA ranges, while
    ; each bank still loads into one conventional-memory segment.
    push ax
    push bx
    push cx
    push dx
    push es

    mov ax, CODE_BANK_LBA
    mov cx, CODE_BANK_SECTORS
    mov dx, CODE_BANK_SEG
    mov si, offset text_code_bank_error
    call load_asset_bank_or_fail

    mov ax, TEXTURE_BANK_LBA
    mov cx, TEXTURE_BANK_SECTORS
    mov dx, TEXTURE_BANK_SEG
    mov si, offset text_texture_bank_error
    call load_asset_bank_or_fail

    mov ax, TEXTURE_BANK_B_LBA
    mov cx, TEXTURE_BANK_B_SECTORS
    mov dx, TEXTURE_BANK_B_SEG
    mov si, offset text_texture_bank_b_error
    call load_asset_bank_or_fail

    mov ax, MAP_BANK_LBA
    mov cx, MAP_BANK_SECTORS
    mov dx, MAP_BANK_SEG
    mov si, offset text_map_bank_error
    call load_asset_bank_or_fail

    mov ax, PRESENT_BANK_LBA
    mov cx, PRESENT_BANK_SECTORS
    mov dx, PRESENT_BANK_SEG
    mov si, offset text_presentation_bank_error
    call load_asset_bank_or_fail

    mov ax, GEOMETRY_BANK_LBA
    mov cx, GEOMETRY_BANK_SECTORS
    mov dx, GEOMETRY_BANK_SEG
    mov si, offset text_geometry_bank_error
    call load_asset_bank_or_fail

load_required_asset_banks_done:
    pop es
    pop dx
    pop cx
    pop bx
    pop ax
    ret

load_asset_bank_or_fail:
    or cx, cx
    jz load_asset_bank_done
    push si
    mov es, dx
    xor bx, bx
    call read_floppy_lba_sectors
    pop si
    jnc load_asset_bank_done
    call fatal_asset_bank_error

load_asset_bank_done:
    ret

read_floppy_lba_sectors:
    ; Read CX sectors from floppy LBA AX into ES:BX. The current phase-1 bank
    ; contract keeps each bank inside one 64 KiB destination segment.
    push ax
    push cx
    push dx
    push si
    push di
    mov si, ax
    mov di, cx

read_floppy_lba_loop:
    or di, di
    jz read_floppy_lba_done
    mov ax, si
    call lba_to_chs
    mov ah, 02h
    mov al, 01h
    mov dl, [boot_drive]
    int 13h
    jc read_floppy_lba_fail
    add bx, FLOPPY_SECTOR_BYTES
    inc si
    dec di
    jmp read_floppy_lba_loop

read_floppy_lba_fail:
    stc
    jmp read_floppy_lba_exit

read_floppy_lba_done:
    clc

read_floppy_lba_exit:
    pop di
    pop si
    pop dx
    pop cx
    pop ax
    ret

lba_to_chs:
    ; Convert a 0-based floppy LBA in AX into BIOS CHS registers for int 13h.
    push ax
    push bx
    xor dx, dx
    mov bx, FLOPPY_SECTORS_PER_TRACK
    div bx
    mov cl, dl
    inc cl
    xor dx, dx
    mov bx, FLOPPY_HEADS
    div bx
    mov ch, al
    mov dh, dl
    pop bx
    pop ax
    ret

fatal_asset_bank_error:
    mov ax, TEXT_MODE_80X25
    int 10h

fatal_asset_bank_print:
    lodsb
    or al, al
    jz fatal_asset_bank_halt
    mov ah, 0Eh
    mov bh, 00h
    mov bl, 0Ch
    int 10h
    jmp fatal_asset_bank_print

fatal_asset_bank_halt:
    cli

fatal_asset_bank_spin:
    hlt
    jmp fatal_asset_bank_spin

text_code_bank_error db 'CYBERSTORM CODE BANK ERROR', 0
text_texture_bank_error db 'CYBERSTORM TEXTURE BANK ERROR', 0
text_texture_bank_b_error db 'CYBERSTORM TEXTURE BANK B ERROR', 0
text_map_bank_error db 'CYBERSTORM MAP BANK ERROR', 0
text_presentation_bank_error db 'CYBERSTORM PRESENTATION BANK ERROR', 0
text_geometry_bank_error db 'CYBERSTORM GEOMETRY BANK ERROR', 0
