; Breach Economy
; --------------
; Compact live-campaign resource loop designed to fit the nearly-full 16-bit
; stage-two segment. The existing PULSE HUD is the visible economy:
;
; - starting a flame spends one pulse;
; - two kills recover one pulse;
; - four collected data shards recover one pulse;
; - any relay/key objective completion recovers one pulse;
; - taking shield damage breaks partial kill/shard recharge progress.
;
; This keeps the desired spend -> attack/route -> recover rhythm without adding
; a second HUD meter or a large response-wave runtime to stage two. Demo/replay
; input bypasses the wrapper and retains the historical deterministic path.

BREACH_KILLS_PER_RECHARGE equ 2
BREACH_DATA_PER_RECHARGE  equ 4

breach_flow_process_play_input:
IF DEBUG_LEGACY_GAMEPLAY EQ 0
    cmp byte ptr [demo_active], 0
    jne breach_flow_passthrough
    call breach_flow_sync
    call breach_flow_pre_input
    call process_play_input
    call breach_flow_post_input
    ret

breach_flow_passthrough:
ENDIF
    jmp process_play_input

breach_flow_pre_input:
    cmp byte ptr [game_state], STATE_PLAYING
    jne breach_flow_pre_done
    cmp byte ptr [pressed_c], 0
    je breach_flow_pre_done

    ; adventure_tick_timers runs before adventure_handle_flame, so timer 0 or 1
    ; can both become a real shot this frame. Larger values remain on cooldown.
    mov al, [adventure_flame_timer]
    cmp al, 1
    ja breach_flow_pre_done
    cmp byte ptr [pulse_count], 0
    jne breach_flow_spend_pulse

    mov byte ptr [pressed_c], 0
    mov al, MSG_NOPULSE
    call set_message_event
    jmp breach_flow_pre_done

breach_flow_spend_pulse:
    dec byte ptr [pulse_count]

breach_flow_pre_done:
    ret

breach_flow_post_input:
    cmp byte ptr [game_state], STATE_PLAYING
    jne breach_flow_reset_runtime

    ; A district transition or checkpoint restart can happen inside the stock
    ; input call. Resync first so counter wrap/reset never looks like progress.
    call breach_flow_sync

    mov al, [shield_count]
    cmp al, [breach_flow_last_shields]
    jb breach_flow_damage_break

    mov al, [kill_count]
    sub al, [breach_flow_last_kills]
    jz breach_flow_check_data
    add [breach_flow_kill_chain], al
    cmp byte ptr [breach_flow_kill_chain], BREACH_KILLS_PER_RECHARGE
    jb breach_flow_check_data
    sub byte ptr [breach_flow_kill_chain], BREACH_KILLS_PER_RECHARGE
    call breach_flow_recharge_with_feedback

breach_flow_check_data:
    mov al, [data_count]
    sub al, [breach_flow_last_data]
    jz breach_flow_check_objectives
    add [breach_flow_data_chain], al
    cmp byte ptr [breach_flow_data_chain], BREACH_DATA_PER_RECHARGE
    jb breach_flow_check_objectives
    sub byte ptr [breach_flow_data_chain], BREACH_DATA_PER_RECHARGE
    call breach_flow_recharge_with_feedback

breach_flow_check_objectives:
    mov al, [adventure_objectives_done]
    cmp al, [breach_flow_last_objectives]
    jbe breach_flow_capture
    ; Preserve the objective's own KEY/SPOOF message. The pulse digit changing is
    ; enough feedback here, and it avoids replacing important progression text.
    call breach_flow_recharge_silent
    jmp breach_flow_capture

breach_flow_damage_break:
    mov byte ptr [breach_flow_kill_chain], 0
    mov byte ptr [breach_flow_data_chain], 0

breach_flow_capture:
    call breach_flow_capture_state
    ret

breach_flow_reset_runtime:
    mov byte ptr [breach_flow_initialized], 0
    ret

breach_flow_sync:
    cmp byte ptr [breach_flow_initialized], 0
    je breach_flow_sync_reset
    mov al, [current_district]
    cmp al, [breach_flow_last_district]
    jne breach_flow_sync_reset
    mov al, [kill_count]
    cmp al, [breach_flow_last_kills]
    jb breach_flow_sync_reset
    mov al, [data_count]
    cmp al, [breach_flow_last_data]
    jb breach_flow_sync_reset
    mov al, [adventure_objectives_done]
    cmp al, [breach_flow_last_objectives]
    jb breach_flow_sync_reset
    ret

breach_flow_sync_reset:
    mov byte ptr [breach_flow_initialized], 1
    mov byte ptr [breach_flow_kill_chain], 0
    mov byte ptr [breach_flow_data_chain], 0
    call breach_flow_capture_state
    ret

breach_flow_capture_state:
    mov al, [current_district]
    mov [breach_flow_last_district], al
    mov al, [kill_count]
    mov [breach_flow_last_kills], al
    mov al, [data_count]
    mov [breach_flow_last_data], al
    mov al, [adventure_objectives_done]
    mov [breach_flow_last_objectives], al
    mov al, [shield_count]
    mov [breach_flow_last_shields], al
    ret

breach_flow_recharge_with_feedback:
    cmp byte ptr [pulse_count], MAX_PULSES
    jae breach_flow_recharge_feedback_done
    inc byte ptr [pulse_count]
    mov al, MSG_RECHARGE
    call set_message_event
breach_flow_recharge_feedback_done:
    ret

breach_flow_recharge_silent:
    cmp byte ptr [pulse_count], MAX_PULSES
    jae breach_flow_recharge_silent_done
    inc byte ptr [pulse_count]
breach_flow_recharge_silent_done:
    ret

breach_flow_initialized     db 0
breach_flow_kill_chain      db 0
breach_flow_data_chain      db 0
breach_flow_last_district   db 0
breach_flow_last_kills      db 0
breach_flow_last_data       db 0
breach_flow_last_objectives db 0
breach_flow_last_shields    db START_SHIELDS
