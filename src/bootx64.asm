option casemap:none

EFI_SYSTEM_TABLE_CONOUT       equ 64
EFI_SYSTEM_TABLE_CONIN        equ 48
EFI_SYSTEM_TABLE_BOOTSERV     equ 96
EFI_SIMPLE_TEXT_OUTPUT_TEXT   equ 8
EFI_SIMPLE_TEXT_OUTPUT_CLEAR  equ 48
EFI_SIMPLE_TEXT_INPUT_READ    equ 8
EFI_SIMPLE_POINTER_GET_STATE  equ 8
EFI_BOOT_SERVICES_ALLOC_PAGES equ 40
EFI_BOOT_SERVICES_HANDLE_PROTOCOL equ 152
EFI_BOOT_SERVICES_STALL       equ 248
EFI_BOOT_SERVICES_LOCATE      equ 320
DIAGNOSTIC_STALL_USEC         equ 60000000
INPUT_LOOP_TICKS              equ 0FFFFFFFFh
INPUT_POLL_STALL_USEC         equ 10000
EFI_ALLOCATE_ANY_PAGES        equ 0
EFI_LOADER_DATA               equ 2

GOP_MODE_OFFSET               equ 24
GOP_MODE_INFO_OFFSET          equ 8
GOP_MODE_FB_BASE_OFFSET       equ 24
GOP_MODE_FB_SIZE_OFFSET       equ 32
GOP_INFO_WIDTH_OFFSET         equ 4
GOP_INFO_HEIGHT_OFFSET        equ 8
GOP_INFO_PIXEL_FORMAT_OFFSET  equ 12
GOP_INFO_RED_MASK_OFFSET      equ 16
GOP_INFO_GREEN_MASK_OFFSET    equ 20
GOP_INFO_BLUE_MASK_OFFSET     equ 24
GOP_INFO_STRIDE_OFFSET        equ 32

DIAG_BG                       equ 00101820h
DIAG_PANEL                    equ 00182A38h
DIAG_HEADER                   equ 003080D0h
DIAG_ACCENT                   equ 00D8FFFFh
DIAG_MAGENTA                  equ 00A020B0h
DIAG_GREEN                    equ 0020D060h
DIAG_TEXT                     equ 00E8F8FFh
DIAG_MUTED                    equ 0088B8D8h
DIAG_OK                       equ 00B0FFC8h
DIAG_WARN                     equ 00FF90FFh

ARENA_TOTAL_BYTES             equ 02000000h
ARENA_TOTAL_PAGES             equ 2000h
ARENA_ENGINE_BYTES            equ 00200000h
ARENA_FRAME_BYTES             equ 0012C000h
ARENA_DEPTH_BYTES             equ 0012C000h
ARENA_TEXTURE_BYTES           equ 00800000h
ARENA_MESH_BYTES              equ 00400000h
ARENA_AUDIO_BYTES             equ 00200000h
ARENA_SCRATCH_BYTES           equ 00200000h
ARENA_LOG_BYTES               equ 00010000h
ARENA_ALIGN_MASK              equ 0FFFFFFFFFFFF0000h
LOG_RECORD_BYTES              equ 00000080h
LOG_MILESTONE_BOOT            equ 00010008h
LOG_FAILURE_NONE              equ 00000000h
LOG_FAILURE_FORCED            equ 0BAD0001h

EFI_LOADED_IMAGE_DEVICE_HANDLE equ 24
EFI_SIMPLE_FILE_SYSTEM_OPEN_VOLUME equ 8
EFI_FILE_OPEN                 equ 8
EFI_FILE_CLOSE                equ 16
EFI_FILE_READ                 equ 32
EFI_FILE_MODE_READ            equ 0000000000000001h

PACK_READ_MAX_BYTES           equ ARENA_SCRATCH_BYTES
PACK_EXPECTED_CHUNKS          equ 9
PACK_RECORD_BYTES             equ 32
PACK_HEADER_BYTES             equ 32
PACK_EXPECTED_MASK            equ 000001FFh
PACK_STATUS_OK                equ 00000000h
PACK_STATUS_IMAGE_PROTOCOL    equ 00000001h
PACK_STATUS_FS_PROTOCOL       equ 00000002h
PACK_STATUS_OPEN_VOLUME       equ 00000003h
PACK_STATUS_OPEN_FILE         equ 00000004h
PACK_STATUS_READ              equ 00000005h
PACK_STATUS_MAGIC             equ 00000006h
PACK_STATUS_HEADER            equ 00000007h
PACK_STATUS_BOUNDS            equ 00000008h
PACK_STATUS_CHECKSUM          equ 00000009h
PACK_STATUS_CHUNK_ID          equ 0000000Ah
PACK_STATUS_CHUNK_MASK        equ 0000000Bh
PACK_STATUS_ENGINE64          equ 0000000Ch
PACK_STATUS_STAGE             equ 0000000Dh
PACK_STATUS_ASSET             equ 0000000Eh
ENGINE64_EXPECTED_WIDTH       equ 00000280h
ENGINE64_EXPECTED_HEIGHT      equ 000001E0h
ENGINE64_MIN_BYTES            equ 00000060h
ENGINE64_FRAME_BYTES          equ 0012C000h
ENGINE64_FRAME_PIXELS         equ 0004B000h
ENGINE64_MODEL_TABLE_FIELD    equ 00000038h
ENGINE64_MODEL_COUNT_FIELD    equ 0000003Ch
ENGINE64_MODEL_RECORD_FIELD   equ 00000040h
ENGINE64_MODEL_RECORD_BYTES   equ 00000020h
ENGINE64_VERTEX_BYTES         equ 00000006h
ENGINE64_FACE_BYTES           equ 00000004h
TEXTURE_CHUNK_HEADER_BYTES    equ 00000020h
TEXTURE_ATLAS_WIDTH           equ 00000100h
TEXTURE_ATLAS_HEIGHT          equ 00000100h
TEXTURE_TILE_SIZE             equ 00000020h
TEXTURE_TILE_COUNT            equ 00000040h
TEXTURE_ATLAS_BYTES           equ 00040000h
MATERIAL_CHUNK_HEADER_BYTES   equ 00000018h
MATERIAL_RECORD_BYTES         equ 00000010h
MESH_CHUNK_HEADER_BYTES       equ 00000020h
MESH_VERTEX_BYTES             equ 00000008h
MESH_TRIANGLE_BYTES           equ 00000010h
MAP_CHUNK_HEADER_BYTES        equ 00000020h
MAP_INSTANCE_BYTES            equ 00000010h
MAP_VOLUME_BYTES              equ 00000020h
MAP_VOLUME_WARDEN             equ 00000001h
MAP_VOLUME_TERMINAL           equ 00000002h
MAP_VOLUME_EXIT               equ 00000003h
RENDER_NEAR_PLANE             equ 00000020h
MATERIAL_FLAG_EMISSIVE        equ 00000001h
MATERIAL_FLAG_FOG             equ 00000002h
PRESENT_MODE_DIRECT           equ 00000000h
PRESENT_MODE_SWAP_RB          equ 00000001h
RENDER_STATUS_OK              equ 00000000h
RENDER_STATUS_NO_ENGINE       equ 00000001h
RENDER_STATUS_HEADER          equ 00000002h
RENDER_STATUS_FRAME_ARENA     equ 00000003h
PRESENT_STATUS_OK             equ 00000000h
PRESENT_STATUS_NO_FRAME       equ 00000001h
PRESENT_STATUS_GOP_SMALL      equ 00000002h
PRESENT_STATUS_FORMAT         equ 00000003h

UEFI_SCAN_UP                  equ 0001h
UEFI_SCAN_DOWN                equ 0002h
UEFI_SCAN_RIGHT               equ 0003h
UEFI_SCAN_LEFT                equ 0004h
UEFI_SCAN_ESC                 equ 0017h
INPUT_ACTION_NONE             equ 0000h
INPUT_ACTION_UP               equ 0001h
INPUT_ACTION_DOWN             equ 0002h
INPUT_ACTION_CONFIRM          equ 0003h
INPUT_ACTION_BACK             equ 0004h
INPUT_ACTION_FIRE             equ 0005h
MENU_MAX_SELECTION            equ 2
GAME_MODE_TITLE               equ 0000h
GAME_MODE_PLAY                equ 0001h
PLAYER_MIN_X                  equ 00000068h
PLAYER_MAX_X                  equ 00000218h
PLAYER_MIN_Y                  equ 000000D8h
PLAYER_MAX_Y                  equ 00000198h
PLAYER_WORLD_MIN_X            equ -000000B8h
PLAYER_WORLD_MAX_X            equ 000000B8h
PLAYER_WORLD_MIN_Z            equ 00000000h
PLAYER_WORLD_MAX_Z            equ 000001A4h
CROSSHAIR_MIN_X               equ 00000050h
CROSSHAIR_MAX_X               equ 00000230h
CROSSHAIR_MIN_Y               equ 00000070h
CROSSHAIR_MAX_Y               equ 00000170h

FILL_GOP_RECT MACRO RectX, RectY, RectW, RectH, RectColor
LOCAL row_loop, offset_ready
    mov eax, RectColor
    call ConvertXrgbToGop
    mov r11d, eax
    mov r10, qword ptr [GopFrameBase]
    mov edx, dword ptr [GopStride]
    mov eax, RectY
    mov ecx, RectX
    cmp dword ptr [DrawOffsetEnabled], 0
    je offset_ready
    add eax, dword ptr [DrawOffsetY]
    add ecx, dword ptr [DrawOffsetX]
offset_ready:
    imul rax, rdx
    add rax, rcx
    shl rax, 2
    lea rdi, [r10 + rax]
    mov r8d, RectH
    mov r9d, edx
    sub r9d, RectW
    shl r9, 2
row_loop:
    mov eax, r11d
    mov ecx, RectW
    rep stosd
    add rdi, r9
    dec r8d
    jnz row_loop
ENDM

DRAW_3D_LINE MACRO X0, Y0, Z0, X1, Y1, Z1, LineColor
    mov ecx, X0
    mov edx, Y0
    mov r8d, Z0
    call ProjectLevelPoint3D
    mov dword ptr [ProjectedX0], eax
    mov dword ptr [ProjectedY0], edx
    mov ecx, X1
    mov edx, Y1
    mov r8d, Z1
    call ProjectLevelPoint3D
    mov dword ptr [ProjectedX1], eax
    mov dword ptr [ProjectedY1], edx
    mov ecx, dword ptr [ProjectedX0]
    mov edx, dword ptr [ProjectedY0]
    mov r8d, dword ptr [ProjectedX1]
    mov r9d, dword ptr [ProjectedY1]
    mov eax, LineColor
    call DrawGopLine
ENDM

DRAW_3D_BOX MACRO MinX, MinY, NearZ, MaxX, MaxY, FarZ, LineColor
    DRAW_3D_LINE MinX, MinY, NearZ, MaxX, MinY, NearZ, LineColor
    DRAW_3D_LINE MaxX, MinY, NearZ, MaxX, MaxY, NearZ, LineColor
    DRAW_3D_LINE MaxX, MaxY, NearZ, MinX, MaxY, NearZ, LineColor
    DRAW_3D_LINE MinX, MaxY, NearZ, MinX, MinY, NearZ, LineColor
    DRAW_3D_LINE MinX, MinY, FarZ, MaxX, MinY, FarZ, LineColor
    DRAW_3D_LINE MaxX, MinY, FarZ, MaxX, MaxY, FarZ, LineColor
    DRAW_3D_LINE MaxX, MaxY, FarZ, MinX, MaxY, FarZ, LineColor
    DRAW_3D_LINE MinX, MaxY, FarZ, MinX, MinY, FarZ, LineColor
    DRAW_3D_LINE MinX, MinY, NearZ, MinX, MinY, FarZ, LineColor
    DRAW_3D_LINE MaxX, MinY, NearZ, MaxX, MinY, FarZ, LineColor
    DRAW_3D_LINE MaxX, MaxY, NearZ, MaxX, MaxY, FarZ, LineColor
    DRAW_3D_LINE MinX, MaxY, NearZ, MinX, MaxY, FarZ, LineColor
ENDM

DRAW_LEVEL_TRI MACRO X0, Y0, Z0, X1, Y1, Z1, X2, Y2, Z2, TriColor
    mov ecx, X0
    mov edx, Y0
    mov r8d, Z0
    call ProjectLevelPoint3D
    mov dword ptr [ProjectedX0], eax
    mov dword ptr [ProjectedY0], edx
    mov dword ptr [ProjectedZ0], r8d
    mov ecx, X1
    mov edx, Y1
    mov r8d, Z1
    call ProjectLevelPoint3D
    mov dword ptr [ProjectedX1], eax
    mov dword ptr [ProjectedY1], edx
    mov dword ptr [ProjectedZ1], r8d
    mov ecx, X2
    mov edx, Y2
    mov r8d, Z2
    call ProjectLevelPoint3D
    mov dword ptr [ProjectedX2], eax
    mov dword ptr [ProjectedY2], edx
    mov dword ptr [ProjectedZ2], r8d
    mov eax, TriColor
    call DrawProjectedTriangleDepth
ENDM

DRAW_LEVEL_QUAD MACRO X0, Y0, Z0, X1, Y1, Z1, X2, Y2, Z2, X3, Y3, Z3, QuadColor
    DRAW_LEVEL_TRI X0, Y0, Z0, X1, Y1, Z1, X2, Y2, Z2, QuadColor
    DRAW_LEVEL_TRI X0, Y0, Z0, X2, Y2, Z2, X3, Y3, Z3, QuadColor
ENDM

DRAW_LEVEL_BOX_FILLED MACRO MinX, MinY, NearZ, MaxX, MaxY, FarZ, BoxColor
    DRAW_LEVEL_QUAD MinX, MinY, NearZ, MaxX, MinY, NearZ, MaxX, MaxY, NearZ, MinX, MaxY, NearZ, BoxColor
    DRAW_LEVEL_QUAD MaxX, MinY, FarZ, MinX, MinY, FarZ, MinX, MaxY, FarZ, MaxX, MaxY, FarZ, BoxColor
    DRAW_LEVEL_QUAD MinX, MinY, FarZ, MinX, MinY, NearZ, MinX, MaxY, NearZ, MinX, MaxY, FarZ, BoxColor
    DRAW_LEVEL_QUAD MaxX, MinY, NearZ, MaxX, MinY, FarZ, MaxX, MaxY, FarZ, MaxX, MaxY, NearZ, BoxColor
    DRAW_LEVEL_QUAD MinX, MaxY, NearZ, MaxX, MaxY, NearZ, MaxX, MaxY, FarZ, MinX, MaxY, FarZ, BoxColor
    DRAW_LEVEL_QUAD MinX, MinY, FarZ, MaxX, MinY, FarZ, MaxX, MinY, NearZ, MinX, MinY, NearZ, BoxColor
ENDM

PUBLIC EfiMain

.code
EfiMain PROC
    push rbp
    mov rbp, rsp
    push rbx
    push rsi
    sub rsp, 20h

    test rdx, rdx
    jz done

    mov qword ptr [ImageHandle], rcx
    mov rbx, rdx
    mov rsi, qword ptr [rbx + EFI_SYSTEM_TABLE_BOOTSERV]
    test rsi, rsi
    jz done

    call TryClearFirmwareText

    lea rcx, EfiGraphicsOutputProtocolGuid
    xor edx, edx
    lea r8, GopProtocol
    call qword ptr [rsi + EFI_BOOT_SERVICES_LOCATE]
    test rax, rax
    jnz panic_no_gop

    mov rcx, qword ptr [GopProtocol]
    call InitGopState
    test eax, eax
    jnz panic_no_gop

    call InitPointerState

    call InitArenas
    test eax, eax
    jz arenas_ready

    lea r8, PanicArenaLine
    call DrawPanicScreen
    jmp stall_visible

arenas_ready:
IFDEF X64_FORCE_PANIC
    mov ecx, LOG_FAILURE_FORCED
    call WriteRuntimeLog
    lea r8, PanicForcedLine
    call DrawPanicScreen
    jmp stall_visible
ENDIF

    call LoadX64Pack
    call DrawActiveScreen
    mov ecx, dword ptr [PackStatusCode]
    call WriteRuntimeLog
    call RunInputLoop
    jmp done

panic_no_gop:
    lea rdx, PanicNoGopMessage
    call PrintFirmwareText

stall_visible:
    mov ecx, DIAGNOSTIC_STALL_USEC
    call qword ptr [rsi + EFI_BOOT_SERVICES_STALL]

done:
    xor eax, eax
    add rsp, 20h
    pop rsi
    pop rbx
    pop rbp
    ret
EfiMain ENDP

TryClearFirmwareText PROC
    push rcx
    push rax
    sub rsp, 20h

    mov rax, qword ptr [rbx + EFI_SYSTEM_TABLE_CONOUT]
    test rax, rax
    jz clear_done

    mov rcx, rax
    call qword ptr [rax + EFI_SIMPLE_TEXT_OUTPUT_CLEAR]

clear_done:
    add rsp, 20h
    pop rax
    pop rcx
    ret
TryClearFirmwareText ENDP

PrintFirmwareText PROC
    push rcx
    push rax
    sub rsp, 20h

    mov rax, qword ptr [rbx + EFI_SYSTEM_TABLE_CONOUT]
    test rax, rax
    jz text_done

    mov rcx, rax
    call qword ptr [rax + EFI_SIMPLE_TEXT_OUTPUT_TEXT]

text_done:
    add rsp, 20h
    pop rax
    pop rcx
    ret
PrintFirmwareText ENDP

InitGopState PROC
    test rcx, rcx
    jz init_fail

    mov r10, qword ptr [rcx + GOP_MODE_OFFSET]
    test r10, r10
    jz init_fail

    mov r11, qword ptr [r10 + GOP_MODE_INFO_OFFSET]
    test r11, r11
    jz init_fail

    mov eax, dword ptr [r11 + GOP_INFO_PIXEL_FORMAT_OFFSET]
    cmp eax, 3
    jae init_fail
    mov dword ptr [GopPixelFormat], eax

    mov dword ptr [GopRedMask], 00FF0000h
    mov dword ptr [GopGreenMask], 0000FF00h
    mov dword ptr [GopBlueMask], 000000FFh
    mov dword ptr [GopPresentMode], PRESENT_MODE_DIRECT

    cmp eax, 0
    je init_gop_rgb
    cmp eax, 1
    je init_gop_bgr

    mov eax, dword ptr [r11 + GOP_INFO_RED_MASK_OFFSET]
    mov dword ptr [GopRedMask], eax
    mov eax, dword ptr [r11 + GOP_INFO_GREEN_MASK_OFFSET]
    mov dword ptr [GopGreenMask], eax
    mov eax, dword ptr [r11 + GOP_INFO_BLUE_MASK_OFFSET]
    mov dword ptr [GopBlueMask], eax

    cmp dword ptr [GopRedMask], 00FF0000h
    jne init_mask_try_swap
    cmp dword ptr [GopGreenMask], 0000FF00h
    jne init_fail
    cmp dword ptr [GopBlueMask], 000000FFh
    jne init_fail
    jmp init_gop_mode_ready

init_mask_try_swap:
    cmp dword ptr [GopRedMask], 000000FFh
    jne init_fail
    cmp dword ptr [GopGreenMask], 0000FF00h
    jne init_fail
    cmp dword ptr [GopBlueMask], 00FF0000h
    jne init_fail
    mov dword ptr [GopPresentMode], PRESENT_MODE_SWAP_RB
    jmp init_gop_mode_ready

init_gop_rgb:
    mov dword ptr [GopRedMask], 000000FFh
    mov dword ptr [GopGreenMask], 0000FF00h
    mov dword ptr [GopBlueMask], 00FF0000h
    mov dword ptr [GopPresentMode], PRESENT_MODE_SWAP_RB
    jmp init_gop_mode_ready

init_gop_bgr:
    mov dword ptr [GopPresentMode], PRESENT_MODE_DIRECT

init_gop_mode_ready:

    mov eax, dword ptr [r11 + GOP_INFO_WIDTH_OFFSET]
    cmp eax, 640
    jb init_fail
    mov dword ptr [GopWidth], eax

    mov eax, dword ptr [r11 + GOP_INFO_HEIGHT_OFFSET]
    cmp eax, 480
    jb init_fail
    mov dword ptr [GopHeight], eax

    mov eax, dword ptr [r11 + GOP_INFO_STRIDE_OFFSET]
    test eax, eax
    jz init_fail
    mov dword ptr [GopStride], eax
    shl rax, 2
    mov qword ptr [GopStrideBytes], rax

    mov rax, qword ptr [r10 + GOP_MODE_FB_BASE_OFFSET]
    test rax, rax
    jz init_fail
    mov qword ptr [GopFrameBase], rax

    mov rax, qword ptr [r10 + GOP_MODE_FB_SIZE_OFFSET]
    mov qword ptr [GopFrameBytes], rax

    xor eax, eax
    ret

init_fail:
    mov eax, 1
    ret
InitGopState ENDP

InitPointerState PROC
    sub rsp, 20h

    mov dword ptr [PointerAvailable], 0
    mov qword ptr [SimplePointerProtocol], 0

    mov rax, qword ptr [rbx + EFI_SYSTEM_TABLE_BOOTSERV]
    test rax, rax
    jz pointer_init_done

    lea rcx, EfiSimplePointerProtocolGuid
    xor edx, edx
    lea r8, SimplePointerProtocol
    call qword ptr [rax + EFI_BOOT_SERVICES_LOCATE]
    test rax, rax
    jnz pointer_init_done

    cmp qword ptr [SimplePointerProtocol], 0
    je pointer_init_done

    mov dword ptr [PointerAvailable], 1

pointer_init_done:
    add rsp, 20h
    ret
InitPointerState ENDP

InitArenas PROC
    sub rsp, 20h

    mov qword ptr [ArenaBase], 0
    xor ecx, ecx
    mov edx, EFI_LOADER_DATA
    mov r8d, ARENA_TOTAL_PAGES
    lea r9, ArenaBase
    call qword ptr [rsi + EFI_BOOT_SERVICES_ALLOC_PAGES]
    test rax, rax
    jnz arena_fail

    mov rax, qword ptr [ArenaBase]
    mov qword ptr [ArenaAllocBase], rax
    mov rcx, rax
    add rcx, ARENA_TOTAL_BYTES
    mov qword ptr [ArenaAllocEnd], rcx

    add rax, 0FFFFh
    and rax, ARENA_ALIGN_MASK
    mov qword ptr [ArenaBase], rax

    mov qword ptr [EngineArenaBase], rax
    mov qword ptr [EngineArenaSize], ARENA_ENGINE_BYTES
    mov qword ptr [EngineArenaUsed], 0
    add rax, ARENA_ENGINE_BYTES
    add rax, 0FFFFh
    and rax, ARENA_ALIGN_MASK

    mov qword ptr [FrameArenaBase], rax
    mov qword ptr [FrameArenaSize], ARENA_FRAME_BYTES
    mov qword ptr [FrameArenaUsed], 0
    add rax, ARENA_FRAME_BYTES
    add rax, 0FFFFh
    and rax, ARENA_ALIGN_MASK

    mov qword ptr [DepthArenaBase], rax
    mov qword ptr [DepthArenaSize], ARENA_DEPTH_BYTES
    mov qword ptr [DepthArenaUsed], 0
    add rax, ARENA_DEPTH_BYTES
    add rax, 0FFFFh
    and rax, ARENA_ALIGN_MASK

    mov qword ptr [TextureArenaBase], rax
    mov qword ptr [TextureArenaSize], ARENA_TEXTURE_BYTES
    mov qword ptr [TextureArenaUsed], 0
    add rax, ARENA_TEXTURE_BYTES
    add rax, 0FFFFh
    and rax, ARENA_ALIGN_MASK

    mov qword ptr [MeshArenaBase], rax
    mov qword ptr [MeshArenaSize], ARENA_MESH_BYTES
    mov qword ptr [MeshArenaUsed], 0
    add rax, ARENA_MESH_BYTES
    add rax, 0FFFFh
    and rax, ARENA_ALIGN_MASK

    mov qword ptr [AudioArenaBase], rax
    mov qword ptr [AudioArenaSize], ARENA_AUDIO_BYTES
    mov qword ptr [AudioArenaUsed], 0
    add rax, ARENA_AUDIO_BYTES
    add rax, 0FFFFh
    and rax, ARENA_ALIGN_MASK

    mov qword ptr [ScratchArenaBase], rax
    mov qword ptr [ScratchArenaSize], ARENA_SCRATCH_BYTES
    mov qword ptr [ScratchArenaUsed], 0
    add rax, ARENA_SCRATCH_BYTES
    add rax, 0FFFFh
    and rax, ARENA_ALIGN_MASK

    mov qword ptr [LogArenaBase], rax
    mov qword ptr [LogArenaSize], ARENA_LOG_BYTES
    mov qword ptr [LogArenaUsed], 0
    add rax, ARENA_LOG_BYTES
    mov qword ptr [ArenaEnd], rax

    cmp rax, qword ptr [ArenaAllocEnd]
    ja arena_fail

    mov qword ptr [EngineArenaFree], ARENA_ENGINE_BYTES
    mov qword ptr [FrameArenaFree], ARENA_FRAME_BYTES
    mov qword ptr [DepthArenaFree], ARENA_DEPTH_BYTES
    mov qword ptr [TextureArenaFree], ARENA_TEXTURE_BYTES
    mov qword ptr [MeshArenaFree], ARENA_MESH_BYTES
    mov qword ptr [AudioArenaFree], ARENA_AUDIO_BYTES
    mov qword ptr [ScratchArenaFree], ARENA_SCRATCH_BYTES
    mov qword ptr [LogArenaFree], ARENA_LOG_BYTES

    xor eax, eax
    add rsp, 20h
    ret

arena_fail:
    mov eax, 1
    add rsp, 20h
    ret
InitArenas ENDP

WriteRuntimeLog PROC
    mov rax, qword ptr [LogArenaBase]
    test rax, rax
    jz log_done

    mov dword ptr [rax], 34365343h
    mov dword ptr [rax + 4], 30474F4Ch
    mov dword ptr [rax + 8], LOG_MILESTONE_BOOT
    mov dword ptr [rax + 12], ecx

    mov rcx, qword ptr [GopFrameBase]
    mov qword ptr [rax + 16], rcx
    mov rcx, qword ptr [ArenaBase]
    mov qword ptr [rax + 24], rcx
    mov rcx, qword ptr [ArenaEnd]
    mov qword ptr [rax + 32], rcx
    mov rcx, qword ptr [FrameArenaBase]
    mov qword ptr [rax + 40], rcx
    mov rcx, qword ptr [DepthArenaBase]
    mov qword ptr [rax + 48], rcx
    mov rcx, qword ptr [LogArenaBase]
    mov qword ptr [rax + 56], rcx
    mov ecx, dword ptr [PackStatusCode]
    mov dword ptr [rax + 64], ecx
    mov ecx, dword ptr [PackReadBytes]
    mov dword ptr [rax + 68], ecx
    mov ecx, dword ptr [PackLoadedChunks]
    mov dword ptr [rax + 72], ecx
    mov ecx, dword ptr [PackChunkMask]
    mov dword ptr [rax + 76], ecx
    mov ecx, dword ptr [Engine64Status]
    mov dword ptr [rax + 80], ecx
    mov ecx, dword ptr [Engine64PayloadBytes]
    mov dword ptr [rax + 84], ecx
    mov ecx, dword ptr [Engine64Width]
    mov dword ptr [rax + 88], ecx
    mov ecx, dword ptr [Engine64Height]
    mov dword ptr [rax + 92], ecx
    mov ecx, dword ptr [Engine64BarCount]
    mov dword ptr [rax + 96], ecx
    mov ecx, dword ptr [Engine64FeatureFlags]
    mov dword ptr [rax + 100], ecx
    mov ecx, dword ptr [PackStagedChunks]
    mov dword ptr [rax + 104], ecx
    mov ecx, dword ptr [PackStagedBytes]
    mov dword ptr [rax + 108], ecx
    mov ecx, dword ptr [PackStageMask]
    mov dword ptr [rax + 112], ecx
    mov ecx, dword ptr [RenderStatus]
    mov dword ptr [rax + 116], ecx
    mov ecx, dword ptr [PresentStatus]
    mov dword ptr [rax + 120], ecx
    mov ecx, dword ptr [PresentFramePixels]
    mov dword ptr [rax + 124], ecx

    mov qword ptr [LogArenaUsed], LOG_RECORD_BYTES
    mov qword ptr [LogArenaFree], ARENA_LOG_BYTES - LOG_RECORD_BYTES

log_done:
    ret
WriteRuntimeLog ENDP

LoadX64Pack PROC
    push rdi
    push r12
    push r13
    push r14
    push r15
    sub rsp, 30h

    mov dword ptr [PackStatusCode], PACK_STATUS_OK
    mov dword ptr [PackReadBytes], 0
    mov dword ptr [PackLoadedChunks], 0
    mov dword ptr [PackChunkMask], 0
    mov dword ptr [PackStagedChunks], 0
    mov dword ptr [PackStagedBytes], 0
    mov dword ptr [PackStageMask], 0
    mov dword ptr [Engine64Status], 0
    mov dword ptr [Engine64PayloadBytes], 0
    mov dword ptr [Engine64Width], 0
    mov dword ptr [Engine64Height], 0
    mov dword ptr [Engine64BarCount], 0
    mov dword ptr [Engine64FeatureFlags], 0
    mov dword ptr [Engine64ModelTableOffset], 0
    mov dword ptr [Engine64ModelCount], 0
    mov dword ptr [Engine64ModelRecordBytes], 0
    mov qword ptr [Engine64ChunkBase], 0
    mov dword ptr [Engine64ChunkBytes], 0
    mov qword ptr [TextureChunkBase], 0
    mov dword ptr [TextureChunkBytes], 0
    mov qword ptr [TextureAtlasPixels], 0
    mov dword ptr [TextureAtlasBytes], 0
    mov qword ptr [MaterialChunkBase], 0
    mov dword ptr [MaterialChunkBytes], 0
    mov qword ptr [MaterialRecordBase], 0
    mov dword ptr [MaterialCount], 0
    mov qword ptr [MeshChunkBase], 0
    mov dword ptr [MeshChunkBytes], 0
    mov qword ptr [MeshVertexBase], 0
    mov qword ptr [MeshTriangleBase], 0
    mov dword ptr [MeshVertexCount], 0
    mov dword ptr [MeshTriangleCount], 0
    mov qword ptr [MapChunkBase], 0
    mov dword ptr [MapChunkBytes], 0
    mov qword ptr [MapInstanceBase], 0
    mov qword ptr [MapVolumeBase], 0
    mov dword ptr [MapInstanceCount], 0
    mov dword ptr [MapVolumeCount], 0
    mov dword ptr [AssetValidationStatus], 0
    mov dword ptr [RenderStatus], RENDER_STATUS_NO_ENGINE
    mov dword ptr [PresentStatus], PRESENT_STATUS_NO_FRAME
    mov dword ptr [RenderFramePixels], 0
    mov dword ptr [PresentFramePixels], 0
    mov qword ptr [LoadedImageProtocol], 0
    mov qword ptr [FileSystemProtocol], 0
    mov qword ptr [RootFileProtocol], 0
    mov qword ptr [PackFileProtocol], 0

    mov rcx, qword ptr [ImageHandle]
    test rcx, rcx
    jz pack_fail_image_protocol

    lea rdx, EfiLoadedImageProtocolGuid
    lea r8, LoadedImageProtocol
    call qword ptr [rsi + EFI_BOOT_SERVICES_HANDLE_PROTOCOL]
    test rax, rax
    jnz pack_fail_image_protocol

    mov r12, qword ptr [LoadedImageProtocol]
    test r12, r12
    jz pack_fail_image_protocol

    mov rcx, qword ptr [r12 + EFI_LOADED_IMAGE_DEVICE_HANDLE]
    test rcx, rcx
    jz pack_fail_image_protocol

    lea rdx, EfiSimpleFileSystemProtocolGuid
    lea r8, FileSystemProtocol
    call qword ptr [rsi + EFI_BOOT_SERVICES_HANDLE_PROTOCOL]
    test rax, rax
    jnz pack_fail_fs_protocol

    mov r12, qword ptr [FileSystemProtocol]
    test r12, r12
    jz pack_fail_fs_protocol

    mov rcx, r12
    lea rdx, RootFileProtocol
    call qword ptr [r12 + EFI_SIMPLE_FILE_SYSTEM_OPEN_VOLUME]
    test rax, rax
    jnz pack_fail_open_volume

    mov r12, qword ptr [RootFileProtocol]
    test r12, r12
    jz pack_fail_open_volume

    mov rcx, r12
    lea rdx, PackFileProtocol
    lea r8, PackFileName
    mov r9d, EFI_FILE_MODE_READ
    mov qword ptr [rsp + 20h], 0
    call qword ptr [r12 + EFI_FILE_OPEN]
    test rax, rax
    jnz pack_fail_open_file

    mov qword ptr [PackReadSize], PACK_READ_MAX_BYTES
    mov rcx, qword ptr [PackFileProtocol]
    lea rdx, PackReadSize
    mov r8, qword ptr [ScratchArenaBase]
    call qword ptr [rcx + EFI_FILE_READ]
    test rax, rax
    jnz pack_fail_read

    mov eax, dword ptr [PackReadSize]
    mov dword ptr [PackReadBytes], eax

    mov rcx, qword ptr [PackFileProtocol]
    test rcx, rcx
    jz pack_after_file_close
    call qword ptr [rcx + EFI_FILE_CLOSE]
    mov qword ptr [PackFileProtocol], 0

pack_after_file_close:
    mov rcx, qword ptr [RootFileProtocol]
    test rcx, rcx
    jz pack_after_root_close
    call qword ptr [rcx + EFI_FILE_CLOSE]
    mov qword ptr [RootFileProtocol], 0

pack_after_root_close:
    call ValidateX64Pack
    test eax, eax
    jnz pack_fail_validation
    jmp pack_done

pack_fail_image_protocol:
    mov dword ptr [PackStatusCode], PACK_STATUS_IMAGE_PROTOCOL
    jmp pack_cleanup

pack_fail_fs_protocol:
    mov dword ptr [PackStatusCode], PACK_STATUS_FS_PROTOCOL
    jmp pack_cleanup

pack_fail_open_volume:
    mov dword ptr [PackStatusCode], PACK_STATUS_OPEN_VOLUME
    jmp pack_cleanup

pack_fail_open_file:
    mov dword ptr [PackStatusCode], PACK_STATUS_OPEN_FILE
    jmp pack_cleanup

pack_fail_read:
    mov dword ptr [PackStatusCode], PACK_STATUS_READ
    jmp pack_cleanup

pack_fail_validation:
    jmp pack_cleanup

pack_cleanup:
    mov rcx, qword ptr [PackFileProtocol]
    test rcx, rcx
    jz pack_cleanup_root
    call qword ptr [rcx + EFI_FILE_CLOSE]
    mov qword ptr [PackFileProtocol], 0

pack_cleanup_root:
    mov rcx, qword ptr [RootFileProtocol]
    test rcx, rcx
    jz pack_done
    call qword ptr [rcx + EFI_FILE_CLOSE]
    mov qword ptr [RootFileProtocol], 0

pack_done:
    add rsp, 30h
    pop r15
    pop r14
    pop r13
    pop r12
    pop rdi
    ret
LoadX64Pack ENDP

ValidateX64Pack PROC
    push rdi
    push r12
    push r13
    push r14
    push r15

    mov rdi, qword ptr [ScratchArenaBase]
    test rdi, rdi
    jz validate_header_fail

    cmp dword ptr [PackReadBytes], PACK_HEADER_BYTES
    jb validate_header_fail

    mov r11, qword ptr [PackMagicValue]
    cmp qword ptr [rdi], r11
    jne validate_magic_fail

    cmp dword ptr [rdi + 8], 1
    jne validate_header_fail
    cmp dword ptr [rdi + 12], PACK_EXPECTED_CHUNKS
    jne validate_header_fail
    cmp dword ptr [rdi + 16], PACK_RECORD_BYTES
    jne validate_header_fail
    cmp dword ptr [rdi + 20], PACK_HEADER_BYTES
    jne validate_header_fail
    mov eax, dword ptr [PackReadBytes]
    cmp dword ptr [rdi + 24], eax
    jne validate_header_fail

    xor r12d, r12d
    mov r13d, PACK_EXPECTED_CHUNKS
    lea r14, [rdi + PACK_HEADER_BYTES]
    mov r15d, dword ptr [PackReadBytes]

validate_loop:
    cmp r12d, r13d
    jae validate_mask

    mov eax, dword ptr [r14 + 8]
    mov ecx, dword ptr [r14 + 12]
    cmp eax, PACK_HEADER_BYTES
    jb validate_bounds_fail
    test ecx, ecx
    jz validate_bounds_fail

    mov edx, eax
    add edx, ecx
    jc validate_bounds_fail
    cmp edx, r15d
    ja validate_bounds_fail

    cmp dword ptr [r14 + 28], 00001000h
    jne validate_header_fail

    mov rdx, qword ptr [ScratchArenaBase]
    add rdx, rax
    call ComputeFnv1a32
    cmp eax, dword ptr [r14 + 24]
    jne validate_checksum_fail

    mov rax, qword ptr [r14]
    call GetPackChunkBit
    test eax, eax
    jz validate_chunk_fail
    mov r10d, eax

    cmp r10d, 00000001h
    jne validate_not_engine64
    mov edx, dword ptr [r14 + 8]
    mov ecx, dword ptr [r14 + 12]
    mov r11, qword ptr [ScratchArenaBase]
    add rdx, r11
    call ValidateEngine64Chunk
    test eax, eax
    jnz validate_engine64_fail

validate_not_engine64:
    push r10
    mov edx, dword ptr [r14 + 8]
    mov ecx, dword ptr [r14 + 12]
    mov r11, qword ptr [ScratchArenaBase]
    add rdx, r11
    mov r8d, r10d
    call StageX64Chunk
    pop r10
    test eax, eax
    jnz validate_stage_fail

    or dword ptr [PackChunkMask], r10d
    inc dword ptr [PackLoadedChunks]

    add r14, PACK_RECORD_BYTES
    inc r12d
    jmp validate_loop

validate_mask:
    cmp dword ptr [PackChunkMask], PACK_EXPECTED_MASK
    jne validate_mask_fail
    cmp dword ptr [PackStageMask], PACK_EXPECTED_MASK
    jne validate_stage_fail
    call ValidateX64AssetChunks
    test eax, eax
    jnz validate_asset_fail
    xor eax, eax
    jmp validate_done

validate_magic_fail:
    mov dword ptr [PackStatusCode], PACK_STATUS_MAGIC
    mov eax, 1
    jmp validate_done

validate_header_fail:
    mov dword ptr [PackStatusCode], PACK_STATUS_HEADER
    mov eax, 1
    jmp validate_done

validate_bounds_fail:
    mov dword ptr [PackStatusCode], PACK_STATUS_BOUNDS
    mov eax, 1
    jmp validate_done

validate_checksum_fail:
    mov dword ptr [PackStatusCode], PACK_STATUS_CHECKSUM
    mov eax, 1
    jmp validate_done

validate_chunk_fail:
    mov dword ptr [PackStatusCode], PACK_STATUS_CHUNK_ID
    mov eax, 1
    jmp validate_done

validate_engine64_fail:
    mov dword ptr [PackStatusCode], PACK_STATUS_ENGINE64
    mov eax, 1
    jmp validate_done

validate_stage_fail:
    mov dword ptr [PackStatusCode], PACK_STATUS_STAGE
    mov eax, 1
    jmp validate_done

validate_mask_fail:
    mov dword ptr [PackStatusCode], PACK_STATUS_CHUNK_MASK
    mov eax, 1
    jmp validate_done

validate_asset_fail:
    mov dword ptr [PackStatusCode], PACK_STATUS_ASSET
    mov eax, 1

validate_done:
    pop r15
    pop r14
    pop r13
    pop r12
    pop rdi
    ret
ValidateX64Pack ENDP

ValidateEngine64Chunk PROC
    cmp ecx, ENGINE64_MIN_BYTES
    jb engine64_fail

    mov dword ptr [Engine64PayloadBytes], ecx

    mov r11, qword ptr [Engine64MagicValue]
    cmp qword ptr [rdx], r11
    jne engine64_fail

    cmp dword ptr [rdx + 8], 00000001h
    jne engine64_fail

    mov eax, dword ptr [rdx + 12]
    mov dword ptr [Engine64Width], eax
    cmp eax, ENGINE64_EXPECTED_WIDTH
    jne engine64_fail

    mov eax, dword ptr [rdx + 16]
    mov dword ptr [Engine64Height], eax
    cmp eax, ENGINE64_EXPECTED_HEIGHT
    jne engine64_fail

    mov eax, dword ptr [rdx + 20]
    mov dword ptr [Engine64BarCount], eax
    test eax, eax
    jz engine64_fail
    cmp eax, 16
    ja engine64_fail

    mov eax, dword ptr [rdx + 24]
    mov dword ptr [Engine64FeatureFlags], eax

    mov eax, dword ptr [rdx + 28]
    cmp eax, ENGINE64_MIN_BYTES - 32
    jb engine64_fail
    cmp eax, ecx
    jae engine64_fail
    mov r11d, eax
    mov eax, dword ptr [Engine64BarCount]
    shl eax, 2
    add eax, r11d
    jc engine64_fail
    cmp eax, ecx
    ja engine64_fail

    mov eax, dword ptr [rdx + ENGINE64_MODEL_TABLE_FIELD]
    mov dword ptr [Engine64ModelTableOffset], eax
    mov eax, dword ptr [rdx + ENGINE64_MODEL_COUNT_FIELD]
    mov dword ptr [Engine64ModelCount], eax
    mov eax, dword ptr [rdx + ENGINE64_MODEL_RECORD_FIELD]
    mov dword ptr [Engine64ModelRecordBytes], eax

    mov r8d, dword ptr [Engine64ModelCount]
    test r8d, r8d
    jz engine64_valid
    cmp r8d, 8
    ja engine64_fail
    cmp dword ptr [Engine64ModelRecordBytes], ENGINE64_MODEL_RECORD_BYTES
    jne engine64_fail

    mov r9d, dword ptr [Engine64ModelTableOffset]
    cmp r9d, ENGINE64_MIN_BYTES
    jb engine64_fail
    cmp r9d, ecx
    jae engine64_fail
    mov eax, r8d
    imul eax, eax, ENGINE64_MODEL_RECORD_BYTES
    add eax, r9d
    jc engine64_fail
    cmp eax, ecx
    ja engine64_fail

    xor r8d, r8d

engine64_model_loop:
    cmp r8d, dword ptr [Engine64ModelCount]
    jae engine64_valid

    mov r9d, r8d
    shl r9d, 5
    add r9d, dword ptr [Engine64ModelTableOffset]

    mov r10d, dword ptr [rdx + r9 + 8]
    cmp r10d, ENGINE64_MIN_BYTES
    jb engine64_fail
    cmp r10d, ecx
    jae engine64_fail
    mov r11d, dword ptr [rdx + r9 + 12]
    test r11d, r11d
    jz engine64_fail
    cmp r11d, 64
    ja engine64_fail
    mov eax, r11d
    imul eax, eax, ENGINE64_VERTEX_BYTES
    add eax, r10d
    jc engine64_fail
    cmp eax, ecx
    ja engine64_fail

    mov r10d, dword ptr [rdx + r9 + 16]
    cmp r10d, ENGINE64_MIN_BYTES
    jb engine64_fail
    cmp r10d, ecx
    jae engine64_fail
    mov r11d, dword ptr [rdx + r9 + 20]
    test r11d, r11d
    jz engine64_fail
    cmp r11d, 128
    ja engine64_fail
    mov eax, r11d
    imul eax, eax, ENGINE64_FACE_BYTES
    add eax, r10d
    jc engine64_fail
    cmp eax, ecx
    ja engine64_fail

    inc r8d
    jmp engine64_model_loop

engine64_valid:
    mov dword ptr [Engine64Status], 0
    xor eax, eax
    ret

engine64_fail:
    mov dword ptr [Engine64Status], PACK_STATUS_ENGINE64
    mov eax, 1
    ret
ValidateEngine64Chunk ENDP

ValidateX64AssetChunks PROC
    call ValidateTextureChunk
    test eax, eax
    jnz validate_assets_fail
    call ValidateMaterialChunk
    test eax, eax
    jnz validate_assets_fail
    call ValidateMeshChunk
    test eax, eax
    jnz validate_assets_fail
    call ValidateMapChunk
    test eax, eax
    jnz validate_assets_fail

    mov dword ptr [AssetValidationStatus], 0
    xor eax, eax
    ret

validate_assets_fail:
    mov dword ptr [AssetValidationStatus], PACK_STATUS_ASSET
    mov eax, 1
    ret
ValidateX64AssetChunks ENDP

ValidateTextureChunk PROC
    mov rdx, qword ptr [TextureChunkBase]
    test rdx, rdx
    jz texture_chunk_fail
    mov ecx, dword ptr [TextureChunkBytes]
    cmp ecx, TEXTURE_CHUNK_HEADER_BYTES + TEXTURE_ATLAS_BYTES
    jb texture_chunk_fail

    mov rax, qword ptr [TextureChunkMagic]
    cmp qword ptr [rdx], rax
    jne texture_chunk_fail
    cmp dword ptr [rdx + 8], 1
    jne texture_chunk_fail
    cmp dword ptr [rdx + 12], TEXTURE_ATLAS_WIDTH
    jne texture_chunk_fail
    cmp dword ptr [rdx + 16], TEXTURE_ATLAS_HEIGHT
    jne texture_chunk_fail
    cmp dword ptr [rdx + 20], TEXTURE_TILE_SIZE
    jne texture_chunk_fail
    cmp dword ptr [rdx + 24], TEXTURE_TILE_COUNT
    jne texture_chunk_fail
    cmp dword ptr [rdx + 28], 0
    jne texture_chunk_fail

    lea rax, [rdx + TEXTURE_CHUNK_HEADER_BYTES]
    mov qword ptr [TextureAtlasPixels], rax
    mov dword ptr [TextureAtlasBytes], TEXTURE_ATLAS_BYTES
    xor eax, eax
    ret

texture_chunk_fail:
    mov eax, 1
    ret
ValidateTextureChunk ENDP

ValidateMaterialChunk PROC
    mov rdx, qword ptr [MaterialChunkBase]
    test rdx, rdx
    jz material_chunk_fail
    mov ecx, dword ptr [MaterialChunkBytes]
    cmp ecx, MATERIAL_CHUNK_HEADER_BYTES
    jb material_chunk_fail

    mov rax, qword ptr [MaterialChunkMagic]
    cmp qword ptr [rdx], rax
    jne material_chunk_fail
    cmp dword ptr [rdx + 8], 1
    jne material_chunk_fail
    mov r8d, dword ptr [rdx + 12]
    test r8d, r8d
    jz material_chunk_fail
    cmp r8d, 64
    ja material_chunk_fail
    cmp dword ptr [rdx + 16], MATERIAL_RECORD_BYTES
    jne material_chunk_fail

    mov eax, r8d
    imul eax, eax, MATERIAL_RECORD_BYTES
    add eax, MATERIAL_CHUNK_HEADER_BYTES
    jc material_chunk_fail
    cmp eax, ecx
    ja material_chunk_fail

    lea rax, [rdx + MATERIAL_CHUNK_HEADER_BYTES]
    mov qword ptr [MaterialRecordBase], rax
    mov dword ptr [MaterialCount], r8d

    xor r9d, r9d
material_validate_loop:
    cmp r9d, r8d
    jae material_valid
    mov eax, r9d
    imul eax, eax, MATERIAL_RECORD_BYTES
    mov r10, qword ptr [MaterialRecordBase]
    add r10, rax
    mov eax, dword ptr [r10 + 4]
    cmp eax, TEXTURE_TILE_COUNT
    jae material_chunk_fail
    inc r9d
    jmp material_validate_loop

material_valid:
    xor eax, eax
    ret

material_chunk_fail:
    mov eax, 1
    ret
ValidateMaterialChunk ENDP

ValidateMeshChunk PROC
    mov rdx, qword ptr [MeshChunkBase]
    test rdx, rdx
    jz mesh_chunk_fail
    mov ecx, dword ptr [MeshChunkBytes]
    cmp ecx, MESH_CHUNK_HEADER_BYTES
    jb mesh_chunk_fail

    mov rax, qword ptr [MeshChunkMagic]
    cmp qword ptr [rdx], rax
    jne mesh_chunk_fail
    cmp dword ptr [rdx + 8], 1
    jne mesh_chunk_fail

    mov r8d, dword ptr [rdx + 12]
    test r8d, r8d
    jz mesh_chunk_fail
    cmp r8d, 2048
    ja mesh_chunk_fail
    mov r9d, dword ptr [rdx + 16]
    test r9d, r9d
    jz mesh_chunk_fail
    cmp r9d, 4096
    ja mesh_chunk_fail

    mov r10d, dword ptr [rdx + 20]
    cmp r10d, MESH_CHUNK_HEADER_BYTES
    jb mesh_chunk_fail
    cmp r10d, ecx
    jae mesh_chunk_fail
    mov eax, r8d
    imul eax, eax, MESH_VERTEX_BYTES
    add eax, r10d
    jc mesh_chunk_fail
    cmp eax, ecx
    ja mesh_chunk_fail

    mov r11d, dword ptr [rdx + 24]
    cmp r11d, MESH_CHUNK_HEADER_BYTES
    jb mesh_chunk_fail
    cmp r11d, ecx
    jae mesh_chunk_fail
    mov eax, r9d
    imul eax, eax, MESH_TRIANGLE_BYTES
    add eax, r11d
    jc mesh_chunk_fail
    cmp eax, ecx
    ja mesh_chunk_fail

    lea rax, [rdx + r10]
    mov qword ptr [MeshVertexBase], rax
    lea rax, [rdx + r11]
    mov qword ptr [MeshTriangleBase], rax
    mov dword ptr [MeshVertexCount], r8d
    mov dword ptr [MeshTriangleCount], r9d

    xor r12d, r12d
mesh_validate_loop:
    cmp r12d, r9d
    jae mesh_valid
    mov eax, r12d
    imul eax, eax, MESH_TRIANGLE_BYTES
    mov r10, qword ptr [MeshTriangleBase]
    add r10, rax

    movzx eax, word ptr [r10]
    cmp eax, r8d
    jae mesh_chunk_fail
    movzx ecx, word ptr [r10 + 2]
    cmp ecx, r8d
    jae mesh_chunk_fail
    movzx edx, word ptr [r10 + 4]
    cmp edx, r8d
    jae mesh_chunk_fail
    cmp eax, ecx
    je mesh_chunk_fail
    cmp eax, edx
    je mesh_chunk_fail
    cmp ecx, edx
    je mesh_chunk_fail
    movzx eax, word ptr [r10 + 6]
    cmp eax, dword ptr [MaterialCount]
    jae mesh_chunk_fail

    inc r12d
    jmp mesh_validate_loop

mesh_valid:
    xor eax, eax
    ret

mesh_chunk_fail:
    mov eax, 1
    ret
ValidateMeshChunk ENDP

ValidateMapChunk PROC
    mov rdx, qword ptr [MapChunkBase]
    test rdx, rdx
    jz map_chunk_fail
    mov ecx, dword ptr [MapChunkBytes]
    cmp ecx, MAP_CHUNK_HEADER_BYTES
    jb map_chunk_fail

    mov rax, qword ptr [MapChunkMagic]
    cmp qword ptr [rdx], rax
    jne map_chunk_fail
    cmp dword ptr [rdx + 8], 1
    jne map_chunk_fail

    mov r8d, dword ptr [rdx + 12]
    test r8d, r8d
    jz map_chunk_fail
    cmp r8d, 16
    ja map_chunk_fail
    mov r9d, dword ptr [rdx + 16]
    test r9d, r9d
    jz map_chunk_fail
    cmp r9d, 32
    ja map_chunk_fail

    mov r10d, dword ptr [rdx + 20]
    cmp r10d, MAP_CHUNK_HEADER_BYTES
    jb map_chunk_fail
    cmp r10d, ecx
    jae map_chunk_fail
    mov eax, r8d
    imul eax, eax, MAP_INSTANCE_BYTES
    add eax, r10d
    jc map_chunk_fail
    cmp eax, ecx
    ja map_chunk_fail

    mov r11d, dword ptr [rdx + 24]
    cmp r11d, MAP_CHUNK_HEADER_BYTES
    jb map_chunk_fail
    cmp r11d, ecx
    jae map_chunk_fail
    mov eax, r9d
    imul eax, eax, MAP_VOLUME_BYTES
    add eax, r11d
    jc map_chunk_fail
    cmp eax, ecx
    ja map_chunk_fail

    lea rax, [rdx + r10]
    mov qword ptr [MapInstanceBase], rax
    lea rax, [rdx + r11]
    mov qword ptr [MapVolumeBase], rax
    mov dword ptr [MapInstanceCount], r8d
    mov dword ptr [MapVolumeCount], r9d

    xor r12d, r12d
map_validate_loop:
    cmp r12d, r9d
    jae map_valid
    mov eax, r12d
    imul eax, eax, MAP_VOLUME_BYTES
    mov r10, qword ptr [MapVolumeBase]
    add r10, rax

    mov eax, dword ptr [r10]
    cmp eax, MAP_VOLUME_WARDEN
    jb map_chunk_fail
    cmp eax, MAP_VOLUME_EXIT
    ja map_chunk_fail
    mov eax, dword ptr [r10 + 4]
    cmp eax, dword ptr [r10 + 16]
    jge map_chunk_fail
    mov eax, dword ptr [r10 + 8]
    cmp eax, dword ptr [r10 + 20]
    jge map_chunk_fail
    mov eax, dword ptr [r10 + 12]
    cmp eax, dword ptr [r10 + 24]
    jge map_chunk_fail

    inc r12d
    jmp map_validate_loop

map_valid:
    xor eax, eax
    ret

map_chunk_fail:
    mov eax, 1
    ret
ValidateMapChunk ENDP

StageX64Chunk PROC
    push rbx
    push rsi
    push rdi

    mov ebx, ecx
    test ebx, ebx
    jz stage_fail

    cmp r8d, 00000001h
    je stage_engine
    cmp r8d, 00000002h
    je stage_texture
    cmp r8d, 00000008h
    je stage_texture
    cmp r8d, 00000040h
    je stage_audio
    jmp stage_mesh

stage_engine:
    mov rax, qword ptr [EngineArenaUsed]
    mov r9, qword ptr [EngineArenaSize]
    add rax, rbx
    cmp rax, r9
    ja stage_fail
    mov rdi, qword ptr [EngineArenaBase]
    add rdi, qword ptr [EngineArenaUsed]
    mov qword ptr [Engine64ChunkBase], rdi
    mov dword ptr [Engine64ChunkBytes], ebx
    mov rsi, rdx
    mov ecx, ebx
    rep movsb
    mov qword ptr [EngineArenaUsed], rax
    mov r9, qword ptr [EngineArenaSize]
    sub r9, rax
    mov qword ptr [EngineArenaFree], r9
    jmp stage_ok

stage_texture:
    mov rax, qword ptr [TextureArenaUsed]
    mov r9, qword ptr [TextureArenaSize]
    add rax, rbx
    cmp rax, r9
    ja stage_fail
    mov rdi, qword ptr [TextureArenaBase]
    add rdi, qword ptr [TextureArenaUsed]
    cmp r8d, 00000002h
    jne stage_material_record
    mov qword ptr [TextureChunkBase], rdi
    mov dword ptr [TextureChunkBytes], ebx
    jmp stage_texture_copy

stage_material_record:
    cmp r8d, 00000008h
    jne stage_texture_copy
    mov qword ptr [MaterialChunkBase], rdi
    mov dword ptr [MaterialChunkBytes], ebx

stage_texture_copy:
    mov rsi, rdx
    mov ecx, ebx
    rep movsb
    mov qword ptr [TextureArenaUsed], rax
    mov r9, qword ptr [TextureArenaSize]
    sub r9, rax
    mov qword ptr [TextureArenaFree], r9
    jmp stage_ok

stage_audio:
    mov rax, qword ptr [AudioArenaUsed]
    mov r9, qword ptr [AudioArenaSize]
    add rax, rbx
    cmp rax, r9
    ja stage_fail
    mov rdi, qword ptr [AudioArenaBase]
    add rdi, qword ptr [AudioArenaUsed]
    mov rsi, rdx
    mov ecx, ebx
    rep movsb
    mov qword ptr [AudioArenaUsed], rax
    mov r9, qword ptr [AudioArenaSize]
    sub r9, rax
    mov qword ptr [AudioArenaFree], r9
    jmp stage_ok

stage_mesh:
    mov rax, qword ptr [MeshArenaUsed]
    mov r9, qword ptr [MeshArenaSize]
    add rax, rbx
    cmp rax, r9
    ja stage_fail
    mov rdi, qword ptr [MeshArenaBase]
    add rdi, qword ptr [MeshArenaUsed]
    cmp r8d, 00000004h
    jne stage_map_record
    mov qword ptr [MeshChunkBase], rdi
    mov dword ptr [MeshChunkBytes], ebx
    jmp stage_mesh_copy

stage_map_record:
    cmp r8d, 00000010h
    jne stage_mesh_copy
    mov qword ptr [MapChunkBase], rdi
    mov dword ptr [MapChunkBytes], ebx

stage_mesh_copy:
    mov rsi, rdx
    mov ecx, ebx
    rep movsb
    mov qword ptr [MeshArenaUsed], rax
    mov r9, qword ptr [MeshArenaSize]
    sub r9, rax
    mov qword ptr [MeshArenaFree], r9

stage_ok:
    inc dword ptr [PackStagedChunks]
    add dword ptr [PackStagedBytes], ebx
    or dword ptr [PackStageMask], r8d
    xor eax, eax
    jmp stage_done

stage_fail:
    mov eax, 1

stage_done:
    pop rdi
    pop rsi
    pop rbx
    ret
StageX64Chunk ENDP

ComputeFnv1a32 PROC
    push rbx

    mov rbx, rdx
    mov r9d, ecx
    mov eax, 0811C9DC5h
    xor r10d, r10d

fnv_loop:
    cmp r10d, r9d
    jae fnv_done
    movzx r11d, byte ptr [rbx + r10]
    xor eax, r11d
    imul eax, eax, 01000193h
    inc r10d
    jmp fnv_loop

fnv_done:
    pop rbx
    ret
ComputeFnv1a32 ENDP

GetPackChunkBit PROC
    cmp rax, qword ptr [PackTypeEngine]
    je pack_bit_engine
    cmp rax, qword ptr [PackTypeTexture]
    je pack_bit_texture
    cmp rax, qword ptr [PackTypeMesh]
    je pack_bit_mesh
    cmp rax, qword ptr [PackTypeMaterial]
    je pack_bit_material
    cmp rax, qword ptr [PackTypeMap]
    je pack_bit_map
    cmp rax, qword ptr [PackTypeScript]
    je pack_bit_script
    cmp rax, qword ptr [PackTypeAudio]
    je pack_bit_audio
    cmp rax, qword ptr [PackTypeTitle]
    je pack_bit_title
    cmp rax, qword ptr [PackTypeCampaign]
    je pack_bit_campaign
    xor eax, eax
    ret

pack_bit_engine:
    mov eax, 00000001h
    ret
pack_bit_texture:
    mov eax, 00000002h
    ret
pack_bit_mesh:
    mov eax, 00000004h
    ret
pack_bit_material:
    mov eax, 00000008h
    ret
pack_bit_map:
    mov eax, 00000010h
    ret
pack_bit_script:
    mov eax, 00000020h
    ret
pack_bit_audio:
    mov eax, 00000040h
    ret
pack_bit_title:
    mov eax, 00000080h
    ret
pack_bit_campaign:
    mov eax, 00000100h
    ret
GetPackChunkBit ENDP

RunInputLoop PROC
    push r12
    push r13
    sub rsp, 28h

    mov r12d, INPUT_LOOP_TICKS

input_loop:
    xor r13d, r13d

    call PollInputKey
    or r13d, eax

    call PollPointerInput
    or r13d, eax

    cmp dword ptr [GameMode], GAME_MODE_PLAY
    jne input_title_tick
    call UpdateLevelObjective
    or r13d, eax
    inc dword ptr [LevelPulseTicks]
    mov eax, dword ptr [LevelPulseTicks]
    and eax, 00000003h
    jnz input_shot_flash_check
    mov r13d, 1

input_shot_flash_check:
    cmp dword ptr [ShotFlashTicks], 0
    je input_hit_flash_check
    dec dword ptr [ShotFlashTicks]
    mov r13d, 1

input_hit_flash_check:
    cmp dword ptr [HitFlashTicks], 0
    je input_redraw_check
    dec dword ptr [HitFlashTicks]
    mov r13d, 1
    jmp input_redraw_check

input_title_tick:
    inc dword ptr [TitlePulseTicks]
    mov eax, dword ptr [TitlePulseTicks]
    and eax, 00000003h
    jnz input_redraw_check
    mov r13d, 1

input_redraw_check:
    mov eax, r13d
    test eax, eax
    jz input_stall

    call DrawActiveScreen

input_stall:
    mov rax, qword ptr [rbx + EFI_SYSTEM_TABLE_BOOTSERV]
    test rax, rax
    jz input_loop_done
    mov ecx, INPUT_POLL_STALL_USEC
    call qword ptr [rax + EFI_BOOT_SERVICES_STALL]
    dec r12d
    jnz input_loop

input_loop_done:
    add rsp, 28h
    pop r13
    pop r12
    ret
RunInputLoop ENDP

DrawActiveScreen PROC
    sub rsp, 20h

    cmp dword ptr [GameMode], GAME_MODE_PLAY
    jne draw_active_title
    call DrawFirstLevel
    jmp draw_active_done

draw_active_title:
    call DrawTitleScreen

draw_active_done:
    add rsp, 20h
    ret
DrawActiveScreen ENDP

PollInputKey PROC
    push r12
    sub rsp, 20h

    mov r12, qword ptr [rbx + EFI_SYSTEM_TABLE_CONIN]
    test r12, r12
    jz no_input_key

    mov rcx, r12
    lea rdx, InputKeyScan
    call qword ptr [r12 + EFI_SIMPLE_TEXT_INPUT_READ]
    test rax, rax
    jnz no_input_key

    call HandleInputKey
    mov eax, 1
    jmp input_key_done

no_input_key:
    xor eax, eax

input_key_done:
    add rsp, 20h
    pop r12
    ret
PollInputKey ENDP

PollPointerInput PROC
    push r12
    sub rsp, 20h

    xor r12d, r12d

    cmp dword ptr [GameMode], GAME_MODE_PLAY
    jne pointer_done
    cmp dword ptr [PointerAvailable], 0
    je pointer_done

    mov rcx, qword ptr [SimplePointerProtocol]
    test rcx, rcx
    jz pointer_done

    lea rdx, PointerStateX
    call qword ptr [rcx + EFI_SIMPLE_POINTER_GET_STATE]
    test rax, rax
    jnz pointer_done

    mov eax, dword ptr [PointerStateX]
    sar eax, 2
    test eax, eax
    jz pointer_check_y
    add eax, dword ptr [CrosshairX]
    cmp eax, CROSSHAIR_MIN_X
    jge pointer_x_min_ok
    mov eax, CROSSHAIR_MIN_X
pointer_x_min_ok:
    cmp eax, CROSSHAIR_MAX_X
    jle pointer_x_max_ok
    mov eax, CROSSHAIR_MAX_X
pointer_x_max_ok:
    mov dword ptr [CrosshairX], eax
    mov r12d, 1

pointer_check_y:
    mov eax, dword ptr [PointerStateY]
    sar eax, 2
    test eax, eax
    jz pointer_check_fire
    add eax, dword ptr [CrosshairY]
    cmp eax, CROSSHAIR_MIN_Y
    jge pointer_y_min_ok
    mov eax, CROSSHAIR_MIN_Y
pointer_y_min_ok:
    cmp eax, CROSSHAIR_MAX_Y
    jle pointer_y_max_ok
    mov eax, CROSSHAIR_MAX_Y
pointer_y_max_ok:
    mov dword ptr [CrosshairY], eax
    mov r12d, 1

pointer_check_fire:
    cmp byte ptr [PointerLeftButton], 0
    je pointer_left_up
    cmp dword ptr [PointerLeftLatch], 0
    jne pointer_done
    mov dword ptr [PointerLeftLatch], 1
    call FireWeapon
    mov r12d, 1
    jmp pointer_done

pointer_left_up:
    mov dword ptr [PointerLeftLatch], 0

pointer_done:
    mov eax, r12d
    add rsp, 20h
    pop r12
    ret
PollPointerInput ENDP

HandleInputKey PROC
    movzx eax, word ptr [InputKeyScan]
    mov dword ptr [InputLastScan], eax
    movzx edx, word ptr [InputKeyChar]
    mov dword ptr [InputLastChar], edx
    inc dword ptr [InputEventCount]

    cmp dword ptr [GameMode], GAME_MODE_PLAY
    je gameplay_key

    cmp ax, UEFI_SCAN_UP
    je input_up
    cmp dx, 'W'
    je input_up
    cmp dx, 'w'
    je input_up

    cmp ax, UEFI_SCAN_DOWN
    je input_down
    cmp dx, 'S'
    je input_down
    cmp dx, 's'
    je input_down

    cmp ax, UEFI_SCAN_RIGHT
    je input_confirm
    cmp dx, 13
    je input_confirm
    cmp dx, ' '
    je input_confirm
    cmp dx, 'D'
    je input_confirm
    cmp dx, 'd'
    je input_confirm

    cmp ax, UEFI_SCAN_LEFT
    je input_back
    cmp ax, UEFI_SCAN_ESC
    je input_back
    cmp dx, 8
    je input_back
    cmp dx, 'A'
    je input_back
    cmp dx, 'a'
    je input_back

    mov dword ptr [InputLastAction], INPUT_ACTION_NONE
    ret

input_up:
    mov dword ptr [InputLastAction], INPUT_ACTION_UP
    mov eax, dword ptr [MenuSelection]
    test eax, eax
    jz input_done
    dec eax
    mov dword ptr [MenuSelection], eax
    ret

input_down:
    mov dword ptr [InputLastAction], INPUT_ACTION_DOWN
    mov eax, dword ptr [MenuSelection]
    cmp eax, MENU_MAX_SELECTION
    jae input_done
    inc eax
    mov dword ptr [MenuSelection], eax
    ret

input_confirm:
    mov dword ptr [InputLastAction], INPUT_ACTION_CONFIRM
    inc dword ptr [InputConfirmCount]
    mov eax, dword ptr [MenuSelection]
    test eax, eax
    jnz input_confirm_panel
    call StartFirstLevel
    ret

input_confirm_panel:
    inc eax
    mov dword ptr [MenuPanel], eax
    ret

input_back:
    mov dword ptr [InputLastAction], INPUT_ACTION_BACK
    inc dword ptr [InputBackCount]
    mov dword ptr [MenuPanel], 0

input_done:
    ret

gameplay_key:
    cmp ax, UEFI_SCAN_UP
    je game_move_up
    cmp dx, 'W'
    je game_move_up
    cmp dx, 'w'
    je game_move_up

    cmp ax, UEFI_SCAN_DOWN
    je game_move_down
    cmp dx, 'S'
    je game_move_down
    cmp dx, 's'
    je game_move_down

    cmp ax, UEFI_SCAN_LEFT
    je game_move_left
    cmp dx, 'A'
    je game_move_left
    cmp dx, 'a'
    je game_move_left

    cmp ax, UEFI_SCAN_RIGHT
    je game_move_right
    cmp dx, 'D'
    je game_move_right
    cmp dx, 'd'
    je game_move_right

    cmp dx, 13
    je game_fire
    cmp dx, ' '
    je game_fire

    cmp ax, UEFI_SCAN_ESC
    je game_back_to_title
    cmp dx, 8
    je game_back_to_title

    mov dword ptr [InputLastAction], INPUT_ACTION_NONE
    ret

game_move_up:
    mov dword ptr [InputLastAction], INPUT_ACTION_UP
    mov eax, dword ptr [PlayerWorldZ]
    add eax, 24
    cmp eax, PLAYER_WORLD_MAX_Z
    jle game_move_up_store
    mov eax, PLAYER_WORLD_MAX_Z
game_move_up_store:
    mov dword ptr [PlayerWorldZ], eax
    call SyncPlayerScreenFromWorld
    ret

game_move_down:
    mov dword ptr [InputLastAction], INPUT_ACTION_DOWN
    mov eax, dword ptr [PlayerWorldZ]
    sub eax, 24
    cmp eax, PLAYER_WORLD_MIN_Z
    jge game_move_down_store
    mov eax, PLAYER_WORLD_MIN_Z
game_move_down_store:
    mov dword ptr [PlayerWorldZ], eax
    call SyncPlayerScreenFromWorld
    ret

game_move_left:
    mov dword ptr [InputLastAction], INPUT_ACTION_BACK
    mov eax, dword ptr [PlayerWorldX]
    sub eax, 24
    cmp eax, PLAYER_WORLD_MIN_X
    jge game_move_left_store
    mov eax, PLAYER_WORLD_MIN_X
game_move_left_store:
    mov dword ptr [PlayerWorldX], eax
    call SyncPlayerScreenFromWorld
    ret

game_move_right:
    mov dword ptr [InputLastAction], INPUT_ACTION_CONFIRM
    mov eax, dword ptr [PlayerWorldX]
    add eax, 24
    cmp eax, PLAYER_WORLD_MAX_X
    jle game_move_right_store
    mov eax, PLAYER_WORLD_MAX_X
game_move_right_store:
    mov dword ptr [PlayerWorldX], eax
    call SyncPlayerScreenFromWorld
    ret

game_fire:
    mov dword ptr [InputLastAction], INPUT_ACTION_FIRE
    inc dword ptr [InputConfirmCount]
    call FireWeapon
    ret

game_back_to_title:
    mov dword ptr [InputLastAction], INPUT_ACTION_BACK
    inc dword ptr [InputBackCount]
    call ReturnToTitle
    ret
HandleInputKey ENDP

SyncPlayerScreenFromWorld PROC
    mov eax, dword ptr [PlayerWorldX]
    add eax, 320
    cmp eax, PLAYER_MIN_X
    jge sync_player_x_min_ok
    mov eax, PLAYER_MIN_X
sync_player_x_min_ok:
    cmp eax, PLAYER_MAX_X
    jle sync_player_x_ready
    mov eax, PLAYER_MAX_X
sync_player_x_ready:
    mov dword ptr [PlayerX], eax

    mov eax, dword ptr [PlayerWorldZ]
    shr eax, 1
    mov ecx, PLAYER_MAX_Y
    sub ecx, eax
    cmp ecx, PLAYER_MIN_Y
    jge sync_player_y_min_ok
    mov ecx, PLAYER_MIN_Y
sync_player_y_min_ok:
    cmp ecx, PLAYER_MAX_Y
    jle sync_player_y_ready
    mov ecx, PLAYER_MAX_Y
sync_player_y_ready:
    mov dword ptr [PlayerY], ecx
    ret
SyncPlayerScreenFromWorld ENDP

StartFirstLevel PROC
    mov dword ptr [GameMode], GAME_MODE_PLAY
    mov dword ptr [MenuPanel], 0
    mov dword ptr [DrawOffsetEnabled], 0
    mov dword ptr [PlayerWorldX], 0
    mov dword ptr [PlayerWorldZ], 0
    call SyncPlayerScreenFromWorld
    mov dword ptr [CrosshairX], 320
    mov dword ptr [CrosshairY], 224
    mov dword ptr [EnemyHp], 3
    mov dword ptr [EnemyAlive], 1
    mov dword ptr [SentryLeftHp], 1
    mov dword ptr [SentryLeftAlive], 1
    mov dword ptr [SentryRightHp], 1
    mov dword ptr [SentryRightAlive], 1
    mov dword ptr [ObjectiveState], 0
    mov dword ptr [ShotFlashTicks], 0
    mov dword ptr [HitFlashTicks], 0
    mov dword ptr [MissionShots], 0
    mov dword ptr [MissionHits], 0
    mov dword ptr [LevelPulseTicks], 0
    mov dword ptr [PointerLeftLatch], 0
    ret
StartFirstLevel ENDP

ReturnToTitle PROC
    mov dword ptr [GameMode], GAME_MODE_TITLE
    mov dword ptr [MenuPanel], 0
    mov dword ptr [DrawOffsetEnabled], 0
    mov dword ptr [DrawOffsetX], 0
    mov dword ptr [DrawOffsetY], 0
    mov dword ptr [ShotFlashTicks], 0
    mov dword ptr [HitFlashTicks], 0
    mov dword ptr [PointerLeftLatch], 0
    ret
ReturnToTitle ENDP

UpdateHostileObjective PROC
    cmp dword ptr [EnemyAlive], 0
    jne hostile_objective_not_clear
    cmp dword ptr [SentryLeftAlive], 0
    jne hostile_objective_not_clear
    cmp dword ptr [SentryRightAlive], 0
    jne hostile_objective_not_clear
    cmp dword ptr [ObjectiveState], 1
    jae hostile_objective_already_ready
    mov dword ptr [ObjectiveState], 1

hostile_objective_already_ready:
    mov eax, 1
    ret

hostile_objective_not_clear:
    xor eax, eax
    ret
UpdateHostileObjective ENDP

UpdateLevelCameraFromPlayer PROC
    mov eax, dword ptr [PlayerWorldX]
    cdq
    mov ecx, 3
    idiv ecx
    mov dword ptr [LevelCameraX], eax

    mov eax, dword ptr [PlayerWorldZ]
    cdq
    mov ecx, 8
    idiv ecx
    mov dword ptr [LevelCameraZ], eax
    ret
UpdateLevelCameraFromPlayer ENDP

FindMapVolume PROC
    mov rdx, qword ptr [MapVolumeBase]
    test rdx, rdx
    jz find_volume_fail
    mov r8d, dword ptr [MapVolumeCount]
    test r8d, r8d
    jz find_volume_fail

find_volume_loop:
    cmp dword ptr [rdx], ecx
    je find_volume_ok
    add rdx, MAP_VOLUME_BYTES
    dec r8d
    jnz find_volume_loop

find_volume_fail:
    xor eax, eax
    ret

find_volume_ok:
    mov eax, 1
    ret
FindMapVolume ENDP

ProjectCrosshairAtWorldZ PROC
    push rbx

    mov ebx, ecx
    sub ebx, dword ptr [LevelCameraZ]
    cmp ebx, 32
    jge aim_depth_ready
    mov ebx, 32

aim_depth_ready:
    mov eax, dword ptr [CrosshairX]
    sub eax, 320
    imul eax, ebx
    cdq
    mov ecx, 180
    idiv ecx
    add eax, dword ptr [LevelCameraX]
    mov r11d, eax

    mov eax, 302
    sub eax, dword ptr [CrosshairY]
    imul eax, ebx
    cdq
    mov ecx, 180
    idiv ecx
    mov edx, eax
    mov eax, r11d

    pop rbx
    ret
ProjectCrosshairAtWorldZ ENDP

FireWeapon PROC
    inc dword ptr [MissionShots]
    mov dword ptr [ShotFlashTicks], 36
    call UpdateLevelCameraFromPlayer

    cmp dword ptr [EnemyAlive], 0
    je fire_check_sentries

    mov ecx, MAP_VOLUME_WARDEN
    call FindMapVolume
    test eax, eax
    jz fire_enemy_legacy_check
    mov r10, rdx
    mov ecx, dword ptr [r10 + 12]
    add ecx, dword ptr [r10 + 24]
    sar ecx, 1
    call ProjectCrosshairAtWorldZ
    cmp eax, dword ptr [r10 + 4]
    jl fire_check_sentries
    cmp eax, dword ptr [r10 + 16]
    jg fire_check_sentries

    cmp edx, dword ptr [r10 + 8]
    jl fire_check_sentries
    cmp edx, dword ptr [r10 + 20]
    jg fire_check_sentries
    jmp fire_enemy_hit

fire_enemy_legacy_check:
    mov ecx, 196
    call ProjectCrosshairAtWorldZ
    cmp eax, -60
    jl fire_check_sentries
    cmp eax, 60
    jg fire_check_sentries
    cmp edx, -32
    jl fire_check_sentries
    cmp edx, 106
    jg fire_check_sentries

fire_enemy_hit:
    inc dword ptr [MissionHits]
    mov dword ptr [HitFlashTicks], 8
    mov eax, dword ptr [EnemyHp]
    test eax, eax
    jz fire_enemy_down
    dec eax
    mov dword ptr [EnemyHp], eax
    test eax, eax
    jnz fire_done

fire_enemy_down:
    mov dword ptr [EnemyAlive], 0
    call UpdateHostileObjective
    jmp fire_done

fire_check_sentries:
    cmp dword ptr [SentryLeftAlive], 0
    je fire_check_right_sentry
    mov ecx, 326
    call ProjectCrosshairAtWorldZ
    cmp eax, -112
    jl fire_check_right_sentry
    cmp eax, -18
    jg fire_check_right_sentry
    cmp edx, -52
    jl fire_check_right_sentry
    cmp edx, 180
    jg fire_check_right_sentry
    inc dword ptr [MissionHits]
    mov dword ptr [HitFlashTicks], 10
    mov eax, dword ptr [SentryLeftHp]
    test eax, eax
    jz fire_left_sentry_down
    dec eax
    mov dword ptr [SentryLeftHp], eax
    test eax, eax
    jnz fire_done

fire_left_sentry_down:
    mov dword ptr [SentryLeftAlive], 0
    call UpdateHostileObjective
    jmp fire_done

fire_check_right_sentry:
    cmp dword ptr [SentryRightAlive], 0
    je fire_check_terminal
    mov ecx, 326
    call ProjectCrosshairAtWorldZ
    cmp eax, 18
    jl fire_check_terminal
    cmp eax, 112
    jg fire_check_terminal
    cmp edx, -52
    jl fire_check_terminal
    cmp edx, 180
    jg fire_check_terminal
    inc dword ptr [MissionHits]
    mov dword ptr [HitFlashTicks], 10
    mov eax, dword ptr [SentryRightHp]
    test eax, eax
    jz fire_right_sentry_down
    dec eax
    mov dword ptr [SentryRightHp], eax
    test eax, eax
    jnz fire_done

fire_right_sentry_down:
    mov dword ptr [SentryRightAlive], 0
    call UpdateHostileObjective
    jmp fire_done

fire_check_terminal:
    cmp dword ptr [ObjectiveState], 1
    jne fire_done

    mov ecx, MAP_VOLUME_TERMINAL
    call FindMapVolume
    test eax, eax
    jz fire_terminal_legacy_check
    mov r10, rdx
    mov ecx, dword ptr [r10 + 12]
    add ecx, dword ptr [r10 + 24]
    sar ecx, 1
    call ProjectCrosshairAtWorldZ
    cmp eax, dword ptr [r10 + 4]
    jl fire_done
    cmp eax, dword ptr [r10 + 16]
    jg fire_done

    cmp edx, dword ptr [r10 + 8]
    jl fire_done
    cmp edx, dword ptr [r10 + 20]
    jg fire_done
    jmp fire_terminal_hit

fire_terminal_legacy_check:
    mov ecx, 292
    call ProjectCrosshairAtWorldZ
    cmp eax, -190
    jl fire_done
    cmp eax, -96
    jg fire_done
    cmp edx, -84
    jl fire_done
    cmp edx, 88
    jg fire_done

fire_terminal_hit:
    inc dword ptr [MissionHits]
    mov dword ptr [HitFlashTicks], 10
    mov dword ptr [ObjectiveState], 2

fire_done:
    ret
FireWeapon ENDP

UpdateLevelObjective PROC
    xor ecx, ecx
    mov eax, dword ptr [ObjectiveState]
    cmp eax, 3
    jae objective_done

    cmp eax, 2
    je objective_check_exit
    cmp eax, 1
    jne objective_done

    mov ecx, MAP_VOLUME_TERMINAL
    call FindMapVolume
    test eax, eax
    jz objective_terminal_legacy
    mov r10, rdx
    mov eax, dword ptr [PlayerWorldX]
    cmp eax, dword ptr [r10 + 4]
    jl objective_done
    cmp eax, dword ptr [r10 + 16]
    jg objective_done
    mov eax, dword ptr [PlayerWorldZ]
    cmp eax, dword ptr [r10 + 12]
    jl objective_done
    cmp eax, dword ptr [r10 + 24]
    jg objective_done
    jmp objective_terminal_breach

objective_terminal_legacy:
    mov eax, dword ptr [PlayerWorldX]
    cmp eax, -190
    jl objective_done
    cmp eax, -88
    jg objective_done
    mov eax, dword ptr [PlayerWorldZ]
    cmp eax, 248
    jl objective_done
    cmp eax, 356
    jg objective_done

objective_terminal_breach:
    mov dword ptr [ObjectiveState], 2
    mov dword ptr [HitFlashTicks], 10
    mov ecx, 1
    jmp objective_done

objective_check_exit:
    mov ecx, MAP_VOLUME_EXIT
    call FindMapVolume
    test eax, eax
    jz objective_exit_legacy
    mov r10, rdx
    mov eax, dword ptr [PlayerWorldX]
    cmp eax, dword ptr [r10 + 4]
    jl objective_done
    cmp eax, dword ptr [r10 + 16]
    jg objective_done
    mov eax, dword ptr [PlayerWorldZ]
    cmp eax, dword ptr [r10 + 12]
    jl objective_done
    cmp eax, dword ptr [r10 + 24]
    jg objective_done
    jmp objective_exit_complete

objective_exit_legacy:
    mov eax, dword ptr [PlayerWorldX]
    cmp eax, 108
    jl objective_done
    cmp eax, 220
    jg objective_done
    mov eax, dword ptr [PlayerWorldZ]
    cmp eax, 300
    jl objective_done
    cmp eax, PLAYER_WORLD_MAX_Z
    jg objective_done

objective_exit_complete:
    mov dword ptr [ObjectiveState], 3
    mov dword ptr [HitFlashTicks], 12
    mov ecx, 1

objective_done:
    mov eax, ecx
    ret
UpdateLevelObjective ENDP

DrawPanicScreen PROC
    push rdi
    push r12
    sub rsp, 28h

    mov r12, r8
    mov eax, 00201018h
    call FillScreen
    FILL_GOP_RECT 32, 40, 576, 132, 00A02030h
    FILL_GOP_RECT 48, 76, 540, 6, 00FF90FFh

    mov ecx, 48
    mov edx, 56
    lea r8, PanicTitleLine
    mov r9d, DIAG_TEXT
    call DrawString

    mov ecx, 48
    mov edx, 116
    mov r8, r12
    mov r9d, DIAG_WARN
    call DrawString

    add rsp, 28h
    pop r12
    pop rdi
    ret
DrawPanicScreen ENDP

DrawMenuOptions PROC
    push rdi
    sub rsp, 20h

    mov eax, dword ptr [TitlePulseTicks]
    and eax, 00000008h
    jz menu_pulse_cyan
    mov dword ptr [TitleSelectColor], 00FF90FFh
    mov dword ptr [TitlePulseColor], 00FFE66Dh
    jmp menu_pulse_ready

menu_pulse_cyan:
    mov dword ptr [TitleSelectColor], 00D8FFFFh
    mov dword ptr [TitlePulseColor], 00FF90FFh

menu_pulse_ready:
    FILL_GOP_RECT 404, 22, 212, 136, 00070B12h
    FILL_GOP_RECT 408, 28, 4, 124, DIAG_ACCENT
    FILL_GOP_RECT 416, 150, 184, 2, 00FF90FFh

    cmp dword ptr [MenuSelection], 0
    jne menu_select_log
    FILL_GOP_RECT 420, 54, 152, 24, dword ptr [TitleSelectColor]
    FILL_GOP_RECT 414, 60, 4, 12, dword ptr [TitlePulseColor]
    jmp menu_highlight_done

menu_select_log:
    cmp dword ptr [MenuSelection], 1
    jne menu_select_credits
    FILL_GOP_RECT 420, 86, 152, 24, dword ptr [TitleSelectColor]
    FILL_GOP_RECT 414, 92, 4, 12, dword ptr [TitlePulseColor]
    jmp menu_highlight_done

menu_select_credits:
    FILL_GOP_RECT 420, 118, 152, 24, dword ptr [TitleSelectColor]
    FILL_GOP_RECT 414, 124, 4, 12, dword ptr [TitlePulseColor]

menu_highlight_done:
    mov eax, dword ptr [TitlePulseTicks]
    and eax, 0000000Fh
    shl eax, 3
    add eax, 420
    mov ecx, eax
    mov edx, 150
    mov r8d, 24
    mov r9d, 2
    mov eax, dword ptr [TitlePulseColor]
    call DrawGopRect

    mov ecx, 424
    mov edx, 32
    lea r8, MenuTitleLine
    mov r9d, DIAG_MUTED
    call DrawString

    lea r8, MenuPanelIdle
    cmp dword ptr [MenuPanel], 1
    jne panel_check_log
    lea r8, MenuPanelDiag
    jmp panel_ready

panel_check_log:
    cmp dword ptr [MenuPanel], 2
    jne panel_check_credits
    lea r8, MenuPanelLog
    jmp panel_ready

panel_check_credits:
    cmp dword ptr [MenuPanel], 3
    jne panel_ready
    lea r8, MenuPanelCredits

panel_ready:
    mov ecx, 560
    mov edx, 32
    mov r9d, DIAG_WARN
    call DrawString

    mov ecx, 428
    mov edx, 58
    lea r8, MenuOptionDiag
    mov r9d, DIAG_TEXT
    cmp dword ptr [MenuSelection], 0
    jne draw_menu_diag
    mov r9d, DIAG_BG
draw_menu_diag:
    call DrawString

    mov ecx, 428
    mov edx, 90
    lea r8, MenuOptionLog
    mov r9d, DIAG_TEXT
    cmp dword ptr [MenuSelection], 1
    jne draw_menu_log
    mov r9d, DIAG_BG
draw_menu_log:
    call DrawString

    mov ecx, 428
    mov edx, 122
    lea r8, MenuOptionCredits
    mov r9d, DIAG_TEXT
    cmp dword ptr [MenuSelection], 2
    jne draw_menu_credits
    mov r9d, DIAG_BG
draw_menu_credits:
    call DrawString

    add rsp, 20h
    pop rdi
    ret
DrawMenuOptions ENDP

DrawTitleScreen PROC
    push rdi
    sub rsp, 20h

    mov dword ptr [DrawOffsetEnabled], 0
    mov eax, 00000000h
    call FillScreen
    call DrawEngine64Showcase

    mov eax, dword ptr [GopWidth]
    cmp eax, ENGINE64_EXPECTED_WIDTH
    jb title_offset_x_zero
    sub eax, ENGINE64_EXPECTED_WIDTH
    shr eax, 1
    jmp title_offset_x_ready

title_offset_x_zero:
    xor eax, eax

title_offset_x_ready:
    mov dword ptr [DrawOffsetX], eax

    mov eax, dword ptr [GopHeight]
    cmp eax, ENGINE64_EXPECTED_HEIGHT
    jb title_offset_y_zero
    sub eax, ENGINE64_EXPECTED_HEIGHT
    shr eax, 1
    jmp title_offset_y_ready

title_offset_y_zero:
    xor eax, eax

title_offset_y_ready:
    mov dword ptr [DrawOffsetY], eax
    mov dword ptr [DrawOffsetEnabled], 1

    mov eax, dword ptr [TitlePulseTicks]
    and eax, 00000008h
    jz title_pulse_cyan
    mov dword ptr [TitleSelectColor], 00FF90FFh
    mov dword ptr [TitlePulseColor], 00FFE66Dh
    jmp title_pulse_ready

title_pulse_cyan:
    mov dword ptr [TitleSelectColor], 00D8FFFFh
    mov dword ptr [TitlePulseColor], 00FF90FFh

title_pulse_ready:
    call DrawTitleHero3DOverlay

    FILL_GOP_RECT 28, 24, 374, 112, 00070B12h
    FILL_GOP_RECT 42, 88, 286, 5, DIAG_ACCENT
    FILL_GOP_RECT 42, 96, 192, 2, 00FFE66Dh

    mov ecx, 44
    mov edx, 40
    lea r8, TitleLine
    mov r9d, DIAG_MAGENTA
    call DrawString4x

    mov ecx, 42
    mov edx, 38
    lea r8, TitleLine
    mov r9d, DIAG_TEXT
    call DrawString4x

    mov ecx, 44
    mov edx, 106
    lea r8, SubtitleLine
    mov r9d, DIAG_MUTED
    call DrawString

    call DrawMenuOptions

    FILL_GOP_RECT 28, 402, 584, 52, 00070B12h
    FILL_GOP_RECT 28, 404, 584, 2, 00FF90FFh

    mov ecx, 42
    mov edx, 414
    lea r8, StartHintLine
    mov r9d, DIAG_TEXT
    call DrawString

    mov ecx, 42
    mov edx, 436
    lea r8, BuildHintLine
    mov r9d, DIAG_MUTED
    call DrawString

    mov dword ptr [DrawOffsetEnabled], 0
    add rsp, 20h
    pop rdi
    ret
DrawTitleScreen ENDP

DrawTitleHero3DOverlay PROC
    push rdi
    sub rsp, 20h

    FILL_GOP_RECT 0, 150, 640, 66, 0004080Dh
    FILL_GOP_RECT 0, 216, 640, 264, 00030A10h
    FILL_GOP_RECT 0, 216, 640, 3, 003080D0h
    FILL_GOP_RECT 0, 246, 640, 2, 00D8FFFFh
    FILL_GOP_RECT 0, 304, 640, 2, 00FF90FFh
    FILL_GOP_RECT 0, 386, 640, 3, 003080D0h

    FILL_GOP_RECT 38, 172, 54, 112, 00070B12h
    FILL_GOP_RECT 106, 136, 78, 148, 000B1924h
    FILL_GOP_RECT 202, 184, 48, 100, 00101820h
    FILL_GOP_RECT 408, 156, 84, 128, 000B1924h
    FILL_GOP_RECT 516, 190, 66, 94, 00101820h
    FILL_GOP_RECT 58, 208, 10, 44, 00D8FFFFh
    FILL_GOP_RECT 128, 164, 12, 32, 00FF90FFh
    FILL_GOP_RECT 164, 210, 8, 48, 00FFE66Dh
    FILL_GOP_RECT 424, 184, 52, 8, 00D8FFFFh
    FILL_GOP_RECT 548, 218, 8, 44, 00FF4058h

    mov eax, dword ptr [TitlePulseTicks]
    and eax, 0000003Fh
    shl eax, 3
    add eax, 32
    mov ecx, eax
    mov edx, 246
    mov r8d, 52
    mov r9d, 2
    mov eax, dword ptr [TitlePulseColor]
    call DrawGopRect

    mov eax, dword ptr [TitlePulseTicks]
    and eax, 0000001Fh
    shl eax, 2
    add eax, 184
    mov ecx, 604
    mov edx, eax
    mov r8d, 4
    mov r9d, 28
    mov eax, 003080D0h
    call DrawGopRect

    mov eax, dword ptr [TitlePulseTicks]
    add eax, 00000010h
    and eax, 0000001Fh
    shl eax, 2
    add eax, 154
    mov ecx, 22
    mov edx, eax
    mov r8d, 4
    mov r9d, 26
    mov eax, 00FF90FFh
    call DrawGopRect

    mov ecx, 320
    mov edx, 220
    mov r8d, 18
    mov r9d, 479
    mov eax, 003080D0h
    call DrawGopLine

    mov ecx, 320
    mov edx, 220
    mov r8d, 150
    mov r9d, 479
    mov eax, 00FF90FFh
    call DrawGopLine

    mov ecx, 320
    mov edx, 220
    mov r8d, 288
    mov r9d, 479
    mov eax, 00D8FFFFh
    call DrawGopLine

    mov ecx, 320
    mov edx, 220
    mov r8d, 352
    mov r9d, 479
    mov eax, 00D8FFFFh
    call DrawGopLine

    mov ecx, 320
    mov edx, 220
    mov r8d, 490
    mov r9d, 479
    mov eax, 00FF90FFh
    call DrawGopLine

    mov ecx, 320
    mov edx, 220
    mov r8d, 622
    mov r9d, 479
    mov eax, 003080D0h
    call DrawGopLine

    FILL_GOP_RECT 230, 246, 72, 20, 00070B12h
    FILL_GOP_RECT 292, 234, 126, 38, 00182A38h
    FILL_GOP_RECT 408, 252, 54, 14, 00070B12h
    FILL_GOP_RECT 254, 268, 210, 5, 00FF90FFh
    FILL_GOP_RECT 318, 246, 48, 8, 00D8FFFFh
    FILL_GOP_RECT 372, 258, 22, 6, 00FFE66Dh
    FILL_GOP_RECT 242, 274, 28, 4, 00FF4058h
    FILL_GOP_RECT 426, 274, 28, 4, 00FF4058h

    mov ecx, 230
    mov edx, 246
    mov r8d, 292
    mov r9d, 234
    mov eax, 00D8FFFFh
    call DrawGopLine

    mov ecx, 418
    mov edx, 234
    mov r8d, 462
    mov r9d, 252
    mov eax, 00D8FFFFh
    call DrawGopLine

    add rsp, 20h
    pop rdi
    ret
DrawTitleHero3DOverlay ENDP

FormatMissionHud PROC
    sub rsp, 20h

    mov ecx, dword ptr [MissionShots]
    lea rdx, LevelStatusLine + 6
    mov r8d, 4
    call WriteHex32

    mov ecx, dword ptr [MissionHits]
    lea rdx, LevelStatusLine + 16
    mov r8d, 4
    call WriteHex32

    add rsp, 20h
    ret
FormatMissionHud ENDP

DrawFirstLevel PROC
    push rdi
    sub rsp, 20h

    call FormatMissionHud
    call RenderFirstLevel3DFrame
    test eax, eax
    jnz draw_first_level_legacy_fallback
    call PresentInternalFrameToGop
    call DrawFirstLevelHudOverlay
    add rsp, 20h
    pop rdi
    ret

draw_first_level_legacy_fallback:

    mov eax, 0004080Dh
    call FillScreen

    FILL_GOP_RECT 0, 0, 640, 44, 00070B12h
    FILL_GOP_RECT 0, 44, 640, 2, 00FF90FFh
    FILL_GOP_RECT 20, 72, 600, 356, 00070B12h
    FILL_GOP_RECT 30, 84, 580, 336, 00101820h
    FILL_GOP_RECT 44, 116, 552, 3, 00D8FFFFh
    FILL_GOP_RECT 44, 384, 552, 4, 00FF90FFh
    FILL_GOP_RECT 86, 150, 66, 214, 00030A10h
    FILL_GOP_RECT 488, 150, 66, 214, 00030A10h
    FILL_GOP_RECT 154, 214, 332, 136, 000B1924h
    FILL_GOP_RECT 194, 244, 252, 72, 00182A38h
    FILL_GOP_RECT 224, 272, 192, 20, 00070B12h
    FILL_GOP_RECT 270, 126, 100, 4, 00FFE66Dh
    FILL_GOP_RECT 100, 170, 10, 72, 00D8FFFFh
    FILL_GOP_RECT 130, 198, 8, 92, 00FF90FFh
    FILL_GOP_RECT 506, 170, 10, 72, 00D8FFFFh
    FILL_GOP_RECT 536, 198, 8, 92, 00FF4058h
    FILL_GOP_RECT 66, 132, 142, 2, 003080D0h
    FILL_GOP_RECT 432, 132, 142, 2, 003080D0h
    FILL_GOP_RECT 154, 352, 332, 4, 00101820h
    FILL_GOP_RECT 168, 330, 304, 2, 003080D0h
    FILL_GOP_RECT 190, 308, 260, 2, 00D8FFFFh
    FILL_GOP_RECT 216, 286, 208, 2, 00FF90FFh
    FILL_GOP_RECT 132, 300, 112, 84, 00070B12h
    FILL_GOP_RECT 486, 296, 88, 88, 00070B12h
    FILL_GOP_RECT 500, 312, 58, 54, 00030A10h
    FILL_GOP_RECT 512, 322, 34, 34, 00101820h
    FILL_GOP_RECT 44, 92, 552, 16, 000B1924h
    FILL_GOP_RECT 60, 136, 520, 4, 00182A38h
    FILL_GOP_RECT 72, 358, 496, 8, 000B1924h
    FILL_GOP_RECT 96, 368, 448, 5, 00101820h
    FILL_GOP_RECT 128, 378, 384, 3, 000B1924h
    FILL_GOP_RECT 60, 146, 18, 216, 00070B12h
    FILL_GOP_RECT 562, 146, 18, 216, 00070B12h
    FILL_GOP_RECT 66, 156, 6, 188, 003080D0h
    FILL_GOP_RECT 568, 156, 6, 188, 00FF90FFh
    FILL_GOP_RECT 238, 150, 40, 8, 003080D0h
    FILL_GOP_RECT 362, 150, 40, 8, 00FF90FFh
    FILL_GOP_RECT 252, 166, 22, 5, 00D8FFFFh
    FILL_GOP_RECT 366, 166, 22, 5, 00FFE66Dh
    FILL_GOP_RECT 70, 252, 54, 7, 00FFE66Dh
    FILL_GOP_RECT 516, 252, 54, 7, 00D8FFFFh
    FILL_GOP_RECT 44, 402, 552, 2, 003080D0h
    FILL_GOP_RECT 44, 456, 552, 28, 00070B12h

    DRAW_3D_LINE -180, -45, 96, 180, -45, 96, 00FF90FFh
    DRAW_3D_LINE -180, -45, 136, 180, -45, 136, 003080D0h
    DRAW_3D_LINE -180, -45, 192, 180, -45, 192, 00D8FFFFh
    DRAW_3D_LINE -180, -45, 280, 180, -45, 280, 003080D0h
    DRAW_3D_LINE -180, -45, 400, 180, -45, 400, 00FF90FFh
    DRAW_3D_LINE -180, -45, 96, -180, -45, 420, 003080D0h
    DRAW_3D_LINE -90, -45, 96, -90, -45, 420, 00D8FFFFh
    DRAW_3D_LINE 0, -45, 96, 0, -45, 420, 00FFE66Dh
    DRAW_3D_LINE 90, -45, 96, 90, -45, 420, 00D8FFFFh
    DRAW_3D_LINE 180, -45, 96, 180, -45, 420, 003080D0h
    DRAW_3D_LINE -180, 95, 96, 180, 95, 96, 003080D0h
    DRAW_3D_LINE -180, 95, 180, 180, 95, 180, 00D8FFFFh
    DRAW_3D_LINE -180, 95, 320, 180, 95, 320, 003080D0h
    DRAW_3D_LINE -180, -45, 420, -180, 95, 420, 00D8FFFFh
    DRAW_3D_LINE 180, -45, 420, 180, 95, 420, 00D8FFFFh
    DRAW_3D_BOX -178, -45, 118, -132, 86, 214, 003080D0h
    DRAW_3D_BOX 132, -45, 118, 178, 86, 214, 00FF90FFh

    mov eax, dword ptr [LevelPulseTicks]
    and eax, 00000008h
    jz draw_level_pulse_cyan
    mov eax, 00FF90FFh
    jmp draw_level_pulse_ready

draw_level_pulse_cyan:
    mov eax, 00D8FFFFh

draw_level_pulse_ready:
    mov ecx, 44
    mov edx, 116
    mov r8d, 552
    mov r9d, 2
    call DrawGopRect

    mov ecx, 88
    mov edx, 386
    mov r8d, 464
    mov r9d, 3
    call DrawGopRect

    mov ecx, 118
    mov edx, 332
    mov r8d, 72
    mov r9d, 4
    call DrawGopRect

    mov ecx, 450
    mov edx, 332
    mov r8d, 72
    mov r9d, 4
    call DrawGopRect

    mov ecx, 44
    mov edx, 402
    mov r8d, 552
    mov r9d, 2
    call DrawGopRect

    mov ecx, 28
    mov edx, 16
    lea r8, LevelTitleLine
    mov r9d, DIAG_TEXT
    call DrawString

    mov ecx, 376
    mov edx, 16
    lea r8, LevelStatusLine
    mov r9d, DIAG_WARN
    call DrawString

    mov ecx, 44
    mov edx, 58
    lea r8, LevelObjectiveKillLine
    cmp dword ptr [ObjectiveState], 1
    jne draw_objective_exit_check
    lea r8, LevelObjectiveBreachLine
    jmp draw_objective_ready

draw_objective_exit_check:
    cmp dword ptr [ObjectiveState], 2
    jne draw_objective_clear_check
    lea r8, LevelObjectiveExitLine
    jmp draw_objective_ready

draw_objective_clear_check:
    cmp dword ptr [ObjectiveState], 3
    jb draw_objective_ready
    lea r8, LevelObjectiveClearLine

draw_objective_ready:
    mov r9d, DIAG_ACCENT
    call DrawString

    mov ecx, 44
    mov edx, 438
    lea r8, LevelLoopLine
    mov r9d, DIAG_MUTED
    call DrawString

    mov ecx, 44
    mov edx, 464
    lea r8, LevelHintLine
    mov r9d, DIAG_TEXT
    call DrawString

    cmp dword ptr [ObjectiveState], 1
    jb draw_terminal_locked
    cmp dword ptr [ObjectiveState], 2
    jb draw_terminal_active
    FILL_GOP_RECT 148, 304, 80, 12, 0020D060h
    FILL_GOP_RECT 160, 322, 56, 4, 00D8FFFFh
    jmp draw_terminal_model

draw_terminal_active:
    FILL_GOP_RECT 148, 304, 80, 12, 00FFE66Dh
    FILL_GOP_RECT 160, 322, 56, 4, 00FF90FFh
    jmp draw_terminal_model

draw_terminal_locked:
    FILL_GOP_RECT 148, 304, 80, 12, 00FF4058h
    FILL_GOP_RECT 160, 322, 56, 4, 003080D0h

draw_terminal_model:
    FILL_GOP_RECT 136, 194, 98, 92, 000B1924h
    FILL_GOP_RECT 140, 198, 90, 4, 003080D0h
    FILL_GOP_RECT 140, 278, 90, 4, 003080D0h
    FILL_GOP_RECT 144, 208, 8, 62, 00FF90FFh
    FILL_GOP_RECT 218, 208, 8, 62, 00D8FFFFh
    FILL_GOP_RECT 148, 204, 74, 66, 00030A10h
    FILL_GOP_RECT 158, 216, 54, 34, 00182A38h
    cmp dword ptr [ObjectiveState], 1
    jb draw_terminal_screen_locked
    cmp dword ptr [ObjectiveState], 2
    jb draw_terminal_screen_active
    FILL_GOP_RECT 164, 222, 42, 20, 0020D060h
    FILL_GOP_RECT 170, 228, 30, 3, 00D8FFFFh
    FILL_GOP_RECT 170, 236, 30, 3, 00D8FFFFh
    jmp draw_terminal_screen_done

draw_terminal_screen_active:
    cmp dword ptr [HitFlashTicks], 0
    je draw_terminal_active_normal
    FILL_GOP_RECT 164, 222, 42, 20, 00FF90FFh
    jmp draw_terminal_screen_done

draw_terminal_active_normal:
    FILL_GOP_RECT 164, 222, 42, 20, 00FFE66Dh
    FILL_GOP_RECT 170, 228, 30, 3, 00070B12h
    FILL_GOP_RECT 170, 236, 20, 3, 00070B12h
    jmp draw_terminal_screen_done

draw_terminal_screen_locked:
    FILL_GOP_RECT 164, 222, 42, 20, 00FF4058h
    FILL_GOP_RECT 170, 228, 30, 3, 00070B12h
    FILL_GOP_RECT 170, 236, 30, 3, 00070B12h

draw_terminal_screen_done:
    FILL_GOP_RECT 154, 252, 62, 6, 00182A38h
    FILL_GOP_RECT 170, 258, 30, 4, 00D8FFFFh
    FILL_GOP_RECT 178, 270, 14, 30, 00030A10h
    cmp dword ptr [ObjectiveState], 1
    jb draw_terminal_box_locked
    cmp dword ptr [ObjectiveState], 2
    jb draw_terminal_box_active
    DRAW_3D_BOX -158, -42, 210, -104, 38, 278, 0020D060h
    jmp draw_terminal_box_done

draw_terminal_box_active:
    DRAW_3D_BOX -158, -42, 210, -104, 38, 278, 00FFE66Dh
    jmp draw_terminal_box_done

draw_terminal_box_locked:
    DRAW_3D_BOX -158, -42, 210, -104, 38, 278, 00FF4058h

draw_terminal_box_done:

    mov ecx, 142
    mov edx, 286
    lea r8, LevelTerminalLine
    mov r9d, DIAG_MUTED
    cmp dword ptr [ObjectiveState], 1
    jb draw_terminal_label
    mov r9d, DIAG_WARN
draw_terminal_label:
    call DrawString

    cmp dword ptr [ObjectiveState], 2
    jb draw_exit_locked
    FILL_GOP_RECT 492, 294, 74, 82, 000B1924h
    FILL_GOP_RECT 498, 300, 62, 70, 00182A38h
    FILL_GOP_RECT 506, 304, 46, 6, 0020D060h
    FILL_GOP_RECT 506, 360, 46, 6, 0020D060h
    FILL_GOP_RECT 516, 318, 26, 34, 00D8FFFFh
    FILL_GOP_RECT 524, 326, 10, 20, 00070B12h
    DRAW_3D_BOX 126, -44, 178, 174, 64, 264, 0020D060h
    cmp dword ptr [HitFlashTicks], 0
    je draw_exit_open_no_flash
    FILL_GOP_RECT 508, 312, 42, 46, 00B0FFC8h

draw_exit_open_no_flash:
    jmp draw_exit_ready

draw_exit_locked:
    FILL_GOP_RECT 492, 294, 74, 82, 000B1924h
    FILL_GOP_RECT 498, 300, 62, 70, 00030A10h
    FILL_GOP_RECT 506, 304, 46, 6, 00FF4058h
    FILL_GOP_RECT 506, 360, 46, 6, 003080D0h
    FILL_GOP_RECT 516, 318, 26, 34, 00182A38h
    FILL_GOP_RECT 526, 318, 6, 34, 00FF4058h
    DRAW_3D_BOX 126, -44, 178, 174, 64, 264, 00FF4058h

draw_exit_ready:
    mov ecx, 508
    mov edx, 282
    lea r8, LevelExitLine
    mov r9d, DIAG_MUTED
    cmp dword ptr [ObjectiveState], 2
    jb draw_exit_label
    mov r9d, DIAG_OK
draw_exit_label:
    call DrawString

    cmp dword ptr [EnemyAlive], 0
    je draw_level_clear

    FILL_GOP_RECT 270, 164, 112, 6, 003080D0h
    FILL_GOP_RECT 270, 262, 112, 6, 00FF90FFh
    FILL_GOP_RECT 278, 178, 96, 80, 00070B12h
    cmp dword ptr [HitFlashTicks], 0
    je draw_warden_body_normal
    FILL_GOP_RECT 286, 182, 80, 70, 00FFE66Dh
    FILL_GOP_RECT 298, 192, 56, 48, 00FF90FFh
    jmp draw_warden_body_ready

draw_warden_body_normal:
    FILL_GOP_RECT 282, 174, 88, 92, 00030A10h
    FILL_GOP_RECT 294, 186, 64, 56, 00182A38h

draw_warden_body_ready:
    FILL_GOP_RECT 292, 180, 68, 8, 00A020B0h
    FILL_GOP_RECT 304, 198, 18, 14, 00D8FFFFh
    FILL_GOP_RECT 334, 198, 18, 14, 00FF4058h
    FILL_GOP_RECT 310, 222, 32, 6, 00030A10h
    FILL_GOP_RECT 316, 234, 20, 18, 003080D0h
    FILL_GOP_RECT 274, 220, 28, 6, 00FF90FFh
    FILL_GOP_RECT 350, 220, 28, 6, 00FF90FFh
    FILL_GOP_RECT 306, 246, 40, 5, 00FFE66Dh
    cmp dword ptr [HitFlashTicks], 0
    je draw_warden_box_normal
    DRAW_3D_BOX -46, -10, 154, 46, 78, 226, 00FFE66Dh
    jmp draw_warden_box_done

draw_warden_box_normal:
    DRAW_3D_BOX -46, -10, 154, 46, 78, 226, 00D8FFFFh

draw_warden_box_done:

    cmp dword ptr [EnemyHp], 1
    jb draw_enemy_label
    FILL_GOP_RECT 292, 154, 18, 5, 00FF4058h
    cmp dword ptr [EnemyHp], 2
    jb draw_enemy_label
    FILL_GOP_RECT 316, 154, 18, 5, 00FFE66Dh
    cmp dword ptr [EnemyHp], 3
    jb draw_enemy_label
    FILL_GOP_RECT 340, 154, 18, 5, 0020D060h

draw_enemy_label:
    mov ecx, 292
    mov edx, 138
    lea r8, LevelEnemyLine
    mov r9d, DIAG_WARN
    call DrawString
    jmp draw_level_actor

draw_level_clear:
    FILL_GOP_RECT 288, 222, 64, 8, 0020D060h
    FILL_GOP_RECT 298, 238, 42, 4, 00D8FFFFh
    FILL_GOP_RECT 300, 252, 38, 3, 00FFE66Dh
    mov ecx, 242
    mov edx, 138
    lea r8, LevelClearLine
    cmp dword ptr [ObjectiveState], 2
    jb draw_level_clear_label
    lea r8, LevelExitOpenLine
    cmp dword ptr [ObjectiveState], 3
    jb draw_level_clear_label
    lea r8, LevelCompleteLine
draw_level_clear_label:
    mov r9d, DIAG_OK
    call DrawString

draw_level_actor:
    cmp dword ptr [ShotFlashTicks], 0
    je draw_level_player

    mov ecx, dword ptr [PlayerX]
    mov edx, dword ptr [PlayerY]
    sub edx, 30
    mov r8d, dword ptr [CrosshairX]
    mov r9d, dword ptr [CrosshairY]
    mov eax, 00FFE66Dh
    call DrawGopLine

    mov ecx, dword ptr [PlayerX]
    add ecx, 4
    mov edx, dword ptr [PlayerY]
    sub edx, 26
    mov r8d, dword ptr [CrosshairX]
    add r8d, 3
    mov r9d, dword ptr [CrosshairY]
    add r9d, 2
    mov eax, 00D8FFFFh
    call DrawGopLine

    mov ecx, dword ptr [PlayerX]
    add ecx, 10
    mov edx, dword ptr [PlayerY]
    sub edx, 14
    mov r8d, 28
    mov r9d, 8
    mov eax, 00FFE66Dh
    call DrawGopRect

    mov ecx, dword ptr [CrosshairX]
    sub ecx, 18
    mov edx, dword ptr [CrosshairY]
    sub edx, 18
    mov r8d, 36
    mov r9d, 2
    mov eax, 00FF90FFh
    call DrawGopRect

    mov ecx, dword ptr [CrosshairX]
    sub ecx, 18
    mov edx, dword ptr [CrosshairY]
    add edx, 16
    mov r8d, 36
    mov r9d, 2
    mov eax, 00FF90FFh
    call DrawGopRect

    mov ecx, dword ptr [CrosshairX]
    sub ecx, 18
    mov edx, dword ptr [CrosshairY]
    sub edx, 18
    mov r8d, 2
    mov r9d, 36
    mov eax, 00FFE66Dh
    call DrawGopRect

    mov ecx, dword ptr [CrosshairX]
    sub ecx, 4
    mov edx, dword ptr [CrosshairY]
    sub edx, 4
    mov r8d, 8
    mov r9d, 8
    mov eax, 00E8F8FFh
    call DrawGopRect

    mov ecx, dword ptr [CrosshairX]
    add ecx, 16
    mov edx, dword ptr [CrosshairY]
    sub edx, 18
    mov r8d, 2
    mov r9d, 36
    mov eax, 00FFE66Dh
    call DrawGopRect

    mov ecx, dword ptr [PlayerX]
    sub ecx, 16
    mov edx, dword ptr [PlayerY]
    sub edx, 34
    mov r8d, 32
    mov r9d, 10
    mov eax, 00FF90FFh
    call DrawGopRect

draw_level_player:
    mov ecx, dword ptr [PlayerX]
    sub ecx, 18
    mov edx, dword ptr [PlayerY]
    add edx, 18
    mov r8d, 36
    mov r9d, 4
    mov eax, 00030A10h
    call DrawGopRect

    mov ecx, dword ptr [PlayerX]
    sub ecx, 12
    mov edx, dword ptr [PlayerY]
    sub edx, 18
    mov r8d, 24
    mov r9d, 36
    mov eax, 00D8FFFFh
    call DrawGopRect

    mov ecx, dword ptr [PlayerX]
    sub ecx, 6
    mov edx, dword ptr [PlayerY]
    sub edx, 28
    mov r8d, 12
    mov r9d, 10
    mov eax, 00E8F8FFh
    call DrawGopRect

    mov ecx, dword ptr [PlayerX]
    sub ecx, 16
    mov edx, dword ptr [PlayerY]
    add edx, 14
    mov r8d, 8
    mov r9d, 14
    mov eax, 003080D0h
    call DrawGopRect

    mov ecx, dword ptr [PlayerX]
    add ecx, 8
    mov edx, dword ptr [PlayerY]
    add edx, 14
    mov r8d, 8
    mov r9d, 14
    mov eax, 00FF90FFh
    call DrawGopRect

    mov ecx, dword ptr [PlayerX]
    add ecx, 10
    mov edx, dword ptr [PlayerY]
    sub edx, 8
    mov r8d, 24
    mov r9d, 5
    mov eax, 00FFE66Dh
    call DrawGopRect

    mov ecx, dword ptr [CrosshairX]
    sub ecx, 12
    mov edx, dword ptr [CrosshairY]
    mov r8d, 24
    mov r9d, 2
    mov eax, 00D8FFFFh
    call DrawGopRect

    mov ecx, dword ptr [CrosshairX]
    mov edx, dword ptr [CrosshairY]
    sub edx, 12
    mov r8d, 2
    mov r9d, 24
    mov eax, 00D8FFFFh
    call DrawGopRect

    add rsp, 20h
    pop rdi
    ret
DrawFirstLevel ENDP

DrawFirstLevelHudOverlay PROC
    push rdi
    sub rsp, 20h

    mov eax, dword ptr [GopPresentX]
    mov dword ptr [DrawOffsetX], eax
    mov eax, dword ptr [GopPresentY]
    mov dword ptr [DrawOffsetY], eax
    mov dword ptr [DrawOffsetEnabled], 1

    mov ecx, 0
    mov edx, 0
    mov r8d, 640
    mov r9d, 44
    mov eax, 00070B12h
    call DrawGopRect

    mov ecx, 0
    mov edx, 44
    mov r8d, 640
    mov r9d, 2
    mov eax, 00FF90FFh
    call DrawGopRect

    mov ecx, 44
    mov edx, 456
    mov r8d, 552
    mov r9d, 24
    mov eax, 00070B12h
    call DrawGopRect

    mov ecx, 44
    mov edx, 456
    mov r8d, 552
    mov r9d, 2
    mov eax, 003080D0h
    call DrawGopRect

    mov ecx, 28
    mov edx, 16
    lea r8, LevelTitleLine
    mov r9d, DIAG_TEXT
    call DrawString

    mov ecx, 376
    mov edx, 16
    lea r8, LevelStatusLine
    mov r9d, DIAG_WARN
    call DrawString

    mov ecx, 44
    mov edx, 58
    lea r8, LevelObjectiveKillLine
    cmp dword ptr [ObjectiveState], 1
    jne hud_objective_exit_check
    lea r8, LevelObjectiveBreachLine
    jmp hud_objective_ready

hud_objective_exit_check:
    cmp dword ptr [ObjectiveState], 2
    jne hud_objective_clear_check
    lea r8, LevelObjectiveExitLine
    jmp hud_objective_ready

hud_objective_clear_check:
    cmp dword ptr [ObjectiveState], 3
    jb hud_objective_ready
    lea r8, LevelObjectiveClearLine

hud_objective_ready:
    mov r9d, DIAG_ACCENT
    call DrawString

    mov ecx, 44
    mov edx, 464
    lea r8, LevelHintLine
    mov r9d, DIAG_TEXT
    call DrawString

    cmp dword ptr [EnemyAlive], 0
    je hud_sentry_pips

    cmp dword ptr [EnemyHp], 1
    jb hud_enemy_pips_done
    mov ecx, 292
    mov edx, 96
    mov r8d, 18
    mov r9d, 5
    mov eax, 00FF4058h
    call DrawGopRect
    cmp dword ptr [EnemyHp], 2
    jb hud_enemy_pips_done
    mov ecx, 316
    mov edx, 96
    mov r8d, 18
    mov r9d, 5
    mov eax, 00FFE66Dh
    call DrawGopRect
    cmp dword ptr [EnemyHp], 3
    jb hud_enemy_pips_done
    mov ecx, 340
    mov edx, 96
    mov r8d, 18
    mov r9d, 5
    mov eax, 0020D060h
    call DrawGopRect

hud_enemy_pips_done:
    jmp hud_sentry_pips

hud_enemy_down:
    jmp hud_sentry_pips

    mov ecx, 250
    mov edx, 78
    lea r8, LevelClearLine
    cmp dword ptr [ObjectiveState], 2
    jb hud_enemy_down_label
    lea r8, LevelExitOpenLine
    cmp dword ptr [ObjectiveState], 3
    jb hud_enemy_down_label
    lea r8, LevelCompleteLine

hud_enemy_down_label:
    mov r9d, DIAG_OK
    call DrawString

hud_sentry_pips:
    cmp dword ptr [SentryLeftAlive], 0
    je hud_sentry_right_pip
    mov ecx, 264
    mov edx, 96
    mov r8d, 16
    mov r9d, 5
    mov eax, 00FF90FFh
    call DrawGopRect

hud_sentry_right_pip:
    cmp dword ptr [SentryRightAlive], 0
    je hud_terminal_label
    mov ecx, 364
    mov edx, 96
    mov r8d, 16
    mov r9d, 5
    mov eax, 00FF90FFh
    call DrawGopRect

hud_terminal_label:
    mov ecx, 116
    mov edx, 312
    lea r8, LevelTerminalLine
    mov r9d, DIAG_MUTED
    cmp dword ptr [ObjectiveState], 1
    jb hud_terminal_draw_label
    mov r9d, DIAG_WARN

hud_terminal_draw_label:
    call DrawString

    mov ecx, 500
    mov edx, 306
    lea r8, LevelExitLine
    mov r9d, DIAG_MUTED
    cmp dword ptr [ObjectiveState], 2
    jb hud_exit_draw_label
    mov r9d, DIAG_OK

hud_exit_draw_label:
    call DrawString

hud_after_world_labels:
    cmp dword ptr [ShotFlashTicks], 0
    je hud_crosshair

    mov ecx, 318
    mov edx, 420
    mov r8d, dword ptr [CrosshairX]
    mov r9d, dword ptr [CrosshairY]
    mov eax, 00FFE66Dh
    call DrawGopLine

    mov ecx, 324
    mov edx, 418
    mov r8d, dword ptr [CrosshairX]
    add r8d, 3
    mov r9d, dword ptr [CrosshairY]
    add r9d, 2
    mov eax, 00D8FFFFh
    call DrawGopLine

    mov ecx, 306
    mov edx, 410
    mov r8d, 30
    mov r9d, 8
    mov eax, 00FFE66Dh
    call DrawGopRect

hud_crosshair:
    mov ecx, dword ptr [CrosshairX]
    sub ecx, 12
    mov edx, dword ptr [CrosshairY]
    mov r8d, 24
    mov r9d, 2
    mov eax, 00D8FFFFh
    call DrawGopRect

    mov ecx, dword ptr [CrosshairX]
    mov edx, dword ptr [CrosshairY]
    sub edx, 12
    mov r8d, 2
    mov r9d, 24
    mov eax, 00D8FFFFh
    call DrawGopRect

    cmp dword ptr [ShotFlashTicks], 0
    je hud_weapon

    mov ecx, dword ptr [CrosshairX]
    sub ecx, 18
    mov edx, dword ptr [CrosshairY]
    sub edx, 18
    mov r8d, 36
    mov r9d, 2
    mov eax, 00FF90FFh
    call DrawGopRect

    mov ecx, dword ptr [CrosshairX]
    sub ecx, 18
    mov edx, dword ptr [CrosshairY]
    add edx, 16
    mov r8d, 36
    mov r9d, 2
    mov eax, 00FF90FFh
    call DrawGopRect

    mov ecx, dword ptr [CrosshairX]
    sub ecx, 18
    mov edx, dword ptr [CrosshairY]
    sub edx, 18
    mov r8d, 2
    mov r9d, 36
    mov eax, 00FFE66Dh
    call DrawGopRect

    mov ecx, dword ptr [CrosshairX]
    add ecx, 16
    mov edx, dword ptr [CrosshairY]
    sub edx, 18
    mov r8d, 2
    mov r9d, 36
    mov eax, 00FFE66Dh
    call DrawGopRect

hud_weapon:
    mov ecx, 286
    mov edx, 414
    mov r8d, 68
    mov r9d, 18
    mov eax, 00030A10h
    call DrawGopRect

    mov ecx, 308
    mov edx, 398
    mov r8d, 28
    mov r9d, 22
    mov eax, 00182A38h
    call DrawGopRect

    mov ecx, 324
    mov edx, 404
    mov r8d, 42
    mov r9d, 8
    mov eax, 00FFE66Dh
    call DrawGopRect

    mov ecx, 314
    mov edx, 396
    mov r8d, 14
    mov r9d, 6
    mov eax, 00E8F8FFh
    call DrawGopRect

    mov dword ptr [DrawOffsetEnabled], 0
    add rsp, 20h
    pop rdi
    ret
DrawFirstLevelHudOverlay ENDP

RenderTexturedLevelFromChunks PROC
    push rbx
    push rsi
    push rdi
    push r12
    push r13
    push r14
    push r15
    sub rsp, 20h

    cmp dword ptr [AssetValidationStatus], 0
    jne render_chunks_fail
    cmp qword ptr [TextureAtlasPixels], 0
    je render_chunks_fail
    cmp qword ptr [MaterialRecordBase], 0
    je render_chunks_fail
    cmp qword ptr [MeshVertexBase], 0
    je render_chunks_fail
    cmp qword ptr [MeshTriangleBase], 0
    je render_chunks_fail
    cmp dword ptr [MeshTriangleCount], 0
    je render_chunks_fail

    xor r12d, r12d

render_chunks_loop:
    cmp r12d, dword ptr [MeshTriangleCount]
    jae render_chunks_ok

    mov rbx, qword ptr [MeshTriangleBase]
    mov eax, r12d
    imul eax, eax, MESH_TRIANGLE_BYTES
    add rbx, rax

    movzx eax, word ptr [rbx + 6]
    mov dword ptr [TriangleMaterialIndex], eax
    cmp eax, 7
    jne render_chunks_material_visible
    cmp dword ptr [EnemyAlive], 0
    je render_chunks_next

render_chunks_material_visible:
    mov rsi, qword ptr [MaterialRecordBase]
    mov ecx, dword ptr [TriangleMaterialIndex]
    shl rcx, 4
    add rsi, rcx
    mov eax, dword ptr [rsi]
    mov dword ptr [TriangleBaseColor], eax
    mov eax, dword ptr [rsi + 4]
    mov dword ptr [TriangleTextureTile], eax
    mov eax, dword ptr [rsi + 8]
    mov dword ptr [TriangleMaterialFlags], eax

    movzx eax, byte ptr [rbx + 8]
    mov dword ptr [ProjectedU0], eax
    movzx eax, byte ptr [rbx + 9]
    mov dword ptr [ProjectedV0], eax
    movzx eax, byte ptr [rbx + 10]
    mov dword ptr [ProjectedU1], eax
    movzx eax, byte ptr [rbx + 11]
    mov dword ptr [ProjectedV1], eax
    movzx eax, byte ptr [rbx + 12]
    mov dword ptr [ProjectedU2], eax
    movzx eax, byte ptr [rbx + 13]
    mov dword ptr [ProjectedV2], eax

    movzx eax, word ptr [rbx]
    cmp eax, dword ptr [MeshVertexCount]
    jae render_chunks_reject
    mov rdi, qword ptr [MeshVertexBase]
    imul rax, rax, MESH_VERTEX_BYTES
    add rdi, rax
    movsx ecx, word ptr [rdi]
    movsx edx, word ptr [rdi + 2]
    movsx r8d, word ptr [rdi + 4]
    mov r11d, r8d
    sub r11d, dword ptr [LevelCameraZ]
    cmp r11d, RENDER_NEAR_PLANE
    jl render_chunks_near_reject
    call ProjectLevelPoint3D
    mov dword ptr [ProjectedX0], eax
    mov dword ptr [ProjectedY0], edx
    mov dword ptr [ProjectedZ0], r8d

    movzx eax, word ptr [rbx + 2]
    cmp eax, dword ptr [MeshVertexCount]
    jae render_chunks_reject
    mov rdi, qword ptr [MeshVertexBase]
    imul rax, rax, MESH_VERTEX_BYTES
    add rdi, rax
    movsx ecx, word ptr [rdi]
    movsx edx, word ptr [rdi + 2]
    movsx r8d, word ptr [rdi + 4]
    mov r11d, r8d
    sub r11d, dword ptr [LevelCameraZ]
    cmp r11d, RENDER_NEAR_PLANE
    jl render_chunks_near_reject
    call ProjectLevelPoint3D
    mov dword ptr [ProjectedX1], eax
    mov dword ptr [ProjectedY1], edx
    mov dword ptr [ProjectedZ1], r8d

    movzx eax, word ptr [rbx + 4]
    cmp eax, dword ptr [MeshVertexCount]
    jae render_chunks_reject
    mov rdi, qword ptr [MeshVertexBase]
    imul rax, rax, MESH_VERTEX_BYTES
    add rdi, rax
    movsx ecx, word ptr [rdi]
    movsx edx, word ptr [rdi + 2]
    movsx r8d, word ptr [rdi + 4]
    mov r11d, r8d
    sub r11d, dword ptr [LevelCameraZ]
    cmp r11d, RENDER_NEAR_PLANE
    jl render_chunks_near_reject
    call ProjectLevelPoint3D
    mov dword ptr [ProjectedX2], eax
    mov dword ptr [ProjectedY2], edx
    mov dword ptr [ProjectedZ2], r8d

    mov dword ptr [TriangleTexturedMode], 1
    mov eax, dword ptr [TriangleBaseColor]
    call DrawProjectedTriangleDepth
    mov dword ptr [TriangleTexturedMode], 0
    jmp render_chunks_next

render_chunks_near_reject:
    inc dword ptr [RendererNearRejectedTriangles]

render_chunks_reject:
    inc dword ptr [RendererRejectedTriangles]

render_chunks_next:
    inc r12d
    jmp render_chunks_loop

render_chunks_ok:
    mov dword ptr [TriangleTexturedMode], 0
    xor eax, eax
    jmp render_chunks_done

render_chunks_fail:
    mov dword ptr [TriangleTexturedMode], 0
    mov eax, 1

render_chunks_done:
    add rsp, 20h
    pop r15
    pop r14
    pop r13
    pop r12
    pop rdi
    pop rsi
    pop rbx
    ret
RenderTexturedLevelFromChunks ENDP

RenderLevelRayTracePass PROC
    push rbx
    push rsi
    push rdi
    push r12
    push r13
    push r14
    push r15

    mov r12d, 304

raytrace_row_loop:
    cmp r12d, 448
    jg raytrace_done

    mov ebx, r12d
    sub ebx, 270
    cmp ebx, 16
    jge raytrace_denominator_ready
    mov ebx, 16

raytrace_denominator_ready:
    mov r14d, 96

raytrace_column_loop:
    cmp r14d, 544
    jg raytrace_next_row

    inc dword ptr [RendererRayCount]

    mov eax, r14d
    sub eax, 320
    imul eax, 320
    cdq
    idiv ebx
    add eax, dword ptr [LevelCameraX]
    mov r8d, eax

    mov eax, 43200
    cdq
    idiv ebx
    add eax, dword ptr [LevelCameraZ]
    mov r9d, eax

    cmp r9d, 72
    jl raytrace_skip
    cmp r9d, 760
    jg raytrace_skip

    xor r15d, r15d

    cmp dword ptr [EnemyAlive], 0
    je raytrace_left_sentry_shadow
    cmp r8d, -76
    jl raytrace_left_sentry_shadow
    cmp r8d, 76
    jg raytrace_left_sentry_shadow
    cmp r9d, 142
    jl raytrace_left_sentry_shadow
    cmp r9d, 286
    jg raytrace_left_sentry_shadow
    mov r15d, 00030608h
    inc dword ptr [RendererRayShadowHits]
    jmp raytrace_write_hit

raytrace_left_sentry_shadow:
    cmp dword ptr [SentryLeftAlive], 0
    je raytrace_right_sentry_shadow
    cmp r8d, -148
    jl raytrace_right_sentry_shadow
    cmp r8d, -54
    jg raytrace_right_sentry_shadow
    cmp r9d, 284
    jl raytrace_right_sentry_shadow
    cmp r9d, 382
    jg raytrace_right_sentry_shadow
    mov r15d, 00030608h
    inc dword ptr [RendererRayShadowHits]
    jmp raytrace_write_hit

raytrace_right_sentry_shadow:
    cmp dword ptr [SentryRightAlive], 0
    je raytrace_light_tests
    cmp r8d, 54
    jl raytrace_light_tests
    cmp r8d, 148
    jg raytrace_light_tests
    cmp r9d, 284
    jl raytrace_light_tests
    cmp r9d, 382
    jg raytrace_light_tests
    mov r15d, 00030608h
    inc dword ptr [RendererRayShadowHits]
    jmp raytrace_write_hit

raytrace_light_tests:
    cmp r8d, -180
    jl raytrace_right_rail
    cmp r8d, -126
    jg raytrace_right_rail
    mov eax, r9d
    add eax, dword ptr [LevelPulseTicks]
    and eax, 0000003Fh
    cmp eax, 24
    ja raytrace_right_rail
    mov r15d, dword ptr [LevelRailColor]
    jmp raytrace_write_hit

raytrace_right_rail:
    cmp r8d, 126
    jl raytrace_center_wet_lane
    cmp r8d, 180
    jg raytrace_center_wet_lane
    mov eax, r9d
    add eax, dword ptr [LevelPulseTicks]
    and eax, 0000003Fh
    cmp eax, 24
    ja raytrace_center_wet_lane
    mov r15d, dword ptr [LevelRailColor]
    jmp raytrace_write_hit

raytrace_center_wet_lane:
    cmp r8d, -36
    jl raytrace_terminal_glow
    cmp r8d, 36
    jg raytrace_terminal_glow
    mov eax, r9d
    and eax, 0000001Fh
    cmp eax, 10
    ja raytrace_terminal_glow
    mov r15d, 003080D0h
    jmp raytrace_write_hit

raytrace_terminal_glow:
    cmp r8d, -220
    jl raytrace_exit_glow
    cmp r8d, -70
    jg raytrace_exit_glow
    cmp r9d, 210
    jl raytrace_exit_glow
    cmp r9d, 410
    jg raytrace_exit_glow
    mov r15d, dword ptr [LevelTerminalColor]
    jmp raytrace_write_hit

raytrace_exit_glow:
    cmp r8d, 72
    jl raytrace_shot_glint
    cmp r8d, 240
    jg raytrace_shot_glint
    cmp r9d, 248
    jl raytrace_shot_glint
    cmp r9d, 458
    jg raytrace_shot_glint
    mov r15d, dword ptr [LevelExitColor]
    jmp raytrace_write_hit

raytrace_shot_glint:
    cmp dword ptr [ShotFlashTicks], 0
    je raytrace_skip
    cmp r8d, -24
    jl raytrace_skip
    cmp r8d, 24
    jg raytrace_skip
    cmp r9d, 110
    jl raytrace_skip
    cmp r9d, 520
    jg raytrace_skip
    mov r15d, 00FFE66Dh

raytrace_write_hit:
    test r15d, r15d
    jz raytrace_skip
    inc dword ptr [RendererRayHits]

    mov eax, r12d
    imul eax, eax, ENGINE64_EXPECTED_WIDTH
    add eax, r14d
    shl rax, 2
    mov rdi, qword ptr [FrameArenaBase]
    add rdi, rax
    mov ecx, 4

raytrace_blend_row0:
    mov eax, dword ptr [rdi]
    cmp r15d, 00030608h
    jne raytrace_blend_glow0
    and eax, 00FCFCFCh
    shr eax, 2
    add eax, 00010203h
    jmp raytrace_store0

raytrace_blend_glow0:
    and eax, 00FEFEFEh
    shr eax, 1
    mov edx, r15d
    and edx, 00FEFEFEh
    shr edx, 1
    add eax, edx

raytrace_store0:
    mov dword ptr [rdi], eax
    add rdi, 4
    loop raytrace_blend_row0

    mov eax, r12d
    inc eax
    cmp eax, ENGINE64_EXPECTED_HEIGHT
    jae raytrace_skip
    imul eax, eax, ENGINE64_EXPECTED_WIDTH
    add eax, r14d
    shl rax, 2
    mov rdi, qword ptr [FrameArenaBase]
    add rdi, rax
    mov ecx, 4

raytrace_blend_row1:
    mov eax, dword ptr [rdi]
    cmp r15d, 00030608h
    jne raytrace_blend_glow1
    and eax, 00FCFCFCh
    shr eax, 2
    add eax, 00010203h
    jmp raytrace_store1

raytrace_blend_glow1:
    and eax, 00FEFEFEh
    shr eax, 1
    mov edx, r15d
    and edx, 00FEFEFEh
    shr edx, 1
    add eax, edx

raytrace_store1:
    mov dword ptr [rdi], eax
    add rdi, 4
    loop raytrace_blend_row1

raytrace_skip:
    add r14d, 4
    jmp raytrace_column_loop

raytrace_next_row:
    add r12d, 4
    jmp raytrace_row_loop

raytrace_done:
    pop r15
    pop r14
    pop r13
    pop r12
    pop rdi
    pop rsi
    pop rbx
    ret
RenderLevelRayTracePass ENDP

RenderLevelAtmospherePass PROC
    push rbx
    push rsi
    push rdi
    push r12
    push r13
    push r14
    push r15

    mov r12d, 176

atmosphere_row_loop:
    cmp r12d, 336
    jg atmosphere_done

    mov r14d, 96

atmosphere_column_loop:
    cmp r14d, 544
    jg atmosphere_next_row

    inc dword ptr [RendererAtmosphereSamples]
    xor r15d, r15d

    mov eax, r14d
    add eax, r12d
    add eax, dword ptr [LevelPulseTicks]
    and eax, 0000003Fh
    cmp eax, 44
    ja atmosphere_center_shaft

    mov eax, r12d
    sub eax, 176
    sar eax, 1
    add eax, 184
    mov ebx, r14d
    sub ebx, eax
    jns atmosphere_left_abs_ready
    neg ebx

atmosphere_left_abs_ready:
    cmp ebx, 20
    ja atmosphere_right_shaft
    mov r15d, 003080D0h
    jmp atmosphere_write_hit

atmosphere_right_shaft:
    mov eax, r12d
    sub eax, 176
    sar eax, 1
    mov ebx, 456
    sub ebx, eax
    mov eax, r14d
    sub eax, ebx
    jns atmosphere_right_abs_ready
    neg eax

atmosphere_right_abs_ready:
    cmp eax, 20
    ja atmosphere_center_shaft
    mov r15d, 00FF90FFh
    jmp atmosphere_write_hit

atmosphere_center_shaft:
    cmp r12d, 214
    jl atmosphere_shot_bloom
    cmp r14d, 292
    jl atmosphere_shot_bloom
    cmp r14d, 348
    jg atmosphere_shot_bloom
    mov eax, r14d
    sub eax, 320
    jns atmosphere_center_abs_ready
    neg eax

atmosphere_center_abs_ready:
    cmp eax, 12
    ja atmosphere_shot_bloom
    mov r15d, 00FFE66Dh
    jmp atmosphere_write_hit

atmosphere_shot_bloom:
    cmp dword ptr [ShotFlashTicks], 0
    je atmosphere_skip
    cmp r12d, 244
    jl atmosphere_skip
    cmp r12d, 328
    jg atmosphere_skip
    mov eax, r14d
    sub eax, 320
    jns atmosphere_shot_abs_ready
    neg eax

atmosphere_shot_abs_ready:
    cmp eax, 38
    ja atmosphere_skip
    mov r15d, 00FFE66Dh

atmosphere_write_hit:
    test r15d, r15d
    jz atmosphere_skip
    inc dword ptr [RendererAtmosphereHits]

    mov eax, r12d
    imul eax, eax, ENGINE64_EXPECTED_WIDTH
    add eax, r14d
    shl rax, 2
    mov rdi, qword ptr [FrameArenaBase]
    add rdi, rax
    mov ecx, 6

atmosphere_blend_row0:
    mov eax, dword ptr [rdi]
    mov edx, eax
    and eax, 00FEFEFEh
    shr eax, 1
    and edx, 00FCFCFCh
    shr edx, 2
    add eax, edx
    mov edx, r15d
    and edx, 00FCFCFCh
    shr edx, 2
    add eax, edx
    mov dword ptr [rdi], eax
    add rdi, 4
    loop atmosphere_blend_row0

    mov eax, r12d
    inc eax
    imul eax, eax, ENGINE64_EXPECTED_WIDTH
    add eax, r14d
    shl rax, 2
    mov rdi, qword ptr [FrameArenaBase]
    add rdi, rax
    mov ecx, 6

atmosphere_blend_row1:
    mov eax, dword ptr [rdi]
    mov edx, eax
    and eax, 00FEFEFEh
    shr eax, 1
    and edx, 00FCFCFCh
    shr edx, 2
    add eax, edx
    mov edx, r15d
    and edx, 00FCFCFCh
    shr edx, 2
    add eax, edx
    mov dword ptr [rdi], eax
    add rdi, 4
    loop atmosphere_blend_row1

atmosphere_skip:
    add r14d, 6
    jmp atmosphere_column_loop

atmosphere_next_row:
    add r12d, 6
    jmp atmosphere_row_loop

atmosphere_done:
    pop r15
    pop r14
    pop r13
    pop r12
    pop rdi
    pop rsi
    pop rbx
    ret
RenderLevelAtmospherePass ENDP

RenderFirstLevel3DFrame PROC
    sub rsp, 20h

    mov dword ptr [RenderStatus], RENDER_STATUS_FRAME_ARENA
    mov dword ptr [PresentStatus], PRESENT_STATUS_NO_FRAME
    mov dword ptr [RenderFramePixels], 0
    mov dword ptr [PresentFramePixels], 0
    mov dword ptr [TriangleTexturedMode], 0
    mov dword ptr [RendererTriangleCount], 0
    mov dword ptr [RendererTexturedTriangleCount], 0
    mov dword ptr [RendererRejectedTriangles], 0
    mov dword ptr [RendererNearRejectedTriangles], 0
    mov dword ptr [RendererDepthWrites], 0
    mov dword ptr [RendererRayCount], 0
    mov dword ptr [RendererRayHits], 0
    mov dword ptr [RendererRayShadowHits], 0
    mov dword ptr [RendererAtmosphereSamples], 0
    mov dword ptr [RendererAtmosphereHits], 0

    mov rax, qword ptr [FrameArenaBase]
    test rax, rax
    jz render_level_fail
    cmp qword ptr [FrameArenaSize], ENGINE64_FRAME_BYTES
    jb render_level_fail

    mov rax, qword ptr [DepthArenaBase]
    test rax, rax
    jz render_level_fail
    cmp qword ptr [DepthArenaSize], ENGINE64_FRAME_BYTES
    jb render_level_fail

    call UpdateLevelCameraFromPlayer

    mov eax, dword ptr [LevelPulseTicks]
    and eax, 00000008h
    jz render_level_pulse_cyan
    mov dword ptr [LevelRailColor], 00FF90FFh
    jmp render_level_pulse_ready

render_level_pulse_cyan:
    mov dword ptr [LevelRailColor], 00D8FFFFh

render_level_pulse_ready:
    mov dword ptr [LevelTerminalColor], 00FF4058h
    mov dword ptr [LevelScreenColor], 003080D0h
    cmp dword ptr [ObjectiveState], 1
    jb render_level_terminal_color_ready
    mov dword ptr [LevelTerminalColor], 00FFE66Dh
    mov dword ptr [LevelScreenColor], 00FFE66Dh
    cmp dword ptr [ObjectiveState], 2
    jb render_level_terminal_color_ready
    mov dword ptr [LevelTerminalColor], 0020D060h
    mov dword ptr [LevelScreenColor], 00B0FFC8h

render_level_terminal_color_ready:
    mov dword ptr [LevelExitColor], 00FF4058h
    mov dword ptr [LevelExitCoreColor], 00182A38h
    cmp dword ptr [ObjectiveState], 2
    jb render_level_exit_color_ready
    mov dword ptr [LevelExitColor], 0020D060h
    mov dword ptr [LevelExitCoreColor], 00D8FFFFh

render_level_exit_color_ready:
    mov dword ptr [LevelWardenColor], 00182A38h
    mov dword ptr [LevelSentryColor], 00FF4058h
    cmp dword ptr [HitFlashTicks], 0
    je render_level_warden_color_ready
    mov dword ptr [LevelWardenColor], 00FFE66Dh
    mov dword ptr [LevelSentryColor], 00FFE66Dh

render_level_warden_color_ready:
    mov eax, 0004080Dh
    call ClearInternalFrame
    call ClearDepthBuffer

    mov ecx, 0
    mov edx, 0
    mov r8d, 640
    mov r9d, 152
    mov eax, 0004080Dh
    call FillFrameRect

    mov ecx, 0
    mov edx, 152
    mov r8d, 640
    mov r9d, 120
    mov eax, 00070B12h
    call FillFrameRect

    mov ecx, 0
    mov edx, 272
    mov r8d, 640
    mov r9d, 208
    mov eax, 00030A10h
    call FillFrameRect

    call RenderTexturedLevelFromChunks
    test eax, eax
    jnz render_level_chunk_fallback
    mov dword ptr [TriangleTexturedMode], 0
    jmp render_level_runtime_actors

render_level_chunk_fallback:
    mov dword ptr [TriangleTexturedMode], 0

    DRAW_LEVEL_QUAD -260, -64, 96, 260, -64, 96, 260, -64, 540, -260, -64, 540, 000B1924h
    DRAW_LEVEL_QUAD -86, -62, 96, 86, -62, 96, 86, -62, 540, -86, -62, 540, 00182A38h
    DRAW_LEVEL_QUAD -260, 130, 96, 260, 130, 96, 260, 130, 540, -260, 130, 540, 00070B12h
    DRAW_LEVEL_QUAD -260, -64, 96, -260, -64, 540, -260, 130, 540, -260, 130, 96, 00030A10h
    DRAW_LEVEL_QUAD 260, -64, 540, 260, -64, 96, 260, 130, 96, 260, 130, 540, 00030A10h
    DRAW_LEVEL_QUAD -260, -64, 540, 260, -64, 540, 260, 130, 540, -260, 130, 540, 00101820h

    DRAW_LEVEL_QUAD -260, -63, 124, 260, -63, 124, 260, -63, 134, -260, -63, 134, 00203244h
    DRAW_LEVEL_QUAD -260, -63, 174, 260, -63, 174, 260, -63, 188, -260, -63, 188, 00142632h
    DRAW_LEVEL_QUAD -260, -63, 246, 260, -63, 246, 260, -63, 264, -260, -63, 264, 00203244h
    DRAW_LEVEL_QUAD -260, -63, 348, 260, -63, 348, 260, -63, 372, -260, -63, 372, 00142632h
    DRAW_LEVEL_QUAD -16, -61, 96, 16, -61, 96, 16, -61, 540, -16, -61, 540, 00203244h
    DRAW_LEVEL_QUAD -132, -61, 96, -108, -61, 96, -108, -61, 540, -132, -61, 540, 00070B12h
    DRAW_LEVEL_QUAD 108, -61, 96, 132, -61, 96, 132, -61, 540, 108, -61, 540, 00070B12h
    DRAW_LEVEL_TRI -78, -60, 142, 0, -60, 116, 78, -60, 142, 00FFE66Dh
    DRAW_LEVEL_TRI -98, -60, 220, 0, -60, 184, 98, -60, 220, 003080D0h
    DRAW_LEVEL_TRI -122, -60, 336, 0, -60, 288, 122, -60, 336, 00FF90FFh
    DRAW_LEVEL_TRI -150, -60, 486, 0, -60, 424, 150, -60, 486, 00D8FFFFh

    DRAW_LEVEL_BOX_FILLED -260, 114, 120, 260, 130, 146, 00142632h
    DRAW_LEVEL_BOX_FILLED -260, 114, 206, 260, 130, 234, 00101820h
    DRAW_LEVEL_BOX_FILLED -260, 114, 326, 260, 130, 362, 00142632h
    DRAW_LEVEL_BOX_FILLED -214, 72, 156, -150, 110, 218, 00182A38h
    DRAW_LEVEL_BOX_FILLED 150, 72, 156, 214, 110, 218, 00182A38h
    DRAW_LEVEL_BOX_FILLED -208, 68, 272, -134, 106, 334, 00101820h
    DRAW_LEVEL_BOX_FILLED 134, 68, 272, 208, 106, 334, 00101820h
    DRAW_LEVEL_QUAD -232, 36, 138, -232, 36, 178, -232, 74, 178, -232, 74, 138, 00D8FFFFh
    DRAW_LEVEL_QUAD 232, 36, 178, 232, 36, 138, 232, 74, 138, 232, 74, 178, 00FF90FFh
    DRAW_LEVEL_QUAD -232, 12, 238, -232, 12, 296, -232, 70, 296, -232, 70, 238, 00FFE66Dh
    DRAW_LEVEL_QUAD 232, 12, 296, 232, 12, 238, 232, 70, 238, 232, 70, 296, 00FF4058h
    DRAW_LEVEL_QUAD -232, 30, 384, -232, 30, 470, -232, 86, 470, -232, 86, 384, 003080D0h
    DRAW_LEVEL_QUAD 232, 30, 470, 232, 30, 384, 232, 86, 384, 232, 86, 470, 0020D060h
    DRAW_LEVEL_TRI -258, -24, 136, -258, 42, 178, -258, -24, 220, 003080D0h
    DRAW_LEVEL_TRI 258, -24, 220, 258, 42, 178, 258, -24, 136, 00FF90FFh
    DRAW_LEVEL_TRI -258, 0, 276, -258, 72, 328, -258, 0, 386, 00D8FFFFh
    DRAW_LEVEL_TRI 258, 0, 386, 258, 72, 328, 258, 0, 276, 00FFE66Dh

    DRAW_LEVEL_QUAD -166, -58, 96, -146, -58, 96, -146, -58, 540, -166, -58, 540, dword ptr [LevelRailColor]
    DRAW_LEVEL_QUAD 146, -58, 96, 166, -58, 96, 166, -58, 540, 146, -58, 540, dword ptr [LevelRailColor]
    DRAW_LEVEL_QUAD -190, -60, 248, -88, -60, 248, -88, -60, 356, -190, -60, 356, dword ptr [LevelTerminalColor]
    DRAW_LEVEL_QUAD 108, -60, 300, 220, -60, 300, 220, -60, 420, 108, -60, 420, dword ptr [LevelExitColor]
    DRAW_LEVEL_QUAD -258, 0, 96, -258, 0, 540, -258, 12, 540, -258, 12, 96, 003080D0h
    DRAW_LEVEL_QUAD 258, 0, 540, 258, 0, 96, 258, 12, 96, 258, 12, 540, 00FF90FFh
    DRAW_LEVEL_QUAD -216, 92, 116, 216, 92, 116, 216, 92, 520, -216, 92, 520, 000B1924h
    DRAW_LEVEL_QUAD -220, 104, 138, 220, 104, 138, 220, 104, 520, -220, 104, 520, dword ptr [LevelRailColor]

    DRAW_LEVEL_BOX_FILLED -248, -64, 128, -204, 112, 220, 00101820h
    DRAW_LEVEL_BOX_FILLED 204, -64, 128, 248, 112, 220, 00101820h
    DRAW_LEVEL_BOX_FILLED -120, -64, 138, -92, -20, 186, 00142632h
    DRAW_LEVEL_BOX_FILLED 92, -64, 138, 120, -20, 186, 00142632h
    DRAW_LEVEL_BOX_FILLED -18, -64, 310, 18, -28, 360, 00182A38h
    DRAW_LEVEL_BOX_FILLED -236, -60, 300, -204, 118, 382, 00070B12h
    DRAW_LEVEL_BOX_FILLED 204, -60, 300, 236, 118, 382, 00070B12h
    DRAW_LEVEL_BOX_FILLED -250, -64, 420, -210, 120, 512, 00142632h
    DRAW_LEVEL_BOX_FILLED 210, -64, 420, 250, 120, 512, 00142632h
    DRAW_LEVEL_BOX_FILLED -90, 82, 430, -48, 122, 520, 00101820h
    DRAW_LEVEL_BOX_FILLED 48, 82, 430, 90, 122, 520, 00101820h
    DRAW_LEVEL_QUAD -90, 74, 452, 90, 74, 452, 90, 86, 484, -90, 86, 484, 003080D0h

    DRAW_LEVEL_BOX_FILLED -178, -64, 268, -108, 48, 338, dword ptr [LevelTerminalColor]
    DRAW_LEVEL_QUAD -164, -2, 258, -122, -2, 258, -122, 32, 258, -164, 32, 258, dword ptr [LevelScreenColor]
    DRAW_LEVEL_BOX_FILLED -158, -64, 338, -128, -14, 390, 000B1924h
    DRAW_LEVEL_QUAD -196, -36, 248, -170, -12, 232, -118, -12, 232, -92, -36, 248, 00182A38h
    DRAW_LEVEL_QUAD -188, -50, 246, -100, -50, 246, -116, -36, 282, -174, -36, 282, dword ptr [LevelScreenColor]
    DRAW_LEVEL_TRI -178, 52, 286, -140, 86, 304, -108, 52, 322, 00D8FFFFh

    DRAW_LEVEL_BOX_FILLED 128, -64, 270, 190, 106, 348, dword ptr [LevelExitColor]
    DRAW_LEVEL_QUAD 144, -44, 264, 176, -44, 264, 176, 76, 264, 144, 76, 264, dword ptr [LevelExitCoreColor]
    DRAW_LEVEL_BOX_FILLED 118, -64, 348, 200, 116, 402, 00070B12h
    DRAW_LEVEL_BOX_FILLED 110, -64, 248, 126, 114, 408, 00101820h
    DRAW_LEVEL_BOX_FILLED 192, -64, 248, 208, 114, 408, 00101820h
    DRAW_LEVEL_BOX_FILLED 110, 96, 248, 208, 118, 408, 00142632h
    DRAW_LEVEL_TRI 126, 78, 250, 160, 118, 282, 192, 78, 250, dword ptr [LevelExitCoreColor]

render_level_runtime_actors:
    call RenderLevelRayTracePass
    call RenderLevelAtmospherePass

    cmp dword ptr [EnemyAlive], 0
    je render_level_warden_down

    DRAW_LEVEL_BOX_FILLED -54, -22, 174, 54, 88, 252, dword ptr [LevelWardenColor]
    DRAW_LEVEL_TRI -86, 26, 192, -54, 82, 214, -54, 10, 250, dword ptr [LevelWardenColor]
    DRAW_LEVEL_TRI 86, 26, 192, 54, 10, 250, 54, 82, 214, dword ptr [LevelWardenColor]
    DRAW_LEVEL_TRI -44, 88, 188, 0, 126, 224, 44, 88, 188, 00142632h
    DRAW_LEVEL_BOX_FILLED -34, 0, 162, 34, 68, 218, 00070B12h
    DRAW_LEVEL_QUAD -30, 22, 158, -8, 22, 158, -8, 38, 158, -30, 38, 158, 00D8FFFFh
    DRAW_LEVEL_QUAD 8, 22, 158, 30, 22, 158, 30, 38, 158, 8, 38, 158, 00FF4058h
    DRAW_LEVEL_BOX_FILLED -72, 4, 190, -52, 28, 242, 00FF90FFh
    DRAW_LEVEL_BOX_FILLED 52, 4, 190, 72, 28, 242, 00FF90FFh
    DRAW_LEVEL_BOX_FILLED -18, -48, 206, 18, -20, 246, 003080D0h
    jmp render_level_sentries

render_level_warden_down:
    DRAW_LEVEL_BOX_FILLED -42, -64, 194, 42, -44, 252, 0020D060h
    DRAW_LEVEL_QUAD -70, -56, 206, 70, -56, 206, 50, -52, 280, -50, -52, 280, 00D8FFFFh

render_level_sentries:
    cmp dword ptr [SentryLeftAlive], 0
    je render_level_left_sentry_down
    DRAW_LEVEL_BOX_FILLED -126, -18, 294, -74, 56, 356, dword ptr [LevelSentryColor]
    DRAW_LEVEL_TRI -150, 18, 312, -126, 54, 334, -126, -8, 350, dword ptr [LevelSentryColor]
    DRAW_LEVEL_BOX_FILLED -112, 2, 286, -86, 34, 314, 00070B12h
    DRAW_LEVEL_QUAD -106, 10, 282, -92, 10, 282, -92, 26, 282, -106, 26, 282, 00FFE66Dh
    DRAW_LEVEL_BOX_FILLED -96, -50, 318, -78, -18, 350, 003080D0h
    jmp render_level_right_sentry

render_level_left_sentry_down:
    DRAW_LEVEL_BOX_FILLED -124, -64, 306, -76, -52, 360, 0020D060h
    DRAW_LEVEL_QUAD -144, -58, 318, -84, -58, 318, -92, -54, 372, -134, -54, 372, 00D8FFFFh

render_level_right_sentry:
    cmp dword ptr [SentryRightAlive], 0
    je render_level_right_sentry_down
    DRAW_LEVEL_BOX_FILLED 74, -18, 294, 126, 56, 356, dword ptr [LevelSentryColor]
    DRAW_LEVEL_TRI 150, 18, 312, 126, -8, 350, 126, 54, 334, dword ptr [LevelSentryColor]
    DRAW_LEVEL_BOX_FILLED 86, 2, 286, 112, 34, 314, 00070B12h
    DRAW_LEVEL_QUAD 92, 10, 282, 106, 10, 282, 106, 26, 282, 92, 26, 282, 00D8FFFFh
    DRAW_LEVEL_BOX_FILLED 78, -50, 318, 96, -18, 350, 003080D0h
    jmp render_level_actor_done

render_level_right_sentry_down:
    DRAW_LEVEL_BOX_FILLED 76, -64, 306, 124, -52, 360, 0020D060h
    DRAW_LEVEL_QUAD 84, -58, 318, 144, -58, 318, 134, -54, 372, 92, -54, 372, 00D8FFFFh

render_level_actor_done:
    mov qword ptr [FrameArenaUsed], ENGINE64_FRAME_BYTES
    mov qword ptr [FrameArenaFree], ARENA_FRAME_BYTES - ENGINE64_FRAME_BYTES
    mov dword ptr [RenderFramePixels], ENGINE64_FRAME_PIXELS
    mov dword ptr [RenderStatus], RENDER_STATUS_OK
    xor eax, eax
    jmp render_level_done

render_level_fail:
    mov eax, 1

render_level_done:
    add rsp, 20h
    ret
RenderFirstLevel3DFrame ENDP

DrawDiagnosticsScreen PROC
    push rdi
    sub rsp, 20h

    call FormatDiagnosticLines
    mov eax, DIAG_BG
    call FillScreen
    call DrawEngine64Showcase

    FILL_GOP_RECT 24, 18, 592, 64, DIAG_HEADER
    FILL_GOP_RECT 40, 48, 340, 6, DIAG_ACCENT
    FILL_GOP_RECT 24, 96, 592, 368, DIAG_PANEL
    FILL_GOP_RECT 40, 124, 560, 3, DIAG_MUTED
    FILL_GOP_RECT 32, 440, 360, 28, DIAG_GREEN
    FILL_GOP_RECT 424, 440, 160, 28, DIAG_MAGENTA

    mov ecx, 40
    mov edx, 30
    lea r8, TitleLine
    mov r9d, DIAG_TEXT
    call DrawString

    mov ecx, 40
    mov edx, 56
    lea r8, SubtitleLine
    mov r9d, DIAG_TEXT
    call DrawString

    mov ecx, 40
    mov edx, 108
    lea r8, ResLine
    mov r9d, DIAG_TEXT
    call DrawString

    mov ecx, 40
    mov edx, 132
    lea r8, PixelLine
    mov r9d, DIAG_TEXT
    call DrawString

    mov ecx, 40
    mov edx, 156
    lea r8, FrameLine
    mov r9d, DIAG_TEXT
    call DrawString

    mov ecx, 40
    mov edx, 180
    lea r8, StrideLine
    mov r9d, DIAG_TEXT
    call DrawString

    mov ecx, 40
    mov edx, 204
    lea r8, ArenaLine
    mov r9d, DIAG_TEXT
    call DrawString

    mov ecx, 40
    mov edx, 228
    lea r8, FrameArenaLine
    mov r9d, DIAG_TEXT
    call DrawString

    mov ecx, 40
    mov edx, 252
    lea r8, DepthArenaLine
    mov r9d, DIAG_TEXT
    call DrawString

    mov ecx, 40
    mov edx, 276
    lea r8, TextureArenaLine
    mov r9d, DIAG_TEXT
    call DrawString

    mov ecx, 40
    mov edx, 300
    lea r8, LogArenaLine
    mov r9d, DIAG_TEXT
    call DrawString

    mov ecx, 40
    mov edx, 324
    lea r8, PackLine
    mov r9d, DIAG_TEXT
    call DrawString

    mov ecx, 40
    mov edx, 348
    lea r8, PackMaskLine
    mov r9d, DIAG_MUTED
    call DrawString

    mov ecx, 40
    mov edx, 372
    lea r8, Engine64Line
    mov r9d, DIAG_TEXT
    call DrawString

    mov ecx, 40
    mov edx, 396
    lea r8, RenderLine
    mov r9d, DIAG_TEXT
    call DrawString

    mov ecx, 40
    mov edx, 420
    lea r8, InputLine
    mov r9d, DIAG_TEXT
    call DrawString

    call DrawMenuOptions

    mov ecx, 40
    mov edx, 450
    lea r8, StatusLine
    mov r9d, DIAG_OK
    call DrawString

    mov ecx, 454
    mov edx, 450
    lea r8, MenuLine
    mov r9d, DIAG_WARN
    call DrawString

    add rsp, 20h
    pop rdi
    ret
DrawDiagnosticsScreen ENDP

FormatDiagnosticLines PROC
    sub rsp, 20h

    mov ecx, dword ptr [GopWidth]
    lea rdx, ResLine + 5
    mov r8d, 8
    call WriteHex32

    mov ecx, dword ptr [GopHeight]
    lea rdx, ResLine + 14
    mov r8d, 8
    call WriteHex32

    mov ecx, dword ptr [GopPixelFormat]
    lea rdx, PixelLine + 7
    mov r8d, 8
    call WriteHex32

    mov rcx, qword ptr [GopFrameBase]
    lea rdx, FrameLine + 4
    mov r8d, 16
    call WriteHex64

    mov ecx, dword ptr [GopStride]
    lea rdx, StrideLine + 8
    mov r8d, 8
    call WriteHex32

    mov rcx, qword ptr [ArenaBase]
    lea rdx, ArenaLine + 10
    mov r8d, 16
    call WriteHex64

    mov ecx, dword ptr [LogArenaUsed]
    lea rdx, LogArenaLine + 19
    mov r8d, 8
    call WriteHex32

    mov ecx, dword ptr [PackStatusCode]
    lea rdx, PackLine + 5
    mov r8d, 8
    call WriteHex32

    mov ecx, dword ptr [PackLoadedChunks]
    lea rdx, PackLine + 17
    mov r8d, 8
    call WriteHex32

    mov ecx, dword ptr [PackStageMask]
    lea rdx, PackMaskLine + 5
    mov r8d, 8
    call WriteHex32

    mov ecx, dword ptr [PackStagedBytes]
    lea rdx, PackMaskLine + 17
    mov r8d, 8
    call WriteHex32

    mov ecx, dword ptr [Engine64Status]
    lea rdx, Engine64Line + 4
    mov r8d, 8
    call WriteHex32

    mov ecx, dword ptr [Engine64Width]
    lea rdx, Engine64Line + 13
    mov r8d, 8
    call WriteHex32

    mov ecx, dword ptr [Engine64Height]
    lea rdx, Engine64Line + 22
    mov r8d, 8
    call WriteHex32

    mov ecx, dword ptr [RenderStatus]
    lea rdx, RenderLine + 4
    mov r8d, 8
    call WriteHex32

    mov ecx, dword ptr [PresentStatus]
    lea rdx, RenderLine + 17
    mov r8d, 8
    call WriteHex32

    mov ecx, dword ptr [InputLastScan]
    lea rdx, InputLine + 6
    mov r8d, 4
    call WriteHex32

    mov ecx, dword ptr [InputLastChar]
    lea rdx, InputLine + 13
    mov r8d, 4
    call WriteHex32

    mov ecx, dword ptr [InputLastAction]
    lea rdx, InputLine + 21
    mov r8d, 4
    call WriteHex32

    mov ecx, dword ptr [InputConfirmCount]
    lea rdx, CountsLine + 3
    mov r8d, 8
    call WriteHex32

    mov ecx, dword ptr [InputBackCount]
    lea rdx, CountsLine + 17
    mov r8d, 8
    call WriteHex32

    add rsp, 20h
    ret
FormatDiagnosticLines ENDP

DrawEngine64Showcase PROC
    sub rsp, 20h

    call RenderEngine64Frame
    test eax, eax
    jnz showcase_done

    call PresentInternalFrameToGop

showcase_done:
    add rsp, 20h
    ret
DrawEngine64Showcase ENDP

RenderEngine64Frame PROC
    push rbx
    push rsi
    push rdi
    push r12
    push r13
    push r14
    push r15

    mov dword ptr [RenderStatus], RENDER_STATUS_NO_ENGINE
    mov dword ptr [PresentStatus], PRESENT_STATUS_NO_FRAME
    mov dword ptr [RenderFramePixels], 0
    mov dword ptr [PresentFramePixels], 0

    mov rsi, qword ptr [Engine64ChunkBase]
    test rsi, rsi
    jz render_fail

    mov rdi, qword ptr [FrameArenaBase]
    test rdi, rdi
    jz render_frame_fail

    cmp qword ptr [FrameArenaSize], ENGINE64_FRAME_BYTES
    jb render_frame_fail

    mov r11, qword ptr [Engine64MagicValue]
    cmp qword ptr [rsi], r11
    jne render_header_fail

    cmp dword ptr [rsi + 12], ENGINE64_EXPECTED_WIDTH
    jne render_header_fail
    cmp dword ptr [rsi + 16], ENGINE64_EXPECTED_HEIGHT
    jne render_header_fail

    mov ebx, dword ptr [rsi + 20]
    test ebx, ebx
    jz render_header_fail
    cmp ebx, 16
    ja render_header_fail

    mov edx, dword ptr [rsi + 28]
    cmp edx, dword ptr [Engine64ChunkBytes]
    jae render_header_fail
    mov eax, ebx
    shl eax, 2
    add eax, edx
    jc render_header_fail
    cmp eax, dword ptr [Engine64ChunkBytes]
    ja render_header_fail
    lea r12, [rsi + rdx]

    xor r8d, r8d

render_sky_row_loop:
    cmp r8d, ENGINE64_EXPECTED_HEIGHT
    jae render_scene_overlays

    mov eax, r8d
    imul eax, eax, ENGINE64_EXPECTED_WIDTH
    shl rax, 2
    mov rdi, qword ptr [FrameArenaBase]
    add rdi, rax

    mov eax, dword ptr [r12]
    cmp r8d, 122
    jb render_sky_color_ready
    mov eax, dword ptr [r12 + 4]
    cmp r8d, 246
    jb render_sky_color_ready
    mov eax, 000B1924h
    cmp r8d, 330
    jb render_sky_color_ready
    mov eax, 00101016h

render_sky_color_ready:
    mov ecx, ENGINE64_EXPECTED_WIDTH
    rep stosd

    inc r8d
    jmp render_sky_row_loop

render_scene_overlays:
    mov ecx, 0
    mov edx, 264
    mov r8d, 640
    mov r9d, 22
    mov eax, 00142632h
    call FillFrameRect

    mov ecx, 0
    mov edx, 286
    mov r8d, 640
    mov r9d, 6
    mov eax, dword ptr [r12 + 16]
    call FillFrameRect

    mov ecx, 0
    mov edx, 304
    mov r8d, 640
    mov r9d, 2
    mov eax, dword ptr [r12 + 12]
    call FillFrameRect

    mov ecx, 0
    mov edx, 326
    mov r8d, 640
    mov r9d, 2
    mov eax, dword ptr [r12 + 28]
    call FillFrameRect

    mov ecx, 0
    mov edx, 356
    mov r8d, 640
    mov r9d, 2
    mov eax, dword ptr [r12 + 36]
    call FillFrameRect

    mov ecx, 0
    mov edx, 392
    mov r8d, 640
    mov r9d, 2
    mov eax, dword ptr [r12 + 28]
    call FillFrameRect

    mov ecx, 0
    mov edx, 436
    mov r8d, 640
    mov r9d, 3
    mov eax, dword ptr [r12 + 16]
    call FillFrameRect

    mov ecx, 320
    mov edx, 20
    mov r8d, 286
    mov r9d, 479
    mov eax, dword ptr [r12 + 12]
    call DrawFrameRoadRay

    mov ecx, 320
    mov edx, 132
    mov r8d, 286
    mov r9d, 479
    mov eax, dword ptr [r12 + 28]
    call DrawFrameRoadRay

    mov ecx, 320
    mov edx, 260
    mov r8d, 286
    mov r9d, 479
    mov eax, dword ptr [r12 + 16]
    call DrawFrameRoadRay

    mov ecx, 320
    mov edx, 380
    mov r8d, 286
    mov r9d, 479
    mov eax, dword ptr [r12 + 16]
    call DrawFrameRoadRay

    mov ecx, 320
    mov edx, 508
    mov r8d, 286
    mov r9d, 479
    mov eax, dword ptr [r12 + 28]
    call DrawFrameRoadRay

    mov ecx, 320
    mov edx, 628
    mov r8d, 286
    mov r9d, 479
    mov eax, dword ptr [r12 + 12]
    call DrawFrameRoadRay

    mov ecx, 318
    mov edx, 286
    mov r8d, 5
    mov r9d, 194
    mov eax, dword ptr [r12 + 12]
    call FillFrameRect

    mov ecx, 42
    mov edx, 140
    mov r8d, 62
    mov r9d, 148
    mov eax, dword ptr [r12 + 44]
    call FillFrameRect

    mov ecx, 114
    mov edx, 104
    mov r8d, 68
    mov r9d, 184
    mov eax, 00081018h
    call FillFrameRect

    mov ecx, 196
    mov edx, 168
    mov r8d, 44
    mov r9d, 120
    mov eax, 0009121Ch
    call FillFrameRect

    mov ecx, 272
    mov edx, 154
    mov r8d, 96
    mov r9d, 86
    mov eax, 00081018h
    call FillFrameRect

    mov ecx, 454
    mov edx, 122
    mov r8d, 72
    mov r9d, 166
    mov eax, dword ptr [r12 + 44]
    call FillFrameRect

    mov ecx, 540
    mov edx, 158
    mov r8d, 56
    mov r9d, 130
    mov eax, 00081018h
    call FillFrameRect

    mov ecx, 224
    mov edx, 330
    mov r8d, 3
    mov r9d, 150
    mov eax, dword ptr [r12 + 8]
    call FillFrameRect

    mov ecx, 442
    mov edx, 330
    mov r8d, 3
    mov r9d, 150
    mov eax, dword ptr [r12 + 8]
    call FillFrameRect

    mov ecx, 62
    mov edx, 198
    mov r8d, 10
    mov r9d, 42
    mov eax, dword ptr [r12 + 16]
    call FillFrameRect

    mov ecx, 84
    mov edx, 176
    mov r8d, 8
    mov r9d, 28
    mov eax, dword ptr [r12 + 36]
    call FillFrameRect

    mov ecx, 132
    mov edx, 188
    mov r8d, 9
    mov r9d, 54
    mov eax, dword ptr [r12 + 20]
    call FillFrameRect

    mov ecx, 160
    mov edx, 126
    mov r8d, 12
    mov r9d, 32
    mov eax, dword ptr [r12 + 40]
    call FillFrameRect

    mov ecx, 292
    mov edx, 176
    mov r8d, 54
    mov r9d, 10
    mov eax, dword ptr [r12 + 16]
    call FillFrameRect

    mov ecx, 462
    mov edx, 156
    mov r8d, 44
    mov r9d, 8
    mov eax, dword ptr [r12 + 36]
    call FillFrameRect

    mov ecx, 486
    mov edx, 190
    mov r8d, 9
    mov r9d, 54
    mov eax, dword ptr [r12 + 28]
    call FillFrameRect

    mov ecx, 552
    mov edx, 198
    mov r8d, 12
    mov r9d, 48
    mov eax, dword ptr [r12 + 40]
    call FillFrameRect

    mov ecx, 272
    mov edx, 222
    mov r8d, 64
    mov r9d, 18
    mov eax, dword ptr [r12 + 44]
    call FillFrameRect

    mov ecx, 310
    mov edx, 206
    mov r8d, 112
    mov r9d, 32
    mov eax, 00101820h
    call FillFrameRect

    mov ecx, 408
    mov edx, 218
    mov r8d, 42
    mov r9d, 14
    mov eax, dword ptr [r12 + 44]
    call FillFrameRect

    mov ecx, 248
    mov edx, 238
    mov r8d, 204
    mov r9d, 4
    mov eax, dword ptr [r12 + 28]
    call FillFrameRect

    mov ecx, 334
    mov edx, 216
    mov r8d, 42
    mov r9d, 8
    mov eax, dword ptr [r12 + 16]
    call FillFrameRect

    mov ecx, 378
    mov edx, 226
    mov r8d, 18
    mov r9d, 6
    mov eax, dword ptr [r12 + 36]
    call FillFrameRect

    mov ecx, 292
    mov edx, 244
    mov r8d, 26
    mov r9d, 3
    mov eax, dword ptr [r12 + 40]
    call FillFrameRect

    mov ecx, 404
    mov edx, 244
    mov r8d, 26
    mov r9d, 3
    mov eax, dword ptr [r12 + 40]
    call FillFrameRect

    mov ecx, 96
    mov edx, 288
    mov r8d, 448
    mov r9d, 1
    mov eax, dword ptr [r12 + 32]
    call FillFrameRect

    mov ecx, 286
    mov edx, 258
    mov r8d, 78
    mov r9d, 6
    mov eax, dword ptr [r12 + 36]
    call FillFrameRect

    mov ecx, 0
    mov edx, 0
    mov r8d, 640
    mov r9d, 8
    mov eax, dword ptr [r12 + 44]
    call FillFrameRect

    mov ecx, 0
    mov edx, 472
    mov r8d, 640
    mov r9d, 8
    mov eax, dword ptr [r12 + 44]
    call FillFrameRect

render_ok:
    mov qword ptr [FrameArenaUsed], ENGINE64_FRAME_BYTES
    mov qword ptr [FrameArenaFree], ARENA_FRAME_BYTES - ENGINE64_FRAME_BYTES
    mov dword ptr [RenderFramePixels], ENGINE64_FRAME_PIXELS
    mov dword ptr [RenderStatus], RENDER_STATUS_OK
    xor eax, eax
    jmp render_done

render_frame_fail:
    mov dword ptr [RenderStatus], RENDER_STATUS_FRAME_ARENA
    mov eax, 1
    jmp render_done

render_header_fail:
    mov dword ptr [RenderStatus], RENDER_STATUS_HEADER
    mov eax, 1
    jmp render_done

render_fail:
    mov eax, 1

render_done:
    pop r15
    pop r14
    pop r13
    pop r12
    pop rdi
    pop rsi
    pop rbx
    ret
RenderEngine64Frame ENDP

FillFrameRect PROC
    push rbx
    push rdi
    push r12
    push r13
    push r14

    mov r11d, eax
    mov r13d, ecx
    mov r14d, edx
    mov ebx, r8d
    mov r12d, r9d

frame_rect_row:
    test r12d, r12d
    jz frame_rect_done

    mov eax, r14d
    imul eax, eax, ENGINE64_EXPECTED_WIDTH
    add eax, r13d
    shl rax, 2
    mov rdi, qword ptr [FrameArenaBase]
    add rdi, rax

    mov eax, r11d
    mov ecx, ebx
    rep stosd

    inc r14d
    dec r12d
    jmp frame_rect_row

frame_rect_done:
    pop r14
    pop r13
    pop r12
    pop rdi
    pop rbx
    ret
FillFrameRect ENDP

DrawFrameRoadRay PROC
    push rbx
    push rsi
    push rdi
    push r12
    push r13
    push r14
    push r15

    mov r15d, eax
    mov r10d, ecx
    mov r11d, edx
    mov r12d, r8d
    mov r13d, r9d

    mov eax, r11d
    sub eax, r10d
    shl eax, 16
    mov ebx, r13d
    sub ebx, r12d
    jle frame_ray_done
    cdq
    idiv ebx
    mov r14d, eax

    mov eax, r10d
    shl eax, 16
    mov esi, eax

frame_ray_loop:
    cmp r12d, r13d
    ja frame_ray_done

    mov eax, esi
    sar eax, 16
    cmp eax, 0
    jl frame_ray_next
    cmp eax, ENGINE64_EXPECTED_WIDTH - 2
    jg frame_ray_next
    cmp r12d, ENGINE64_EXPECTED_HEIGHT
    jae frame_ray_next

    mov ecx, r12d
    imul ecx, ecx, ENGINE64_EXPECTED_WIDTH
    add ecx, eax
    shl rcx, 2
    mov rdi, qword ptr [FrameArenaBase]
    add rdi, rcx

    mov eax, r15d
    stosd
    stosd

frame_ray_next:
    add esi, r14d
    inc r12d
    jmp frame_ray_loop

frame_ray_done:
    pop r15
    pop r14
    pop r13
    pop r12
    pop rdi
    pop rsi
    pop rbx
    ret
DrawFrameRoadRay ENDP

ClearInternalFrame PROC
    push rdi

    mov rdi, qword ptr [FrameArenaBase]
    test rdi, rdi
    jz clear_internal_frame_done

    mov ecx, ENGINE64_FRAME_PIXELS
    rep stosd

clear_internal_frame_done:
    pop rdi
    ret
ClearInternalFrame ENDP

ClearDepthBuffer PROC
    push rdi

    mov rdi, qword ptr [DepthArenaBase]
    test rdi, rdi
    jz clear_depth_done

    mov eax, 07FFFFFFFh
    mov ecx, ENGINE64_FRAME_PIXELS
    rep stosd
    mov qword ptr [DepthArenaUsed], ENGINE64_FRAME_BYTES
    mov qword ptr [DepthArenaFree], ARENA_DEPTH_BYTES - ENGINE64_FRAME_BYTES

clear_depth_done:
    pop rdi
    ret
ClearDepthBuffer ENDP

DrawProjectedTriangleDepth PROC
    push rbx
    push rsi
    push rdi
    push r12
    push r13
    push r14
    push r15

    mov dword ptr [TriangleColor], eax

    mov eax, dword ptr [ProjectedX1]
    sub eax, dword ptr [ProjectedX0]
    mov ecx, dword ptr [ProjectedY2]
    sub ecx, dword ptr [ProjectedY0]
    imul eax, ecx
    mov r10d, eax

    mov eax, dword ptr [ProjectedX2]
    sub eax, dword ptr [ProjectedX0]
    mov ecx, dword ptr [ProjectedY1]
    sub ecx, dword ptr [ProjectedY0]
    imul eax, ecx
    sub r10d, eax
    test r10d, r10d
    jz tri_reject
    jg tri_area_ready

    mov eax, dword ptr [ProjectedX1]
    xchg eax, dword ptr [ProjectedX2]
    mov dword ptr [ProjectedX1], eax
    mov eax, dword ptr [ProjectedY1]
    xchg eax, dword ptr [ProjectedY2]
    mov dword ptr [ProjectedY1], eax
    mov eax, dword ptr [ProjectedZ1]
    xchg eax, dword ptr [ProjectedZ2]
    mov dword ptr [ProjectedZ1], eax
    cmp dword ptr [TriangleTexturedMode], 0
    je tri_swap_done
    mov eax, dword ptr [ProjectedU1]
    xchg eax, dword ptr [ProjectedU2]
    mov dword ptr [ProjectedU1], eax
    mov eax, dword ptr [ProjectedV1]
    xchg eax, dword ptr [ProjectedV2]
    mov dword ptr [ProjectedV1], eax

tri_swap_done:
    neg r10d

tri_area_ready:
    mov dword ptr [TriArea], r10d
    mov eax, dword ptr [TriangleColor]
    mov dword ptr [TriangleShadeColor], eax
    cmp eax, 00D8FFFFh
    je tri_shade_ready
    cmp eax, 00FF90FFh
    je tri_shade_ready
    cmp eax, 00FFE66Dh
    je tri_shade_ready
    cmp eax, 00FF4058h
    je tri_shade_ready
    cmp eax, 0020D060h
    je tri_shade_ready
    cmp eax, 00B0FFC8h
    je tri_shade_ready

    mov eax, dword ptr [ProjectedZ0]
    add eax, dword ptr [ProjectedZ1]
    add eax, dword ptr [ProjectedZ2]
    cdq
    mov ecx, 3
    idiv ecx
    cmp eax, 420
    jge tri_far_shade
    cmp eax, 300
    jl tri_shade_ready

    mov eax, dword ptr [TriangleColor]
    and eax, 00FEFEFEh
    shr eax, 1
    mov ecx, dword ptr [TriangleColor]
    and ecx, 00FCFCFCh
    shr ecx, 2
    add eax, ecx
    add eax, 00020406h
    mov dword ptr [TriangleShadeColor], eax
    jmp tri_shade_ready

tri_far_shade:
    mov eax, dword ptr [TriangleColor]
    and eax, 00FEFEFEh
    shr eax, 1
    add eax, 0004080Dh
    mov dword ptr [TriangleShadeColor], eax

tri_shade_ready:

    mov eax, dword ptr [ProjectedX0]
    mov ecx, dword ptr [ProjectedX1]
    cmp ecx, eax
    jge tri_minx_check_2
    mov eax, ecx
tri_minx_check_2:
    mov ecx, dword ptr [ProjectedX2]
    cmp ecx, eax
    jge tri_minx_ready
    mov eax, ecx
tri_minx_ready:
    mov dword ptr [TriMinX], eax

    mov eax, dword ptr [ProjectedX0]
    mov ecx, dword ptr [ProjectedX1]
    cmp ecx, eax
    jle tri_maxx_check_2
    mov eax, ecx
tri_maxx_check_2:
    mov ecx, dword ptr [ProjectedX2]
    cmp ecx, eax
    jle tri_maxx_ready
    mov eax, ecx
tri_maxx_ready:
    mov dword ptr [TriMaxX], eax

    cmp dword ptr [TriMaxX], 0
    jl tri_reject
    cmp dword ptr [TriMinX], ENGINE64_EXPECTED_WIDTH - 1
    jg tri_reject
    cmp dword ptr [TriMinX], 0
    jge tri_minx_clamped
    mov dword ptr [TriMinX], 0
tri_minx_clamped:
    cmp dword ptr [TriMaxX], ENGINE64_EXPECTED_WIDTH - 1
    jle tri_maxx_clamped
    mov dword ptr [TriMaxX], ENGINE64_EXPECTED_WIDTH - 1
tri_maxx_clamped:

    mov eax, dword ptr [ProjectedY0]
    mov ecx, dword ptr [ProjectedY1]
    cmp ecx, eax
    jge tri_miny_check_2
    mov eax, ecx
tri_miny_check_2:
    mov ecx, dword ptr [ProjectedY2]
    cmp ecx, eax
    jge tri_miny_ready
    mov eax, ecx
tri_miny_ready:
    mov dword ptr [TriMinY], eax

    mov eax, dword ptr [ProjectedY0]
    mov ecx, dword ptr [ProjectedY1]
    cmp ecx, eax
    jle tri_maxy_check_2
    mov eax, ecx
tri_maxy_check_2:
    mov ecx, dword ptr [ProjectedY2]
    cmp ecx, eax
    jle tri_maxy_ready
    mov eax, ecx
tri_maxy_ready:
    mov dword ptr [TriMaxY], eax

    cmp dword ptr [TriMaxY], 0
    jl tri_reject
    cmp dword ptr [TriMinY], ENGINE64_EXPECTED_HEIGHT - 1
    jg tri_reject
    cmp dword ptr [TriMinY], 0
    jge tri_miny_clamped
    mov dword ptr [TriMinY], 0
tri_miny_clamped:
    cmp dword ptr [TriMaxY], ENGINE64_EXPECTED_HEIGHT - 1
    jle tri_maxy_clamped
    mov dword ptr [TriMaxY], ENGINE64_EXPECTED_HEIGHT - 1
tri_maxy_clamped:

    mov eax, dword ptr [ProjectedZ1]
    sub eax, dword ptr [ProjectedZ0]
    mov ecx, dword ptr [ProjectedY2]
    sub ecx, dword ptr [ProjectedY0]
    imul eax, ecx
    mov r11d, eax
    mov eax, dword ptr [ProjectedZ2]
    sub eax, dword ptr [ProjectedZ0]
    mov ecx, dword ptr [ProjectedY1]
    sub ecx, dword ptr [ProjectedY0]
    imul eax, ecx
    sub r11d, eax
    mov eax, r11d
    imul eax, 256
    cdq
    idiv dword ptr [TriArea]
    mov dword ptr [TriDzDx], eax

    mov eax, dword ptr [ProjectedX1]
    sub eax, dword ptr [ProjectedX0]
    mov ecx, dword ptr [ProjectedZ2]
    sub ecx, dword ptr [ProjectedZ0]
    imul eax, ecx
    mov r11d, eax
    mov eax, dword ptr [ProjectedX2]
    sub eax, dword ptr [ProjectedX0]
    mov ecx, dword ptr [ProjectedZ1]
    sub ecx, dword ptr [ProjectedZ0]
    imul eax, ecx
    sub r11d, eax
    mov eax, r11d
    imul eax, 256
    cdq
    idiv dword ptr [TriArea]
    mov dword ptr [TriDzDy], eax

    cmp dword ptr [TriangleTexturedMode], 0
    je tri_uv_gradients_zero

    mov eax, dword ptr [ProjectedU1]
    sub eax, dword ptr [ProjectedU0]
    mov ecx, dword ptr [ProjectedY2]
    sub ecx, dword ptr [ProjectedY0]
    imul eax, ecx
    mov r11d, eax
    mov eax, dword ptr [ProjectedU2]
    sub eax, dword ptr [ProjectedU0]
    mov ecx, dword ptr [ProjectedY1]
    sub ecx, dword ptr [ProjectedY0]
    imul eax, ecx
    sub r11d, eax
    mov eax, r11d
    imul eax, 256
    cdq
    idiv dword ptr [TriArea]
    mov dword ptr [TriDuDx], eax

    mov eax, dword ptr [ProjectedX1]
    sub eax, dword ptr [ProjectedX0]
    mov ecx, dword ptr [ProjectedU2]
    sub ecx, dword ptr [ProjectedU0]
    imul eax, ecx
    mov r11d, eax
    mov eax, dword ptr [ProjectedX2]
    sub eax, dword ptr [ProjectedX0]
    mov ecx, dword ptr [ProjectedU1]
    sub ecx, dword ptr [ProjectedU0]
    imul eax, ecx
    sub r11d, eax
    mov eax, r11d
    imul eax, 256
    cdq
    idiv dword ptr [TriArea]
    mov dword ptr [TriDuDy], eax

    mov eax, dword ptr [ProjectedV1]
    sub eax, dword ptr [ProjectedV0]
    mov ecx, dword ptr [ProjectedY2]
    sub ecx, dword ptr [ProjectedY0]
    imul eax, ecx
    mov r11d, eax
    mov eax, dword ptr [ProjectedV2]
    sub eax, dword ptr [ProjectedV0]
    mov ecx, dword ptr [ProjectedY1]
    sub ecx, dword ptr [ProjectedY0]
    imul eax, ecx
    sub r11d, eax
    mov eax, r11d
    imul eax, 256
    cdq
    idiv dword ptr [TriArea]
    mov dword ptr [TriDvDx], eax

    mov eax, dword ptr [ProjectedX1]
    sub eax, dword ptr [ProjectedX0]
    mov ecx, dword ptr [ProjectedV2]
    sub ecx, dword ptr [ProjectedV0]
    imul eax, ecx
    mov r11d, eax
    mov eax, dword ptr [ProjectedX2]
    sub eax, dword ptr [ProjectedX0]
    mov ecx, dword ptr [ProjectedV1]
    sub ecx, dword ptr [ProjectedV0]
    imul eax, ecx
    sub r11d, eax
    mov eax, r11d
    imul eax, 256
    cdq
    idiv dword ptr [TriArea]
    mov dword ptr [TriDvDy], eax
    jmp tri_uv_gradients_ready

tri_uv_gradients_zero:
    mov dword ptr [TriDuDx], 0
    mov dword ptr [TriDuDy], 0
    mov dword ptr [TriDvDx], 0
    mov dword ptr [TriDvDy], 0

tri_uv_gradients_ready:
    mov eax, dword ptr [ProjectedY2]
    sub eax, dword ptr [ProjectedY1]
    mov dword ptr [TriEdge0Dx], eax
    mov eax, dword ptr [ProjectedX1]
    sub eax, dword ptr [ProjectedX2]
    mov dword ptr [TriEdge0Dy], eax

    mov eax, dword ptr [ProjectedY0]
    sub eax, dword ptr [ProjectedY2]
    mov dword ptr [TriEdge1Dx], eax
    mov eax, dword ptr [ProjectedX2]
    sub eax, dword ptr [ProjectedX0]
    mov dword ptr [TriEdge1Dy], eax

    mov eax, dword ptr [ProjectedY1]
    sub eax, dword ptr [ProjectedY0]
    mov dword ptr [TriEdge2Dx], eax
    mov eax, dword ptr [ProjectedX0]
    sub eax, dword ptr [ProjectedX1]
    mov dword ptr [TriEdge2Dy], eax

    mov eax, dword ptr [ProjectedZ0]
    shl eax, 8
    mov r10d, eax
    mov ecx, dword ptr [TriMinX]
    sub ecx, dword ptr [ProjectedX0]
    mov eax, dword ptr [TriDzDx]
    imul eax, ecx
    add r10d, eax
    mov ecx, dword ptr [TriMinY]
    sub ecx, dword ptr [ProjectedY0]
    mov eax, dword ptr [TriDzDy]
    imul eax, ecx
    add r10d, eax
    mov dword ptr [TriZRow], r10d

    mov eax, dword ptr [ProjectedU0]
    shl eax, 8
    mov r10d, eax
    mov ecx, dword ptr [TriMinX]
    sub ecx, dword ptr [ProjectedX0]
    mov eax, dword ptr [TriDuDx]
    imul eax, ecx
    add r10d, eax
    mov ecx, dword ptr [TriMinY]
    sub ecx, dword ptr [ProjectedY0]
    mov eax, dword ptr [TriDuDy]
    imul eax, ecx
    add r10d, eax
    mov dword ptr [TriURow], r10d

    mov eax, dword ptr [ProjectedV0]
    shl eax, 8
    mov r10d, eax
    mov ecx, dword ptr [TriMinX]
    sub ecx, dword ptr [ProjectedX0]
    mov eax, dword ptr [TriDvDx]
    imul eax, ecx
    add r10d, eax
    mov ecx, dword ptr [TriMinY]
    sub ecx, dword ptr [ProjectedY0]
    mov eax, dword ptr [TriDvDy]
    imul eax, ecx
    add r10d, eax
    mov dword ptr [TriVRow], r10d

    mov r12d, dword ptr [TriMinY]

tri_row_loop:
    cmp r12d, dword ptr [TriMaxY]
    jg tri_done

    mov eax, dword ptr [TriMinX]
    sub eax, dword ptr [ProjectedX1]
    mov ecx, dword ptr [ProjectedY2]
    sub ecx, dword ptr [ProjectedY1]
    imul eax, ecx
    mov ebx, eax
    mov eax, r12d
    sub eax, dword ptr [ProjectedY1]
    mov ecx, dword ptr [ProjectedX2]
    sub ecx, dword ptr [ProjectedX1]
    imul eax, ecx
    sub ebx, eax

    mov eax, dword ptr [TriMinX]
    sub eax, dword ptr [ProjectedX2]
    mov ecx, dword ptr [ProjectedY0]
    sub ecx, dword ptr [ProjectedY2]
    imul eax, ecx
    mov r13d, eax
    mov eax, r12d
    sub eax, dword ptr [ProjectedY2]
    mov ecx, dword ptr [ProjectedX0]
    sub ecx, dword ptr [ProjectedX2]
    imul eax, ecx
    sub r13d, eax

    mov eax, dword ptr [TriMinX]
    sub eax, dword ptr [ProjectedX0]
    mov ecx, dword ptr [ProjectedY1]
    sub ecx, dword ptr [ProjectedY0]
    imul eax, ecx
    mov edx, eax
    mov eax, r12d
    sub eax, dword ptr [ProjectedY0]
    mov ecx, dword ptr [ProjectedX1]
    sub ecx, dword ptr [ProjectedX0]
    imul eax, ecx
    sub edx, eax

    mov r14d, dword ptr [TriMinX]
    mov r10d, dword ptr [TriZRow]
    mov r8d, dword ptr [TriURow]
    mov r9d, dword ptr [TriVRow]

    mov eax, r12d
    imul eax, eax, ENGINE64_EXPECTED_WIDTH
    add eax, dword ptr [TriMinX]
    shl rax, 2
    mov rdi, qword ptr [DepthArenaBase]
    add rdi, rax
    mov rsi, qword ptr [FrameArenaBase]
    add rsi, rax

tri_pixel_loop:
    cmp r14d, dword ptr [TriMaxX]
    jg tri_next_row

    test ebx, ebx
    jg tri_skip_pixel
    test r13d, r13d
    jg tri_skip_pixel
    test edx, edx
    jg tri_skip_pixel

    mov eax, r10d
    sar eax, 8
    cmp eax, dword ptr [rdi]
    jge tri_skip_pixel
    mov dword ptr [rdi], eax
    cmp dword ptr [TriangleTexturedMode], 0
    je tri_write_flat_pixel

    mov eax, dword ptr [TriangleTextureTile]
    mov r15d, eax
    and eax, 00000007h
    shl eax, 5
    mov ecx, r8d
    sar ecx, 8
    and ecx, 000000FFh
    shr ecx, 3
    add eax, ecx
    mov ecx, r15d
    shr ecx, 3
    shl ecx, 5
    mov r11d, r9d
    sar r11d, 8
    and r11d, 000000FFh
    shr r11d, 3
    add ecx, r11d
    shl ecx, 8
    add eax, ecx
    shl rax, 2
    mov r15, qword ptr [TextureAtlasPixels]
    add r15, rax
    mov eax, dword ptr [r15]
    cmp dword ptr [TriangleMaterialIndex], 7
    jne tri_tex_not_warden
    cmp dword ptr [HitFlashTicks], 0
    je tri_tex_not_warden
    mov eax, 00FFE66Dh

tri_tex_not_warden:
    cmp dword ptr [TriangleMaterialIndex], 6
    jne tri_tex_not_terminal
    cmp dword ptr [ObjectiveState], 1
    jb tri_tex_terminal_locked
    cmp dword ptr [ObjectiveState], 2
    jb tri_tex_terminal_active
    mov eax, 00B0FFC8h
    jmp tri_tex_dynamic_ready

tri_tex_terminal_active:
    mov eax, 00FFE66Dh
    jmp tri_tex_dynamic_ready

tri_tex_terminal_locked:
    mov eax, 00FF4058h
    jmp tri_tex_dynamic_ready

tri_tex_not_terminal:
    cmp dword ptr [TriangleMaterialIndex], 8
    jne tri_tex_dynamic_ready
    cmp dword ptr [ObjectiveState], 2
    jae tri_tex_exit_open
    mov eax, 00FF4058h
    jmp tri_tex_dynamic_ready

tri_tex_exit_open:
    mov eax, 0020D060h

tri_tex_dynamic_ready:
    mov ecx, dword ptr [TriangleMaterialFlags]
    test ecx, MATERIAL_FLAG_EMISSIVE
    jnz tri_write_pixel
    mov ecx, r10d
    sar ecx, 8
    cmp ecx, 420
    jge tri_tex_far_fog
    cmp ecx, 300
    jl tri_write_pixel
    and eax, 00FEFEFEh
    shr eax, 1
    mov ecx, dword ptr [TriangleBaseColor]
    and ecx, 00FCFCFCh
    shr ecx, 2
    add eax, ecx
    add eax, 00020406h
    jmp tri_write_pixel

tri_tex_far_fog:
    and eax, 00FEFEFEh
    shr eax, 1
    add eax, 0004080Dh
    jmp tri_write_pixel

tri_write_flat_pixel:
    mov eax, dword ptr [TriangleShadeColor]

tri_write_pixel:
    mov dword ptr [rsi], eax
    inc dword ptr [RendererDepthWrites]

tri_skip_pixel:
    add ebx, dword ptr [TriEdge0Dx]
    add r13d, dword ptr [TriEdge1Dx]
    add edx, dword ptr [TriEdge2Dx]
    add r10d, dword ptr [TriDzDx]
    add r8d, dword ptr [TriDuDx]
    add r9d, dword ptr [TriDvDx]
    add rdi, 4
    add rsi, 4
    inc r14d
    jmp tri_pixel_loop

tri_next_row:
    mov eax, dword ptr [TriZRow]
    add eax, dword ptr [TriDzDy]
    mov dword ptr [TriZRow], eax
    mov eax, dword ptr [TriURow]
    add eax, dword ptr [TriDuDy]
    mov dword ptr [TriURow], eax
    mov eax, dword ptr [TriVRow]
    add eax, dword ptr [TriDvDy]
    mov dword ptr [TriVRow], eax
    inc r12d
    jmp tri_row_loop

tri_reject:
    inc dword ptr [RendererRejectedTriangles]
    jmp tri_exit

tri_done:
    inc dword ptr [RendererTriangleCount]
    cmp dword ptr [TriangleTexturedMode], 0
    je tri_exit
    inc dword ptr [RendererTexturedTriangleCount]

tri_exit:
    pop r15
    pop r14
    pop r13
    pop r12
    pop rdi
    pop rsi
    pop rbx
    ret
DrawProjectedTriangleDepth ENDP

PresentInternalFrameToGop PROC
    push rsi
    push rdi
    push r12
    push r13
    push r14
    push r15

    mov dword ptr [PresentStatus], PRESENT_STATUS_NO_FRAME
    mov dword ptr [PresentFramePixels], 0

    mov rsi, qword ptr [FrameArenaBase]
    test rsi, rsi
    jz present_fail
    cmp dword ptr [RenderStatus], RENDER_STATUS_OK
    jne present_fail

    cmp dword ptr [GopWidth], ENGINE64_EXPECTED_WIDTH
    jb present_gop_small
    cmp dword ptr [GopHeight], ENGINE64_EXPECTED_HEIGHT
    jb present_gop_small

    cmp dword ptr [GopPresentMode], PRESENT_MODE_SWAP_RB
    ja present_format_fail

    mov eax, dword ptr [GopWidth]
    sub eax, ENGINE64_EXPECTED_WIDTH
    shr eax, 1
    mov dword ptr [GopPresentX], eax

    mov eax, dword ptr [GopHeight]
    sub eax, ENGINE64_EXPECTED_HEIGHT
    shr eax, 1
    mov dword ptr [GopPresentY], eax

    mov eax, 00000000h
    call FillScreen

    xor r12d, r12d

present_row_loop:
    cmp r12d, ENGINE64_EXPECTED_HEIGHT
    jae present_ok

    mov eax, r12d
    imul eax, eax, ENGINE64_EXPECTED_WIDTH
    shl rax, 2
    mov rsi, qword ptr [FrameArenaBase]
    add rsi, rax

    mov eax, r12d
    add eax, dword ptr [GopPresentY]
    mov edx, dword ptr [GopStride]
    imul rax, rdx
    mov edx, dword ptr [GopPresentX]
    add rax, rdx
    shl rax, 2
    mov rdi, qword ptr [GopFrameBase]
    add rdi, rax

    cmp dword ptr [GopPresentMode], PRESENT_MODE_SWAP_RB
    je present_swap_row

    mov ecx, ENGINE64_EXPECTED_WIDTH
    rep movsd
    jmp present_next_row

present_swap_row:
    mov r15d, ENGINE64_EXPECTED_WIDTH

present_swap_pixel:
    mov eax, dword ptr [rsi]
    mov edx, eax
    and eax, 0000FF00h
    mov ecx, edx
    and ecx, 000000FFh
    shl ecx, 16
    or eax, ecx
    mov ecx, edx
    and ecx, 00FF0000h
    shr ecx, 16
    or eax, ecx
    mov dword ptr [rdi], eax
    add rsi, 4
    add rdi, 4
    dec r15d
    jnz present_swap_pixel

present_next_row:
    inc r12d
    jmp present_row_loop

present_ok:
    mov dword ptr [PresentFramePixels], ENGINE64_FRAME_PIXELS
    mov dword ptr [PresentStatus], PRESENT_STATUS_OK
    xor eax, eax
    jmp present_done

present_gop_small:
    mov dword ptr [PresentStatus], PRESENT_STATUS_GOP_SMALL
    mov eax, 1
    jmp present_done

present_format_fail:
    mov dword ptr [PresentStatus], PRESENT_STATUS_FORMAT
    mov eax, 1
    jmp present_done

present_fail:
    mov eax, 1

present_done:
    pop r15
    pop r14
    pop r13
    pop r12
    pop rdi
    pop rsi
    ret
PresentInternalFrameToGop ENDP

ConvertXrgbToGop PROC
    cmp dword ptr [GopPresentMode], PRESENT_MODE_SWAP_RB
    jne convert_done

    mov edx, eax
    and eax, 0000FF00h
    mov ecx, edx
    and ecx, 000000FFh
    shl ecx, 16
    or eax, ecx
    mov ecx, edx
    and ecx, 00FF0000h
    shr ecx, 16
    or eax, ecx

convert_done:
    ret
ConvertXrgbToGop ENDP

FillScreen PROC
    push rdi

    call ConvertXrgbToGop
    mov rdi, qword ptr [GopFrameBase]
    mov ecx, dword ptr [GopStride]
    imul ecx, dword ptr [GopHeight]
    rep stosd

    pop rdi
    ret
FillScreen ENDP

DrawGopRect PROC
    push rbx
    push rdi
    push r12
    push r13
    push r14
    push r15
    sub rsp, 28h

    mov r12d, ecx
    mov r13d, edx
    mov r14d, r8d
    mov r15d, r9d
    cmp dword ptr [DrawOffsetEnabled], 0
    je gop_rect_no_offset
    add r12d, dword ptr [DrawOffsetX]
    add r13d, dword ptr [DrawOffsetY]

gop_rect_no_offset:
    call ConvertXrgbToGop
    mov ebx, eax

gop_rect_row:
    test r15d, r15d
    jz gop_rect_done

    mov eax, r13d
    mov edx, dword ptr [GopStride]
    imul rax, rdx
    add rax, r12
    shl rax, 2
    mov rdi, qword ptr [GopFrameBase]
    add rdi, rax

    mov eax, ebx
    mov ecx, r14d
    rep stosd

    inc r13d
    dec r15d
    jmp gop_rect_row

gop_rect_done:
    add rsp, 28h
    pop r15
    pop r14
    pop r13
    pop r12
    pop rdi
    pop rbx
    ret
DrawGopRect ENDP

ProjectLevelPoint3D PROC
    push rbx

    mov r11d, edx
    sub ecx, dword ptr [LevelCameraX]
    mov ebx, r8d
    sub ebx, dword ptr [LevelCameraZ]
    cmp ebx, 32
    jge project_z_ready
    mov ebx, 32

project_z_ready:
    mov eax, ecx
    imul eax, 180
    cdq
    idiv ebx
    add eax, 320
    mov r10d, eax

    mov eax, r11d
    imul eax, 180
    cdq
    idiv ebx
    mov edx, 302
    sub edx, eax
    mov eax, r10d
    mov r8d, ebx

    pop rbx
    ret
ProjectLevelPoint3D ENDP

DrawGopLine PROC
    push rbx
    push rsi
    push rdi
    push r12
    push r13
    push r14
    push r15
    sub rsp, 20h

    mov esi, eax
    cmp dword ptr [DrawOffsetEnabled], 0
    je gop_line_no_offset
    add ecx, dword ptr [DrawOffsetX]
    add edx, dword ptr [DrawOffsetY]
    add r8d, dword ptr [DrawOffsetX]
    add r9d, dword ptr [DrawOffsetY]

gop_line_no_offset:
    mov r12d, ecx
    shl r12d, 8
    mov r13d, edx
    shl r13d, 8

    mov r14d, r8d
    sub r14d, ecx
    mov r15d, r9d
    sub r15d, edx

    mov ebx, r14d
    test ebx, ebx
    jns line_dx_ready
    neg ebx

line_dx_ready:
    mov edi, r15d
    test edi, edi
    jns line_dy_ready
    neg edi

line_dy_ready:
    cmp ebx, edi
    jae line_steps_ready
    mov ebx, edi

line_steps_ready:
    test ebx, ebx
    jnz line_has_steps

    mov ecx, r12d
    sar ecx, 8
    mov edx, r13d
    sar edx, 8
    jmp line_draw_point

line_has_steps:
    shl r14d, 8
    mov eax, r14d
    cdq
    idiv ebx
    mov r14d, eax

    shl r15d, 8
    mov eax, r15d
    cdq
    idiv ebx
    mov r15d, eax
    inc ebx

line_loop:
    mov ecx, r12d
    sar ecx, 8
    mov edx, r13d
    sar edx, 8

line_draw_point:
    cmp ecx, 0
    jl line_skip_point
    cmp ecx, 638
    jge line_skip_point
    cmp edx, 0
    jl line_skip_point
    cmp edx, 478
    jge line_skip_point

    mov r8d, 2
    mov r9d, 2
    mov eax, esi
    call DrawGopRect

line_skip_point:
    test ebx, ebx
    jz line_done
    add r12d, r14d
    add r13d, r15d
    dec ebx
    jnz line_loop

line_done:
    add rsp, 20h
    pop r15
    pop r14
    pop r13
    pop r12
    pop rdi
    pop rsi
    pop rbx
    ret
DrawGopLine ENDP

ProjectEngine64Vertex PROC
    mov r11, qword ptr [CurrentModelVertexBase]
    mov eax, ecx
    lea rax, [rax + rax * 2]
    shl rax, 1
    add r11, rax

    movsx eax, word ptr [r11]
    imul eax, dword ptr [CurrentModelScale]
    sar eax, 4
    mov r8d, eax

    movsx eax, word ptr [r11 + 4]
    imul eax, dword ptr [CurrentModelScale]
    mov r9d, eax
    sar eax, 5
    add r8d, eax

    mov eax, dword ptr [CurrentModelBaseX]
    add eax, r8d

    movsx edx, word ptr [r11 + 2]
    imul edx, dword ptr [CurrentModelScale]
    sar edx, 4
    mov r10d, dword ptr [CurrentModelBaseY]
    sub r10d, edx

    mov edx, r9d
    sar edx, 6
    add r10d, edx
    mov edx, r10d
    ret
ProjectEngine64Vertex ENDP

DrawEngine64Model PROC
    push rbx
    push rsi
    push rdi
    push r12
    push r13
    push r14
    push r15
    sub rsp, 20h

    mov r12, qword ptr [Engine64ChunkBase]
    test r12, r12
    jz model_done

    cmp dword ptr [Engine64ModelRecordBytes], ENGINE64_MODEL_RECORD_BYTES
    jne model_done
    cmp ecx, dword ptr [Engine64ModelCount]
    jae model_done

    mov dword ptr [CurrentModelBaseX], edx
    mov dword ptr [CurrentModelBaseY], r8d
    mov dword ptr [CurrentModelScale], r9d

    mov r13d, dword ptr [Engine64ModelTableOffset]
    lea rdi, [r12 + r13]
    mov eax, ecx
    shl rax, 5
    add rdi, rax

    mov eax, dword ptr [rdi + 8]
    lea rax, [r12 + rax]
    mov qword ptr [CurrentModelVertexBase], rax

    mov eax, dword ptr [rdi + 16]
    lea rax, [r12 + rax]
    mov qword ptr [CurrentModelFaceBase], rax

    mov eax, dword ptr [r12 + 28]
    lea rax, [r12 + rax]
    mov qword ptr [CurrentModelPaletteBase], rax

    mov r14, qword ptr [CurrentModelFaceBase]
    mov r15d, dword ptr [rdi + 20]
    xor ebx, ebx

model_face_loop:
    cmp ebx, r15d
    jae model_done

    lea rsi, [r14 + rbx * 4]

    movzx ecx, byte ptr [rsi]
    call ProjectEngine64Vertex
    mov dword ptr [ProjectedX0], eax
    mov dword ptr [ProjectedY0], edx

    movzx ecx, byte ptr [rsi + 1]
    call ProjectEngine64Vertex
    mov dword ptr [ProjectedX1], eax
    mov dword ptr [ProjectedY1], edx

    movzx ecx, byte ptr [rsi + 2]
    call ProjectEngine64Vertex
    mov dword ptr [ProjectedX2], eax
    mov dword ptr [ProjectedY2], edx

    movzx eax, byte ptr [rsi + 3]
    cmp eax, dword ptr [Engine64BarCount]
    jae model_default_color
    mov rdx, qword ptr [CurrentModelPaletteBase]
    shl rax, 2
    mov eax, dword ptr [rdx + rax]
    jmp model_color_ready

model_default_color:
    mov eax, DIAG_ACCENT

model_color_ready:
    mov r13d, eax

    mov ecx, dword ptr [ProjectedX0]
    mov edx, dword ptr [ProjectedY0]
    mov r8d, dword ptr [ProjectedX1]
    mov r9d, dword ptr [ProjectedY1]
    mov eax, r13d
    call DrawGopLine

    mov ecx, dword ptr [ProjectedX1]
    mov edx, dword ptr [ProjectedY1]
    mov r8d, dword ptr [ProjectedX2]
    mov r9d, dword ptr [ProjectedY2]
    mov eax, r13d
    call DrawGopLine

    mov ecx, dword ptr [ProjectedX2]
    mov edx, dword ptr [ProjectedY2]
    mov r8d, dword ptr [ProjectedX0]
    mov r9d, dword ptr [ProjectedY0]
    mov eax, r13d
    call DrawGopLine

    inc ebx
    jmp model_face_loop

model_done:
    add rsp, 20h
    pop r15
    pop r14
    pop r13
    pop r12
    pop rdi
    pop rsi
    pop rbx
    ret
DrawEngine64Model ENDP

DrawString PROC
    push rbp
    mov rbp, rsp
    push rbx
    push rsi
    push r12
    push r13
    push r14
    push r15
    sub rsp, 20h

    mov r12d, ecx
    mov r13d, edx
    mov r14, r8
    mov r15d, r9d
    cmp dword ptr [DrawOffsetEnabled], 0
    je string_no_offset
    add r12d, dword ptr [DrawOffsetX]
    add r13d, dword ptr [DrawOffsetY]

string_no_offset:

string_loop:
    movzx eax, byte ptr [r14]
    test al, al
    jz string_done
    inc r14

    mov ecx, r12d
    mov edx, r13d
    mov r8d, eax
    mov r9d, r15d
    call DrawGlyph
    add r12d, 18
    jmp string_loop

string_done:
    add rsp, 20h
    pop r15
    pop r14
    pop r13
    pop r12
    pop rsi
    pop rbx
    pop rbp
    ret
DrawString ENDP

DrawGlyph PROC
    push rbx
    push rsi
    push rdi
    push r12
    push r13
    push r14
    push r15

    mov r12d, ecx
    mov r13d, edx
    mov eax, r9d
    call ConvertXrgbToGop
    mov r14d, eax

    mov eax, r8d
    call GetGlyphPtr
    mov rsi, rax

    xor r10d, r10d
glyph_row_loop:
    cmp r10d, 8
    jae glyph_done

    movzx ebx, byte ptr [rsi + r10]
    xor r11d, r11d
glyph_col_loop:
    cmp r11d, 8
    jae glyph_next_row

    mov eax, 80h
    mov ecx, r11d
    shr eax, cl
    test ebx, eax
    jz glyph_skip_pixel

    mov eax, r13d
    mov edx, r10d
    shl edx, 1
    add eax, edx
    mov edx, dword ptr [GopStride]
    imul rax, rdx
    mov edx, r12d
    mov ecx, r11d
    shl ecx, 1
    add edx, ecx
    add rax, rdx
    shl rax, 2

    mov rdi, qword ptr [GopFrameBase]
    add rdi, rax
    mov eax, r14d
    mov dword ptr [rdi], eax
    mov dword ptr [rdi + 4], eax
    add rdi, qword ptr [GopStrideBytes]
    mov dword ptr [rdi], eax
    mov dword ptr [rdi + 4], eax

glyph_skip_pixel:
    inc r11d
    jmp glyph_col_loop

glyph_next_row:
    inc r10d
    jmp glyph_row_loop

glyph_done:
    pop r15
    pop r14
    pop r13
    pop r12
    pop rdi
    pop rsi
    pop rbx
    ret
DrawGlyph ENDP

DrawString4x PROC
    push rbp
    mov rbp, rsp
    push rbx
    push rsi
    push r12
    push r13
    push r14
    push r15
    sub rsp, 20h

    mov r12d, ecx
    mov r13d, edx
    mov r14, r8
    mov r15d, r9d
    cmp dword ptr [DrawOffsetEnabled], 0
    je string4_no_offset
    add r12d, dword ptr [DrawOffsetX]
    add r13d, dword ptr [DrawOffsetY]

string4_no_offset:

string4_loop:
    movzx eax, byte ptr [r14]
    test al, al
    jz string4_done
    inc r14

    mov ecx, r12d
    mov edx, r13d
    mov r8d, eax
    mov r9d, r15d
    call DrawGlyph4x
    add r12d, 34
    jmp string4_loop

string4_done:
    add rsp, 20h
    pop r15
    pop r14
    pop r13
    pop r12
    pop rsi
    pop rbx
    pop rbp
    ret
DrawString4x ENDP

DrawGlyph4x PROC
    push rbx
    push rsi
    push rdi
    push r12
    push r13
    push r14
    push r15

    mov r12d, ecx
    mov r13d, edx
    mov eax, r9d
    call ConvertXrgbToGop
    mov r14d, eax

    mov eax, r8d
    call GetGlyphPtr
    mov rsi, rax

    xor r10d, r10d
glyph4_row_loop:
    cmp r10d, 8
    jae glyph4_done

    movzx ebx, byte ptr [rsi + r10]
    xor r11d, r11d
glyph4_col_loop:
    cmp r11d, 8
    jae glyph4_next_row

    mov eax, 80h
    mov ecx, r11d
    shr eax, cl
    test ebx, eax
    jz glyph4_skip_pixel

    mov eax, r13d
    mov edx, r10d
    shl edx, 2
    add eax, edx
    mov edx, dword ptr [GopStride]
    imul rax, rdx
    mov edx, r12d
    mov ecx, r11d
    shl ecx, 2
    add edx, ecx
    add rax, rdx
    shl rax, 2

    mov rdi, qword ptr [GopFrameBase]
    add rdi, rax
    mov r15d, 4

glyph4_pixel_row:
    mov eax, r14d
    mov dword ptr [rdi], eax
    mov dword ptr [rdi + 4], eax
    mov dword ptr [rdi + 8], eax
    mov dword ptr [rdi + 12], eax
    add rdi, qword ptr [GopStrideBytes]
    dec r15d
    jnz glyph4_pixel_row

glyph4_skip_pixel:
    inc r11d
    jmp glyph4_col_loop

glyph4_next_row:
    inc r10d
    jmp glyph4_row_loop

glyph4_done:
    pop r15
    pop r14
    pop r13
    pop r12
    pop rdi
    pop rsi
    pop rbx
    ret
DrawGlyph4x ENDP

GetGlyphPtr PROC
    cmp al, '0'
    jb glyph_check_letter
    cmp al, '9'
    ja glyph_check_letter
    sub al, '0'
    movzx eax, al
    shl eax, 3
    lea rdx, FontDigits
    add rax, rdx
    ret

glyph_check_letter:
    cmp al, 'A'
    jb glyph_check_symbol
    cmp al, 'Z'
    ja glyph_check_symbol
    sub al, 'A'
    movzx eax, al
    shl eax, 3
    lea rdx, FontLetters
    add rax, rdx
    ret

glyph_check_symbol:
    cmp al, ':'
    je glyph_colon
    cmp al, 'X'
    je glyph_x
    lea rax, [FontSpace]
    ret

glyph_colon:
    lea rax, [FontColon]
    ret

glyph_x:
    lea rax, [FontLetters + (23 * 8)]
    ret
GetGlyphPtr ENDP

WriteHex32 PROC
    push rbx
    mov ebx, ecx
    mov r10d, r8d
    mov r11d, r8d
    dec r11d
    shl r11d, 2

hex32_loop:
    mov eax, ebx
    mov ecx, r11d
    shr eax, cl
    and eax, 0Fh
    cmp eax, 10
    jb hex32_digit
    add eax, 'A' - 10
    jmp hex32_store
hex32_digit:
    add eax, '0'
hex32_store:
    mov byte ptr [rdx], al
    inc rdx
    sub r11d, 4
    dec r10d
    jnz hex32_loop

    pop rbx
    ret
WriteHex32 ENDP

WriteHex64 PROC
    push rbx
    mov rbx, rcx
    mov r10d, r8d
    mov r11d, r8d
    dec r11d
    shl r11d, 2

hex64_loop:
    mov rax, rbx
    mov ecx, r11d
    shr rax, cl
    and eax, 0Fh
    cmp eax, 10
    jb hex64_digit
    add eax, 'A' - 10
    jmp hex64_store
hex64_digit:
    add eax, '0'
hex64_store:
    mov byte ptr [rdx], al
    inc rdx
    sub r11d, 4
    dec r10d
    jnz hex64_loop

    pop rbx
    ret
WriteHex64 ENDP

.data
align 8
ImageHandle dq 0
GopProtocol dq 0
SimplePointerProtocol dq 0
GopFrameBase dq 0
GopFrameBytes dq 0
GopStrideBytes dq 0
GopWidth dd 0
GopHeight dd 0
GopPixelFormat dd 0
GopStride dd 0
GopRedMask dd 0
GopGreenMask dd 0
GopBlueMask dd 0
GopPresentMode dd 0
GopPresentX dd 0
GopPresentY dd 0
DrawOffsetEnabled dd 0
DrawOffsetX dd 0
DrawOffsetY dd 0

align 8
ArenaAllocBase dq 0
ArenaAllocEnd dq 0
ArenaBase dq 0
ArenaEnd dq 0
EngineArenaBase dq 0
EngineArenaSize dq 0
EngineArenaUsed dq 0
EngineArenaFree dq 0
FrameArenaBase dq 0
FrameArenaSize dq 0
FrameArenaUsed dq 0
FrameArenaFree dq 0
DepthArenaBase dq 0
DepthArenaSize dq 0
DepthArenaUsed dq 0
DepthArenaFree dq 0
TextureArenaBase dq 0
TextureArenaSize dq 0
TextureArenaUsed dq 0
TextureArenaFree dq 0
MeshArenaBase dq 0
MeshArenaSize dq 0
MeshArenaUsed dq 0
MeshArenaFree dq 0
AudioArenaBase dq 0
AudioArenaSize dq 0
AudioArenaUsed dq 0
AudioArenaFree dq 0
ScratchArenaBase dq 0
ScratchArenaSize dq 0
ScratchArenaUsed dq 0
ScratchArenaFree dq 0
LogArenaBase dq 0
LogArenaSize dq 0
LogArenaUsed dq 0
LogArenaFree dq 0

align 8
LoadedImageProtocol dq 0
FileSystemProtocol dq 0
RootFileProtocol dq 0
PackFileProtocol dq 0
PackReadSize dq 0
PackStatusCode dd 0
PackReadBytes dd 0
PackLoadedChunks dd 0
PackChunkMask dd 0
PackStagedChunks dd 0
PackStagedBytes dd 0
PackStageMask dd 0
Engine64Status dd 0
Engine64PayloadBytes dd 0
Engine64Width dd 0
Engine64Height dd 0
Engine64BarCount dd 0
Engine64FeatureFlags dd 0
Engine64ModelTableOffset dd 0
Engine64ModelCount dd 0
Engine64ModelRecordBytes dd 0
align 8
Engine64ChunkBase dq 0
Engine64ChunkBytes dd 0
align 8
TextureChunkBase dq 0
TextureChunkBytes dd 0
TextureAtlasPixels dq 0
TextureAtlasBytes dd 0
MaterialChunkBase dq 0
MaterialChunkBytes dd 0
MaterialRecordBase dq 0
MaterialCount dd 0
MeshChunkBase dq 0
MeshChunkBytes dd 0
MeshVertexBase dq 0
MeshTriangleBase dq 0
MeshVertexCount dd 0
MeshTriangleCount dd 0
MapChunkBase dq 0
MapChunkBytes dd 0
MapInstanceBase dq 0
MapVolumeBase dq 0
MapInstanceCount dd 0
MapVolumeCount dd 0
AssetValidationStatus dd 0
RenderStatus dd RENDER_STATUS_NO_ENGINE
PresentStatus dd PRESENT_STATUS_NO_FRAME
RenderFramePixels dd 0
PresentFramePixels dd 0

align 4
InputKeyScan dw 0
InputKeyChar dw 0
InputEventCount dd 0
InputConfirmCount dd 0
InputBackCount dd 0
InputLastScan dd 0
InputLastChar dd 0
InputLastAction dd 0
MenuSelection dd 0
MenuPanel dd 0
GameMode dd GAME_MODE_TITLE
PointerAvailable dd 0
PointerLeftLatch dd 0
PointerStateX dd 0
PointerStateY dd 0
PointerStateZ dd 0
PointerLeftButton db 0
PointerRightButton db 0
PointerStatePad dw 0
PlayerX dd 320
PlayerY dd 388
PlayerWorldX dd 0
PlayerWorldZ dd 0
CrosshairX dd 320
CrosshairY dd 224
EnemyHp dd 3
EnemyAlive dd 1
SentryLeftHp dd 1
SentryLeftAlive dd 1
SentryRightHp dd 1
SentryRightAlive dd 1
ObjectiveState dd 0
ShotFlashTicks dd 0
HitFlashTicks dd 0
MissionShots dd 0
MissionHits dd 0
LevelPulseTicks dd 0
align 8
CurrentModelVertexBase dq 0
CurrentModelFaceBase dq 0
CurrentModelPaletteBase dq 0
align 4
CurrentModelBaseX dd 0
CurrentModelBaseY dd 0
CurrentModelScale dd 0
ProjectedX0 dd 0
ProjectedY0 dd 0
ProjectedZ0 dd 0
ProjectedU0 dd 0
ProjectedV0 dd 0
ProjectedX1 dd 0
ProjectedY1 dd 0
ProjectedZ1 dd 0
ProjectedU1 dd 0
ProjectedV1 dd 0
ProjectedX2 dd 0
ProjectedY2 dd 0
ProjectedZ2 dd 0
ProjectedU2 dd 0
ProjectedV2 dd 0
LevelCameraX dd 0
LevelCameraZ dd 0
LevelRailColor dd 00D8FFFFh
LevelTerminalColor dd 00FF4058h
LevelScreenColor dd 003080D0h
LevelExitColor dd 00FF4058h
LevelExitCoreColor dd 00182A38h
LevelWardenColor dd 00182A38h
LevelSentryColor dd 00FF4058h
TitlePulseTicks dd 0
TitleSelectColor dd 00D8FFFFh
TitlePulseColor dd 00FF90FFh
TriangleColor dd 0
TriangleShadeColor dd 0
TriArea dd 0
TriMinX dd 0
TriMaxX dd 0
TriMinY dd 0
TriMaxY dd 0
TriDzDx dd 0
TriDzDy dd 0
TriZRow dd 0
TriDuDx dd 0
TriDuDy dd 0
TriDvDx dd 0
TriDvDy dd 0
TriURow dd 0
TriVRow dd 0
TriEdge0Dx dd 0
TriEdge0Dy dd 0
TriEdge1Dx dd 0
TriEdge1Dy dd 0
TriEdge2Dx dd 0
TriEdge2Dy dd 0
TriangleTexturedMode dd 0
TriangleTextureTile dd 0
TriangleMaterialIndex dd 0
TriangleMaterialFlags dd 0
TriangleBaseColor dd 0
RendererTriangleCount dd 0
RendererTexturedTriangleCount dd 0
RendererRejectedTriangles dd 0
RendererNearRejectedTriangles dd 0
RendererDepthWrites dd 0
RendererRayCount dd 0
RendererRayHits dd 0
RendererRayShadowHits dd 0
RendererAtmosphereSamples dd 0
RendererAtmosphereHits dd 0

TitleLine db 'CYBERSTORM',0
SubtitleLine db 'NEON DISTRICT',0
ResLine db 'RES: 00000000X00000000',0
PixelLine db 'PXFMT: 00000000',0
FrameLine db 'FB: 0000000000000000',0
StrideLine db 'STRIDE: 00000000',0
ArenaLine db 'ARENA OK: 0000000000000000',0
FrameArenaLine db 'FRAME: 0012C000 XRGB',0
DepthArenaLine db 'DEPTH: 0012C000 FREE',0
TextureArenaLine db 'TEX: 00800000 FREE',0
LogArenaLine db 'LOG: 00010000 USED 00000000',0
PackLine db 'PACK 00000000 CH 00000000',0
PackMaskLine db 'LOAD 00000000 BY 00000000',0
Engine64Line db 'E64 00000000 00000000X00000000',0
RenderLine db 'REN 00000000 PRE 00000000',0
InputLine db 'KEY SC0000 CH0000 ACT0000',0
CountsLine db 'OK 00000000 BACK 00000000',0
StatusLine db 'STATUS: TITLE READY',0
MenuLine db 'X64 START',0
StartHintLine db 'W S SELECT  ENTER GO',0
BuildHintLine db 'ESC BACK  OPTIONS  CREDITS',0
MenuTitleLine db 'SELECT',0
MenuOptionDiag db 'NEW GAME',0
MenuOptionLog db 'OPTIONS',0
MenuOptionCredits db 'CREDITS',0
MenuPanelIdle db 'ON',0
MenuPanelDiag db 'RUN',0
MenuPanelLog db 'FX',0
MenuPanelCredits db 'CR',0
LevelTitleLine db 'LEVEL 01 NEON SPINE',0
LevelObjectiveLine db 'ELIMINATE HOSTILES',0
LevelObjectiveKillLine db 'ELIMINATE HOSTILES',0
LevelObjectiveBreachLine db 'BREACH TERMINAL',0
LevelObjectiveExitLine db 'REACH EXIT GATE',0
LevelObjectiveClearLine db 'MISSION COMPLETE',0
LevelLoopLine db 'DOWN WARDEN BREACH EXTRACT',0
LevelHintLine db 'W S MOVE  A D STRAFE  FIRE  ESC',0
LevelStatusLine db 'SHOTS 0000 HITS 0000',0
LevelClearLine db 'WARDEN DOWN',0
LevelExitOpenLine db 'EXIT ROUTE OPEN',0
LevelCompleteLine db 'MISSION COMPLETE',0
LevelEnemyLine db 'WARDEN',0
LevelTerminalLine db 'NODE',0
LevelExitLine db 'EXIT',0
PanicTitleLine db 'CYBERSTORM X64 BOOT ALERT',0
PanicArenaLine db 'ARENA ALLOC FAIL',0
PanicForcedLine db 'BOOT ALERT CHECK',0

PackFileName LABEL WORD
    dw 'X','6','4','P','A','C','K','.','B','I','N',0

align 8
PackMagicValue dq 0304B503436585343h
Engine64MagicValue dq 030474E4534365343h
TextureChunkMagic dq 03130305845545343h
MaterialChunkMagic dq 031303054414D5343h
MeshChunkMagic dq 031303048534D5343h
MapChunkMagic dq 031303050414D5343h
PackTypeEngine dq 03436454E49474E45h
PackTypeTexture dq 00045525554584554h
PackTypeMesh dq 0000000004853454Dh
PackTypeMaterial dq 04C4149524554414Dh
PackTypeMap dq 0000000000050414Dh
PackTypeScript dq 00000545049524353h
PackTypeAudio dq 00000004F49445541h
PackTypeTitle dq 0000000454C544954h
PackTypeCampaign dq 04E474941504D4143h

PanicNoGopMessage LABEL WORD
    dw 'C','y','b','e','r','S','t','o','r','m',' ','x','6','4',' ','P','A','N','I','C',13,10
    dw 'G','O','P',' ','l','o','c','a','t','e',' ','f','a','i','l','e','d',13,10,0

EfiGraphicsOutputProtocolGuid LABEL BYTE
    dd 09042A9DEh
    dw 023DCh
    dw 04A38h
    db 096h,0FBh,07Ah,0DEh,0D0h,080h,051h,06Ah

EfiSimplePointerProtocolGuid LABEL BYTE
    dd 31878C87h
    dw 00B75h
    dw 011D5h
    db 09Ah,04Fh,000h,090h,027h,03Fh,0C1h,04Dh

EfiLoadedImageProtocolGuid LABEL BYTE
    dd 05B1B31A1h
    dw 09562h
    dw 011D2h
    db 08Eh,03Fh,000h,0A0h,0C9h,069h,072h,03Bh

EfiSimpleFileSystemProtocolGuid LABEL BYTE
    dd 0964E5B22h
    dw 06459h
    dw 011D2h
    db 08Eh,039h,000h,0A0h,0C9h,069h,072h,03Bh

FontSpace db 00h,00h,00h,00h,00h,00h,00h,00h
FontColon db 00h,18h,18h,00h,18h,18h,00h,00h

FontDigits LABEL BYTE
    db 3Ch,66h,6Eh,76h,66h,66h,3Ch,00h
    db 18h,38h,18h,18h,18h,18h,7Eh,00h
    db 3Ch,66h,06h,1Ch,30h,60h,7Eh,00h
    db 3Ch,66h,06h,1Ch,06h,66h,3Ch,00h
    db 0Ch,1Ch,3Ch,6Ch,7Eh,0Ch,0Ch,00h
    db 7Eh,60h,7Ch,06h,06h,66h,3Ch,00h
    db 1Ch,30h,60h,7Ch,66h,66h,3Ch,00h
    db 7Eh,06h,0Ch,18h,30h,30h,30h,00h
    db 3Ch,66h,66h,3Ch,66h,66h,3Ch,00h
    db 3Ch,66h,66h,3Eh,06h,0Ch,38h,00h

FontLetters LABEL BYTE
    db 18h,3Ch,66h,66h,7Eh,66h,66h,00h
    db 7Ch,66h,66h,7Ch,66h,66h,7Ch,00h
    db 3Ch,66h,60h,60h,60h,66h,3Ch,00h
    db 78h,6Ch,66h,66h,66h,6Ch,78h,00h
    db 7Eh,60h,60h,7Ch,60h,60h,7Eh,00h
    db 7Eh,60h,60h,7Ch,60h,60h,60h,00h
    db 3Ch,66h,60h,6Eh,66h,66h,3Ch,00h
    db 66h,66h,66h,7Eh,66h,66h,66h,00h
    db 7Eh,18h,18h,18h,18h,18h,7Eh,00h
    db 1Eh,0Ch,0Ch,0Ch,0Ch,6Ch,38h,00h
    db 66h,6Ch,78h,70h,78h,6Ch,66h,00h
    db 60h,60h,60h,60h,60h,60h,7Eh,00h
    db 63h,77h,7Fh,6Bh,63h,63h,63h,00h
    db 66h,76h,7Eh,7Eh,6Eh,66h,66h,00h
    db 3Ch,66h,66h,66h,66h,66h,3Ch,00h
    db 7Ch,66h,66h,7Ch,60h,60h,60h,00h
    db 3Ch,66h,66h,66h,6Eh,3Ch,0Eh,00h
    db 7Ch,66h,66h,7Ch,78h,6Ch,66h,00h
    db 3Ch,66h,60h,3Ch,06h,66h,3Ch,00h
    db 7Eh,18h,18h,18h,18h,18h,18h,00h
    db 66h,66h,66h,66h,66h,66h,3Ch,00h
    db 66h,66h,66h,66h,66h,3Ch,18h,00h
    db 63h,63h,63h,6Bh,7Fh,77h,63h,00h
    db 66h,66h,3Ch,18h,3Ch,66h,66h,00h
    db 66h,66h,66h,3Ch,18h,18h,18h,00h
    db 7Eh,06h,0Ch,18h,30h,60h,7Eh,00h

END
