render_screen:
    ; Most render helpers write through ES and expect it to stay pointed at the
    ; backbuffer for the duration of the frame.
    mov ax, BACKBUFFER_SEG
    mov es, ax
    call update_machine_kernel_frame_mode
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
    cmp byte ptr [game_state], STATE_VERIFY_PASS
    je render_verify_pass_screen
    cmp byte ptr [game_state], STATE_VERIFY_FAIL
    je render_verify_fail_screen
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
    jmp render_present

render_verify_pass_screen:
    call draw_verify_pass_scene
    jmp render_present

render_verify_fail_screen:
    call draw_verify_fail_scene

render_present:
    call present_frame
    ret

draw_splash_scene:
IF DEBUG_SCENE_RENDER_MODE EQ SCENE_RENDER_MODE_2D
    call draw_splash_scene_2d
ELSE
    call draw_splash_scene_3d
ENDIF
    ret

draw_splash_scene_2d:
    ; The startup splash now reads as a studio ident instead of a flat panel:
    ; the floor grid and pylons establish depth first, then the BitRiver mark
    ; rises in, and finally the existing prompt/progress UI comes online.
    call draw_splash_backdrop
    call draw_splash_floor_grid

    cmp byte ptr [splash_ticks], SPLASH_REVEAL_PYLONS
    jb splash_scene_logo_gate
    call draw_splash_pylons

splash_scene_logo_gate:
    cmp byte ptr [splash_ticks], SPLASH_REVEAL_LOGO
    jb splash_scene_ui_gate
    call draw_splash_brand_stack

splash_scene_ui_gate:
    cmp byte ptr [splash_ticks], SPLASH_REVEAL_UI
    jb splash_scene_done
    call draw_splash_ui
splash_scene_done:
    ret

draw_splash_backdrop:
    push ax
    push bx
    push cx
    push dx
    push bp

    mov bx, 0
    mov dx, 0
    mov cx, SCREEN_W
    mov bp, SCREEN_H
    mov al, PAL_BG0
    call fill_rect

    mov bx, 0
    mov dx, 92
    mov cx, SCREEN_W
    mov bp, 108
    mov al, PAL_BG1
    call fill_rect

    mov bx, 46
    mov dx, 74
    mov cx, 228
    mov bp, 1
    mov al, PAL_PANEL2
    call fill_rect

    mov bx, 62
    mov dx, 78
    mov cx, 196
    mov bp, 1
    mov al, PAL_CYAN
    call fill_rect

    mov bx, 88
    mov dx, 82
    mov cx, 144
    mov bp, 2
    test byte ptr [anim_phase], 1
    jz splash_horizon_dim
    mov al, PAL_CYAN2
    jmp splash_horizon_ready

splash_horizon_dim:
    mov al, PAL_CYAN

splash_horizon_ready:
    call fill_rect

    mov bx, 112
    mov dx, 86
    mov cx, 96
    mov bp, 5
    mov al, PAL_PANEL
    call fill_rect

    mov bx, 130
    mov dx, 90
    mov cx, 60
    mov bp, 5
    mov al, PAL_PANEL2
    call fill_rect

    pop bp
    pop dx
    pop cx
    pop bx
    pop ax
    ret

draw_splash_floor_grid:
    call draw_splash_grid_rungs
    call draw_splash_grid_rails
    call draw_splash_lane_markers
    ret

draw_splash_grid_rungs:
    push ax
    push bx
    push cx
    push dx
    push si
    push di
    push bp
    xor si, si
    xor di, di

splash_grid_rung_loop:
    cmp di, 8
    jae splash_grid_rungs_done
    mov al, [splash_grid_reveal_ticks + di]
    cmp byte ptr [splash_ticks], al
    jb splash_grid_rung_next
    mov bx, [splash_grid_lefts + si]
    mov dx, [splash_grid_rows + si]
    mov cx, [splash_grid_widths + si]
    mov bp, 1
    mov al, [splash_grid_colors + di]
    call fill_rect

splash_grid_rung_next:
    add si, 2
    inc di
    jmp splash_grid_rung_loop

splash_grid_rungs_done:
    pop bp
    pop di
    pop si
    pop dx
    pop cx
    pop bx
    pop ax
    ret

draw_splash_grid_rails:
    push ax
    push bx
    push cx
    push dx
    push si
    push di
    push bp
    xor si, si
    mov di, 1
    test byte ptr [anim_phase], 1
    jz splash_grid_rails_dim
    mov al, PAL_CYAN2
    jmp splash_grid_rails_color_ready

splash_grid_rails_dim:
    mov al, PAL_CYAN

splash_grid_rails_color_ready:
splash_grid_rail_loop:
    cmp di, 8
    jae splash_grid_rails_done
    mov ah, [splash_grid_reveal_ticks + di]
    cmp byte ptr [splash_ticks], ah
    jb splash_grid_rail_next

    mov dx, [splash_grid_rows + si]
    mov bp, [splash_grid_rows + si + 2]
    sub bp, dx

    mov bx, [splash_grid_lefts + si + 2]
    mov cx, 2
    call fill_rect

    mov bx, [splash_grid_lefts + si + 2]
    mov cx, [splash_grid_widths + si + 2]
    add bx, cx
    sub bx, 2
    mov cx, 2
    call fill_rect

splash_grid_rail_next:
    add si, 2
    inc di
    jmp splash_grid_rail_loop

splash_grid_rails_done:
    pop bp
    pop di
    pop si
    pop dx
    pop cx
    pop bx
    pop ax
    ret

draw_splash_lane_markers:
    push ax
    push bx
    push cx
    push dx
    push si
    push di
    push bp
    xor ax, ax
    mov al, [splash_ticks]
    and ax, 7
    shl ax, 1
    mov si, ax
    xor di, di

splash_lane_marker_loop:
    cmp di, 8
    jae splash_lane_markers_done
    mov dx, [splash_lane_rows + di]
    add dx, si
    cmp dx, 188
    ja splash_lane_marker_next
    mov cx, [splash_lane_widths + di]
    mov bx, 160
    mov ax, cx
    shr ax, 1
    sub bx, ax
    test byte ptr [anim_phase], 1
    jz splash_lane_marker_dim
    mov al, PAL_WHITE
    jmp splash_lane_marker_color_ready

splash_lane_marker_dim:
    mov al, PAL_CYAN2

splash_lane_marker_color_ready:
    mov bp, 2
    call fill_rect

splash_lane_marker_next:
    add di, 2
    jmp splash_lane_marker_loop

splash_lane_markers_done:
    pop bp
    pop di
    pop si
    pop dx
    pop cx
    pop bx
    pop ax
    ret

draw_splash_pylons:
    push ax
    push bx
    push cx
    push dx
    push bp
    test byte ptr [anim_phase], 1
    jz splash_pylon_frame_dim
    mov al, PAL_CYAN2
    jmp splash_pylon_frame_ready

splash_pylon_frame_dim:
    mov al, PAL_CYAN

splash_pylon_frame_ready:
    mov bx, 36
    mov dx, 40
    mov cx, 26
    mov bp, 60
    call draw_rect_outline

    mov bx, 258
    mov dx, 40
    mov cx, 26
    mov bp, 60
    call draw_rect_outline

    mov bx, 66
    mov dx, 54
    mov cx, 18
    mov bp, 40
    call draw_rect_outline

    mov bx, 236
    mov dx, 54
    mov cx, 18
    mov bp, 40
    call draw_rect_outline

    mov bx, 42
    mov dx, 48
    mov cx, 14
    mov bp, 1
    mov al, PAL_PANEL2
    call fill_rect
    mov dx, 62
    call fill_rect
    mov dx, 76
    call fill_rect

    mov bx, 264
    mov dx, 48
    mov cx, 14
    mov bp, 1
    call fill_rect
    mov dx, 62
    call fill_rect
    mov dx, 76
    call fill_rect

    mov bx, 72
    mov dx, 62
    mov cx, 8
    mov bp, 1
    call fill_rect
    mov dx, 74
    call fill_rect

    mov bx, 240
    mov dx, 62
    mov cx, 8
    mov bp, 1
    call fill_rect
    mov dx, 74
    call fill_rect

    test byte ptr [anim_phase], 1
    jz splash_pylon_scan_dim
    mov al, PAL_WHITE
    jmp splash_pylon_scan_ready

splash_pylon_scan_dim:
    mov al, PAL_CYAN2

splash_pylon_scan_ready:
    mov bx, 47
    mov dx, 46
    mov cx, 2
    mov bp, 44
    call fill_rect

    mov bx, 271
    mov dx, 46
    mov cx, 2
    mov bp, 44
    call fill_rect

    mov bx, 73
    mov dx, 58
    mov cx, 2
    mov bp, 28
    call fill_rect

    mov bx, 245
    mov dx, 58
    mov cx, 2
    mov bp, 28
    call fill_rect

    pop bp
    pop dx
    pop cx
    pop bx
    pop ax
    ret

draw_splash_brand_stack:
    push ax
    push bx
    push cx
    push dx
    push si
    push bp
    xor ax, ax
    mov al, [splash_ticks]
    cmp al, SPLASH_REVEAL_WORDMARK
    jae splash_brand_lockup_ready
    mov bl, SPLASH_REVEAL_WORDMARK
    sub bl, al
    shr bl, 1
    xor bh, bh
    mov ax, bx

splash_brand_lockup_ready:
    mov bx, 82
    mov dx, 58
    add dx, ax
    mov cx, 156
    mov bp, 30
    mov al, PAL_PANEL
    call fill_rect

    mov bx, 80
    mov dx, 56
    add dx, ax
    mov cx, 160
    mov bp, 34
    test byte ptr [anim_phase], 1
    jz splash_brand_frame_dim
    mov al, PAL_CYAN2
    jmp splash_brand_frame_ready

splash_brand_frame_dim:
    mov al, PAL_CYAN

splash_brand_frame_ready:
    call draw_rect_outline

    mov bx, 95
    mov dx, 64
    add dx, ax
    mov si, offset splash_brand
    mov ah, PAL_PANEL2
    call draw_text_big

    mov bx, 94
    mov dx, 63
    add dx, ax
    mov si, offset splash_brand
    mov ah, PAL_WHITE
    call draw_text_big

    cmp byte ptr [splash_ticks], SPLASH_REVEAL_WORDMARK
    jb splash_brand_stack_done

    mov bx, 116
    mov dx, 86
    add dx, ax
    mov cx, 88
    mov bp, 8
    mov al, PAL_PANEL2
    call fill_rect

    mov bx, 114
    mov dx, 84
    add dx, ax
    mov cx, 92
    mov bp, 12
    mov al, PAL_AMBER
    call draw_rect_outline

    mov bx, 128
    mov dx, 88
    add dx, ax
    mov si, offset splash_subtitle
    mov ah, PAL_WHITE
    call draw_text_small

    mov bx, 94
    mov dx, 54
    add dx, ax
    mov cx, 132
    mov bp, 1
    mov al, PAL_WHITE
    call fill_rect

    mov bx, 110
    mov dx, 97
    add dx, ax
    mov cx, 100
    mov bp, 1
    mov al, PAL_AMBER
    call fill_rect

splash_brand_stack_done:
    pop bp
    pop si
    pop dx
    pop cx
    pop bx
    pop ax
    ret

draw_splash_ui:
    mov bx, 53
    mov dx, 126
    mov si, offset splash_tagline
    mov ah, PAL_CYAN
    call draw_text_small

    mov bx, 78
    mov dx, 148
    mov cx, 164
    mov bp, 8
    mov al, PAL_PANEL2
    call fill_rect

    mov bx, 76
    mov dx, 146
    mov cx, 168
    mov bp, 12
    test byte ptr [anim_phase], 1
    jz splash_ui_frame_dim
    mov al, PAL_WHITE
    jmp splash_ui_frame_ready

splash_ui_frame_dim:
    mov al, PAL_CYAN

splash_ui_frame_ready:
    call draw_rect_outline

    xor ax, ax
    mov al, [splash_ticks]
    mov cx, ax
    shl ax, 1
    add ax, cx
    cmp ax, 160
    jbe splash_bar_clamped
    mov ax, 160

splash_bar_clamped:
    mov cx, ax
    jcxz splash_ui_prompt
    mov bx, 80
    mov dx, 150
    mov bp, 4
    test byte ptr [anim_phase], 1
    jz splash_bar_base
    mov al, PAL_WHITE
    jmp splash_bar_ready

splash_bar_base:
    mov al, PAL_GATE

splash_bar_ready:
    call fill_rect

splash_ui_prompt:
    mov bx, 79
    mov dx, 166
    mov si, offset splash_run_prompt
    mov ah, PAL_WHITE
    call draw_text_small

    mov bx, 88
    mov dx, 176
    mov si, offset splash_skip_prompt
    test byte ptr [anim_phase], 1
    jz splash_prompt_dim
    mov ah, PAL_WHITE
    jmp splash_prompt_ready

splash_prompt_dim:
    mov ah, PAL_AMBER

splash_prompt_ready:
    call draw_text_small
    ret

draw_title_scene:
IF DEBUG_SCENE_RENDER_MODE EQ SCENE_RENDER_MODE_2D
    call draw_title_scene_overlay
ELSE
    call draw_title_scene_3d
ENDIF
    ret

draw_title_scene_overlay:
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

    ; Keep the title screen typography-led so the first boot reads as a clean
    ; invitation instead of a noisy presentation collage.
    mov bx, 74
    mov dx, 56
    mov si, offset title_logo
    mov ah, PAL_CYAN2
    call draw_text_big

    mov bx, 80
    mov dx, 84
    mov cx, 160
    mov bp, 1
    mov al, PAL_CYAN
    call fill_rect

    mov bx, 100
    mov dx, 88
    mov cx, 120
    mov bp, 1
    mov al, PAL_AMBER
    call fill_rect

    mov bx, 48
    mov dx, 102
    mov si, offset title_line_1
    mov ah, PAL_WHITE
    call draw_text_small

    mov bx, 48
    mov dx, 114
    mov si, offset title_line_2
    mov ah, PAL_WHITE
    call draw_text_small

    mov bx, 74
    mov dx, 138
    mov si, offset title_line_4
    test byte ptr [anim_phase], 2
    jz title_prompt_amber
    mov ah, PAL_WHITE
    jmp title_line_ready

title_prompt_amber:
    mov ah, PAL_AMBER

title_line_ready:
    call draw_text_small

    mov bx, 58
    mov dx, 150
    mov si, offset title_prompt
    mov ah, PAL_CYAN
    call draw_text_small
    call draw_title_demo_arm_badge

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
IF DEBUG_SCENE_RENDER_MODE EQ SCENE_RENDER_MODE_2D
    call draw_win_scene_overlay
ELSE
    call draw_win_scene_3d
ENDIF
    ret

draw_win_scene_overlay:
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

    mov bx, 96
    mov dx, 38
    mov si, PRESENT_BANNER_WIN_BANNER_OFFSET
    call draw_presentation_asset_2x
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

    cmp byte ptr [state_ticks], END_REVEAL_BODY
    jb win_scene_headline_gate
    mov bx, 74
    mov dx, 104
    mov si, PRESENT_BANNER_WIN_PLATE_OFFSET
    call draw_presentation_asset_2x

win_scene_headline_gate:
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
    mov bp, 22
    mov al, PAL_GATE
    call draw_rect_outline

    mov bx, 60
    mov dx, 126
    mov si, offset score_text
    mov ah, PAL_WHITE
    call draw_text_small
    mov ax, [score_total]
    mov bx, 96
    mov dx, 126
    mov cl, PAL_GATE
    call draw_word_decimal_small

    mov bx, 176
    mov dx, 126
    call get_score_rank_ptr
    call get_score_rank_color
    mov ah, al
    call draw_text_small

    mov bx, 60
    mov dx, 138
    mov si, offset sector1_short_text
    mov ah, PAL_WHITE
    call draw_text_small
    mov al, 1
    call get_sector_score_ax
    mov bx, 74
    mov dx, 138
    mov cl, PAL_GATE
    call draw_word_decimal_small

    mov bx, 122
    mov dx, 138
    mov si, offset sector2_short_text
    mov ah, PAL_WHITE
    call draw_text_small
    mov al, 2
    call get_sector_score_ax
    mov bx, 136
    mov dx, 138
    mov cl, PAL_GATE
    call draw_word_decimal_small

    mov bx, 184
    mov dx, 138
    mov si, offset sector3_short_text
    mov ah, PAL_WHITE
    call draw_text_small
    mov al, 3
    call get_sector_score_ax
    mov bx, 198
    mov dx, 138
    mov cl, PAL_GATE
    call draw_word_decimal_small
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
IF DEBUG_SCENE_RENDER_MODE EQ SCENE_RENDER_MODE_2D
    call draw_lose_scene_overlay
ELSE
    call draw_lose_scene_3d
ENDIF
    ret

draw_lose_scene_overlay:
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

    mov bx, 96
    mov dx, 38
    mov si, PRESENT_BANNER_LOSE_BANNER_OFFSET
    call draw_presentation_asset_2x
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

    cmp byte ptr [state_ticks], END_REVEAL_BODY
    jb lose_scene_headline_gate
    mov bx, 74
    mov dx, 104
    mov si, PRESENT_BANNER_LOSE_PLATE_OFFSET
    call draw_presentation_asset_2x

lose_scene_headline_gate:
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
    mov bp, 22
    mov al, PAL_RED2
    call draw_rect_outline

    mov bx, 64
    mov dx, 126
    mov si, offset score_text
    mov ah, PAL_WHITE
    call draw_text_small
    mov ax, [score_total]
    mov bx, 100
    mov dx, 126
    mov cl, PAL_RED2
    call draw_word_decimal_small

    mov bx, 182
    mov dx, 126
    call get_score_rank_ptr
    call get_score_rank_color
    mov ah, al
    call draw_text_small

    mov bx, 64
    mov dx, 138
    mov si, offset sector1_short_text
    mov ah, PAL_WHITE
    call draw_text_small
    mov al, 1
    call get_sector_score_ax
    mov bx, 78
    mov dx, 138
    mov cl, PAL_RED2
    call draw_word_decimal_small

    mov bx, 124
    mov dx, 138
    mov si, offset sector2_short_text
    mov ah, PAL_WHITE
    call draw_text_small
    mov al, 2
    call get_sector_score_ax
    mov bx, 138
    mov dx, 138
    mov cl, PAL_RED2
    call draw_word_decimal_small

    mov bx, 184
    mov dx, 138
    mov si, offset sector3_short_text
    mov ah, PAL_WHITE
    call draw_text_small
    mov al, 3
    call get_sector_score_ax
    mov bx, 198
    mov dx, 138
    mov cl, PAL_RED2
    call draw_word_decimal_small
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

draw_verify_pass_scene:
    call draw_verify_scene_common
    ret

draw_verify_fail_scene:
    call draw_verify_scene_common
    ret

draw_verify_scene_common:
    mov bx, 28
    mov dx, 28
    mov cx, 264
    mov bp, 144
    mov al, PAL_PANEL
    call fill_rect

    mov bx, 24
    mov dx, 24
    mov cx, 272
    mov bp, 152
    call get_verify_scene_accent_color
    call draw_rect_outline

    mov bx, VERIFY_MARKER_X
    mov dx, VERIFY_MARKER_Y
    mov cx, VERIFY_MARKER_W
    mov bp, VERIFY_MARKER_H
    call get_verify_scene_accent_color
    call fill_rect

    mov bx, 68
    mov dx, 42
    cmp byte ptr [verify_mode], VERIFY_MODE_FRONTEND
    je verify_headline_frontend
    cmp byte ptr [game_state], STATE_VERIFY_PASS
    jne verify_headline_fail
    mov si, offset verify_pass_headline
    mov ah, PAL_CYAN2
    jmp verify_headline_ready

verify_headline_frontend:
    cmp byte ptr [game_state], STATE_VERIFY_PASS
    jne verify_headline_frontend_fail
    mov si, offset frontend_verify_pass_headline
    mov ah, PAL_CYAN2
    jmp verify_headline_ready

verify_headline_frontend_fail:
    mov si, offset frontend_verify_fail_headline
    mov ah, PAL_RED2
    jmp verify_headline_ready

verify_headline_fail:
    mov si, offset verify_fail_headline
    mov ah, PAL_RED2

verify_headline_ready:
    call draw_text_big

    mov bx, 68
    mov dx, 60
    cmp byte ptr [verify_mode], VERIFY_MODE_FRONTEND
    je verify_subject_frontend
    mov si, offset verify_demo_label
    mov ah, PAL_WHITE
    call draw_text_small

    mov bx, 98
    mov dx, 60
    call get_demo_name_ptr
    call get_verify_scene_accent_color
    mov ah, al
    call draw_text_small
    jmp verify_subject_done

verify_subject_frontend:
    mov si, offset verify_scenario_label
    mov ah, PAL_WHITE
    call draw_text_small

    mov bx, 98
    mov dx, 60
    call get_frontend_verify_scenario_name_ptr
    call get_verify_scene_accent_color
    mov ah, al
    call draw_text_small

verify_subject_done:

    mov bx, 68
    mov dx, 72
    cmp byte ptr [verify_mode], VERIFY_MODE_FRONTEND
    je verify_detail_frontend
    call get_current_template_scenario_name_ptr
    jmp verify_detail_ready

verify_detail_frontend:
    call get_frontend_verify_detail_ptr

verify_detail_ready:
    mov ah, PAL_WHITE
    call draw_text_small

    mov bx, 68
    mov dx, 86
    cmp byte ptr [verify_mode], VERIFY_MODE_FRONTEND
    je verify_body_frontend
    cmp byte ptr [game_state], STATE_VERIFY_PASS
    jne verify_body_fail
    mov si, offset verify_line_1
    mov ah, PAL_WHITE
    jmp verify_body_ready

verify_body_fail:
    mov si, offset verify_line_2
    mov ah, PAL_WHITE

verify_body_ready:
    call draw_text_small

    cmp byte ptr [verify_mode], VERIFY_MODE_FRONTEND
    je verify_state_line_done

    mov bx, 68
    mov dx, 94
    mov si, offset verify_state_px_label
    mov ah, PAL_WHITE
    call draw_text_small
    mov al, [player_x]
    mov ah, PAL_WHITE
    mov bx, 84
    mov dx, 94
    call draw_two_digit_small

    mov bx, 102
    mov dx, 94
    mov si, offset verify_state_py_label
    mov ah, PAL_WHITE
    call draw_text_small
    mov al, [player_y]
    mov ah, PAL_WHITE
    mov bx, 118
    mov dx, 94
    call draw_two_digit_small

    mov bx, 136
    mov dx, 94
    mov si, offset verify_state_action_label
    mov ah, PAL_WHITE
    call draw_text_small
    mov al, [sector_actions]
    mov ah, PAL_WHITE
    mov bx, 152
    mov dx, 94
    call draw_two_digit_small

    mov bx, 170
    mov dx, 94
    mov si, offset verify_state_heading_label
    mov ah, PAL_WHITE
    call draw_text_small
    mov al, [verify_snapshot_heading]
    mov ah, PAL_WHITE
    mov bx, 186
    mov dx, 94
    call draw_two_digit_small

    mov bx, 204
    mov dx, 94
    mov si, offset verify_state_variant_label
    mov ah, PAL_WHITE
    call draw_text_small
    mov al, [verify_snapshot_variant]
    mov ah, PAL_WHITE
    mov bx, 220
    mov dx, 94
    call draw_two_digit_small

verify_state_line_done:
    cmp byte ptr [verify_mode], VERIFY_MODE_FRONTEND
    je verify_state_detail_done

    mov bx, 68
    mov dx, 102
    mov si, offset verify_state_shield_label
    mov ah, PAL_WHITE
    call draw_text_small
    mov al, [shield_count]
    mov ah, PAL_WHITE
    mov bx, 84
    mov dx, 102
    call draw_two_digit_small

    mov bx, 102
    mov dx, 102
    mov si, offset verify_state_pulse_label
    mov ah, PAL_WHITE
    call draw_text_small
    mov al, [pulse_count]
    mov ah, PAL_WHITE
    mov bx, 118
    mov dx, 102
    call draw_two_digit_small

    mov bx, 136
    mov dx, 102
    mov si, offset verify_state_data_label
    mov ah, PAL_WHITE
    call draw_text_small
    mov al, [data_count]
    mov ah, PAL_WHITE
    mov bx, 152
    mov dx, 102
    call draw_two_digit_small

    mov bx, 170
    mov dx, 102
    mov si, offset verify_state_kill_label
    mov ah, PAL_WHITE
    call draw_text_small
    mov al, [kill_count]
    mov ah, PAL_WHITE
    mov bx, 186
    mov dx, 102
    call draw_two_digit_small

    mov bx, 204
    mov dx, 102
    mov si, offset verify_state_subject_x_label
    mov ah, PAL_WHITE
    call draw_text_small
    mov al, [game3d_shot_subject_x]
    mov ah, PAL_WHITE
    mov bx, 220
    mov dx, 102
    call draw_two_digit_small

    mov bx, 238
    mov dx, 102
    mov si, offset verify_state_subject_y_label
    mov ah, PAL_WHITE
    call draw_text_small
    mov al, [game3d_shot_subject_y]
    mov ah, PAL_WHITE
    mov bx, 254
    mov dx, 102
    call draw_two_digit_small

verify_state_detail_done:
    cmp byte ptr [verify_mode], VERIFY_MODE_FRONTEND
    je verify_state_hidden_done

    mov bx, 68
    mov dx, 110
    mov si, offset verify_state_rng_label
    mov ah, PAL_WHITE
    call draw_text_small
    mov bx, 84
    mov dx, 110
    mov ax, [rng_state]
    mov cl, PAL_WHITE
    call draw_word_hex_small

    mov bx, 136
    mov dx, 110
    mov si, offset verify_state_cue_label
    mov ah, PAL_WHITE
    call draw_text_small
    mov al, [verify_snapshot_cue_flags]
    mov ah, PAL_WHITE
    mov bx, 152
    mov dx, 110
    call draw_two_digit_small

    mov bx, 170
    mov dx, 110
    mov si, offset verify_state_tick_label
    mov ah, PAL_WHITE
    call draw_text_small
    mov al, [game3d_shot_tick]
    mov ah, PAL_WHITE
    mov bx, 186
    mov dx, 110
    call draw_two_digit_small

    mov bx, 204
    mov dx, 110
    mov si, offset verify_state_shot_label
    mov ah, PAL_WHITE
    call draw_text_small
    mov al, [game3d_shot_mode]
    mov ah, PAL_WHITE
    mov bx, 220
    mov dx, 110
    call draw_two_digit_small

    mov bx, 238
    mov dx, 110
    mov si, offset verify_state_reason_label
    mov ah, PAL_WHITE
    call draw_text_small
    mov al, [game3d_shot_reason]
    mov ah, PAL_WHITE
    mov bx, 254
    mov dx, 110
    call draw_two_digit_small

    mov bx, 272
    mov dx, 110
    mov si, offset verify_state_frame_label
    mov ah, PAL_WHITE
    call draw_text_small
    mov al, [game3d_shot_frame_variant]
    mov ah, PAL_WHITE
    mov bx, 288
    mov dx, 110
    call draw_two_digit_small

verify_state_hidden_done:
    jmp verify_step_label_gate

verify_body_frontend:
    cmp byte ptr [game_state], STATE_VERIFY_PASS
    jne verify_body_frontend_fail
    mov si, offset frontend_verify_line_1
    mov ah, PAL_WHITE
    jmp verify_body_ready

verify_body_frontend_fail:
    mov si, offset frontend_verify_line_2
    mov ah, PAL_WHITE
    jmp verify_body_ready

verify_step_label_gate:
    mov bx, 68
    mov dx, 120
    cmp byte ptr [verify_mode], VERIFY_MODE_FRONTEND
    je verify_step_frontend
    mov si, offset verify_step_label
    jmp verify_step_label_ready

verify_step_frontend:
    mov si, offset verify_event_label

verify_step_label_ready:
    mov ah, PAL_WHITE
    call draw_text_small

    mov al, [verify_action_index]
    mov ah, PAL_WHITE
    mov bx, 92
    mov dx, 120
    call draw_two_digit_small

    mov bx, 126
    mov dx, 120
    mov si, offset verify_expect_label
    mov ah, PAL_WHITE
    call draw_text_small

    mov ax, [verify_expected_signature]
    push ax
    mov bx, 150
    mov dx, 120
    call get_verify_scene_accent_color
    mov cl, al
    pop ax
    call draw_word_hex_small

    mov bx, 204
    mov dx, 120
    mov si, offset verify_observe_label
    mov ah, PAL_WHITE
    call draw_text_small

    mov ax, [verify_observed_signature]
    push ax
    mov bx, 228
    mov dx, 120
    call get_verify_scene_accent_color
    mov cl, al
    pop ax
    call draw_word_hex_small

    mov bx, 68
    mov dx, VERIFY_EXPECT_BITS_Y - 2
    mov si, offset verify_expect_label
    mov ah, PAL_WHITE
    call draw_text_small
    mov ax, [verify_expected_signature]
    mov bx, VERIFY_BITS_X
    mov dx, VERIFY_EXPECT_BITS_Y
    call draw_verify_signature_bits

    mov bx, 68
    mov dx, VERIFY_OBS_BITS_Y - 2
    mov si, offset verify_observe_label
    mov ah, PAL_WHITE
    call draw_text_small
    mov ax, [verify_observed_signature]
    mov bx, VERIFY_BITS_X
    mov dx, VERIFY_OBS_BITS_Y
    call draw_verify_signature_bits

    cmp byte ptr [verify_mode], VERIFY_MODE_FRONTEND
    je verify_draw_prompt_box

    mov bx, 56
    mov dx, 168
    mov cx, 246
    mov bp, 22
    mov al, PAL_PANEL2
    call fill_rect

    mov bx, 54
    mov dx, 166
    mov cx, 250
    mov bp, 26
    test byte ptr [anim_phase], 1
    jz verify_prompt_frame_base
    mov al, PAL_WHITE
    jmp verify_prompt_frame_ready

verify_prompt_frame_base:
    call get_verify_scene_accent_color

verify_prompt_frame_ready:
    call draw_rect_outline

    mov bx, 64
    mov dx, 172
    mov si, offset verify_state_intro_label
    mov ah, PAL_WHITE
    call draw_text_small
    mov al, [verify_snapshot_intro_timer]
    mov ah, PAL_WHITE
    mov bx, 80
    mov dx, 172
    call draw_two_digit_small

    mov bx, 98
    mov dx, 172
    mov si, offset verify_state_enemy_tick_label
    mov ah, PAL_WHITE
    call draw_text_small
    mov al, [verify_snapshot_enemy_tick]
    mov ah, PAL_WHITE
    mov bx, 114
    mov dx, 172
    call draw_two_digit_small

    mov bx, 132
    mov dx, 172
    mov si, offset verify_state_threat_label
    mov ah, PAL_WHITE
    call draw_text_small
    mov al, [verify_snapshot_threat_level]
    mov ah, PAL_WHITE
    mov bx, 148
    mov dx, 172
    call draw_two_digit_small

    mov bx, 166
    mov dx, 172
    mov si, offset verify_state_threat_x_label
    mov ah, PAL_WHITE
    call draw_text_small
    mov al, [verify_snapshot_threat_x]
    mov ah, PAL_WHITE
    mov bx, 182
    mov dx, 172
    call draw_two_digit_small

    mov bx, 200
    mov dx, 172
    mov si, offset verify_state_threat_y_label
    mov ah, PAL_WHITE
    call draw_text_small
    mov al, [verify_snapshot_threat_y]
    mov ah, PAL_WHITE
    mov bx, 216
    mov dx, 172
    call draw_two_digit_small

    mov bx, 64
    mov dx, 180
    mov si, offset verify_state_enemy0_label
    mov ah, PAL_WHITE
    call draw_text_small
    mov ax, [verify_snapshot_enemy0]
    mov bx, 80
    mov dx, 180
    mov cl, PAL_WHITE
    call draw_word_hex_small

    mov bx, 138
    mov dx, 180
    mov si, offset verify_state_enemy1_label
    mov ah, PAL_WHITE
    call draw_text_small
    mov ax, [verify_snapshot_enemy1]
    mov bx, 154
    mov dx, 180
    mov cl, PAL_WHITE
    call draw_word_hex_small

    mov bx, 212
    mov dx, 180
    mov si, offset verify_state_enemy2_label
    mov ah, PAL_WHITE
    call draw_text_small
    mov ax, [verify_snapshot_enemy2]
    mov bx, 228
    mov dx, 180
    mov cl, PAL_WHITE
    call draw_word_hex_small
    ret

verify_draw_prompt_box:
    mov bx, 74
    mov dx, 170
    mov cx, 172
    mov bp, 10
    mov al, PAL_PANEL2
    call fill_rect

    mov bx, 72
    mov dx, 168
    mov cx, 176
    mov bp, 14
    test byte ptr [anim_phase], 1
    jz verify_prompt_frontend_base
    mov al, PAL_WHITE
    jmp verify_prompt_frontend_ready

verify_prompt_frontend_base:
    call get_verify_scene_accent_color

verify_prompt_frontend_ready:
    call draw_rect_outline

    mov bx, 86
    mov dx, 174
    mov si, offset verify_prompt
    test byte ptr [anim_phase], 1
    jz verify_prompt_dim
    mov ah, PAL_WHITE
    jmp verify_prompt_ready

verify_prompt_dim:
    mov ah, PAL_AMBER

verify_prompt_ready:
    call draw_text_small
    ret

get_verify_scene_accent_color:
    cmp byte ptr [game_state], STATE_VERIFY_PASS
    jne verify_scene_color_fail
    mov al, PAL_CYAN2
    ret

verify_scene_color_fail:
    mov al, PAL_RED2
    ret

draw_verify_signature_bits:
    push ax
    push bx
    push cx
    push dx
    push si
    mov si, 8000h
    mov cx, 16

verify_bits_loop:
    push ax
    push bx
    push cx
    push dx
    test ax, si
    jz verify_bit_zero
    mov al, PAL_WHITE
    jmp verify_bit_color_ready

verify_bit_zero:
    mov al, PAL_PANEL2

verify_bit_color_ready:
    mov bp, VERIFY_BIT_SIZE
    mov cx, VERIFY_BIT_SIZE
    call fill_rect
    pop dx
    pop cx
    pop bx
    pop ax
    add bx, VERIFY_BIT_PITCH
    shr si, 1
    loop verify_bits_loop
    pop si
    pop dx
    pop cx
    pop bx
    pop ax
    ret

draw_title_demo_arm_badge:
    ; Once the title has been idle for a while, arm the attract demo visually
    ; before the handoff so the player can read the coming transition.
    cmp byte ptr [title_idle_ticks], TITLE_BADGE_DELAY
    jb title_demo_badge_done
    mov bx, 222
    mov dx, 54
    mov si, PRESENT_BANNER_DEMO_BADGE_OFFSET
    call draw_presentation_asset_1x
    mov bx, 236
    mov dx, 80
    mov si, offset demo_text
    mov ah, PAL_WHITE
    call draw_text_small
title_demo_badge_done:
    ret

splash_grid_rows       dw 92, 100, 110, 122, 136, 152, 170, 188
splash_grid_lefts      dw 140, 124, 106, 84, 58, 34, 10, 0
splash_grid_widths     dw 40, 72, 108, 152, 204, 252, 300, 320
splash_grid_reveal_ticks db 0, 1, 2, 4, 6, 8, 10, 12
splash_grid_colors     db PAL_PANEL2, PAL_PANEL2, PAL_CYAN, PAL_PANEL2, PAL_CYAN, PAL_PANEL2, PAL_CYAN2, PAL_CYAN
splash_lane_rows       dw 104, 126, 150, 176
splash_lane_widths     dw 4, 8, 12, 18
