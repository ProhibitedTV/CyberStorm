option casemap:none

EFI_SYSTEM_TABLE_CONOUT       equ 64
EFI_SYSTEM_TABLE_CONIN        equ 48
EFI_SYSTEM_TABLE_BOOTSERV     equ 96
EFI_SIMPLE_TEXT_OUTPUT_TEXT   equ 8
EFI_SIMPLE_TEXT_OUTPUT_CLEAR  equ 48
EFI_SIMPLE_TEXT_INPUT_READ    equ 8
EFI_BOOT_SERVICES_ALLOC_PAGES equ 40
EFI_BOOT_SERVICES_HANDLE_PROTOCOL equ 152
EFI_BOOT_SERVICES_STALL       equ 248
EFI_BOOT_SERVICES_LOCATE      equ 320
DIAGNOSTIC_STALL_USEC         equ 60000000
INPUT_LOOP_TICKS              equ 6000
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
ENGINE64_EXPECTED_WIDTH       equ 00000280h
ENGINE64_EXPECTED_HEIGHT      equ 000001E0h
ENGINE64_MIN_BYTES            equ 00000060h
ENGINE64_FRAME_BYTES          equ 0012C000h
ENGINE64_FRAME_PIXELS         equ 0004B000h
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
MENU_MAX_SELECTION            equ 2

FILL_GOP_RECT MACRO RectX, RectY, RectW, RectH, RectColor
LOCAL row_loop
    mov eax, RectColor
    call ConvertXrgbToGop
    mov r11d, eax
    mov r10, qword ptr [GopFrameBase]
    mov edx, dword ptr [GopStride]
    mov rax, RectY
    imul rax, rdx
    add rax, RectX
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
    call DrawTitleScreen
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
    mov qword ptr [Engine64ChunkBase], 0
    mov dword ptr [Engine64ChunkBytes], 0
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

    mov dword ptr [Engine64Status], 0
    xor eax, eax
    ret

engine64_fail:
    mov dword ptr [Engine64Status], PACK_STATUS_ENGINE64
    mov eax, 1
    ret
ValidateEngine64Chunk ENDP

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
    sub rsp, 20h

    mov r12d, INPUT_LOOP_TICKS

input_loop:
    call PollInputKey
    test eax, eax
    jz input_stall

    call DrawTitleScreen

input_stall:
    mov ecx, INPUT_POLL_STALL_USEC
    call qword ptr [rsi + EFI_BOOT_SERVICES_STALL]
    dec r12d
    jnz input_loop

    add rsp, 20h
    pop r12
    ret
RunInputLoop ENDP

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

HandleInputKey PROC
    movzx eax, word ptr [InputKeyScan]
    mov dword ptr [InputLastScan], eax
    movzx edx, word ptr [InputKeyChar]
    mov dword ptr [InputLastChar], edx
    inc dword ptr [InputEventCount]

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
    inc eax
    mov dword ptr [MenuPanel], eax
    ret

input_back:
    mov dword ptr [InputLastAction], INPUT_ACTION_BACK
    inc dword ptr [InputBackCount]
    mov dword ptr [MenuPanel], 0

input_done:
    ret
HandleInputKey ENDP

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

    FILL_GOP_RECT 404, 22, 212, 136, 00070B12h
    FILL_GOP_RECT 408, 28, 4, 124, DIAG_ACCENT
    FILL_GOP_RECT 416, 150, 184, 2, 00FF90FFh

    cmp dword ptr [MenuSelection], 0
    jne menu_select_log
    FILL_GOP_RECT 420, 54, 152, 24, DIAG_ACCENT
    FILL_GOP_RECT 414, 60, 4, 12, 00FF90FFh
    jmp menu_highlight_done

menu_select_log:
    cmp dword ptr [MenuSelection], 1
    jne menu_select_panic
    FILL_GOP_RECT 420, 86, 152, 24, DIAG_ACCENT
    FILL_GOP_RECT 414, 92, 4, 12, 00FF90FFh
    jmp menu_highlight_done

menu_select_panic:
    FILL_GOP_RECT 420, 118, 152, 24, DIAG_ACCENT
    FILL_GOP_RECT 414, 124, 4, 12, 00FF90FFh

menu_highlight_done:
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
    jne panel_check_panic
    lea r8, MenuPanelLog
    jmp panel_ready

panel_check_panic:
    cmp dword ptr [MenuPanel], 3
    jne panel_ready
    lea r8, MenuPanelPanic

panel_ready:
    mov ecx, 522
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
    lea r8, MenuOptionPanic
    mov r9d, DIAG_TEXT
    cmp dword ptr [MenuSelection], 2
    jne draw_menu_panic
    mov r9d, DIAG_BG
draw_menu_panic:
    call DrawString

    add rsp, 20h
    pop rdi
    ret
DrawMenuOptions ENDP

DrawTitleScreen PROC
    push rdi
    sub rsp, 20h

    call DrawEngine64Showcase

    FILL_GOP_RECT 28, 24, 360, 104, 00070B12h
    FILL_GOP_RECT 42, 86, 286, 5, DIAG_ACCENT
    FILL_GOP_RECT 42, 94, 192, 2, 00FFE66Dh

    mov ecx, 42
    mov edx, 42
    lea r8, TitleLine
    mov r9d, DIAG_TEXT
    call DrawString

    mov ecx, 44
    mov edx, 100
    lea r8, SubtitleLine
    mov r9d, DIAG_MUTED
    call DrawString

    call DrawMenuOptions

    FILL_GOP_RECT 28, 402, 412, 52, 00070B12h
    FILL_GOP_RECT 28, 404, 412, 2, 00FF90FFh

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

    add rsp, 20h
    pop rdi
    ret
DrawTitleScreen ENDP

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

    mov dword ptr [GopPresentX], 0
    mov dword ptr [GopPresentY], 0

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
align 8
Engine64ChunkBase dq 0
Engine64ChunkBytes dd 0
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

TitleLine db 'CYBERSTORM',0
SubtitleLine db 'X64 NEON DISTRICT',0
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
StartHintLine db 'W/S SELECT  ENTER CONFIRM',0
BuildHintLine db 'ESC BACK  OPTIONS  CREDITS',0
MenuTitleLine db 'SELECT',0
MenuOptionDiag db 'NEW GAME',0
MenuOptionLog db 'OPTIONS',0
MenuOptionPanic db 'CREDITS',0
MenuPanelIdle db 'LIVE',0
MenuPanelDiag db 'RUN',0
MenuPanelLog db 'TUNE',0
MenuPanelPanic db 'CREDS',0
PanicTitleLine db 'CYBERSTORM X64 BOOT ALERT',0
PanicArenaLine db 'ARENA ALLOC FAIL',0
PanicForcedLine db 'BOOT ALERT CHECK',0

PackFileName LABEL WORD
    dw 'X','6','4','P','A','C','K','.','B','I','N',0

align 8
PackMagicValue dq 0304B503436585343h
Engine64MagicValue dq 030474E4534365343h
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
