set_message_event:
    push ax
    mov [message_id], al
    call get_message_feedback_ticks
    mov [feedback_timer], al
    pop ax
    call play_message_sfx
    ret

get_message_feedback_ticks:
    cmp al, MSG_SECTOR
    je feedback_major
    cmp al, MSG_BLOCK
    je feedback_minor
    cmp al, MSG_NOPULSE
    je feedback_minor
    cmp al, MSG_GATE
    je feedback_major
    cmp al, MSG_HIT
    je feedback_major
    cmp al, MSG_KILL
    je feedback_major
    cmp al, MSG_SURGE
    je feedback_major
    cmp al, MSG_TRAP
    je feedback_major
    cmp al, MSG_RECHARGE
    je feedback_major
    cmp al, MSG_SPOOF
    je feedback_major
    cmp al, MSG_KEY
    je feedback_major
    mov al, FEEDBACK_TICKS_STANDARD
    ret

feedback_minor:
    mov al, FEEDBACK_TICKS_MINOR
    ret

feedback_major:
    mov al, FEEDBACK_TICKS_MAJOR
    ret

play_message_sfx:
    cmp al, MSG_SECTOR
    je play_message_sfx_sector
    cmp al, MSG_BLOCK
    je play_message_sfx_block
    cmp al, MSG_SHARD
    je play_message_sfx_shard
    cmp al, MSG_GATE
    je play_message_sfx_gate
    cmp al, MSG_HIT
    je play_message_sfx_hit
    cmp al, MSG_KILL
    je play_message_sfx_kill
    cmp al, MSG_PULSE
    je play_message_sfx_pulse
    cmp al, MSG_NOPULSE
    je play_message_sfx_dry
    cmp al, MSG_SURGE
    je play_message_sfx_surge
    cmp al, MSG_TRAP
    je play_message_sfx_trap
    cmp al, MSG_RECHARGE
    je play_message_sfx_recharge
    cmp al, MSG_SPOOF
    je play_message_sfx_recharge
    cmp al, MSG_KEY
    je play_message_sfx_recharge
    ret

play_message_sfx_sector:
    mov al, SFX_SECTOR
    jmp start_sfx
play_message_sfx_block:
    mov al, SFX_BLOCK
    jmp start_sfx
play_message_sfx_shard:
    mov al, SFX_SHARD
    jmp start_sfx
play_message_sfx_gate:
    mov al, SFX_GATE
    jmp start_sfx
play_message_sfx_hit:
    mov al, SFX_HIT
    jmp start_sfx
play_message_sfx_kill:
    mov al, SFX_KILL
    jmp start_sfx
play_message_sfx_pulse:
    mov al, SFX_PULSE
    jmp start_sfx
play_message_sfx_dry:
    mov al, SFX_DRY
    jmp start_sfx
play_message_sfx_surge:
    mov al, SFX_SURGE
    jmp start_sfx
play_message_sfx_trap:
    mov al, SFX_TRAP
    jmp start_sfx
play_message_sfx_recharge:
    mov al, SFX_RECHARGE
    jmp start_sfx

update_runtime_feedback:
    push ax
    call game3d_update_shot_state
    mov al, [game_state]
    cmp al, [last_game_state]
    je runtime_state_stable
    mov [last_game_state], al
    mov byte ptr [state_ticks], 0
    call handle_state_change_feedback

runtime_state_stable:
    cmp byte ptr [state_ticks], 255
    je runtime_tick_done
    inc byte ptr [state_ticks]

runtime_tick_done:
    cmp byte ptr [feedback_timer], 0
    je runtime_feedback_done
    dec byte ptr [feedback_timer]

runtime_feedback_done:
    call update_audio
    pop ax
    ret

handle_state_change_feedback:
    cmp al, STATE_WIN
    je state_change_win
    cmp al, STATE_LOSE
    je state_change_lose
    cmp al, STATE_SPLASH
    je state_change_quiet
    cmp al, STATE_TITLE
    je state_change_quiet
    ret

state_change_win:
    mov byte ptr [feedback_timer], FEEDBACK_TICKS_MAJOR
    mov al, SFX_WIN
    call start_sfx
    ret

state_change_lose:
    mov byte ptr [feedback_timer], FEEDBACK_TICKS_MAJOR
    mov al, SFX_LOSE
    call start_sfx
    ret

state_change_quiet:
    call stop_sfx
    ret
