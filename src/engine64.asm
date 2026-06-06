option casemap:none

PUBLIC Engine64PayloadStart

.code
Engine64PayloadStart LABEL BYTE
    db 'CS64ENG0'
    dd 00000001h        ; payload format version
    dd 00000280h        ; target width: 640
    dd 000001E0h        ; target height: 480
    dd 00000008h        ; deterministic title/backdrop color bars
    dd 0000001Fh        ; GOP, xRGB8888, bars, pack, diagnostics
    dd 00000040h        ; bar table offset
    dd 00000004h        ; bytes per bar color
    dd 00000000h        ; internal present format: xRGB8888
    dd 0012C000h        ; 640x480x4 frame arena budget
    dd 0012C000h        ; 640x480x4 depth arena budget
    dd 00000000h        ; reserved for renderer entry RVA
    dd 00101820h        ; clear color
    dd 00000000h
    dd 00000000h
    dd 00000000h

Engine64ColorBars LABEL DWORD
    dd 00101820h
    dd 00182A38h
    dd 003080D0h
    dd 00D8FFFFh
    dd 0020D060h
    dd 00A020B0h
    dd 00FF90FFh
    dd 00E8F8FFh

END
