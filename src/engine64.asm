option casemap:none

PUBLIC Engine64PayloadStart

.code
Engine64PayloadStart LABEL BYTE
    db 'CS64ENG0'
    dd 00000001h        ; payload format version
    dd 00000280h        ; target width: 640
    dd 000001E0h        ; target height: 480
    dd 0000000Ch        ; deterministic title-scene palette entries
    dd 0000003Fh        ; GOP, xRGB8888, title scene, pack, boot logs, model assets
    dd 00000044h        ; palette table offset
    dd 00000004h        ; bytes per palette color
    dd 00000000h        ; internal present format: xRGB8888
    dd 0012C000h        ; 640x480x4 frame arena budget
    dd 0012C000h        ; 640x480x4 depth arena budget
    dd 00000000h        ; reserved for renderer entry RVA
    dd 00101820h        ; clear color
    dd Engine64ModelTable - Engine64PayloadStart
    dd 00000002h        ; authored model records
    dd 00000020h        ; model record bytes

Engine64TitlePalette LABEL DWORD
    dd 00070B12h
    dd 00101820h
    dd 00182A38h
    dd 003080D0h
    dd 00D8FFFFh
    dd 0020D060h
    dd 00A020B0h
    dd 00FF90FFh
    dd 00E8F8FFh
    dd 00FFE66Dh
    dd 00FF4058h
    dd 00030A10h

Engine64ModelTable LABEL BYTE
    db 'WARDEN  '
    dd Engine64WardenVertices - Engine64PayloadStart
    dd 00000008h
    dd Engine64WardenFaces - Engine64PayloadStart
    dd 0000000Ch
    dd 00000000h
    dd 00000000h

    db 'TERMNL  '
    dd Engine64TerminalVertices - Engine64PayloadStart
    dd 00000008h
    dd Engine64TerminalFaces - Engine64PayloadStart
    dd 0000000Ah
    dd 00000000h
    dd 00000000h

Engine64WardenVertices LABEL WORD
    dw -22,  22,   0
    dw  22,  22,   0
    dw  28, -14,   0
    dw -28, -14,   0
    dw -14,  12,  22
    dw  14,  12,  22
    dw  12, -20,  22
    dw -12, -20,  22

Engine64WardenFaces LABEL BYTE
    db 0, 1, 2, 6
    db 0, 2, 3, 7
    db 0, 4, 5, 8
    db 0, 5, 1, 4
    db 1, 5, 6, 10
    db 1, 6, 2, 7
    db 2, 6, 7, 6
    db 2, 7, 3, 7
    db 3, 7, 4, 4
    db 3, 4, 0, 7
    db 4, 7, 6, 9
    db 4, 6, 5, 9

Engine64TerminalVertices LABEL WORD
    dw -30,  24,   0
    dw  30,  24,   0
    dw  30, -24,   0
    dw -30, -24,   0
    dw -18,  14,  18
    dw  18,  14,  18
    dw  18, -14,  18
    dw -18, -14,  18

Engine64TerminalFaces LABEL BYTE
    db 0, 1, 2, 5
    db 0, 2, 3, 4
    db 0, 4, 5, 8
    db 0, 5, 1, 9
    db 1, 5, 6, 10
    db 1, 6, 2, 4
    db 2, 6, 7, 5
    db 2, 7, 3, 4
    db 3, 7, 4, 8
    db 3, 4, 0, 9

END
