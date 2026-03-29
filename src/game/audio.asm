SPEAKER_DIV_DRY    equ 3600
SPEAKER_DIV_LOW    equ 3000
SPEAKER_DIV_WARN   equ 2400
SPEAKER_DIV_MID    equ 1800
SPEAKER_DIV_UP     equ 1400
SPEAKER_DIV_HIGH   equ 1100
SPEAKER_DIV_CHIME  equ 900

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
    ret

update_audio_sfx:
    call update_sfx
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

stop_speaker_output:
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
