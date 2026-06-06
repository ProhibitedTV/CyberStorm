.386p
.model flat
.code

public engine32_entry

ENGINE32_VERSION      equ 00000002h
ENGINE32_VBE_LFB      equ 000A0000h
ENGINE32_LOAD_BASE    equ 00100000h
ENGINE32_RENDER_ARENA equ 00800000h
ENGINE32_TEXTURE_POOL equ 01000000h
ENGINE32_FRAME565     equ 03000000h
ENGINE32_ZBUFFER      equ 03100000h
ENGINE32_FRAME_BYTES  equ 00096000h
ENGINE32_DEPTH_BYTES  equ 00096000h
ENGINE32_SCREEN_W     equ 00000280h
ENGINE32_SCREEN_H     equ 000001E0h
ENGINE32_BPP          equ 00000010h
ENGINE32_PIXELS       equ 0004B000h

ENGINE32_PIPE_NEAR_CLIP  equ 00000001h
ENGINE32_PIPE_GUARD_CLIP equ 00000002h
ENGINE32_PIPE_DEGEN      equ 00000004h
ENGINE32_PIPE_BACKFACE   equ 00000008h
ENGINE32_PIPE_ZSPAN      equ 00000010h
ENGINE32_PIPE_FOG        equ 00000020h
ENGINE32_PIPE_EMISSIVE   equ 00000040h

C_BLACK_PAIR       equ 00080008h
C_SPACE_PAIR       equ 08410841h
C_SPACE_DEEP_PAIR  equ 000A000Ah
C_PANEL_PAIR       equ 18E318E3h
C_PANEL_DARK_PAIR  equ 10821082h
C_CYAN_PAIR        equ 07FF07FFh
C_CYAN_DIM_PAIR    equ 04100410h
C_AMBER_PAIR       equ 0FEA0FEA0h
C_WHITE_PAIR       equ 0FFFFFFFFh

; Expanded protected-mode visual payload.
;
; Calling convention for the eventual loader handoff:
;   - CPU is in 32-bit protected mode.
;   - DS/ES/SS describe a flat writable address space.
;   - The visual pack is already available at ENGINE32_TEXTURE_POOL.
;   - The routine renders a deterministic 640x480 RGB565 title showcase into
;     ENGINE32_FRAME565 and clears a matching 16-bit depth buffer.
;
; Stage two still owns the shipping title/gameplay path today. This payload is
; intentionally self-contained so the bootloader can promote it to live runtime
; without changing the expanded ISO pack layout again.
engine32_entry proc
    cld
    pushad
    call engine32_clear_depth
    call engine32_draw_backdrop
    call engine32_draw_showcase_ship
    call engine32_draw_menu_read_zone
    popad
    ret
engine32_entry endp

engine32_clear_depth proc
    pushad
    mov edi, ENGINE32_ZBUFFER
    mov eax, 0FFFFFFFFh
    mov ecx, ENGINE32_DEPTH_BYTES / 4
    rep stosd
    popad
    ret
engine32_clear_depth endp

engine32_draw_backdrop proc
    pushad

    mov edi, ENGINE32_FRAME565
    mov edx, 120
    mov eax, C_SPACE_DEEP_PAIR
engine32_backdrop_space_top:
    mov ecx, ENGINE32_SCREEN_W / 2
    rep stosd
    dec edx
    jnz engine32_backdrop_space_top

    mov edx, 160
    mov eax, C_SPACE_PAIR
engine32_backdrop_space_mid:
    mov ecx, ENGINE32_SCREEN_W / 2
    rep stosd
    dec edx
    jnz engine32_backdrop_space_mid

    mov edx, 200
    mov eax, C_BLACK_PAIR
engine32_backdrop_floor:
    mov ecx, ENGINE32_SCREEN_W / 2
    rep stosd
    dec edx
    jnz engine32_backdrop_floor

    mov eax, C_CYAN_DIM_PAIR
    mov ebx, 48
    mov edx, 282
    mov esi, 544
    mov ebp, 2
    call engine32_fill_rect

    mov eax, C_PANEL_DARK_PAIR
    mov ebx, 0
    mov edx, 306
    mov esi, ENGINE32_SCREEN_W
    mov ebp, 174
    call engine32_fill_rect

    mov eax, C_CYAN_DIM_PAIR
    mov ebx, 80
    mov edx, 338
    mov esi, 480
    mov ebp, 1
    call engine32_fill_rect
    mov ebx, 112
    mov edx, 378
    mov esi, 416
    mov ebp, 1
    call engine32_fill_rect
    mov ebx, 152
    mov edx, 424
    mov esi, 336
    mov ebp, 1
    call engine32_fill_rect

    popad
    ret
engine32_draw_backdrop endp

engine32_draw_showcase_ship proc
    pushad

    ; Large center silhouette with emissive cuts. The live triangle renderer
    ; still owns current presentation, but this gives the expanded payload an
    ; executable visual target instead of just a manifest contract.
    mov eax, C_PANEL_PAIR
    mov ebx, 186
    mov edx, 150
    mov esi, 268
    mov ebp, 46
    call engine32_fill_rect

    mov eax, C_PANEL_DARK_PAIR
    mov ebx, 142
    mov edx, 196
    mov esi, 356
    mov ebp, 36
    call engine32_fill_rect

    mov eax, C_PANEL_PAIR
    mov ebx, 236
    mov edx, 112
    mov esi, 168
    mov ebp, 38
    call engine32_fill_rect

    mov eax, C_CYAN_PAIR
    mov ebx, 220
    mov edx, 164
    mov esi, 200
    mov ebp, 4
    call engine32_fill_rect
    mov ebx, 248
    mov edx, 202
    mov esi, 144
    mov ebp, 4
    call engine32_fill_rect

    mov eax, C_AMBER_PAIR
    mov ebx, 294
    mov edx, 132
    mov esi, 52
    mov ebp, 6
    call engine32_fill_rect

    popad
    ret
engine32_draw_showcase_ship endp

engine32_draw_menu_read_zone proc
    pushad

    mov eax, C_PANEL_DARK_PAIR
    mov ebx, 40
    mov edx, 336
    mov esi, 184
    mov ebp, 78
    call engine32_fill_rect

    mov eax, C_CYAN_DIM_PAIR
    mov ebx, 52
    mov edx, 356
    mov esi, 136
    mov ebp, 2
    call engine32_fill_rect

    mov eax, C_WHITE_PAIR
    mov ebx, 66
    mov edx, 374
    mov esi, 112
    mov ebp, 2
    call engine32_fill_rect

    popad
    ret
engine32_draw_menu_read_zone endp

; Input:
;   EAX = RGB565 pair
;   EBX = x
;   EDX = y
;   ESI = width in pixels, even
;   EBP = height in rows
engine32_fill_rect proc
    pushad
    mov edi, edx
    imul edi, edi, ENGINE32_SCREEN_W
    add edi, ebx
    shl edi, 1
    add edi, ENGINE32_FRAME565
    mov ebx, ENGINE32_SCREEN_W
    sub ebx, esi
    shl ebx, 1
    mov edx, ebp

engine32_fill_rect_row:
    mov ecx, esi
    shr ecx, 1
    rep stosd
    add edi, ebx
    dec edx
    jnz engine32_fill_rect_row

    popad
    ret
engine32_fill_rect endp

align 4
engine32_header:
    db 'CS32VIS1'
    dd ENGINE32_VERSION
    dd ENGINE32_VBE_LFB
    dd ENGINE32_LOAD_BASE
    dd ENGINE32_RENDER_ARENA
    dd ENGINE32_TEXTURE_POOL
    dd ENGINE32_FRAME565
    dd ENGINE32_ZBUFFER
    dd ENGINE32_FRAME_BYTES
    dd ENGINE32_DEPTH_BYTES
    dd ENGINE32_SCREEN_W
    dd ENGINE32_SCREEN_H
    dd ENGINE32_BPP

engine32_pipeline_flags:
    dd ENGINE32_PIPE_NEAR_CLIP
    dd ENGINE32_PIPE_GUARD_CLIP
    dd ENGINE32_PIPE_DEGEN
    dd ENGINE32_PIPE_BACKFACE
    dd ENGINE32_PIPE_ZSPAN
    dd ENGINE32_PIPE_FOG
    dd ENGINE32_PIPE_EMISSIVE

engine32_notes:
    db '32-bit software renderer contract: 640x480 RGB565, frame arena, z arena, texture pool, clipped triangles, depth-tested showcase.', 0

end
