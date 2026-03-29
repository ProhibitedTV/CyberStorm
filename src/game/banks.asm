load_required_asset_banks:
    ; Phase 1 keeps the boot contract untouched and loads one read-only map bank
    ; after stage two starts. The generated bank layout include defines the LBA
    ; range, while MAP_BANK_SEG is the runtime destination segment.
    push ax
    push bx
    push cx
    push es
    mov cx, MAP_BANK_SECTORS
    jcxz load_required_asset_banks_done
    mov ax, MAP_BANK_SEG
    mov es, ax
    xor bx, bx
    mov ax, MAP_BANK_LBA
    call read_floppy_lba_sectors
    jnc load_required_asset_banks_done
    mov si, offset text_map_bank_error
    call fatal_asset_bank_error

load_required_asset_banks_done:
    pop es
    pop cx
    pop bx
    pop ax
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

text_map_bank_error db 'CYBERSTORM MAP BANK ERROR', 0
