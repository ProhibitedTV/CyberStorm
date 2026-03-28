render_screen:
    mov ax, BACKBUFFER_SEG
    mov es, ax
    call clear_backbuffer
    call draw_starfield

    cmp byte ptr [game_state], STATE_TITLE
    je render_title_screen
    cmp byte ptr [game_state], STATE_WIN
    je render_win_screen
    cmp byte ptr [game_state], STATE_LOSE
    je render_lose_screen
    call render_game_screen
    jmp render_present

render_title_screen:
    call draw_title_scene
    jmp render_present

render_win_screen:
    call draw_win_scene
    jmp render_present

render_lose_screen:
    call draw_lose_scene

render_present:
    call present_frame
    ret

draw_title_scene:
    mov bx, 24
    mov dx, 26
    mov cx, 272
    mov bp, 132
    mov al, PAL_PANEL
    call fill_rect

    mov bx, 20
    mov dx, 22
    mov cx, 280
    mov bp, 140
    mov al, PAL_CYAN
    call draw_rect_outline

    mov bx, 34
    mov dx, 42
    mov si, offset title_logo
    mov ah, PAL_CYAN2
    call draw_text_big

    mov bx, 42
    mov dx, 84
    mov si, offset title_line_1
    mov ah, PAL_WHITE
    call draw_text_small

    mov bx, 42
    mov dx, 96
    mov si, offset title_line_2
    mov ah, PAL_WHITE
    call draw_text_small

    mov bx, 42
    mov dx, 108
    mov si, offset title_line_3
    mov ah, PAL_WHITE
    call draw_text_small

    mov bx, 62
    mov dx, 132
    mov si, offset title_line_4
    mov ah, PAL_AMBER
    call draw_text_small

    mov bx, 74
    mov dx, 150
    mov si, offset title_prompt
    mov ah, PAL_CYAN
    call draw_text_small
    ret

draw_win_scene:
    mov bx, 30
    mov dx, 34
    mov cx, 260
    mov bp, 120
    mov al, PAL_PANEL
    call fill_rect

    mov bx, 26
    mov dx, 30
    mov cx, 268
    mov bp, 128
    mov al, PAL_CYAN
    call draw_rect_outline

    mov bx, 78
    mov dx, 54
    mov si, offset win_line_1
    mov ah, PAL_CYAN2
    call draw_text_big

    mov bx, 52
    mov dx, 100
    mov si, offset win_line_2
    mov ah, PAL_WHITE
    call draw_text_small

    mov bx, 70
    mov dx, 132
    mov si, offset replay_prompt
    mov ah, PAL_AMBER
    call draw_text_small
    ret

draw_lose_scene:
    mov bx, 30
    mov dx, 34
    mov cx, 260
    mov bp, 120
    mov al, PAL_PANEL
    call fill_rect

    mov bx, 26
    mov dx, 30
    mov cx, 268
    mov bp, 128
    mov al, PAL_RED
    call draw_rect_outline

    mov bx, 82
    mov dx, 54
    mov si, offset lose_line_1
    mov ah, PAL_RED2
    call draw_text_big

    mov bx, 46
    mov dx, 100
    mov si, offset lose_line_2
    mov ah, PAL_WHITE
    call draw_text_small

    mov bx, 70
    mov dx, 132
    mov si, offset replay_prompt
    mov ah, PAL_AMBER
    call draw_text_small
    ret

render_game_screen:
    call draw_game_panels
    call render_game_status
    call render_map
    call render_enemies
    call render_player
    call render_game_effects
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

    xor ax, ax
    mov al, [message_id]
    shl ax, 1
    mov bx, ax
    mov si, word ptr [message_table + bx]
    mov bx, 18
    mov dx, 175
    mov ah, PAL_WHITE
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
    mov al, PAL_CYAN2
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
    mov al, PAL_PANEL2
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
    mov al, PAL_AMBER
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
    cmp byte ptr [data_count], SHARD_COUNT
    jne gate_closed
    mov bx, 260
    mov dx, 144
    mov cx, 36
    mov bp, 6
    mov al, PAL_CYAN2
    call fill_rect
    ret

gate_closed:
    mov bx, 260
    mov dx, 144
    mov cx, 36
    mov bp, 6
    mov al, PAL_RED
    call fill_rect
    ret
