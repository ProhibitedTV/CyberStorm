scene3d_get_sin_cos:
    ; Input : AL = 0..255 turn angle
    ; Output: BX = sin(angle) in signed 8.8 fixed
    ;         DX = cos(angle) in signed 8.8 fixed
    push ax
    push cx
    push es
    push si
    mov cl, al
    mov ax, CODE_BANK_SEG
    mov es, ax
    mov al, cl
    xor ah, ah
    shl ax, 1
    mov si, ax
    mov bx, es:[MC_TABLE_SIN_TABLE_88_OFFSET + si]

    mov al, cl
    add al, 64
    xor ah, ah
    shl ax, 1
    mov si, ax
    mov dx, es:[MC_TABLE_SIN_TABLE_88_OFFSET + si]
    pop si
    pop es
    pop cx
    pop ax
    ret

scene3d_mul_ax_bx_fixed:
    ; Signed 8.8 fixed multiply: AX * BX -> AX.
    push bx
    push cx
    push dx
    imul bx
    mov cx, 8

scene3d_mul_ax_bx_shift:
    sar dx, 1
    rcr ax, 1
    loop scene3d_mul_ax_bx_shift

    pop dx
    pop cx
    pop bx
    ret

scene3d_project_ax:
    ; Signed projection helper: AX = (AX * BX) / CX
    push dx
    imul bx
    idiv cx
    pop dx
    ret
