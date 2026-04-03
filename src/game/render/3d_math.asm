scene3d_get_sin_cos:
    ; Input : AL = 0..255 turn angle
    ; Output: BX = sin(angle) in signed 8.8 fixed
    ;         DX = cos(angle) in signed 8.8 fixed
    push ax
    push si
    xor ah, ah
    shl ax, 1
    mov si, ax
    mov bx, cs:[scene3d_sin_table + si]

    pop si
    pop ax
    add al, 64
    push si
    xor ah, ah
    shl ax, 1
    mov si, ax
    mov dx, cs:[scene3d_sin_table + si]
    pop si
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

scene3d_sin_table:
dw 0, 6, 13, 19, 25, 31, 38, 44
dw 50, 56, 62, 68, 74, 80, 86, 92
dw 98, 104, 109, 115, 121, 126, 132, 137
dw 142, 147, 152, 157, 162, 167, 172, 177
dw 181, 185, 190, 194, 198, 202, 206, 209
dw 213, 216, 220, 223, 226, 229, 231, 234
dw 237, 239, 241, 243, 245, 247, 248, 250
dw 251, 252, 253, 254, 255, 255, 256, 256
dw 256, 256, 256, 255, 255, 254, 253, 252
dw 251, 250, 248, 247, 245, 243, 241, 239
dw 237, 234, 231, 229, 226, 223, 220, 216
dw 213, 209, 206, 202, 198, 194, 190, 185
dw 181, 177, 172, 167, 162, 157, 152, 147
dw 142, 137, 132, 126, 121, 115, 109, 104
dw 98, 92, 86, 80, 74, 68, 62, 56
dw 50, 44, 38, 31, 25, 19, 13, 6
dw 0, -6, -13, -19, -25, -31, -38, -44
dw -50, -56, -62, -68, -74, -80, -86, -92
dw -98, -104, -109, -115, -121, -126, -132, -137
dw -142, -147, -152, -157, -162, -167, -172, -177
dw -181, -185, -190, -194, -198, -202, -206, -209
dw -213, -216, -220, -223, -226, -229, -231, -234
dw -237, -239, -241, -243, -245, -247, -248, -250
dw -251, -252, -253, -254, -255, -255, -256, -256
dw -256, -256, -256, -255, -255, -254, -253, -252
dw -251, -250, -248, -247, -245, -243, -241, -239
dw -237, -234, -231, -229, -226, -223, -220, -216
dw -213, -209, -206, -202, -198, -194, -190, -185
dw -181, -177, -172, -167, -162, -157, -152, -147
dw -142, -137, -132, -126, -121, -115, -109, -104
dw -98, -92, -86, -80, -74, -68, -62, -56
dw -50, -44, -38, -31, -25, -19, -13, -6
