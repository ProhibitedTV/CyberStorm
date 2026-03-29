render_game_screen:
    call draw_game_panels
    call render_game_status
    call render_map
    ; Ambient overlays sit between tiles and entities so the sectors feel
    ; alive without drawing over hunters, the runner, or threat telegraphs.
    call draw_sector_ambient
    call render_enemies
    call render_player
    call render_game_effects
IF DEBUG_OVERLAY
    call render_debug_overlay
ENDIF
    ret

draw_game_panels:
    mov bx, 12
    mov dx, 10
    mov cx, 296
    mov bp, 18
    mov al, PAL_PANEL
    call fill_rect

    mov bx, 12
    mov dx, 36
    mov cx, 232
    mov bp, 128
    mov al, PAL_PANEL
    call fill_rect

    mov bx, 252
    mov dx, 36
    mov cx, 56
    mov bp, 128
    mov al, PAL_PANEL
    call fill_rect

    mov bx, 12
    mov dx, 170
    mov cx, 296
    mov bp, 20
    mov al, PAL_PANEL
    call fill_rect

    call get_sector_accent_color
    mov bx, 10
    mov dx, 8
    mov cx, 300
    mov bp, 22
    call draw_rect_outline

    mov bx, 10
    mov dx, 34
    mov cx, 236
    mov bp, 132
    call draw_rect_outline

    mov bx, 250
    mov dx, 34
    mov cx, 60
    mov bp, 132
    call draw_rect_outline

    mov bx, 10
    mov dx, 168
    mov cx, 300
    mov bp, 24
    call draw_rect_outline

    mov bx, 14
    mov dx, 29
    mov cx, 292
    mov bp, 1
    call fill_rect

    mov dx, 169
    call fill_rect
    ret

render_game_status:
    mov bx, 18
    mov dx, 15
    mov si, offset score_text
    mov ah, PAL_WHITE
    call draw_text_small

    mov ax, [score_total]
    mov bx, 54
    mov dx, 15
    mov cl, PAL_AMBER
    call draw_word_decimal_small

    mov bx, 96
    mov dx, 15
    call get_sector_name_ptr
    call get_sector_title_color
    mov ah, al
    call draw_text_small

    mov bx, 174
    mov dx, 15
    mov si, offset data_text
    mov ah, PAL_WHITE
    call draw_text_small

    mov al, [data_count]
    mov ah, PAL_AMBER
    mov bx, 200
    mov dx, 15
    call draw_digit_small

    mov bx, 214
    mov dx, 15
    mov si, offset kills_text
    mov ah, PAL_WHITE
    call draw_text_small

    mov al, [kill_count]
    mov ah, PAL_AMBER
    mov bx, 248
    mov dx, 15
    call draw_two_digit_small

    call draw_spoof_status
    call draw_demo_status

    mov bx, 258
    mov dx, 46
    mov si, offset shield_text
    mov ah, PAL_WHITE
    call draw_text_small

    mov bx, 258
    mov dx, 88
    mov si, offset pulse_text
    mov ah, PAL_WHITE
    call draw_text_small

    mov bx, 258
    mov dx, 130
    mov si, offset gate_text
    mov ah, PAL_WHITE
    call draw_text_small

    call draw_shield_meter
    call draw_pulse_meter
    call draw_gate_meter

    call draw_message_banner
    call get_message_text_ptr
    mov bx, 18
    mov dx, 175
    call get_message_text_color
    mov ah, al
    call draw_text_small

    mov bx, 18
    mov dx, 184
    mov si, offset controls_text
    call get_sector_accent_color
    mov ah, al
    call draw_text_small
    ret

draw_spoof_status:
    mov bx, 258
    mov dx, 15
    mov si, offset spoof_text
    cmp byte ptr [spoof_timer], 0
    je spoof_status_idle
    test byte ptr [anim_phase], 1
    jz spoof_status_live_base
    mov ah, PAL_WHITE
    jmp spoof_status_text_ready

spoof_status_live_base:
    mov ah, PAL_CYAN2
    jmp spoof_status_text_ready

spoof_status_idle:
    mov ah, PAL_PANEL2

spoof_status_text_ready:
    call draw_text_small
    mov al, [spoof_timer]
    cmp al, 0
    jne spoof_status_digit_live
    mov ah, PAL_PANEL2
    jmp spoof_status_digit_ready

spoof_status_digit_live:
    mov ah, PAL_WHITE

spoof_status_digit_ready:
    mov bx, 294
    mov dx, 15
    call draw_digit_small
    ret

draw_demo_status:
    cmp byte ptr [demo_active], 0
    je demo_status_done
    mov bx, 258
    mov dx, 36
    mov si, offset demo_text
    test byte ptr [anim_phase], 1
    jz demo_status_base
    mov ah, PAL_WHITE
    jmp demo_status_draw

demo_status_base:
    mov ah, PAL_CYAN2

demo_status_draw:
    call draw_text_small

demo_status_done:
    ret

get_sector_name_ptr:
    xor ax, ax
    mov al, [sector_num]
    dec al
    xor ah, ah
    shl ax, 1
    mov bx, ax
    mov si, word ptr [sector_name_table + bx]
    ret

get_sector_intro_ptr:
    xor ax, ax
    mov al, [sector_num]
    dec al
    xor ah, ah
    shl ax, 1
    mov bx, ax
    mov si, word ptr [sector_intro_table + bx]
    ret

get_message_text_ptr:
    mov al, [message_id]
    cmp al, MSG_SECTOR
    je message_text_ptr_sector
    xor ah, ah
    shl ax, 1
    mov bx, ax
    mov si, word ptr [message_table + bx]
    ret

message_text_ptr_sector:
    call get_sector_intro_ptr
    ret

get_sector_accent_color:
    mov al, [sector_num]
    cmp al, 2
    je sector_accent_furnace
    cmp al, 3
    je sector_accent_lock
    mov al, PAL_CYAN
    ret

sector_accent_furnace:
    mov al, PAL_AMBER
    ret

sector_accent_lock:
    mov al, PAL_RED2
    ret

get_sector_title_color:
    mov al, [sector_num]
    cmp al, 2
    je sector_title_furnace
    cmp al, 3
    je sector_title_lock
    mov al, PAL_CYAN2
    ret

sector_title_furnace:
    mov al, PAL_AMBER
    ret

sector_title_lock:
    mov al, PAL_WHITE
    ret

draw_shield_meter:
    mov bx, 258
    mov dx, 58
    mov cx, 5
    xor di, di

shield_meter_loop:
    push bx
    push dx
    push cx
    mov cx, 12
    mov bp, 8
    mov al, PAL_PANEL2
    call fill_rect
    pop cx
    pop dx
    pop bx
    xor ax, ax
    mov al, [shield_count]
    cmp di, ax
    jae shield_meter_next
    push bx
    push dx
    mov cx, 12
    mov bp, 8
    cmp byte ptr [feedback_timer], 0
    je shield_meter_feedback_done
    mov al, [message_id]
    cmp al, MSG_HIT
    je shield_meter_feedback_live
    cmp al, MSG_SURGE
    jne shield_meter_feedback_done
shield_meter_feedback_live:
    test byte ptr [anim_phase], 1
    jz shield_meter_feedback_red
    mov al, PAL_WHITE
    jmp shield_meter_color_ready
shield_meter_feedback_red:
    mov al, PAL_RED2
    jmp shield_meter_color_ready
shield_meter_feedback_done:
    cmp byte ptr [shield_count], 1
    jne shield_meter_safe
    test byte ptr [anim_phase], 1
    jz shield_meter_safe
    mov al, PAL_WHITE
    jmp shield_meter_color_ready

shield_meter_safe:
    mov al, PAL_CYAN2

shield_meter_color_ready:
    call fill_rect
    pop dx
    pop bx

shield_meter_next:
    add dx, 12
    inc di
    loop shield_meter_loop
    ret

draw_pulse_meter:
    mov bx, 258
    mov dx, 100
    mov cx, 5
    xor di, di

pulse_meter_loop:
    push bx
    push dx
    push cx
    mov cx, 12
    mov bp, 8
    cmp byte ptr [feedback_timer], 0
    je pulse_meter_bg_ready
    mov al, [message_id]
    cmp al, MSG_NOPULSE
    jne pulse_meter_bg_ready
    test byte ptr [anim_phase], 1
    jz pulse_meter_bg_warn
    mov al, PAL_RED2
    jmp pulse_meter_bg_draw
pulse_meter_bg_warn:
    mov al, PAL_RED
    jmp pulse_meter_bg_draw
pulse_meter_bg_ready:
    mov al, PAL_PANEL2
pulse_meter_bg_draw:
    call fill_rect
    pop cx
    pop dx
    pop bx
    xor ax, ax
    mov al, [pulse_count]
    cmp di, ax
    jae pulse_meter_next
    push bx
    push dx
    mov cx, 12
    mov bp, 8
    cmp byte ptr [feedback_timer], 0
    je pulse_meter_fill_ready
    mov al, [message_id]
    cmp al, MSG_PULSE
    je pulse_meter_flash_live
    cmp al, MSG_RECHARGE
    jne pulse_meter_fill_ready
pulse_meter_flash_live:
    test byte ptr [anim_phase], 1
    jz pulse_meter_flash_base
    mov al, PAL_WHITE
    jmp pulse_meter_color_ready
pulse_meter_flash_base:
    mov al, PAL_AMBER
    jmp pulse_meter_color_ready
pulse_meter_fill_ready:
    mov al, PAL_AMBER
pulse_meter_color_ready:
    call fill_rect
    pop dx
    pop bx

pulse_meter_next:
    add dx, 12
    inc di
    loop pulse_meter_loop
    ret

draw_gate_meter:
    mov bx, 258
    mov dx, 142
    mov cx, 40
    mov bp, 10
    mov al, PAL_PANEL2
    call fill_rect
    mov bx, 260
    mov dx, 144
    mov cx, 36
    mov bp, 6
    test byte ptr [anim_phase], 1
    jz gate_meter_locked_base
    mov al, PAL_RED2
    jmp gate_meter_locked_ready

gate_meter_locked_base:
    mov al, PAL_RED

gate_meter_locked_ready:
    call fill_rect
    cmp byte ptr [data_count], SHARD_COUNT
    jne gate_meter_partial
    mov bx, 260
    mov dx, 144
    mov cx, 36
    mov bp, 6
    test byte ptr [anim_phase], 1
    jz gate_open_base
    mov al, PAL_WHITE
    jmp gate_meter_ready

gate_open_base:
    mov al, PAL_GATE
    jmp gate_meter_ready

gate_meter_partial:
    xor ax, ax
    mov al, [data_count]
    mov cx, ax
    shl ax, 3
    add ax, cx
    mov cx, ax
    jcxz gate_meter_done
    mov bx, 260
    mov dx, 144
    mov bp, 6
    cmp byte ptr [feedback_timer], 0
    je gate_meter_partial_ready
    mov al, [message_id]
    cmp al, MSG_SHARD
    jne gate_meter_partial_ready
    test byte ptr [anim_phase], 1
    jz gate_meter_partial_flash
    mov al, PAL_WHITE
    jmp gate_meter_ready
gate_meter_partial_flash:
    mov al, PAL_CYAN2
    jmp gate_meter_ready

gate_meter_partial_ready:
    cmp byte ptr [data_count], SHARD_COUNT - 1
    jne gate_meter_partial_base
    test byte ptr [anim_phase], 1
    jz gate_meter_partial_primed
    mov al, PAL_WHITE
    jmp gate_meter_ready

gate_meter_partial_primed:
    mov al, PAL_GATE
    jmp gate_meter_ready

gate_meter_partial_base:
    mov al, PAL_CYAN

gate_meter_ready:
    call fill_rect

gate_meter_done:
    ret

draw_message_banner:
    cmp byte ptr [feedback_timer], 0
    je message_banner_done
    mov bx, 16
    mov dx, 172
    mov cx, 288
    mov bp, 8
    call get_message_banner_color
    call fill_rect
    ; The banner glint rides either the active SFX phase or the idle animation
    ; phase so major messages feel tied to the same beat as the speaker.
    call draw_message_banner_glint

message_banner_done:
    ret

draw_message_banner_glint:
    cmp byte ptr [sound_timer], 0
    jne banner_glint_sound
    xor bx, bx
    mov bl, [anim_phase]
    and bl, 0Fh
    shl bx, 4
    add bx, 20
    jmp banner_glint_ready

banner_glint_sound:
    xor bx, bx
    mov bl, [sound_phase]
    and bl, 07h
    shl bx, 5
    add bx, 24

banner_glint_ready:
    mov dx, 173
    mov cx, 18
    mov bp, 1
    mov al, PAL_WHITE
    call fill_rect
    ret

get_message_banner_color:
    mov al, [message_id]
    cmp al, MSG_SECTOR
    je message_banner_sector
    cmp al, MSG_HIT
    je message_banner_danger
    cmp al, MSG_SURGE
    je message_banner_danger
    cmp al, MSG_GATE
    je message_banner_gate
    cmp al, MSG_RECHARGE
    je message_banner_gate
    cmp al, MSG_BLOCK
    je message_banner_warn
    cmp al, MSG_NOPULSE
    je message_banner_warn
    mov al, PAL_CYAN
    ret

message_banner_sector:
    call get_sector_accent_color
    ret

message_banner_gate:
    mov al, PAL_GATE
    ret

message_banner_warn:
    mov al, PAL_AMBER
    ret

message_banner_danger:
    mov al, PAL_RED
    ret

get_message_text_color:
    cmp byte ptr [feedback_timer], 0
    je message_text_default
    mov al, [message_id]
    cmp al, MSG_SECTOR
    je message_text_sector
    cmp al, MSG_HIT
    je message_text_danger
    cmp al, MSG_SURGE
    je message_text_danger
    cmp al, MSG_GATE
    je message_text_gate
    cmp al, MSG_RECHARGE
    je message_text_gate
    cmp al, MSG_BLOCK
    je message_text_warn
    cmp al, MSG_NOPULSE
    je message_text_warn
    test byte ptr [anim_phase], 1
    jz message_text_cyan
    mov al, PAL_WHITE
    ret

message_text_sector:
    test byte ptr [anim_phase], 1
    jz message_text_sector_base
    mov al, PAL_WHITE
    ret

message_text_sector_base:
    call get_sector_title_color
    ret

message_text_cyan:
    mov al, PAL_CYAN2
    ret

message_text_gate:
    test byte ptr [anim_phase], 1
    jz message_text_gate_base
    mov al, PAL_WHITE
    ret

message_text_gate_base:
    mov al, PAL_GATE
    ret

message_text_warn:
    test byte ptr [anim_phase], 1
    jz message_text_warn_base
    mov al, PAL_WHITE
    ret

message_text_warn_base:
    mov al, PAL_AMBER
    ret

message_text_danger:
    test byte ptr [anim_phase], 1
    jz message_text_danger_base
    mov al, PAL_WHITE
    ret

message_text_danger_base:
    mov al, PAL_RED2
    ret

message_text_default:
    mov al, PAL_WHITE
    ret

IF DEBUG_OVERLAY
render_debug_overlay:
    mov bx, 16
    mov dx, 38
    mov cx, 224
    mov bp, 10
    mov al, PAL_PANEL2
    call fill_rect

    mov bx, 18
    mov dx, 40
    mov si, offset debug_tag_text
    mov ah, PAL_AMBER
    call draw_text_small

    mov bx, 42
    mov dx, 40
    mov si, offset debug_sector_tag
    mov ah, PAL_CYAN
    call draw_text_small

    mov al, [sector_num]
    mov ah, PAL_WHITE
    mov bx, 48
    mov dx, 40
    call draw_digit_small

    mov bx, 60
    mov dx, 40
    mov si, offset debug_x_tag
    mov ah, PAL_CYAN
    call draw_text_small

    mov al, [player_x]
    mov ah, PAL_WHITE
    mov bx, 66
    mov dx, 40
    call draw_two_digit_small

    mov bx, 84
    mov dx, 40
    mov si, offset debug_y_tag
    mov ah, PAL_CYAN
    call draw_text_small

    mov al, [player_y]
    mov ah, PAL_WHITE
    mov bx, 90
    mov dx, 40
    call draw_two_digit_small

    mov bx, 108
    mov dx, 40
    mov si, offset debug_shield_tag
    mov ah, PAL_CYAN
    call draw_text_small

    mov al, [shield_count]
    mov ah, PAL_WHITE
    mov bx, 114
    mov dx, 40
    call draw_digit_small

    mov bx, 126
    mov dx, 40
    mov si, offset debug_pulse_tag
    mov ah, PAL_CYAN
    call draw_text_small

    mov al, [pulse_count]
    mov ah, PAL_WHITE
    mov bx, 132
    mov dx, 40
    call draw_digit_small

    mov bx, 144
    mov dx, 40
    mov si, offset debug_data_tag
    mov ah, PAL_CYAN
    call draw_text_small

    mov al, [data_count]
    mov ah, PAL_WHITE
    mov bx, 150
    mov dx, 40
    call draw_digit_small

    mov bx, 162
    mov dx, 40
    mov si, offset debug_enemy_tag
    mov ah, PAL_CYAN
    call draw_text_small

    call count_live_enemies
    mov ah, PAL_WHITE
    mov bx, 168
    mov dx, 40
    call draw_two_digit_small
    ret

count_live_enemies:
    push si
    push cx
    xor al, al
    mov si, offset enemies
    mov cx, MAX_ENEMIES

count_live_enemy_loop:
    cmp byte ptr [si + ENEMY_ALIVE], 0
    je count_live_enemy_next
    inc al

count_live_enemy_next:
    add si, ENEMY_SIZE
    loop count_live_enemy_loop
    pop cx
    pop si
    ret
ENDIF
