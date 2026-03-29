SPEAKER_DIV_DRY    equ 3600
SPEAKER_DIV_LOW    equ 3000
SPEAKER_DIV_WARN   equ 2400
SPEAKER_DIV_MID    equ 1800
SPEAKER_DIV_UP     equ 1400
SPEAKER_DIV_HIGH   equ 1100
SPEAKER_DIV_CHIME  equ 900

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
