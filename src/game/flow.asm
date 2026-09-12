; Breach Flow
; -----------
; A compact live-campaign mastery layer that binds the existing verbs together:
; charge/flame kills, gems, relays, keys, shield damage, score, and pulse reserve.
;
; Design rules:
; - Adventure flame consumes one pulse when it actually starts.
; - Kills build flow quickly; gems/objectives build it slowly.
; - Taking damage breaks flow.
; - Flow decays after a district-specific inactivity window.
; - Sustained flow grants a small kill-score bonus.
; - Max flow converts into one pulse recharge, then falls back to the bonus tier.
; - Demo/replay runs bypass this layer so existing deterministic oracle scripts
;   continue to exercise the historical reference path unchanged.

BREACH_FLOW_MAX                 equ 8
BREACH_FLOW_KILL_GAIN           equ 3
BREACH_FLOW_PROGRESS_GAIN       equ 1
BREACH_FLOW_BONUS_THRESHOLD     equ 4
BREACH_FLOW_KILL_BONUS          equ 20
BREACH_FLOW_RECHARGE_THRESHOLD  equ 8
BREACH_FLOW_RECHARGE_COST       equ 4
BREACH_FLOW_DECAY_DISTRICT_1    equ 120
BREACH_FLOW_DECAY_DISTRICT_2    equ 90
BREACH_FLOW_DECAY_DISTRICT_3    equ 75
BREACH_FLOW_DECAY_DISTRICT_4    equ 60
BREACH_FLOW_DECAY_STEP          equ 30
BREACH_FLOW_FLASH_TICKS         equ 8
BREACH_FLOW_FLASH_NONE          equ 0
BREACH_FLOW_FLASH_BREAK         equ 1
BREACH_FLOW_FLASH_RECHARGE      equ 2
BREACH_FLOW_FLASH_DRY           equ 3

; -----------------------------------------------------------------------------
; Gameplay hook
; -----------------------------------------------------------------------------

breach_flow_process_play_input:
IF DEBUG_LEGACY_GAMEPLAY EQ 0
    cmp byte ptr [demo_active], 0
    jne breach_flow_input_passthrough
    call breach_flow_pre_input
    call process_play_input
    call breach_flow_post_input
    ret

breach_flow_input_passthrough:
ENDIF
    jmp process_play_input

breach_flow_pre_input:
    cmp byte ptr [game_state], STATE_PLAYING
    jne breach_flow_pre_done

    call breach_flow_sync_run_state
    call breach_flow_try_recharge

    ; Flame is now tied to the pulse reserve shown in the adventure HUD. Only
    ; consume a pulse when the flame timer is idle and this press can actually
    ; start a new flame action.
    cmp byte ptr [pressed_c], 0
    je breach_flow_pre_done
    cmp byte ptr [adventure_flame_timer], 0
    jne breach_flow_pre_done
    cmp byte ptr [pulse_count], 0
    jne breach_flow_spend_pulse

    mov byte ptr [pressed_c], 0
    mov byte ptr [breach_flow_flash_mode], BREACH_FLOW_FLASH_DRY
    mov byte ptr [breach_flow_flash_timer], BREACH_FLOW_FLASH_TICKS
    mov al, MSG_NOPULSE
    call set_message_event
    jmp breach_flow_pre_done

breach_flow_spend_pulse:
    dec byte ptr [pulse_count]

breach_flow_pre_done:
    ret

breach_flow_post_input:
    cmp byte ptr [game_state], STATE_PLAYING
    jne breach_flow_post_not_playing

    ; Restart/sector transitions can happen inside the stock input routine, so
    ; synchronize again before computing deltas.
    call breach_flow_sync_run_state
    mov byte ptr [breach_flow_progressed], 0

    cmp byte ptr [breach_flow_flash_timer], 0
    je breach_flow_flash_tick_done
    dec byte ptr [breach_flow_flash_timer]
    jnz breach_flow_flash_tick_done
    mov byte ptr [breach_flow_flash_mode], BREACH_FLOW_FLASH_NONE

breach_flow_flash_tick_done:
    call breach_flow_credit_kills
    call breach_flow_credit_data
    call breach_flow_credit_objectives

    ; Damage wins over progress on the same frame: the player may still keep
    ; score from a kill, but the momentum chain itself is broken.
    mov al, [shield_count]
    cmp al, [breach_flow_last_shields]
    jae breach_flow_no_damage

    mov byte ptr [breach_flow_value], 0
    mov byte ptr [breach_flow_decay_timer], 0
    mov byte ptr [breach_flow_flash_mode], BREACH_FLOW_FLASH_BREAK
    mov byte ptr [breach_flow_flash_timer], BREACH_FLOW_FLASH_TICKS
    jmp breach_flow_post_track

breach_flow_no_damage:
    cmp byte ptr [breach_flow_progressed], 0
    je breach_flow_post_idle
    call breach_flow_arm_decay
    call breach_flow_try_recharge
    jmp breach_flow_post_track

breach_flow_post_idle:
    call breach_flow_try_recharge
    call breach_flow_decay

breach_flow_post_track:
    call breach_flow_capture_runtime_state
    ret

breach_flow_post_not_playing:
    mov byte ptr [breach_flow_initialized], 0
    ret

; -----------------------------------------------------------------------------
; Flow accounting
; -----------------------------------------------------------------------------

breach_flow_sync_run_state:
    cmp byte ptr [breach_flow_initialized], 0
    je breach_flow_sync_reset

    mov al, [current_district]
    cmp al, [breach_flow_last_district]
    jne breach_flow_sync_reset

    ; Same-district checkpoint restarts reset local progress counters. Treat any
    ; backwards jump as a fresh chain rather than a huge unsigned delta.
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
    mov byte ptr [breach_flow_value], 0
    mov byte ptr [breach_flow_decay_timer], 0
    mov byte ptr [breach_flow_flash_timer], 0
    mov byte ptr [breach_flow_flash_mode], BREACH_FLOW_FLASH_NONE
    call breach_flow_capture_runtime_state
    ret

breach_flow_capture_runtime_state:
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

breach_flow_credit_kills:
    mov al, [kill_count]
    sub al, [breach_flow_last_kills]
    jz breach_flow_credit_kills_done

    mov dl, al
    mov bl, BREACH_FLOW_KILL_GAIN
    mul bl
    call breach_flow_add_al
    mov byte ptr [breach_flow_progressed], 1

    ; Once the player reaches the bonus tier, every kill in this frame adds a
    ; compact mastery bonus. Core survival scoring remains dominant.
    cmp byte ptr [breach_flow_value], BREACH_FLOW_BONUS_THRESHOLD
    jb breach_flow_credit_kills_done
    mov al, dl
    mov bl, BREACH_FLOW_KILL_BONUS
    mul bl
    call award_score_ax

breach_flow_credit_kills_done:
    ret

breach_flow_credit_data:
    mov al, [data_count]
    sub al, [breach_flow_last_data]
    jz breach_flow_credit_data_done
    mov bl, BREACH_FLOW_PROGRESS_GAIN
    mul bl
    call breach_flow_add_al
    mov byte ptr [breach_flow_progressed], 1

breach_flow_credit_data_done:
    ret

breach_flow_credit_objectives:
    mov al, [adventure_objectives_done]
    sub al, [breach_flow_last_objectives]
    jz breach_flow_credit_objectives_done
    mov bl, BREACH_FLOW_PROGRESS_GAIN
    mul bl
    call breach_flow_add_al
    mov byte ptr [breach_flow_progressed], 1

breach_flow_credit_objectives_done:
    ret

breach_flow_add_al:
    add byte ptr [breach_flow_value], al
    cmp byte ptr [breach_flow_value], BREACH_FLOW_MAX
    jbe breach_flow_add_done
    mov byte ptr [breach_flow_value], BREACH_FLOW_MAX

breach_flow_add_done:
    ret

breach_flow_try_recharge:
    cmp byte ptr [breach_flow_value], BREACH_FLOW_RECHARGE_THRESHOLD
    jb breach_flow_recharge_done
    cmp byte ptr [pulse_count], MAX_PULSES
    jae breach_flow_recharge_done

    inc byte ptr [pulse_count]
    sub byte ptr [breach_flow_value], BREACH_FLOW_RECHARGE_COST
    mov byte ptr [breach_flow_flash_mode], BREACH_FLOW_FLASH_RECHARGE
    mov byte ptr [breach_flow_flash_timer], BREACH_FLOW_FLASH_TICKS
    mov al, MSG_RECHARGE
    call set_message_event

breach_flow_recharge_done:
    ret

breach_flow_arm_decay:
    mov al, BREACH_FLOW_DECAY_DISTRICT_1
    cmp byte ptr [current_district], 2
    jb breach_flow_arm_decay_store
    mov al, BREACH_FLOW_DECAY_DISTRICT_2
    cmp byte ptr [current_district], 3
    jb breach_flow_arm_decay_store
    mov al, BREACH_FLOW_DECAY_DISTRICT_3
    cmp byte ptr [current_district], 4
    jb breach_flow_arm_decay_store
    mov al, BREACH_FLOW_DECAY_DISTRICT_4

breach_flow_arm_decay_store:
    mov [breach_flow_decay_timer], al
    ret

breach_flow_decay:
    cmp byte ptr [breach_flow_value], 0
    je breach_flow_decay_done
    cmp byte ptr [breach_flow_decay_timer], 0
    je breach_flow_decay_now
    dec byte ptr [breach_flow_decay_timer]
    ret

breach_flow_decay_now:
    dec byte ptr [breach_flow_value]
    cmp byte ptr [breach_flow_value], 0
    je breach_flow_decay_done
    mov byte ptr [breach_flow_decay_timer], BREACH_FLOW_DECAY_STEP

breach_flow_decay_done:
    ret

; -----------------------------------------------------------------------------
; Rendering hook
; -----------------------------------------------------------------------------

breach_flow_render_game_screen:
    call render_game_screen
IF DEBUG_LEGACY_GAMEPLAY EQ 0
    cmp byte ptr [game_state], STATE_PLAYING
    jne breach_flow_render_done
    cmp byte ptr [demo_active], 0
    jne breach_flow_render_done

    ; Render helpers are allowed to borrow DS/ES. Reassert the stage-two tiny
    ; model contracts before drawing the post-pass overlay.
    push cs
    pop ds
    mov ax, BACKBUFFER_SEG
    mov es, ax

    call breach_flow_sync_run_state
    call draw_breach_flow_overlay
breach_flow_render_done:
ENDIF
    ret

draw_breach_flow_overlay:
    push ax
    push bx
    push cx
    push dx
    push si
    push di
    push bp

    ; A small diegetic meter sits inside the upper-left of the gameplay view so
    ; it does not displace the existing realm/objective HUD.
    mov bx, 12
    mov dx, 27
    mov cx, 76
    mov bp, 11
    mov al, PAL_PANEL
    call fill_rect

    mov bx, 15
    mov dx, 30
    mov si, offset breach_flow_text
    call breach_flow_get_color
    mov ah, al
    call draw_text_small

    mov di, 1
    mov bx, 42
    call draw_breach_flow_pip
    mov di, 2
    mov bx, 47
    call draw_breach_flow_pip
    mov di, 3
    mov bx, 52
    call draw_breach_flow_pip
    mov di, 4
    mov bx, 57
    call draw_breach_flow_pip
    mov di, 5
    mov bx, 62
    call draw_breach_flow_pip
    mov di, 6
    mov bx, 67
    call draw_breach_flow_pip
    mov di, 7
    mov bx, 72
    call draw_breach_flow_pip
    mov di, 8
    mov bx, 77
    call draw_breach_flow_pip

    pop bp
    pop di
    pop si
    pop dx
    pop cx
    pop bx
    pop ax
    ret

draw_breach_flow_pip:
    push ax
    push cx
    push dx
    push bp

    xor ax, ax
    mov al, [breach_flow_value]
    cmp ax, di
    jb breach_flow_pip_inactive
    call breach_flow_get_color
    jmp breach_flow_pip_color_ready

breach_flow_pip_inactive:
    mov al, PAL_PANEL2

breach_flow_pip_color_ready:
    mov dx, 31
    mov cx, 4
    mov bp, 4
    call fill_rect

    pop bp
    pop dx
    pop cx
    pop ax
    ret

breach_flow_get_color:
    cmp byte ptr [breach_flow_flash_timer], 0
    je breach_flow_color_tier
    cmp byte ptr [breach_flow_flash_mode], BREACH_FLOW_FLASH_BREAK
    je breach_flow_color_red
    cmp byte ptr [breach_flow_flash_mode], BREACH_FLOW_FLASH_DRY
    je breach_flow_color_red
    cmp byte ptr [breach_flow_flash_mode], BREACH_FLOW_FLASH_RECHARGE
    je breach_flow_color_white

breach_flow_color_tier:
    cmp byte ptr [breach_flow_value], BREACH_FLOW_BONUS_THRESHOLD
    jb breach_flow_color_cyan
    cmp byte ptr [breach_flow_value], BREACH_FLOW_MAX
    jb breach_flow_color_amber
    test byte ptr [anim_phase], 1
    jz breach_flow_color_amber

breach_flow_color_white:
    mov al, PAL_WHITE
    ret

breach_flow_color_red:
    mov al, PAL_RED2
    ret

breach_flow_color_amber:
    mov al, PAL_AMBER
    ret

breach_flow_color_cyan:
    mov al, PAL_CYAN2
    ret

; -----------------------------------------------------------------------------
; Local state
; -----------------------------------------------------------------------------

breach_flow_initialized     db 0
breach_flow_value           db 0
breach_flow_decay_timer     db 0
breach_flow_flash_timer     db 0
breach_flow_flash_mode      db BREACH_FLOW_FLASH_NONE
breach_flow_progressed      db 0
breach_flow_last_district   db 0
breach_flow_last_kills      db 0
breach_flow_last_data       db 0
breach_flow_last_objectives db 0
breach_flow_last_shields    db START_SHIELDS
breach_flow_text            db 'FLOW', 0
