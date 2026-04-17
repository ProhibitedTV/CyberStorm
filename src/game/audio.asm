SPEAKER_DIV_DRY    equ 4200
SPEAKER_DIV_LOW    equ 3600
SPEAKER_DIV_WARN   equ 3000
SPEAKER_DIV_MID    equ 2400
SPEAKER_DIV_UP     equ 1800
SPEAKER_DIV_HIGH   equ 1400
SPEAKER_DIV_CHIME  equ 1100

AUDIO_BACKEND_PCSPEAKER equ 0
AUDIO_BACKEND_SB16      equ 1

SB16_BASE              equ 0220h
SB16_RESET_PORT        equ SB16_BASE + 6
SB16_READ_DATA_PORT    equ SB16_BASE + 0Ah
SB16_WRITE_DATA_PORT   equ SB16_BASE + 0Ch
SB16_WRITE_STATUS_PORT equ SB16_BASE + 0Ch
SB16_READ_STATUS_PORT  equ SB16_BASE + 0Eh

DMA1_MASK_PORT         equ 0Ah
DMA1_MODE_PORT         equ 0Bh
DMA1_CLEAR_PORT        equ 0Ch
DMA1_CH1_ADDR_PORT     equ 02h
DMA1_CH1_COUNT_PORT    equ 03h
DMA1_CH1_PAGE_PORT     equ 083h
DMA1_MASK_CHANNEL_1    equ 05h
DMA1_UNMASK_CHANNEL_1  equ 01h
DMA1_MODE_SINGLE_WRITE equ 049h

SB16_SET_BLOCK_SIZE    equ 048h
SB16_START_AUTO_DMA_8  equ 01Ch
SB16_TIME_CONSTANT     equ 166
; 611 samples at the current SB16 time constant lands very close to one BIOS
; tick, so the background voice can change on the same rhythm as the game loop.
AUDIO_BLOCK_SAMPLES    equ 611
AUDIO_SAMPLE_CENTER    equ 128

MUSIC_THEME_SPLASH equ 0
MUSIC_THEME_TITLE  equ 1
MUSIC_THEME_RUN    equ 2
MUSIC_THEME_WIN    equ 3
MUSIC_THEME_LOSE   equ 4
MUSIC_THEME_NONE   equ 0FFh

; Generated themes are 2-byte cells:
;   <note id>, <duration in BIOS ticks>
; The transport owns theme selection, pointer rewind, and note timing. The
; voice layer turns the current transport note into a single raw tone. Because
; the hardware path is effectively monophonic, one-shot SFX always take the
; speaker while the music transport simply pauses on its current note.
MUSIC_NOTE_REST equ 0
MUSIC_NOTE_G2   equ 1
MUSIC_NOTE_A2   equ 2
MUSIC_NOTE_C3   equ 3
MUSIC_NOTE_D3   equ 4
MUSIC_NOTE_E3   equ 5
MUSIC_NOTE_F3   equ 6
MUSIC_NOTE_G3   equ 7
MUSIC_NOTE_A3   equ 8
MUSIC_NOTE_C4   equ 9
MUSIC_NOTE_D4   equ 10
MUSIC_NOTE_E4   equ 11
MUSIC_NOTE_F4   equ 12
MUSIC_NOTE_G4   equ 13
MUSIC_NOTE_LOOP equ 0FFh

init_audio:
    mov byte ptr [audio_backend], AUDIO_BACKEND_PCSPEAKER
    mov byte ptr [audio_phase_accum], 0
    mov byte ptr [sb16_dma_active], 0
    mov word ptr [audio_hw_divisor], 0
    call clear_music_voice
    call clear_sfx_voice
    call clear_audio_output_voice
    call init_sb16_backend
    call stop_sfx
    call stop_music
    ret

update_audio:
IF AUDIO_MUSIC_ENABLED
    call sync_music_theme
    call update_music_transport
ELSE
    call stop_music
ENDIF
    call update_sfx_transport
    call resolve_audio_transport
    call commit_audio_output
    ret

sync_music_theme:
    cmp byte ptr [session_music_enabled], 0
    jne sync_music_theme_enabled
    cmp byte ptr [music_theme], MUSIC_THEME_NONE
    je sync_music_done
    call stop_music
    jmp sync_music_done

sync_music_theme_enabled:
    call get_music_theme_for_state
    cmp al, [music_theme]
    je sync_music_done
    call start_music_theme

sync_music_done:
    ret

get_music_theme_for_state:
    mov al, [game_state]
    cmp al, STATE_SPLASH
    je music_theme_state_splash
    cmp al, STATE_TITLE
    je music_theme_state_title
    cmp al, STATE_PLAYING
    je music_theme_state_run
    cmp al, STATE_WIN
    je music_theme_state_win
    cmp al, STATE_LOSE
    je music_theme_state_lose
    mov al, MUSIC_THEME_NONE
    ret

music_theme_state_splash:
    mov al, MUSIC_THEME_SPLASH
    ret

music_theme_state_title:
    mov al, MUSIC_THEME_TITLE
    ret

music_theme_state_run:
    mov al, MUSIC_THEME_RUN
    ret

music_theme_state_win:
    mov al, MUSIC_THEME_WIN
    ret

music_theme_state_lose:
    mov al, MUSIC_THEME_LOSE
    ret

start_music_theme:
    cmp al, MUSIC_THEME_NONE
    jne start_music_apply
    call stop_music
    ret

start_music_apply:
    mov [music_theme], al
    call reset_music_pointer
    mov byte ptr [music_ticks], 0
    mov byte ptr [music_note], MUSIC_NOTE_REST
    call clear_music_voice
    ret

stop_music:
    mov byte ptr [music_theme], MUSIC_THEME_NONE
    mov byte ptr [music_ticks], 0
    mov byte ptr [music_note], MUSIC_NOTE_REST
    mov word ptr [music_ptr], 0
    call clear_music_voice
    ret

reset_music_pointer:
    push ax
    push bx
    mov al, [music_theme]
    xor ah, ah
    shl ax, 1
    mov bx, ax
    mov ax, word ptr [music_theme_table + bx]
    mov word ptr [music_ptr], ax
    pop bx
    pop ax
    ret

update_music_transport:
    cmp byte ptr [music_theme], MUSIC_THEME_NONE
    jne update_music_theme_active
    call clear_music_voice
    ret

update_music_theme_active:
    cmp byte ptr [sound_timer], 0
    jne update_music_paused
    cmp byte ptr [music_ticks], 0
    jne update_music_have_event
    call load_music_event

update_music_have_event:
    cmp byte ptr [music_ticks], 0
    je update_music_clear
    cmp byte ptr [music_note], MUSIC_NOTE_REST
    je update_music_rest
    call set_music_voice_from_note
    jmp update_music_tick

update_music_rest:
    call clear_music_voice

update_music_tick:
    dec byte ptr [music_ticks]
    ret

update_music_paused:
    ret

update_music_clear:
    call clear_music_voice
    ret

load_music_event:
    push ax
    push si
    mov si, word ptr [music_ptr]

load_music_event_retry:
    mov al, [si]
    cmp al, MUSIC_NOTE_LOOP
    jne load_music_event_apply
    call reset_music_pointer
    mov si, word ptr [music_ptr]
    jmp load_music_event_retry

load_music_event_apply:
    mov [music_note], al
    mov al, [si + 1]
    mov [music_ticks], al
    add si, 2
    mov word ptr [music_ptr], si
    pop si
    pop ax
    ret

set_music_voice_from_note:
    push ax
    push bx
    push si
    mov al, [music_note]
    xor ah, ah
    mov si, ax
    shl ax, 1
    mov bx, word ptr [music_note_divisors + ax]
    mov word ptr [music_divisor], bx
    mov al, [music_note_phase_steps + si]
    mov [music_phase_step], al
    pop si
    pop bx
    pop ax
    ret

start_sfx:
    push ax
    push bx
    cmp al, SFX_NONE
    jne start_sfx_pick
    call stop_sfx
    jmp start_sfx_done

start_sfx_pick:
    mov [sound_id], al
    xor bh, bh
    mov bl, 4
    cmp al, SFX_GATE
    jne start_sfx_check_hit
    mov bl, 8
    jmp start_sfx_apply

start_sfx_check_hit:
    cmp al, SFX_HIT
    jne start_sfx_check_pulse
    mov bl, 7
    jmp start_sfx_apply

start_sfx_check_pulse:
    cmp al, SFX_PULSE
    jne start_sfx_check_surge
    mov bl, 6
    jmp start_sfx_apply

start_sfx_check_surge:
    cmp al, SFX_SURGE
    jne start_sfx_check_recharge
    mov bl, 6
    jmp start_sfx_apply

start_sfx_check_recharge:
    cmp al, SFX_RECHARGE
    jne start_sfx_check_sector
    mov bl, 6
    jmp start_sfx_apply

start_sfx_check_sector:
    cmp al, SFX_SECTOR
    jne start_sfx_check_win
    mov bl, 6
    jmp start_sfx_apply

start_sfx_check_win:
    cmp al, SFX_WIN
    jne start_sfx_check_lose
    mov bl, 12
    jmp start_sfx_apply

start_sfx_check_lose:
    cmp al, SFX_LOSE
    jne start_sfx_apply
    mov bl, 12

start_sfx_apply:
    mov [sound_timer], bl
    mov byte ptr [sound_phase], 0
    call clear_sfx_voice

start_sfx_done:
    pop bx
    pop ax
    ret

update_sfx_transport:
    push ax
    push bx
    cmp byte ptr [sound_timer], 0
    jne update_sfx_active
    call clear_sfx_voice
    jmp update_sfx_done

update_sfx_active:
    mov al, [sound_id]
    mov bl, [sound_phase]
    cmp al, SFX_SECTOR
    je update_sfx_sector
    cmp al, SFX_BLOCK
    je update_sfx_block
    cmp al, SFX_SHARD
    je update_sfx_shard
    cmp al, SFX_GATE
    je update_sfx_gate
    cmp al, SFX_HIT
    je update_sfx_hit
    cmp al, SFX_KILL
    je update_sfx_kill
    cmp al, SFX_PULSE
    je update_sfx_pulse
    cmp al, SFX_DRY
    je update_sfx_dry
    cmp al, SFX_SURGE
    je update_sfx_surge
    cmp al, SFX_TRAP
    je update_sfx_trap
    cmp al, SFX_RECHARGE
    je update_sfx_recharge
    cmp al, SFX_WIN
    je update_sfx_win
    cmp al, SFX_LOSE
    je update_sfx_lose
    call stop_sfx
    jmp update_sfx_done

update_sfx_sector:
    cmp bl, 2
    jb update_sfx_sector_a
    cmp bl, 4
    jb update_sfx_sector_b
    mov bx, SPEAKER_DIV_UP
    jmp update_sfx_apply
update_sfx_sector_a:
    mov bx, SPEAKER_DIV_LOW
    jmp update_sfx_apply
update_sfx_sector_b:
    mov bx, SPEAKER_DIV_MID
    jmp update_sfx_apply

update_sfx_block:
    mov bx, SPEAKER_DIV_DRY
    jmp update_sfx_apply

update_sfx_shard:
    cmp bl, 2
    jb update_sfx_shard_a
    mov bx, SPEAKER_DIV_HIGH
    jmp update_sfx_apply
update_sfx_shard_a:
    mov bx, SPEAKER_DIV_UP
    jmp update_sfx_apply

update_sfx_gate:
    cmp bl, 2
    jb update_sfx_gate_a
    cmp bl, 4
    jb update_sfx_gate_b
    cmp bl, 6
    jb update_sfx_gate_c
    mov bx, SPEAKER_DIV_CHIME
    jmp update_sfx_apply
update_sfx_gate_a:
    mov bx, SPEAKER_DIV_MID
    jmp update_sfx_apply
update_sfx_gate_b:
    mov bx, SPEAKER_DIV_UP
    jmp update_sfx_apply
update_sfx_gate_c:
    mov bx, SPEAKER_DIV_HIGH
    jmp update_sfx_apply

update_sfx_hit:
    test bl, 1
    jz update_sfx_hit_a
    mov bx, SPEAKER_DIV_WARN
    jmp update_sfx_apply
update_sfx_hit_a:
    mov bx, SPEAKER_DIV_LOW
    jmp update_sfx_apply

update_sfx_kill:
    cmp bl, 2
    jb update_sfx_kill_a
    mov bx, SPEAKER_DIV_WARN
    jmp update_sfx_apply
update_sfx_kill_a:
    mov bx, SPEAKER_DIV_UP
    jmp update_sfx_apply

update_sfx_pulse:
    test bl, 1
    jz update_sfx_pulse_a
    mov bx, SPEAKER_DIV_UP
    jmp update_sfx_apply
update_sfx_pulse_a:
    mov bx, SPEAKER_DIV_LOW
    jmp update_sfx_apply

update_sfx_dry:
    mov bx, SPEAKER_DIV_DRY
    jmp update_sfx_apply

update_sfx_surge:
    test bl, 1
    jz update_sfx_surge_a
    mov bx, SPEAKER_DIV_MID
    jmp update_sfx_apply
update_sfx_surge_a:
    mov bx, SPEAKER_DIV_LOW
    jmp update_sfx_apply

update_sfx_trap:
    cmp bl, 2
    jb update_sfx_trap_a
    cmp bl, 4
    jb update_sfx_trap_b
    mov bx, SPEAKER_DIV_HIGH
    jmp update_sfx_apply
update_sfx_trap_a:
    mov bx, SPEAKER_DIV_WARN
    jmp update_sfx_apply
update_sfx_trap_b:
    mov bx, SPEAKER_DIV_UP
    jmp update_sfx_apply

update_sfx_recharge:
    cmp bl, 2
    jb update_sfx_recharge_a
    cmp bl, 4
    jb update_sfx_recharge_b
    mov bx, SPEAKER_DIV_HIGH
    jmp update_sfx_apply
update_sfx_recharge_a:
    mov bx, SPEAKER_DIV_MID
    jmp update_sfx_apply
update_sfx_recharge_b:
    mov bx, SPEAKER_DIV_UP
    jmp update_sfx_apply

update_sfx_win:
    mov al, bl
    and al, 03h
    cmp al, 0
    je update_sfx_win_a
    cmp al, 1
    je update_sfx_win_b
    cmp al, 2
    je update_sfx_win_c
    mov bx, SPEAKER_DIV_CHIME
    jmp update_sfx_apply
update_sfx_win_a:
    mov bx, SPEAKER_DIV_MID
    jmp update_sfx_apply
update_sfx_win_b:
    mov bx, SPEAKER_DIV_UP
    jmp update_sfx_apply
update_sfx_win_c:
    mov bx, SPEAKER_DIV_HIGH
    jmp update_sfx_apply

update_sfx_lose:
    mov al, bl
    and al, 03h
    cmp al, 0
    je update_sfx_lose_a
    cmp al, 1
    je update_sfx_lose_b
    cmp al, 2
    je update_sfx_lose_c
    mov bx, SPEAKER_DIV_WARN
    jmp update_sfx_apply
update_sfx_lose_a:
    mov bx, SPEAKER_DIV_LOW
    jmp update_sfx_apply
update_sfx_lose_b:
    mov bx, SPEAKER_DIV_DRY
    jmp update_sfx_apply
update_sfx_lose_c:
    mov bx, SPEAKER_DIV_LOW

update_sfx_apply:
    call set_sfx_voice_from_divisor
    inc byte ptr [sound_phase]
    dec byte ptr [sound_timer]
    jne update_sfx_done
    call stop_sfx

update_sfx_done:
    pop bx
    pop ax
    ret

set_sfx_voice_from_divisor:
    push ax
    mov word ptr [sfx_divisor], bx
    call map_divisor_to_phase_step
    mov [sfx_phase_step], al
    pop ax
    ret

resolve_audio_transport:
    cmp byte ptr [sound_timer], 0
    jne resolve_audio_use_sfx
    mov ax, [music_divisor]
    mov [audio_output_divisor], ax
    mov al, [music_phase_step]
    mov [audio_output_phase_step], al
    ret

resolve_audio_use_sfx:
    mov ax, [sfx_divisor]
    mov [audio_output_divisor], ax
    mov al, [sfx_phase_step]
    mov [audio_output_phase_step], al
    ret

commit_audio_output:
    cmp byte ptr [audio_backend], AUDIO_BACKEND_SB16
    jne commit_audio_pc_speaker
    call fill_sb16_buffer
    ret

commit_audio_pc_speaker:
    mov bx, [audio_output_divisor]
    cmp bx, 0
    jne commit_audio_pc_program
    call stop_pc_speaker_output
    mov word ptr [audio_hw_divisor], 0
    ret

commit_audio_pc_program:
    cmp bx, [audio_hw_divisor]
    je commit_audio_done
    call program_pc_speaker_divisor
    mov [audio_hw_divisor], bx

commit_audio_done:
    ret

program_pc_speaker_divisor:
    push ax
    push dx
    mov dx, 43h
    mov al, 0B6h
    out dx, al
    mov dx, 42h
    mov al, bl
    out dx, al
    mov al, bh
    out dx, al
    mov dx, 61h
    in al, dx
    or al, 03h
    out dx, al
    pop dx
    pop ax
    ret

stop_pc_speaker_output:
    push ax
    push dx
    mov dx, 61h
    in al, dx
    and al, 0FCh
    out dx, al
    pop dx
    pop ax
    ret

stop_sfx:
    mov byte ptr [sound_id], SFX_NONE
    mov byte ptr [sound_timer], 0
    mov byte ptr [sound_phase], 0
    call clear_sfx_voice
    ret

clear_music_voice:
    mov word ptr [music_divisor], 0
    mov byte ptr [music_phase_step], 0
    ret

clear_sfx_voice:
    mov word ptr [sfx_divisor], 0
    mov byte ptr [sfx_phase_step], 0
    ret

clear_audio_output_voice:
    mov word ptr [audio_output_divisor], 0
    mov byte ptr [audio_output_phase_step], 0
    ret

init_sb16_backend:
    call sb16_reset
    jc init_sb16_done
    mov byte ptr [audio_backend], AUDIO_BACKEND_SB16
    call fill_sb16_buffer
    call program_dma1_for_sb16
    mov al, 040h
    call sb16_write_dsp
    mov al, SB16_TIME_CONSTANT
    call sb16_write_dsp
    mov al, SB16_SET_BLOCK_SIZE
    call sb16_write_dsp
    mov ax, AUDIO_BLOCK_SAMPLES - 1
    call sb16_write_block_length
    mov al, 0D1h
    call sb16_write_dsp
    mov al, SB16_START_AUTO_DMA_8
    call sb16_write_dsp
    mov byte ptr [sb16_dma_active], 1

init_sb16_done:
    ret

fill_sb16_buffer:
    push ax
    push bx
    push cx
    push dx
    push di
    mov di, offset sb16_audio_buffer
    mov cx, AUDIO_BLOCK_SAMPLES
    mov dl, [audio_output_phase_step]
    cmp dl, 0
    jne fill_sb16_tone
    mov al, AUDIO_SAMPLE_CENTER
    rep stosb
    jmp fill_sb16_done

fill_sb16_tone:
    mov ah, [audio_phase_accum]

fill_sb16_loop:
    add ah, dl
    mov al, ah
    shr al, 1
    shr al, 1
    shr al, 1
    xor bh, bh
    mov bl, al
    mov al, [sb16_waveform + bx]
    add al, AUDIO_SAMPLE_CENTER
    stosb
    loop fill_sb16_loop
    mov [audio_phase_accum], ah

fill_sb16_done:
    pop di
    pop dx
    pop cx
    pop bx
    pop ax
    ret

program_dma1_for_sb16:
    push ax
    push bx
    push cx
    push dx
    mov ax, ds
    mov bx, ax
    shl ax, 1
    shl ax, 1
    shl ax, 1
    shl ax, 1
    shr bx, 1
    shr bx, 1
    shr bx, 1
    shr bx, 1
    shr bx, 1
    shr bx, 1
    shr bx, 1
    shr bx, 1
    shr bx, 1
    shr bx, 1
    shr bx, 1
    shr bx, 1
    add ax, offset sb16_audio_buffer
    adc bl, 0
    mov cx, ax

    mov dx, DMA1_MASK_PORT
    mov al, DMA1_MASK_CHANNEL_1
    out dx, al
    mov dx, DMA1_CLEAR_PORT
    xor al, al
    out dx, al
    mov dx, DMA1_MODE_PORT
    mov al, DMA1_MODE_SINGLE_WRITE
    out dx, al
    mov dx, DMA1_CH1_ADDR_PORT
    mov al, cl
    out dx, al
    mov al, ch
    out dx, al
    mov dx, DMA1_CH1_PAGE_PORT
    mov al, bl
    out dx, al
    mov dx, DMA1_CLEAR_PORT
    xor al, al
    out dx, al
    mov dx, DMA1_CH1_COUNT_PORT
    mov ax, AUDIO_BLOCK_SAMPLES - 1
    out dx, al
    mov al, ah
    out dx, al
    mov dx, DMA1_MASK_PORT
    mov al, DMA1_UNMASK_CHANNEL_1
    out dx, al
    pop dx
    pop cx
    pop bx
    pop ax
    ret

sb16_reset:
    push ax
    push cx
    push dx
    mov dx, SB16_RESET_PORT
    mov al, 1
    out dx, al
    mov cx, 256

sb16_reset_delay:
    loop sb16_reset_delay
    xor al, al
    out dx, al
    mov dx, SB16_READ_STATUS_PORT
    mov cx, 0FFFFh

sb16_wait_ready:
    in al, dx
    test al, 080h
    jnz sb16_check_ack
    loop sb16_wait_ready
    stc
    jmp sb16_reset_done

sb16_check_ack:
    mov dx, SB16_READ_DATA_PORT
    in al, dx
    cmp al, 0AAh
    jne sb16_reset_fail
    clc
    jmp sb16_reset_done

sb16_reset_fail:
    stc

sb16_reset_done:
    pop dx
    pop cx
    pop ax
    ret

sb16_write_dsp:
    push ax
    push cx
    push dx
    mov ah, al
    mov dx, SB16_WRITE_STATUS_PORT
    mov cx, 0FFFFh

sb16_write_wait:
    in al, dx
    test al, 080h
    jz sb16_write_ready
    loop sb16_write_wait

sb16_write_ready:
    mov dx, SB16_WRITE_DATA_PORT
    mov al, ah
    out dx, al
    pop dx
    pop cx
    pop ax
    ret

sb16_write_block_length:
    push ax
    mov al, al
    call sb16_write_dsp
    mov al, ah
    call sb16_write_dsp
    pop ax
    ret

map_divisor_to_phase_step:
    mov al, 0
    cmp bx, SPEAKER_DIV_DRY
    je map_divisor_6
    cmp bx, SPEAKER_DIV_LOW
    je map_divisor_7
    cmp bx, SPEAKER_DIV_WARN
    je map_divisor_9
    cmp bx, SPEAKER_DIV_MID
    je map_divisor_12
    cmp bx, SPEAKER_DIV_UP
    je map_divisor_16
    cmp bx, SPEAKER_DIV_HIGH
    je map_divisor_21
    cmp bx, SPEAKER_DIV_CHIME
    je map_divisor_27
    cmp bx, 12174
    je map_divisor_2
    cmp bx, 10847
    je map_divisor_3
    cmp bx, 9121
    je map_divisor_3
    cmp bx, 8126
    je map_divisor_4
    cmp bx, 7241
    je map_divisor_4
    cmp bx, 6833
    je map_divisor_5
    cmp bx, 6087
    je map_divisor_5
    cmp bx, 5424
    je map_divisor_6
    cmp bx, 4560
    je map_divisor_7
    cmp bx, 4063
    je map_divisor_8
    cmp bx, 3620
    je map_divisor_8
    cmp bx, 3417
    je map_divisor_9
    cmp bx, 3044
    je map_divisor_10
    ret

map_divisor_27:
    mov al, 27
    ret
map_divisor_21:
    mov al, 21
    ret
map_divisor_16:
    mov al, 16
    ret
map_divisor_12:
    mov al, 12
    ret
map_divisor_10:
    mov al, 10
    ret
map_divisor_9:
    mov al, 9
    ret
map_divisor_8:
    mov al, 8
    ret
map_divisor_7:
    mov al, 7
    ret
map_divisor_6:
    mov al, 6
    ret
map_divisor_5:
    mov al, 5
    ret
map_divisor_4:
    mov al, 4
    ret
map_divisor_3:
    mov al, 3
    ret
map_divisor_2:
    mov al, 2
    ret

music_note_divisors dw 0
                    dw 12174
                    dw 10847
                    dw 9121
                    dw 8126
                    dw 7241
                    dw 6833
                    dw 6087
                    dw 5424
                    dw 4560
                    dw 4063
                    dw 3620
                    dw 3417
                    dw 3044

music_note_phase_steps db 0
                      db 2
                      db 3
                      db 3
                      db 4
                      db 4
                      db 5
                      db 5
                      db 6
                      db 7
                      db 8
                      db 8
                      db 9
                      db 10

; Theme tables are generated from assets\music.psd1 so content iteration does
; not require hand-editing long note lists in assembly.
include generated_music.inc

audio_backend db AUDIO_BACKEND_PCSPEAKER
audio_mode_value db AUDIO_MODE
audio_phase_accum db 0
audio_output_phase_step db 0
audio_output_divisor dw 0
audio_hw_divisor dw 0
music_phase_step db 0
music_divisor dw 0
sfx_phase_step db 0
sfx_divisor dw 0
sb16_dma_active db 0
sb16_audio_buffer db AUDIO_BLOCK_SAMPLES dup (AUDIO_SAMPLE_CENTER)
; A short rounded waveform keeps the looping-theme path less piercing than
; the earlier hard-edged square-wave approach while still staying period-lean.
sb16_waveform db 0, 6, 12, 18, 23, 28, 31, 34
              db 36, 34, 31, 28, 23, 18, 12, 6
              db 0, -6, -12, -18, -23, -28, -31, -34
              db -36, -34, -31, -28, -23, -18, -12, -6
