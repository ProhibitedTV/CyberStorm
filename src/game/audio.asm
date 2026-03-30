SPEAKER_DIV_DRY    equ 3600
SPEAKER_DIV_LOW    equ 3000
SPEAKER_DIV_WARN   equ 2400
SPEAKER_DIV_MID    equ 1800
SPEAKER_DIV_UP     equ 1400
SPEAKER_DIV_HIGH   equ 1100
SPEAKER_DIV_CHIME  equ 900

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
AUDIO_BLOCK_SAMPLES    equ 611
AUDIO_SAMPLE_CENTER    equ 128
AUDIO_SAMPLE_AMPLITUDE equ 80

MUSIC_THEME_SPLASH equ 0
MUSIC_THEME_TITLE  equ 1
MUSIC_THEME_RUN    equ 2
MUSIC_THEME_WIN    equ 3
MUSIC_THEME_LOSE   equ 4
MUSIC_THEME_NONE   equ 0FFh

; Music note ids index music_note_divisors. Themes are 2-byte cells:
;   <note id>, <duration in BIOS ticks>
; NOTE_REST mutes the speaker for that duration.
; MUSIC_NOTE_LOOP rewinds to the current theme start and keeps looping.
; The PC speaker is single-voice, so active SFX always own the channel. While a
; one-shot SFX is active, theme timing pauses and resumes on the same note.
MUSIC_NOTE_REST equ 0
MUSIC_NOTE_A3   equ 1
MUSIC_NOTE_C4   equ 2
MUSIC_NOTE_D4   equ 3
MUSIC_NOTE_E4   equ 4
MUSIC_NOTE_G4   equ 5
MUSIC_NOTE_A4   equ 6
MUSIC_NOTE_B4   equ 7
MUSIC_NOTE_C5   equ 8
MUSIC_NOTE_D5   equ 9
MUSIC_NOTE_E5   equ 10
MUSIC_NOTE_G5   equ 11
MUSIC_NOTE_LOOP equ 0FFh

init_audio:
    mov byte ptr [audio_backend], AUDIO_BACKEND_PCSPEAKER
    mov byte ptr [audio_half_period], 0
    mov byte ptr [audio_phase_count], 1
    mov byte ptr [audio_wave_high], 1
    mov byte ptr [sb16_dma_active], 0
    call init_sb16_backend
    call stop_sfx
    mov byte ptr [music_theme], MUSIC_THEME_NONE
    mov byte ptr [music_ticks], 0
    mov byte ptr [music_note], MUSIC_NOTE_REST
    mov word ptr [music_ptr], 0
    ret

update_audio:
    call sync_music_theme
    cmp byte ptr [sound_timer], 0
    jne update_audio_sfx
    call update_music
    jmp update_audio_commit

update_audio_sfx:
    call update_sfx

update_audio_commit:
    call commit_audio_output
    ret

sync_music_theme:
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
    ret

stop_music:
    mov byte ptr [music_theme], MUSIC_THEME_NONE
    mov byte ptr [music_ticks], 0
    mov byte ptr [music_note], MUSIC_NOTE_REST
    mov word ptr [music_ptr], 0
    call stop_speaker_output
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

update_music:
    push ax
    cmp byte ptr [music_theme], MUSIC_THEME_NONE
    jne update_music_check
    call stop_speaker_output
    jmp update_music_done

update_music_check:
    cmp byte ptr [music_ticks], 0
    jne update_music_play
    call load_music_event

update_music_play:
    cmp byte ptr [music_ticks], 0
    je update_music_done
    cmp byte ptr [music_note], MUSIC_NOTE_REST
    je update_music_rest
    call play_music_note
    jmp update_music_tick

update_music_rest:
    call stop_speaker_output

update_music_tick:
    dec byte ptr [music_ticks]

update_music_done:
    pop ax
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

play_music_note:
    push ax
    push bx
    push si
    mov al, [music_note]
    xor ah, ah
    shl ax, 1
    mov si, ax
    mov bx, word ptr [music_note_divisors + si]
    call speaker_play_divisor
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

start_sfx_done:
    pop bx
    pop ax
    ret

update_sfx:
    push ax
    push bx
    cmp byte ptr [sound_timer], 0
    jne update_sfx_active
    call stop_speaker_output
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
    call speaker_play_divisor
    inc byte ptr [sound_phase]
    dec byte ptr [sound_timer]
    jne update_sfx_done
    call stop_sfx

update_sfx_done:
    pop bx
    pop ax
    ret

speaker_play_divisor:
    push ax
    push dx
    cmp byte ptr [audio_backend], AUDIO_BACKEND_SB16
    je speaker_route_sb16
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
    jmp speaker_play_done

speaker_route_sb16:
    call map_divisor_to_half_period
    mov [audio_half_period], al
    cmp al, 0
    jne speaker_sb16_active
    mov byte ptr [audio_phase_count], 1
    mov byte ptr [audio_wave_high], 1
    jmp speaker_play_done

speaker_sb16_active:
    mov [audio_phase_count], al
    mov byte ptr [audio_wave_high], 1

speaker_play_done:
    pop dx
    pop ax
    ret

stop_speaker_output:
    cmp byte ptr [audio_backend], AUDIO_BACKEND_SB16
    jne stop_pc_speaker_output
    mov byte ptr [audio_half_period], 0
    mov byte ptr [audio_phase_count], 1
    mov byte ptr [audio_wave_high], 1
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
    call stop_speaker_output
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

commit_audio_output:
    cmp byte ptr [audio_backend], AUDIO_BACKEND_SB16
    jne commit_audio_done
    call fill_sb16_buffer

commit_audio_done:
    ret

fill_sb16_buffer:
    push ax
    push bx
    push cx
    push dx
    push di
    mov di, offset sb16_audio_buffer
    mov cx, AUDIO_BLOCK_SAMPLES
    mov bl, [audio_half_period]
    ; The SB16 stream loops this block continuously. Keeping the block length
    ; near one BIOS tick makes note changes land more cleanly on the game's
    ; only global clock while still staying simple and IRQ-free.
    cmp bl, 0
    jne fill_sb16_tone
    mov al, AUDIO_SAMPLE_CENTER
    rep stosb
    jmp fill_sb16_done

fill_sb16_tone:
    mov dl, [audio_phase_count]
    mov ah, [audio_wave_high]

fill_sb16_loop:
    cmp ah, 0
    je fill_sb16_low
    mov al, AUDIO_SAMPLE_CENTER + AUDIO_SAMPLE_AMPLITUDE
    jmp fill_sb16_store

fill_sb16_low:
    mov al, AUDIO_SAMPLE_CENTER - AUDIO_SAMPLE_AMPLITUDE

fill_sb16_store:
    stosb
    dec dl
    jne fill_sb16_next
    mov dl, bl
    xor ah, 1

fill_sb16_next:
    loop fill_sb16_loop
    mov [audio_phase_count], dl
    mov [audio_wave_high], ah

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

map_divisor_to_half_period:
    mov al, 0
    cmp bx, SPEAKER_DIV_DRY
    je map_divisor_17
    cmp bx, SPEAKER_DIV_LOW
    je map_divisor_14
    cmp bx, SPEAKER_DIV_WARN
    je map_divisor_11
    cmp bx, SPEAKER_DIV_MID
    je map_divisor_8
    cmp bx, SPEAKER_DIV_UP
    je map_divisor_6
    cmp bx, SPEAKER_DIV_HIGH
    je map_divisor_5
    cmp bx, SPEAKER_DIV_CHIME
    je map_divisor_4
    cmp bx, 5424
    je map_divisor_25
    cmp bx, 4560
    je map_divisor_21
    cmp bx, 4063
    je map_divisor_19
    cmp bx, 3620
    je map_divisor_17
    cmp bx, 3044
    je map_divisor_14
    cmp bx, 2712
    je map_divisor_13
    cmp bx, 2416
    je map_divisor_11
    cmp bx, 2280
    je map_divisor_10
    cmp bx, 2032
    je map_divisor_9
    cmp bx, 1810
    je map_divisor_8
    cmp bx, 1522
    je map_divisor_7
    ret

map_divisor_25:
    mov al, 25
    ret
map_divisor_21:
    mov al, 21
    ret
map_divisor_19:
    mov al, 19
    ret
map_divisor_17:
    mov al, 17
    ret
map_divisor_14:
    mov al, 14
    ret
map_divisor_13:
    mov al, 13
    ret
map_divisor_11:
    mov al, 11
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

music_note_divisors dw 0
                    dw 5424
                    dw 4560
                    dw 4063
                    dw 3620
                    dw 3044
                    dw 2712
                    dw 2416
                    dw 2280
                    dw 2032
                    dw 1810
                    dw 1522

; Theme tables are generated from assets\music.psd1 so content iteration does
; not require hand-editing long note lists in assembly.
include generated_music.inc

audio_backend db AUDIO_BACKEND_PCSPEAKER
audio_half_period db 0
audio_phase_count db 1
audio_wave_high db 1
sb16_dma_active db 0
sb16_audio_buffer db AUDIO_BLOCK_SAMPLES dup (AUDIO_SAMPLE_CENTER)
