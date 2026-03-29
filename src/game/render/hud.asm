render_game_screen:
    call draw_game_panels
    call render_game_status
    call render_map
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

    mov bx, 10
    mov dx, 8
    mov cx, 300
    mov bp, 22
    mov al, PAL_CYAN
    call draw_rect_outline

    mov bx, 10
    mov dx, 34
    mov cx, 236
    mov bp, 132
    mov al, PAL_CYAN
    call draw_rect_outline

    mov bx, 250
    mov dx, 34
    mov cx, 60
    mov bp, 132
    mov al, PAL_CYAN
    call draw_rect_outline

    mov bx, 10
    mov dx, 168
    mov cx, 300
    mov bp, 24
    mov al, PAL_CYAN
    call draw_rect_outline
    ret

render_game_status:
    mov bx, 18
    mov dx, 15
    mov si, offset hud_title
    mov ah, PAL_CYAN2
    call draw_text_small

    mov bx, 116
    mov dx, 15
    mov si, offset sector_text
    mov ah, PAL_WHITE
    call draw_text_small

    mov al, [sector_num]
    mov ah, PAL_AMBER
    mov bx, 154
    mov dx, 15
    call draw_digit_small

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
    xor ax, ax
    mov al, [message_id]
    shl ax, 1
    mov bx, ax
    mov si, word ptr [message_table + bx]
    mov bx, 18
    mov dx, 175
    call get_message_text_color
    mov ah, al
    call draw_text_small

    mov bx, 18
    mov dx, 184
    mov si, offset controls_text
    mov ah, PAL_CYAN
    call draw_text_small
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

message_banner_done:
    ret

get_message_banner_color:
    mov al, [message_id]
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
