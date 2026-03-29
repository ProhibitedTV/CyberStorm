; Sprite and tile bitmap data is generated into build\generated_art.inc so future
; visual edits happen in a compact source format instead of raw db rows here.
include generated_art.inc

; The starfield, palette, and font are still hand-authored assembly data because
; they are compact, low churn, and easier to reason about directly in-source.
STAR_COUNT equ 16
starfield  dw 24, 18, PAL_CYAN
           dw 62, 28, PAL_WHITE
           dw 110, 12, PAL_CYAN
           dw 182, 22, PAL_WHITE
           dw 238, 18, PAL_CYAN
           dw 298, 26, PAL_WHITE
           dw 36, 176, PAL_CYAN
           dw 88, 188, PAL_WHITE
           dw 140, 182, PAL_CYAN
           dw 210, 190, PAL_WHITE
           dw 280, 178, PAL_CYAN
           dw 304, 150, PAL_WHITE
           dw 14, 98, PAL_CYAN
           dw 308, 74, PAL_WHITE
           dw 286, 54, PAL_CYAN
           dw 8, 144, PAL_WHITE

palette_data db 0,0,0
             db 2,3,8
             db 4,7,14
             db 5,10,18
             db 8,14,22
             db 0,36,42
             db 12,52,58
             db 63,63,63
             db 63,42,8
             db 48,8,8
             db 63,18,18
             db 12,16,22
             db 20,28,38
             db 6,12,16
             db 10,20,24
             db 10,46,52
             db 50,12,18
             db 18,60,56
PALETTE_BYTES equ ($ - palette_data)

font5x7 db 0Eh,11h,11h,1Fh,11h,11h,11h
        db 1Eh,11h,11h,1Eh,11h,11h,1Eh
        db 0Eh,11h,10h,10h,10h,11h,0Eh
        db 1Eh,11h,11h,11h,11h,11h,1Eh
        db 1Fh,10h,10h,1Eh,10h,10h,1Fh
        db 1Fh,10h,10h,1Eh,10h,10h,10h
        db 0Eh,11h,10h,17h,11h,11h,0Fh
        db 11h,11h,11h,1Fh,11h,11h,11h
        db 1Fh,04h,04h,04h,04h,04h,1Fh
        db 01h,01h,01h,01h,11h,11h,0Eh
        db 11h,12h,14h,18h,14h,12h,11h
        db 10h,10h,10h,10h,10h,10h,1Fh
        db 11h,1Bh,15h,15h,11h,11h,11h
        db 11h,19h,15h,13h,11h,11h,11h
        db 0Eh,11h,11h,11h,11h,11h,0Eh
        db 1Eh,11h,11h,1Eh,10h,10h,10h
        db 0Eh,11h,11h,11h,15h,12h,0Dh
        db 1Eh,11h,11h,1Eh,14h,12h,11h
        db 0Fh,10h,10h,0Eh,01h,01h,1Eh
        db 1Fh,04h,04h,04h,04h,04h,04h
        db 11h,11h,11h,11h,11h,11h,0Eh
        db 11h,11h,11h,11h,11h,0Ah,04h
        db 11h,11h,11h,15h,15h,15h,0Ah
        db 11h,11h,0Ah,04h,0Ah,11h,11h
        db 11h,11h,0Ah,04h,04h,04h,04h
        db 1Fh,01h,02h,04h,08h,10h,1Fh
        db 0Eh,11h,13h,15h,19h,11h,0Eh
        db 04h,0Ch,04h,04h,04h,04h,0Eh
        db 0Eh,11h,01h,02h,04h,08h,1Fh
        db 1Eh,01h,01h,06h,01h,01h,1Eh
        db 02h,06h,0Ah,12h,1Fh,02h,02h
        db 1Fh,10h,10h,1Eh,01h,01h,1Eh
        db 06h,08h,10h,1Eh,11h,11h,0Eh
        db 1Fh,01h,02h,04h,08h,08h,08h
        db 0Eh,11h,11h,0Eh,11h,11h,0Eh
        db 0Eh,11h,11h,0Fh,01h,02h,0Ch
        db 00h,00h,00h,00h,00h,0Ch,0Ch
        db 00h,00h,00h,00h,00h,00h,00h
