option casemap:none

PUBLIC Engine64PayloadStart

.code
Engine64PayloadStart LABEL BYTE
    db 'CS64ENG0'
    dd 00000001h        ; payload format version
    dd 00000280h        ; target width: 640
    dd 000001E0h        ; target height: 480
    dd 0000000Ch        ; deterministic title-scene palette entries
    dd 0000001Fh        ; GOP, xRGB8888, title scene, pack, boot logs
    dd 00000040h        ; palette table offset
    dd 00000004h        ; bytes per palette color
    dd 00000000h        ; internal present format: xRGB8888
    dd 0012C000h        ; 640x480x4 frame arena budget
    dd 0012C000h        ; 640x480x4 depth arena budget
    dd 00000000h        ; reserved for renderer entry RVA
    dd 00101820h        ; clear color
    dd 00000000h
    dd 00000000h
    dd 00000000h

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

END
