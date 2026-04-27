render_screen:
    ; Most render helpers write through ES and expect it to stay pointed at the
    ; backbuffer for the duration of the frame.
    mov ax, BACKBUFFER_SEG
    mov es, ax
    call update_machine_kernel_frame_mode
    call update_palette_animation
    call clear_backbuffer
IF DEBUG_RENDER_SENTINELS
    mov bx, 0
    mov dx, 0
    mov al, PAL_WHITE
    call draw_debug_render_sentinel_vga
ENDIF
    call draw_starfield
IF DEBUG_RENDER_SENTINELS
    mov bx, 8
    mov dx, 0
    mov al, PAL_CYAN
    call draw_debug_render_sentinel_vga
ENDIF

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
IF DEBUG_RENDER_SENTINELS
    mov bx, 0
    mov dx, 8
    mov al, PAL_CYAN
    call draw_debug_render_sentinel_vga
ENDIF
    call draw_splash_scene
    jmp render_present

render_title_screen:
IF DEBUG_RENDER_SENTINELS
    mov bx, 8
    mov dx, 8
    mov al, PAL_CYAN2
    call draw_debug_render_sentinel_vga
ENDIF
    call draw_title_scene
    jmp render_present

render_win_screen:
IF DEBUG_RENDER_SENTINELS
    mov bx, 16
    mov dx, 8
    mov al, PAL_AMBER
    call draw_debug_render_sentinel_vga
ENDIF
    call draw_win_scene
    jmp render_present

render_lose_screen:
IF DEBUG_RENDER_SENTINELS
    mov bx, 24
    mov dx, 8
    mov al, PAL_AMBER
    call draw_debug_render_sentinel_vga
ENDIF
    call draw_lose_scene
    jmp render_present

render_verify_pass_screen:
IF DEBUG_RENDER_SENTINELS
    mov bx, 0
    mov dx, 12
    mov al, PAL_CYAN2
    call draw_debug_render_sentinel_vga
ENDIF
    call draw_verify_pass_scene
    jmp render_present

render_verify_fail_screen:
IF DEBUG_RENDER_SENTINELS
    mov bx, 8
    mov dx, 12
    mov al, PAL_AMBER
    call draw_debug_render_sentinel_vga
ENDIF
    call draw_verify_fail_scene

render_present:
    mov ax, BACKBUFFER_SEG
    mov es, ax
IF DEBUG_SMOKE_SENTINEL
    mov bx, SMOKE_SENTINEL_X
    mov dx, SMOKE_SENTINEL_Y
    mov cx, SMOKE_SENTINEL_W
    mov bp, SMOKE_SENTINEL_H
    mov al, SMOKE_SENTINEL_COLOR
    ; Keep the smoke marker on the deterministic reference fill path so the
    ; VM harness sees an exact solid block even when machine gameplay is active.
    call fill_rect_reference
ENDIF
    call present_frame
    ret

draw_splash_scene:
IF DEBUG_SCENE_RENDER_MODE EQ SCENE_RENDER_MODE_2D
    call draw_splash_scene_2d
ELSE
    call draw_splash_scene_3d
ENDIF
    ret

IF DEBUG_SCENE_RENDER_MODE EQ SCENE_RENDER_MODE_2D
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
ENDIF

draw_splash_brand_stack:
    push ax
    push bx
    push cx
    push dx
    push si
    push bp
    mov al, [splash_ticks]
    cmp al, SPLASH_REVEAL_LOGO
    jb splash_brand_stack_done
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
    mov [scene3d_temp_s], ax
    mov bx, 116
    mov dx, 60
    add dx, [scene3d_temp_s]
    mov cx, 88
    mov bp, 1
    test byte ptr [anim_phase], 1
    jz splash_brand_rule_dim
    mov al, PAL_CYAN2
    jmp splash_brand_rule_ready

splash_brand_rule_dim:
    mov al, PAL_CYAN

splash_brand_rule_ready:
    call fill_rect

    mov bx, 101
    mov dx, 66
    add dx, [scene3d_temp_s]
    mov si, offset splash_brand
    mov ah, PAL_PANEL2
    call draw_text_big

    mov bx, 100
    mov dx, 65
    add dx, [scene3d_temp_s]
    mov si, offset splash_brand
    mov ah, PAL_WHITE
    call draw_text_big

    cmp byte ptr [splash_ticks], SPLASH_REVEAL_WORDMARK
    jb splash_brand_stack_done

    mov bx, 121
    mov dx, 83
    add dx, [scene3d_temp_s]
    mov cx, 18
    mov bp, 1
    mov al, PAL_CYAN
    call fill_rect

    mov bx, 181
    mov dx, 83
    add dx, [scene3d_temp_s]
    mov cx, 18
    mov bp, 1
    mov al, PAL_CYAN
    call fill_rect

    mov bx, 128
    mov dx, 81
    add dx, [scene3d_temp_s]
    mov si, offset splash_subtitle
    mov ah, PAL_WHITE
    call draw_text_small

    mov bx, 124
    mov dx, 90
    add dx, [scene3d_temp_s]
    mov cx, 72
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
    mov bx, 86
    mov dx, 144
    mov cx, 148
    mov bp, 6
    mov al, PAL_PANEL2
    call fill_rect

    mov bx, 84
    mov dx, 142
    mov cx, 152
    mov bp, 10
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
    cmp ax, 144
    jbe splash_bar_clamped
    mov ax, 144

splash_bar_clamped:
    mov cx, ax
    jcxz splash_ui_prompt
    mov bx, 88
    mov dx, 146
    mov bp, 2
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
    mov dx, 161
    mov si, offset splash_run_prompt
    mov ah, PAL_WHITE
    call draw_text_small

    mov bx, 88
    mov dx, 171
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
    call draw_title_scene_overlay
ENDIF
    ret

draw_title_scene_overlay:
    mov bx, 56
    mov dx, 22
    mov cx, 208
    mov bp, 30
    mov al, PAL_PANEL
    call fill_rect

    mov bx, 60
    mov dx, 74
    mov cx, 200
    mov bp, 34
    mov al, PAL_PANEL
    call fill_rect

    mov bx, 52
    mov dx, 116
    mov cx, 216
    mov bp, 74
    mov al, PAL_PANEL
    call fill_rect

    mov bx, 40
    mov dx, 16
    mov cx, 240
    mov bp, 176
    test byte ptr [anim_phase], 1
    jz title_frame_dim
    mov al, PAL_CYAN2
    jmp title_frame_ready

title_frame_dim:
    mov al, PAL_CYAN

title_frame_ready:
    call draw_rect_outline

    mov bx, 74
    mov dx, 30
    mov si, offset title_logo
    mov ah, PAL_CYAN2
    call draw_text_big

    mov bx, 74
    mov dx, 58
    mov cx, 172
    mov bp, 1
    mov al, PAL_CYAN
    call fill_rect

    mov bx, 96
    mov dx, 64
    mov cx, 128
    mov bp, 1
    mov al, PAL_AMBER
    call fill_rect

    mov bx, 42
    mov dx, 78
    mov si, offset title_line_1
    mov ah, PAL_WHITE
    call draw_text_small

    mov bx, 80
    mov dx, 90
    mov si, offset title_line_2
    mov ah, PAL_WHITE
    call draw_text_small

    mov bx, 76
    mov dx, 102
    mov si, offset title_line_4
    mov ah, PAL_AMBER
    call draw_text_small

    cmp byte ptr [title_panel_mode], TITLE_PANEL_CREDITS
    je title_draw_credits_panel
    cmp byte ptr [title_panel_mode], TITLE_PANEL_OPTIONS
    je title_draw_options_panel

    mov bx, 90
    mov dx, 122
    mov si, offset title_menu_new_game_text
    cmp byte ptr [title_menu_index], TITLE_MENU_NEW_GAME
    jne title_new_game_dim
    mov ah, PAL_WHITE
    jmp title_new_game_ready

title_new_game_dim:
    mov ah, PAL_CYAN2

title_new_game_ready:
    call draw_text_small

    mov bx, 102
    mov dx, 136
    mov si, offset title_menu_credits_text
    cmp byte ptr [title_menu_index], TITLE_MENU_CREDITS
    jne title_credits_dim
    mov ah, PAL_WHITE
    jmp title_credits_ready

title_credits_dim:
    mov ah, PAL_CYAN2

title_credits_ready:
    call draw_text_small

    mov bx, 102
    mov dx, 150
    mov si, offset title_menu_options_text
    cmp byte ptr [title_menu_index], TITLE_MENU_OPTIONS
    jne title_options_dim
    mov ah, PAL_WHITE
    jmp title_options_ready

title_options_dim:
    mov ah, PAL_CYAN2

title_options_ready:
    call draw_text_small

    mov bx, 84
    mov dx, 168
    mov si, offset title_menu_hint_text
    mov ah, PAL_WHITE
    call draw_text_small

    mov bx, 110
    mov dx, 182
    mov si, offset title_prompt
    mov ah, PAL_CYAN
    call draw_text_small
IF DEBUG_FRONTEND_VERIFY
    call draw_title_frontend_verify_debug
ENDIF
    call draw_title_demo_arm_badge
    ret

title_draw_credits_panel:
    mov bx, 116
    mov dx, 124
    mov si, offset title_panel_credits_text
    mov ah, PAL_WHITE
    call draw_text_small

    mov bx, 84
    mov dx, 136
    mov si, offset credits_line_1
    mov ah, PAL_CYAN2
    call draw_text_small

    mov bx, 70
    mov dx, 148
    mov si, offset credits_line_2
    mov ah, PAL_WHITE
    call draw_text_small

    mov bx, 56
    mov dx, 160
    mov si, offset credits_line_3
    mov ah, PAL_WHITE
    call draw_text_small

    mov bx, 94
    mov dx, 172
    mov si, offset credits_line_4
    mov ah, PAL_AMBER
    call draw_text_small

    mov bx, 86
    mov dx, 184
    mov si, offset title_panel_return_text
    mov ah, PAL_CYAN
    call draw_text_small
    ret

title_draw_options_panel:
    mov bx, 116
    mov dx, 122
    mov si, offset title_panel_options_text
    mov ah, PAL_WHITE
    call draw_text_small

    mov bx, 82
    mov dx, 136
    mov si, offset title_option_music_text
    cmp byte ptr [title_options_index], TITLE_OPTIONS_MUSIC
    jne title_opt_music_dim
    mov ah, PAL_WHITE
    jmp title_opt_music_ready

title_opt_music_dim:
    mov ah, PAL_CYAN2

title_opt_music_ready:
    call draw_text_small
    mov bx, 196
    mov si, offset title_toggle_off_text
    cmp byte ptr [session_music_enabled], 0
    je title_opt_music_value
    mov si, offset title_toggle_on_text

title_opt_music_value:
    mov ah, PAL_WHITE
    call draw_text_small

    mov bx, 82
    mov dx, 148
    mov si, offset title_option_idle_demo_text
    cmp byte ptr [title_options_index], TITLE_OPTIONS_IDLE_DEMO
    jne title_opt_idle_dim
    mov ah, PAL_WHITE
    jmp title_opt_idle_ready

title_opt_idle_dim:
    mov ah, PAL_CYAN2

title_opt_idle_ready:
    call draw_text_small
    mov bx, 196
    mov si, offset title_toggle_off_text
    cmp byte ptr [session_idle_demo_enabled], 0
    je title_opt_idle_value
    mov si, offset title_toggle_on_text

title_opt_idle_value:
    mov ah, PAL_WHITE
    call draw_text_small

    mov bx, 82
    mov dx, 160
    mov si, offset title_option_back_text
    cmp byte ptr [title_options_index], TITLE_OPTIONS_BACK
    jne title_opt_back_dim
    mov ah, PAL_WHITE
    jmp title_opt_back_ready

title_opt_back_dim:
    mov ah, PAL_CYAN2

title_opt_back_ready:
    call draw_text_small

    mov bx, 86
    mov dx, 184
    mov si, offset title_panel_return_text
    mov ah, PAL_CYAN
    call draw_text_small

    ret

IF DEBUG_FRONTEND_VERIFY
draw_title_frontend_verify_debug:
    cmp byte ptr [verify_mode], VERIFY_MODE_FRONTEND
    jne title_frontend_verify_debug_done

    mov bx, 6
    mov dx, 6
    mov si, offset frontend_verify_vm_tag
    mov ah, PAL_CYAN2
    call draw_text_small
    mov al, [verify_mode]
    mov ah, PAL_WHITE
    mov bx, 18
    mov dx, 6
    call draw_byte_hex_small

    mov bx, 36
    mov dx, 6
    mov si, offset frontend_verify_sc_tag
    mov ah, PAL_CYAN2
    call draw_text_small
    mov al, [verify_frontend_scenario]
    mov ah, PAL_WHITE
    mov bx, 48
    mov dx, 6
    call draw_byte_hex_small

    mov bx, 66
    mov dx, 6
    mov si, offset frontend_verify_vt_tag
    mov ah, PAL_CYAN2
    call draw_text_small
    mov al, [verify_frontend_ticks]
    mov ah, PAL_WHITE
    mov bx, 78
    mov dx, 6
    call draw_byte_hex_small

    mov bx, 96
    mov dx, 6
    mov si, offset frontend_verify_ti_tag
    mov ah, PAL_CYAN2
    call draw_text_small
    mov al, [title_idle_ticks]
    mov ah, PAL_WHITE
    mov bx, 108
    mov dx, 6
    call draw_byte_hex_small

    mov bx, 126
    mov dx, 6
    mov si, offset frontend_verify_vf_tag
    mov ah, PAL_CYAN2
    call draw_text_small
    mov al, [verify_frontend_event_fired]
    mov ah, PAL_WHITE
    mov bx, 138
    mov dx, 6
    call draw_byte_hex_small

    mov bx, 156
    mov dx, 6
    mov si, offset frontend_verify_fa_tag
    mov ah, PAL_CYAN2
    call draw_text_small
    mov al, [frontend_last_action]
    mov ah, PAL_WHITE
    mov bx, 168
    mov dx, 6
    call draw_byte_hex_small

title_frontend_verify_debug_done:
    ret
ENDIF

draw_win_scene:
IF DEBUG_SCENE_RENDER_MODE EQ SCENE_RENDER_MODE_2D
    call draw_win_scene_overlay
ELSE
    call draw_win_scene_3d
ENDIF
    ret

draw_win_scene_overlay:
    mov bx, 30
    mov dx, 26
    mov cx, 260
    mov bp, 152
    mov al, PAL_PANEL
    call fill_rect

    mov bx, 26
    mov dx, 22
    mov cx, 268
    mov bp, 160
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
    mov dx, 34
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
    mov dx, 84
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
    mov dx, 76
    mov bp, 2
    call fill_rect
    mov dx, 92
    call fill_rect

    cmp byte ptr [state_ticks], END_REVEAL_BODY
    jb win_scene_headline_gate
    mov bx, 74
    mov dx, 94
    mov si, PRESENT_BANNER_WIN_PLATE_OFFSET
    call draw_presentation_asset_2x

win_scene_headline_gate:
    ; End scenes now reveal in headline/body/stats/prompt phases so the sound
    ; and accent bars land before the replay prompt appears.
    cmp byte ptr [state_ticks], END_REVEAL_HEADLINE
    jb win_scene_done

    mov bx, 70
    mov dx, 52
    mov si, offset win_line_1
    mov ah, PAL_CYAN2
    call draw_text_big
    cmp byte ptr [state_ticks], END_REVEAL_BODY
    jb win_scene_done

    mov bx, 40
    mov dx, 98
    mov si, offset win_line_2
    mov ah, PAL_WHITE
    call draw_text_small
    mov bx, 40
    mov dx, 110
    mov si, offset win_line_3
    mov ah, PAL_CYAN
    call draw_text_small
    cmp byte ptr [state_ticks], END_REVEAL_STATS
    jb win_scene_done

    mov bx, 48
    mov dx, 122
    mov cx, 204
    mov bp, 40
    mov al, PAL_GATE
    call draw_rect_outline

    mov bx, 56
    mov dx, 126
    mov si, offset score_text
    mov ah, PAL_WHITE
    call draw_text_small
    mov ax, [score_total]
    mov bx, 92
    mov dx, 126
    mov cl, PAL_GATE
    call draw_word_decimal_small

    mov bx, 174
    mov dx, 126
    call get_score_rank_ptr
    call get_score_rank_color
    mov ah, al
    call draw_text_small

    mov bx, 56
    mov dx, 138
    mov si, offset sector1_short_text
    mov ah, PAL_WHITE
    call draw_text_small
    mov al, 1
    call get_sector_score_ax
    mov bx, 70
    mov dx, 138
    mov cl, PAL_GATE
    call draw_word_decimal_small

    mov bx, 126
    mov dx, 138
    mov si, offset sector2_short_text
    mov ah, PAL_WHITE
    call draw_text_small
    mov al, 2
    call get_sector_score_ax
    mov bx, 140
    mov dx, 138
    mov cl, PAL_GATE
    call draw_word_decimal_small

    mov bx, 56
    mov dx, 148
    mov si, offset sector3_short_text
    mov ah, PAL_WHITE
    call draw_text_small
    mov al, 3
    call get_sector_score_ax
    mov bx, 70
    mov dx, 148
    mov cl, PAL_GATE
    call draw_word_decimal_small

    mov bx, 126
    mov dx, 148
    mov si, offset sector4_short_text
    mov ah, PAL_WHITE
    call draw_text_small
    mov al, 4
    call get_sector_score_ax
    mov bx, 140
    mov dx, 148
    mov cl, PAL_GATE
    call draw_word_decimal_small

    call get_score_rank_index
    cmp al, 0
    je win_scene_top_rank

    mov bx, 56
    mov dx, 158
    mov si, offset next_rank_text
    mov ah, PAL_WHITE
    call draw_text_small

    mov bx, 84
    mov dx, 158
    call get_next_rank_ptr
    mov ah, PAL_CYAN2
    call draw_text_small

    mov bx, 118
    mov dx, 158
    mov si, offset plus_text
    mov ah, PAL_WHITE
    call draw_text_small

    call get_next_rank_delta_ax
    mov bx, 126
    mov dx, 158
    mov cl, PAL_GATE
    call draw_word_decimal_small
    jmp win_scene_prompt_gate

win_scene_top_rank:
    mov bx, 56
    mov dx, 158
    mov si, offset top_rank_text
    mov ah, PAL_WHITE
    call draw_text_small

win_scene_prompt_gate:
    cmp byte ptr [state_ticks], END_REVEAL_PROMPT
    jb win_scene_done

    mov bx, 64
    mov dx, 166
    mov cx, 170
    mov bp, 10
    mov al, PAL_PANEL2
    call fill_rect

    mov bx, 62
    mov dx, 164
    mov cx, 174
    mov bp, 14
    test byte ptr [anim_phase], 1
    jz win_prompt_frame_base
    mov al, PAL_WHITE
    jmp win_prompt_frame_ready

win_prompt_frame_base:
    mov al, PAL_GATE

win_prompt_frame_ready:
    call draw_rect_outline

    mov bx, 78
    mov dx, 170
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
    mov dx, 26
    mov cx, 260
    mov bp, 152
    mov al, PAL_PANEL
    call fill_rect

    mov bx, 26
    mov dx, 22
    mov cx, 268
    mov bp, 160
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
    mov dx, 34
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
    mov dx, 84
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
    mov dx, 76
    mov bp, 2
    call fill_rect
    mov dx, 92
    call fill_rect

    cmp byte ptr [state_ticks], END_REVEAL_BODY
    jb lose_scene_headline_gate
    mov bx, 74
    mov dx, 94
    mov si, PRESENT_BANNER_LOSE_PLATE_OFFSET
    call draw_presentation_asset_2x

lose_scene_headline_gate:
    cmp byte ptr [state_ticks], END_REVEAL_HEADLINE
    jb lose_scene_done

    mov bx, 58
    mov dx, 52
    mov si, offset lose_line_1
    mov ah, PAL_RED2
    call draw_text_big
    cmp byte ptr [state_ticks], END_REVEAL_BODY
    jb lose_scene_done

    mov bx, 34
    mov dx, 98
    mov si, offset lose_line_2
    mov ah, PAL_WHITE
    call draw_text_small
    mov bx, 34
    mov dx, 110
    mov si, offset lose_line_3
    mov ah, PAL_AMBER
    call draw_text_small
    cmp byte ptr [state_ticks], END_REVEAL_STATS
    jb lose_scene_done

    mov bx, 48
    mov dx, 122
    mov cx, 204
    mov bp, 40
    mov al, PAL_RED2
    call draw_rect_outline

    mov bx, 56
    mov dx, 126
    mov si, offset score_text
    mov ah, PAL_WHITE
    call draw_text_small
    mov ax, [score_total]
    mov bx, 92
    mov dx, 126
    mov cl, PAL_RED2
    call draw_word_decimal_small

    mov bx, 174
    mov dx, 126
    call get_score_rank_ptr
    call get_score_rank_color
    mov ah, al
    call draw_text_small

    mov bx, 56
    mov dx, 138
    mov si, offset sector1_short_text
    mov ah, PAL_WHITE
    call draw_text_small
    mov al, 1
    call get_sector_score_ax
    mov bx, 70
    mov dx, 138
    mov cl, PAL_RED2
    call draw_word_decimal_small

    mov bx, 126
    mov dx, 138
    mov si, offset sector2_short_text
    mov ah, PAL_WHITE
    call draw_text_small
    mov al, 2
    call get_sector_score_ax
    mov bx, 140
    mov dx, 138
    mov cl, PAL_RED2
    call draw_word_decimal_small

    mov bx, 56
    mov dx, 148
    mov si, offset sector3_short_text
    mov ah, PAL_WHITE
    call draw_text_small
    mov al, 3
    call get_sector_score_ax
    mov bx, 70
    mov dx, 148
    mov cl, PAL_RED2
    call draw_word_decimal_small

    mov bx, 126
    mov dx, 148
    mov si, offset sector4_short_text
    mov ah, PAL_WHITE
    call draw_text_small
    mov al, 4
    call get_sector_score_ax
    mov bx, 140
    mov dx, 148
    mov cl, PAL_RED2
    call draw_word_decimal_small

    call get_score_rank_index
    cmp al, 0
    je lose_scene_top_rank

    mov bx, 56
    mov dx, 158
    mov si, offset next_rank_text
    mov ah, PAL_WHITE
    call draw_text_small

    mov bx, 84
    mov dx, 158
    call get_next_rank_ptr
    mov ah, PAL_AMBER
    call draw_text_small

    mov bx, 118
    mov dx, 158
    mov si, offset plus_text
    mov ah, PAL_WHITE
    call draw_text_small

    call get_next_rank_delta_ax
    mov bx, 126
    mov dx, 158
    mov cl, PAL_RED2
    call draw_word_decimal_small
    jmp lose_scene_prompt_gate

lose_scene_top_rank:
    mov bx, 56
    mov dx, 158
    mov si, offset top_rank_text
    mov ah, PAL_WHITE
    call draw_text_small

lose_scene_prompt_gate:
    cmp byte ptr [state_ticks], END_REVEAL_PROMPT
    jb lose_scene_done

    mov bx, 64
    mov dx, 166
    mov cx, 170
    mov bp, 10
    mov al, PAL_PANEL2
    call fill_rect

    mov bx, 62
    mov dx, 164
    mov cx, 174
    mov bp, 14
    test byte ptr [anim_phase], 1
    jz lose_prompt_frame_base
    mov al, PAL_WHITE
    jmp lose_prompt_frame_ready

lose_prompt_frame_base:
    mov al, PAL_RED2

lose_prompt_frame_ready:
    call draw_rect_outline

    mov bx, 78
    mov dx, 170
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
    mov bx, 36
    mov dx, 34
    mov cx, 248
    mov bp, 132
    mov al, PAL_PANEL
    call fill_rect

    mov bx, 32
    mov dx, 30
    mov cx, 256
    mov bp, 140
    call get_verify_scene_accent_color
    call draw_rect_outline

    mov bx, VERIFY_MARKER_X
    mov dx, VERIFY_MARKER_Y
    mov cx, VERIFY_MARKER_W
    mov bp, VERIFY_MARKER_H
    mov al, PAL_WHITE
    call draw_rect_outline

    mov bx, VERIFY_MARKER_X + 2
    mov dx, VERIFY_MARKER_Y + 2
    mov cx, VERIFY_MARKER_W - 4
    mov bp, VERIFY_MARKER_H - 4
    call get_verify_scene_accent_color
    call fill_rect

    mov bx, 66
    mov dx, 46
    cmp byte ptr [verify_mode], VERIFY_MODE_FRONTEND
    jne verify_scene_runtime_headline
    cmp byte ptr [game_state], STATE_VERIFY_PASS
    jne verify_scene_frontend_fail
    mov si, offset frontend_verify_pass_headline
    mov ah, PAL_CYAN2
    jmp verify_scene_headline_ready

verify_scene_frontend_fail:
    mov si, offset frontend_verify_fail_headline
    mov ah, PAL_RED2
    jmp verify_scene_headline_ready

verify_scene_runtime_headline:
    cmp byte ptr [game_state], STATE_VERIFY_PASS
    jne verify_scene_runtime_fail
    mov si, offset verify_pass_headline
    mov ah, PAL_CYAN2
    jmp verify_scene_headline_ready

verify_scene_runtime_fail:
    mov si, offset verify_fail_headline
    mov ah, PAL_RED2

verify_scene_headline_ready:
    call draw_text_big

    mov bx, 66
    mov dx, 70
    cmp byte ptr [verify_mode], VERIFY_MODE_FRONTEND
    je verify_scene_subject_frontend
    mov si, offset verify_demo_label
    mov ah, PAL_WHITE
    call draw_text_small

    mov bx, 96
    mov dx, 70
    call get_demo_name_ptr
    call get_verify_scene_accent_color
    mov ah, al
    call draw_text_small
    jmp verify_scene_subject_done

verify_scene_subject_frontend:
    mov si, offset verify_scenario_label
    mov ah, PAL_WHITE
    call draw_text_small

    mov bx, 96
    mov dx, 70
    call get_frontend_verify_scenario_name_ptr
    call get_verify_scene_accent_color
    mov ah, al
    call draw_text_small

verify_scene_subject_done:
    mov bx, 66
    mov dx, 82
    cmp byte ptr [verify_mode], VERIFY_MODE_FRONTEND
    je verify_scene_detail_frontend
    call get_current_template_scenario_name_ptr
    jmp verify_scene_detail_ready

verify_scene_detail_frontend:
    call get_frontend_verify_detail_ptr

verify_scene_detail_ready:
    mov ah, PAL_WHITE
    call draw_text_small

    mov bx, 66
    mov dx, 98
    mov si, offset verify_expect_label
    mov ah, PAL_WHITE
    call draw_text_small

    mov bx, 114
    mov dx, 98
    call get_verify_scene_accent_color
    mov cl, al
    mov ax, [verify_expected_signature]
    call draw_word_hex_small

    mov bx, 178
    mov dx, 98
    mov si, offset verify_observe_label
    mov ah, PAL_WHITE
    call draw_text_small

    mov bx, 208
    mov dx, 98
    call get_verify_scene_accent_color
    mov cl, al
    mov ax, [verify_observed_signature]
    call draw_word_hex_small

    mov bx, 66
    mov dx, 114
    cmp byte ptr [verify_mode], VERIFY_MODE_FRONTEND
    je verify_scene_body_frontend
    cmp byte ptr [game_state], STATE_VERIFY_PASS
    jne verify_scene_body_fail
    mov si, offset verify_line_1
    mov ah, PAL_WHITE
    jmp verify_scene_body_ready

verify_scene_body_fail:
    call get_runtime_verify_fail_reason_ptr
    mov ah, PAL_WHITE

verify_scene_body_ready:
    call draw_text_small

    mov ax, [verify_expected_signature]
    mov bx, VERIFY_BITS_X
    mov dx, VERIFY_EXPECT_BITS_Y
    call draw_verify_word_bits

    mov ax, [verify_observed_signature]
    mov bx, VERIFY_BITS_X
    mov dx, VERIFY_OBS_BITS_Y
    call draw_verify_word_bits

    xor ax, ax
    cmp byte ptr [verify_mode], VERIFY_MODE_FRONTEND
    je verify_scene_reason_bits_ready
    cmp byte ptr [game_state], STATE_VERIFY_FAIL
    jne verify_scene_reason_bits_ready
    mov al, [verify_fail_reason]

verify_scene_reason_bits_ready:
    mov bx, VERIFY_BITS_X
    mov dx, VERIFY_REASON_BITS_Y
    call draw_verify_word_bits

    cmp byte ptr [verify_mode], VERIFY_MODE_FRONTEND
    je verify_scene_prompt

    mov ax, [verify_diag_action]
    mov bx, VERIFY_BITS_X
    mov dx, VERIFY_DIAG_ACTION_BITS_Y
    call draw_verify_word_bits

    mov ax, [verify_diag_script_ptr]
    mov bx, VERIFY_BITS_X
    mov dx, VERIFY_DIAG_SCRIPT_BITS_Y
    call draw_verify_word_bits

    mov ax, [verify_diag_progress]
    mov bx, VERIFY_BITS_X
    mov dx, VERIFY_DIAG_PROGRESS_BITS_Y
    call draw_verify_word_bits

    mov ax, [verify_diag_flags]
    mov bx, VERIFY_BITS_X
    mov dx, VERIFY_DIAG_FLAGS_BITS_Y
    call draw_verify_word_bits
    jmp verify_scene_prompt

verify_scene_body_frontend:
    cmp byte ptr [game_state], STATE_VERIFY_PASS
    jne verify_scene_body_frontend_fail
    mov si, offset frontend_verify_line_1
    mov ah, PAL_WHITE
    jmp verify_scene_body_ready

verify_scene_body_frontend_fail:
    mov si, offset frontend_verify_line_2
    mov ah, PAL_WHITE
    jmp verify_scene_body_ready

verify_scene_prompt:
    mov bx, 78
    mov dx, 184
    mov cx, 168
    mov bp, 12
    mov al, PAL_PANEL2
    call fill_rect

    mov bx, 76
    mov dx, 182
    mov cx, 176
    mov bp, 16
    test byte ptr [anim_phase], 1
    jz verify_scene_prompt_base
    mov al, PAL_WHITE
    jmp verify_scene_prompt_ready

verify_scene_prompt_base:
    call get_verify_scene_accent_color

verify_scene_prompt_ready:
    call draw_rect_outline

    mov bx, 88
    mov dx, 188
    mov si, offset verify_prompt
    test byte ptr [anim_phase], 1
    jz verify_scene_prompt_dim
    mov ah, PAL_WHITE
    jmp verify_scene_prompt_text_ready

verify_scene_prompt_dim:
    mov ah, PAL_AMBER

verify_scene_prompt_text_ready:
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

get_runtime_verify_fail_reason_ptr:
    mov al, [verify_fail_reason]
    cmp al, VERIFY_FAIL_REASON_TIMEOUT
    je verify_scene_reason_timeout
    cmp al, VERIFY_FAIL_REASON_EARLY_END
    je verify_scene_reason_early_end
    mov si, offset verify_line_2
    ret

verify_scene_reason_timeout:
    mov si, offset verify_reason_timeout_text
    ret

verify_scene_reason_early_end:
    mov si, offset verify_reason_early_end_text
    ret

draw_verify_word_bits:
    push ax
    push bx
    push cx
    push dx
    push si
    push di
    push bp
    push ax
    mov [text_cursor_x], bx
    mov [text_cursor_y], dx
    mov cx, (VERIFY_BIT_PITCH * 15) + VERIFY_BIT_SIZE
    mov bp, VERIFY_BIT_SIZE
    mov al, PAL_BG0
    call fill_rect
    pop si
    mov di, 16

verify_word_bits_loop:
    mov bx, [text_cursor_x]
    mov dx, [text_cursor_y]
    test si, 8000h
    jz verify_word_bits_off
    mov al, PAL_WHITE
    jmp verify_word_bits_color_ready

verify_word_bits_off:
    mov al, PAL_BG0

verify_word_bits_color_ready:
    mov cx, VERIFY_BIT_SIZE
    mov bp, VERIFY_BIT_SIZE
    call fill_rect
    add word ptr [text_cursor_x], VERIFY_BIT_PITCH
    shl si, 1
    dec di
    jne verify_word_bits_loop

    pop bp
    pop di
    pop si
    pop dx
    pop cx
    pop bx
    pop ax
    ret

draw_title_demo_arm_badge:
    ; Once the title has been idle for a while, arm the attract demo visually
    ; before the handoff so the player can read the coming transition.
    cmp byte ptr [menu_idle_ticks], TITLE_BADGE_DELAY
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
