render_screen:
    ; Most render helpers write through ES and expect it to stay pointed at the
    ; backbuffer for the duration of the frame.
    mov ax, BACKBUFFER_SEG
    mov es, ax
    call update_palette_animation
    call clear_backbuffer
    call draw_starfield

    cmp byte ptr [game_state], STATE_SPLASH
    je render_splash_screen
    cmp byte ptr [game_state], STATE_TITLE
    je render_title_screen
    cmp byte ptr [game_state], STATE_WIN
    je render_win_screen
    cmp byte ptr [game_state], STATE_LOSE
    je render_lose_screen
    call render_game_screen
    jmp render_present

render_splash_screen:
    call draw_splash_scene
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

draw_splash_scene:
    mov bx, 48
    mov dx, 34
    mov cx, 224
    mov bp, 124
    mov al, PAL_PANEL
    call fill_rect

    mov bx, 44
    mov dx, 30
    mov cx, 232
    mov bp, 132
    test byte ptr [anim_phase], 1
    jz splash_frame_base
    mov al, PAL_CYAN2
    jmp splash_frame_ready

splash_frame_base:
    mov al, PAL_CYAN

splash_frame_ready:
    call draw_rect_outline

    mov bx, 60
    mov dx, 54
    mov cx, 52
    mov bp, 52
    mov al, PAL_PANEL2
    call fill_rect

    mov bx, 58
    mov dx, 52
    mov cx, 56
    mov bp, 56
    mov al, PAL_CYAN
    call draw_rect_outline

    mov bx, 70
    mov dx, 64
    mov si, offset sprite_bitriver_mark
    call draw_sprite16_2x

    mov bx, 126
    mov dx, 62
    mov si, offset splash_brand
    mov ah, PAL_CYAN2
    call draw_text_big

    mov bx, 148
    mov dx, 92
    mov si, offset splash_subtitle
    mov ah, PAL_WHITE
    call draw_text_small

    mov bx, 66
    mov dx, 122
    mov si, offset splash_tagline
    mov ah, PAL_CYAN
    call draw_text_small

    mov bx, 78
    mov dx, 142
    mov cx, 164
    mov bp, 8
    mov al, PAL_PANEL2
    call fill_rect

    mov bx, 76
    mov dx, 140
    mov cx, 168
    mov bp, 12
    mov al, PAL_CYAN
    call draw_rect_outline

    xor ax, ax
    mov al, [splash_ticks]
    mov cx, ax
    shl ax, 1
    add ax, cx
    mov cx, ax
    jcxz splash_bar_done
    mov bx, 80
    mov dx, 144
    mov bp, 4
    test byte ptr [anim_phase], 1
    jz splash_bar_base
    mov al, PAL_WHITE
    jmp splash_bar_ready

splash_bar_base:
    mov al, PAL_GATE

splash_bar_ready:
    call fill_rect

splash_bar_done:
    mov bx, 114
    mov dx, 158
    mov si, offset splash_skip
    test byte ptr [anim_phase], 1
    jz splash_skip_dim
    mov ah, PAL_WHITE
    jmp splash_skip_ready

splash_skip_dim:
    mov ah, PAL_AMBER

splash_skip_ready:
    call draw_text_small
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
    test byte ptr [anim_phase], 1
    jz title_frame_dim
    mov al, PAL_CYAN2
    jmp title_frame_ready

title_frame_dim:
    mov al, PAL_CYAN

title_frame_ready:
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
    test byte ptr [anim_phase], 2
    jz title_prompt_amber
    mov ah, PAL_WHITE
    jmp title_line_ready

title_prompt_amber:
    mov ah, PAL_AMBER

title_line_ready:
    call draw_text_small

    mov bx, 74
    mov dx, 150
    mov si, offset title_prompt
    mov ah, PAL_CYAN
    call draw_text_small

IF DEBUG_BUILD
    mov bx, 42
    mov dx, 166
    mov si, offset debug_keys_text
    mov ah, PAL_AMBER
    call draw_text_small

    mov al, [input_event_count]
    mov ah, PAL_WHITE
    mov bx, 68
    mov dx, 166
    call draw_two_digit_small

    mov bx, 92
    mov dx, 166
    mov si, offset debug_enter_text
    mov ah, PAL_AMBER
    call draw_text_small

    xor al, al
    mov al, [pressed_enter]
    mov ah, PAL_WHITE
    mov bx, 118
    mov dx, 166
    call draw_digit_small

    mov bx, 142
    mov dx, 166
    mov si, offset debug_check_text
    mov ah, PAL_AMBER
    call draw_text_small

    mov al, [input_check_count]
    mov ah, PAL_WHITE
    mov bx, 168
    mov dx, 166
    call draw_two_digit_small

    mov bx, 186
    mov dx, 166
    mov si, offset debug_poll_text
    mov ah, PAL_AMBER
    call draw_text_small

    mov al, [input_poll_count]
    mov ah, PAL_WHITE
    mov bx, 212
    mov dx, 166
    call draw_two_digit_small

    test byte ptr [anim_phase], 1
    jz title_cursor_off
    mov bx, 216
    mov dx, 157
    mov cx, 10
    mov bp, 2
    mov al, PAL_AMBER
    call fill_rect
ENDIF

title_cursor_off:
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
    cmp byte ptr [sound_id], SFX_WIN
    jne win_frame_anim
    cmp byte ptr [sound_timer], 0
    je win_frame_anim
    test byte ptr [sound_phase], 1
    jz win_frame_base
    mov al, PAL_WHITE
    jmp win_frame_ready

win_frame_anim:
    test byte ptr [anim_phase], 1
    jz win_frame_base
    mov al, PAL_WHITE
    jmp win_frame_ready

win_frame_base:
    mov al, PAL_CYAN

win_frame_ready:
    call draw_rect_outline
    xor ax, ax
    mov al, [state_ticks]
    mov cx, ax
    shl ax, 3
    add ax, cx
    add ax, cx
    cmp ax, 200
    jbe win_bar_ready
    mov ax, 200

win_bar_ready:
    mov cx, ax
    mov bx, 60
    mov dx, 88
    mov bp, 4
    cmp byte ptr [sound_id], SFX_WIN
    jne win_bar_anim
    cmp byte ptr [sound_timer], 0
    je win_bar_anim
    test byte ptr [sound_phase], 1
    jz win_bar_base
    mov al, PAL_WHITE
    jmp win_bar_color_ready

win_bar_anim:
    test byte ptr [anim_phase], 1
    jz win_bar_base
    mov al, PAL_WHITE
    jmp win_bar_color_ready

win_bar_base:
    mov al, PAL_GATE
win_bar_color_ready:
    call fill_rect
    mov bx, 60
    mov dx, 80
    mov bp, 2
    call fill_rect
    mov dx, 96
    call fill_rect

    ; End scenes now reveal in headline/body/stats/prompt phases so the sound
    ; and accent bars land before the replay prompt appears.
    cmp byte ptr [state_ticks], END_REVEAL_HEADLINE
    jb win_scene_done

    mov bx, 78
    mov dx, 54
    mov si, offset win_line_1
    mov ah, PAL_CYAN2
    call draw_text_big
    cmp byte ptr [state_ticks], END_REVEAL_BODY
    jb win_scene_done

    mov bx, 52
    mov dx, 100
    mov si, offset win_line_2
    mov ah, PAL_WHITE
    call draw_text_small
    mov bx, 68
    mov dx, 112
    mov si, offset win_line_3
    mov ah, PAL_CYAN
    call draw_text_small
    cmp byte ptr [state_ticks], END_REVEAL_STATS
    jb win_scene_done

    mov bx, 52
    mov dx, 122
    mov cx, 196
    mov bp, 12
    mov al, PAL_GATE
    call draw_rect_outline

    mov bx, 60
    mov dx, 126
    mov si, offset sector_text
    mov ah, PAL_WHITE
    call draw_text_small
    mov al, [sector_num]
    mov ah, PAL_GATE
    mov bx, 98
    mov dx, 126
    call draw_digit_small

    mov bx, 122
    mov dx, 126
    mov si, offset kills_text
    mov ah, PAL_WHITE
    call draw_text_small
    mov al, [kill_count]
    mov ah, PAL_GATE
    mov bx, 156
    mov dx, 126
    call draw_two_digit_small

    mov bx, 188
    mov dx, 126
    mov si, offset shield_text
    mov ah, PAL_WHITE
    call draw_text_small
    mov al, [shield_count]
    mov ah, PAL_GATE
    mov bx, 232
    mov dx, 126
    call draw_digit_small
    cmp byte ptr [state_ticks], END_REVEAL_PROMPT
    jb win_scene_done

    mov bx, 64
    mov dx, 142
    mov cx, 156
    mov bp, 10
    mov al, PAL_PANEL2
    call fill_rect

    mov bx, 62
    mov dx, 140
    mov cx, 160
    mov bp, 14
    test byte ptr [anim_phase], 1
    jz win_prompt_frame_base
    mov al, PAL_WHITE
    jmp win_prompt_frame_ready

win_prompt_frame_base:
    mov al, PAL_GATE

win_prompt_frame_ready:
    call draw_rect_outline

    mov bx, 70
    mov dx, 146
    mov si, offset replay_prompt
    test byte ptr [anim_phase], 1
    jz win_prompt_dim
    mov ah, PAL_WHITE
    jmp win_prompt_ready

win_prompt_dim:
    mov ah, PAL_AMBER

win_prompt_ready:
    call draw_text_small
win_scene_done:
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
    cmp byte ptr [sound_id], SFX_LOSE
    jne lose_frame_anim
    cmp byte ptr [sound_timer], 0
    je lose_frame_anim
    test byte ptr [sound_phase], 1
    jz lose_frame_base
    mov al, PAL_WHITE
    jmp lose_frame_ready

lose_frame_anim:
    test byte ptr [anim_phase], 1
    jz lose_frame_base
    mov al, PAL_RED2
    jmp lose_frame_ready

lose_frame_base:
    mov al, PAL_RED

lose_frame_ready:
    call draw_rect_outline
    xor ax, ax
    mov al, [state_ticks]
    mov cx, ax
    shl ax, 3
    add ax, cx
    add ax, cx
    cmp ax, 200
    jbe lose_bar_ready
    mov ax, 200

lose_bar_ready:
    mov cx, ax
    mov bx, 60
    mov dx, 88
    mov bp, 4
    cmp byte ptr [sound_id], SFX_LOSE
    jne lose_bar_anim
    cmp byte ptr [sound_timer], 0
    je lose_bar_anim
    test byte ptr [sound_phase], 1
    jz lose_bar_base
    mov al, PAL_WHITE
    jmp lose_bar_color_ready

lose_bar_anim:
    test byte ptr [anim_phase], 1
    jz lose_bar_base
    mov al, PAL_WHITE
    jmp lose_bar_color_ready

lose_bar_base:
    mov al, PAL_RED2
lose_bar_color_ready:
    call fill_rect
    mov bx, 60
    mov dx, 80
    mov bp, 2
    call fill_rect
    mov dx, 96
    call fill_rect

    cmp byte ptr [state_ticks], END_REVEAL_HEADLINE
    jb lose_scene_done

    mov bx, 82
    mov dx, 54
    mov si, offset lose_line_1
    mov ah, PAL_RED2
    call draw_text_big
    cmp byte ptr [state_ticks], END_REVEAL_BODY
    jb lose_scene_done

    mov bx, 46
    mov dx, 100
    mov si, offset lose_line_2
    mov ah, PAL_WHITE
    call draw_text_small
    mov bx, 62
    mov dx, 112
    mov si, offset lose_line_3
    mov ah, PAL_AMBER
    call draw_text_small
    cmp byte ptr [state_ticks], END_REVEAL_STATS
    jb lose_scene_done

    mov bx, 56
    mov dx, 122
    mov cx, 192
    mov bp, 12
    mov al, PAL_RED2
    call draw_rect_outline

    mov bx, 64
    mov dx, 126
    mov si, offset sector_text
    mov ah, PAL_WHITE
    call draw_text_small
    mov al, [sector_num]
    mov ah, PAL_RED2
    mov bx, 102
    mov dx, 126
    call draw_digit_small

    mov bx, 126
    mov dx, 126
    mov si, offset kills_text
    mov ah, PAL_WHITE
    call draw_text_small
    mov al, [kill_count]
    mov ah, PAL_RED2
    mov bx, 160
    mov dx, 126
    call draw_two_digit_small

    mov bx, 192
    mov dx, 126
    mov si, offset shield_text
    mov ah, PAL_WHITE
    call draw_text_small
    mov al, [shield_count]
    mov ah, PAL_RED2
    mov bx, 236
    mov dx, 126
    call draw_digit_small
    cmp byte ptr [state_ticks], END_REVEAL_PROMPT
    jb lose_scene_done

    mov bx, 64
    mov dx, 142
    mov cx, 156
    mov bp, 10
    mov al, PAL_PANEL2
    call fill_rect

    mov bx, 62
    mov dx, 140
    mov cx, 160
    mov bp, 14
    test byte ptr [anim_phase], 1
    jz lose_prompt_frame_base
    mov al, PAL_WHITE
    jmp lose_prompt_frame_ready

lose_prompt_frame_base:
    mov al, PAL_RED2

lose_prompt_frame_ready:
    call draw_rect_outline

    mov bx, 70
    mov dx, 146
    mov si, offset replay_prompt
    test byte ptr [anim_phase], 1
    jz lose_prompt_dim
    mov ah, PAL_WHITE
    jmp lose_prompt_ready

lose_prompt_dim:
    mov ah, PAL_AMBER

lose_prompt_ready:
    call draw_text_small
lose_scene_done:
    ret
