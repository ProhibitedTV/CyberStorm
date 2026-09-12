; Breach Response
; ---------------
; Objective completions now provoke a compact hunter response instead of only
; changing counters. This keeps the four-district campaign's existing enemy
; vocabulary but turns relays/key progress into encounter beats.
;
; Spawn rules stay defensive: every candidate must be inside the playable map,
; on plain floor, unoccupied, and within the live-enemy cap. Response hunters
; therefore never overwrite shards, hazards, terminals, gates, or other actors.

BREACH_RESPONSE_MAX_LIVE    equ 6
BREACH_RESPONSE_FLASH_TICKS equ 45

; -----------------------------------------------------------------------------
; Public hooks used by flow.asm
; -----------------------------------------------------------------------------

breach_response_reset:
    mov byte ptr [breach_response_flash_timer], 0
    mov byte ptr [breach_response_spawned_count], 0
    ret

breach_response_tick:
    cmp byte ptr [breach_response_flash_timer], 0
    je breach_response_tick_done
    dec byte ptr [breach_response_flash_timer]

breach_response_tick_done:
    ret

breach_response_objective_advanced:
    mov byte ptr [breach_response_spawned_count], 0

    mov al, [current_district]
    cmp al, 1
    je breach_response_district_1
    cmp al, 2
    je breach_response_district_2
    cmp al, 3
    je breach_response_district_3
    jmp breach_response_district_4

; Subgrid teaches the rule gently: one pursuit hunter answers each major breach.
breach_response_district_1:
    mov al, [adventure_objectives_done]
    cmp al, 1
    ja breach_response_d1_flanker
    mov al, ENEMY_RUSHER
    call breach_response_spawn_near_player
    jmp breach_response_finish_wave

breach_response_d1_flanker:
    mov al, ENEMY_FLANKER
    call breach_response_spawn_near_player
    jmp breach_response_finish_wave

; Switchyard makes later progress produce a two-angle chase.
breach_response_district_2:
    mov al, [adventure_objectives_done]
    cmp al, 1
    jne breach_response_d2_second
    mov al, ENEMY_RUSHER
    call breach_response_spawn_near_player
    jmp breach_response_finish_wave

breach_response_d2_second:
    mov al, ENEMY_FLANKER
    call breach_response_spawn_near_player
    cmp byte ptr [adventure_objectives_done], 3
    jb breach_response_finish_wave
    mov al, ENEMY_RUSHER
    call breach_response_spawn_near_player
    jmp breach_response_finish_wave

; Foundry escalates into mixed response pressure and introduces a late Warden.
breach_response_district_3:
    mov al, [adventure_objectives_done]
    cmp al, 1
    jne breach_response_d3_second
    mov al, ENEMY_FLANKER
    call breach_response_spawn_near_player
    jmp breach_response_finish_wave

breach_response_d3_second:
    cmp al, 2
    jne breach_response_d3_third
    mov al, ENEMY_FLANKER
    call breach_response_spawn_near_player
    mov al, ENEMY_RUSHER
    call breach_response_spawn_near_player
    jmp breach_response_finish_wave

breach_response_d3_third:
    mov al, ENEMY_WARDEN
    call breach_response_spawn_near_player
    jmp breach_response_finish_wave

; Apex treats every objective as a lockdown trigger. The live cap prevents the
; finale from becoming an unreadable pile if the player rushes objectives while
; leaving the opening hunters alive.
breach_response_district_4:
    mov al, [adventure_objectives_done]
    cmp al, 1
    jne breach_response_d4_second
    mov al, ENEMY_FLANKER
    call breach_response_spawn_near_player
    mov al, ENEMY_RUSHER
    call breach_response_spawn_near_player
    jmp breach_response_finish_wave

breach_response_d4_second:
    cmp al, 2
    jne breach_response_d4_third
    mov al, ENEMY_FLANKER
    call breach_response_spawn_near_player
    mov al, ENEMY_FLANKER
    call breach_response_spawn_near_player
    jmp breach_response_finish_wave

breach_response_d4_third:
    mov al, ENEMY_WARDEN
    call breach_response_spawn_near_player
    mov al, ENEMY_FLANKER
    call breach_response_spawn_near_player

breach_response_finish_wave:
    cmp byte ptr [breach_response_spawned_count], 0
    je breach_response_wave_done

    mov byte ptr [breach_response_flash_timer], BREACH_RESPONSE_FLASH_TICKS
    call clear_enemy_pressure
    call update_enemy_pressure
    call game3d_note_pressure_change
    call game3d_start_enemy_reveal_shot

breach_response_wave_done:
    ret

; -----------------------------------------------------------------------------
; Safe local spawning
; -----------------------------------------------------------------------------

; AL = enemy kind. The routine tries a readable ring of candidate ingress tiles
; around the player, far enough away to avoid cheap contact spawns but close
; enough that the simple hunter steering can turn the response into pressure.
breach_response_spawn_near_player:
    mov [breach_response_spawn_kind], al
    call breach_response_count_live
    cmp al, BREACH_RESPONSE_MAX_LIVE
    jae breach_response_spawn_done

    mov cl, -5
    mov ch, 0
    call breach_response_try_relative
    jc breach_response_spawn_done

    mov cl, 5
    mov ch, 0
    call breach_response_try_relative
    jc breach_response_spawn_done

    mov cl, 0
    mov ch, -4
    call breach_response_try_relative
    jc breach_response_spawn_done

    mov cl, 0
    mov ch, 4
    call breach_response_try_relative
    jc breach_response_spawn_done

    mov cl, -4
    mov ch, -2
    call breach_response_try_relative
    jc breach_response_spawn_done

    mov cl, 4
    mov ch, -2
    call breach_response_try_relative
    jc breach_response_spawn_done

    mov cl, -4
    mov ch, 2
    call breach_response_try_relative
    jc breach_response_spawn_done

    mov cl, 4
    mov ch, 2
    call breach_response_try_relative
    jc breach_response_spawn_done

    ; Tight fallback ring for narrow corridors. Three tiles still gives the
    ; player reaction time at the adventure enemy-step cadence.
    mov cl, -3
    mov ch, 0
    call breach_response_try_relative
    jc breach_response_spawn_done

    mov cl, 3
    mov ch, 0
    call breach_response_try_relative
    jc breach_response_spawn_done

    mov cl, 0
    mov ch, -3
    call breach_response_try_relative
    jc breach_response_spawn_done

    mov cl, 0
    mov ch, 3
    call breach_response_try_relative

breach_response_spawn_done:
    ret

; CL/CH = signed x/y offset from the player's current tile.
; Carry set when a hunter was spawned.
breach_response_try_relative:
    push ax
    push bx
    push cx
    push dx
    push si
    push di

    mov bl, [player_x]
    add bl, cl
    mov bh, [player_y]
    add bh, ch

    cmp bl, PLAY_MIN_X
    jb breach_response_candidate_fail
    cmp bl, PLAY_MAX_X
    ja breach_response_candidate_fail
    cmp bh, PLAY_MIN_Y
    jb breach_response_candidate_fail
    cmp bh, PLAY_MAX_Y
    ja breach_response_candidate_fail

    call get_tile
    cmp al, TILE_FLOOR
    jne breach_response_candidate_fail

    mov di, 0FFFFh
    call find_enemy_at
    jc breach_response_candidate_fail

    call breach_response_find_free_slot
    jnc breach_response_candidate_fail

    mov byte ptr [si + ENEMY_ALIVE], 1
    mov [si + ENEMY_X], bl
    mov [si + ENEMY_Y], bh
    mov al, [breach_response_spawn_kind]
    mov [si + ENEMY_KIND], al
    call set_effect_focus_tile
    inc byte ptr [breach_response_spawned_count]
    stc
    jmp breach_response_candidate_done

breach_response_candidate_fail:
    clc

breach_response_candidate_done:
    pop di
    pop si
    pop dx
    pop cx
    pop bx
    pop ax
    ret

breach_response_find_free_slot:
    push cx
    mov si, offset enemies
    mov cx, MAX_ENEMIES

breach_response_find_slot_loop:
    cmp byte ptr [si + ENEMY_ALIVE], 0
    je breach_response_find_slot_success
    add si, ENEMY_SIZE
    loop breach_response_find_slot_loop
    pop cx
    clc
    ret

breach_response_find_slot_success:
    pop cx
    stc
    ret

breach_response_count_live:
    push cx
    push si
    xor ax, ax
    mov si, offset enemies
    mov cx, MAX_ENEMIES

breach_response_count_loop:
    cmp byte ptr [si + ENEMY_ALIVE], 0
    je breach_response_count_next
    inc al

breach_response_count_next:
    add si, ENEMY_SIZE
    loop breach_response_count_loop
    pop si
    pop cx
    ret

; -----------------------------------------------------------------------------
; Short-lived response telegraph
; -----------------------------------------------------------------------------

draw_breach_response_overlay:
    cmp byte ptr [breach_response_flash_timer], 0
    je breach_response_overlay_done

    push ax
    push bx
    push cx
    push dx
    push si
    push bp

    mov bx, 238
    mov dx, 27
    mov cx, 68
    mov bp, 11
    mov al, PAL_PANEL
    call fill_rect

    mov bx, 242
    mov dx, 30
    mov si, offset breach_response_text
    mov ah, PAL_AMBER
    test byte ptr [anim_phase], 1
    jz breach_response_overlay_label_ready
    mov ah, PAL_RED2

breach_response_overlay_label_ready:
    call draw_text_small

    mov al, [breach_response_spawned_count]
    mov bx, 294
    mov dx, 30
    mov ah, PAL_WHITE
    call draw_digit_small

    pop bp
    pop si
    pop dx
    pop cx
    pop bx
    pop ax

breach_response_overlay_done:
    ret

; -----------------------------------------------------------------------------
; Local state
; -----------------------------------------------------------------------------

breach_response_flash_timer   db 0
breach_response_spawn_kind    db ENEMY_RUSHER
breach_response_spawned_count db 0
breach_response_text          db 'TRACE', 0
