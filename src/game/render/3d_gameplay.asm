game3d_mark_room_dirty:
    mov byte ptr [game3d_room_dirty], 1
    ret

game3d_reset_room_state:
    mov byte ptr [game3d_room_dirty], 1
    mov byte ptr [game3d_room_overflow], 0
    mov byte ptr [game3d_room_face_count], 0
    mov word ptr [game3d_room_vertex_count], 0
    call game3d_reset_shot_state
    call game3d_sync_camera_facing
    ret

game3d_sync_camera_facing:
    mov byte ptr [game3d_camera_heading], GAME3D_HEADING_EAST
    mov byte ptr [game3d_room_variant], GAME3D_ROOM_VARIANT_NORTHWEST
    mov al, GAME3D_HEADING_EAST
    call game3d_get_heading_target_yaw
    mov [game3d_camera_yaw_current], al
    mov [game3d_camera_yaw_target], al
    ret

game3d_clear_active_shot:
    mov byte ptr [game3d_shot_mode], GAME3D_SHOT_BASE_CHASE
    mov byte ptr [game3d_shot_reason], GAME3D_SHOT_REASON_NONE
    mov byte ptr [game3d_shot_tick], 0
    mov byte ptr [game3d_shot_duration], 0
    mov byte ptr [game3d_shot_frame_variant], GAME3D_FRAME_VARIANT_NONE
    mov al, [player_x]
    mov [game3d_shot_subject_x], al
    mov al, [player_y]
    mov [game3d_shot_subject_y], al
    ret

game3d_reset_shot_state:
    call game3d_clear_active_shot
    mov byte ptr [game3d_end_state_pending], 0
    mov byte ptr [game3d_last_threat_level], THREAT_NONE
    ret

game3d_get_shot_duration:
    cmp al, GAME3D_SHOT_MOVE_SETTLE
    je game3d_shot_duration_move
    cmp al, GAME3D_SHOT_SECTOR_ENTRY
    je game3d_shot_duration_sector
    cmp al, GAME3D_SHOT_ENEMY_REVEAL
    je game3d_shot_duration_reveal
    cmp al, GAME3D_SHOT_INTERACTION
    je game3d_shot_duration_interaction
    cmp al, GAME3D_SHOT_WARDEN_PRESSURE
    je game3d_shot_duration_warden
    cmp al, GAME3D_SHOT_END_BEAT
    je game3d_shot_duration_end
    xor al, al
    ret

game3d_shot_duration_move:
    mov al, GAME3D_SHOT_MOVE_IN + GAME3D_SHOT_MOVE_HOLD + GAME3D_SHOT_MOVE_OUT
    ret

game3d_shot_duration_sector:
    mov al, GAME3D_SHOT_SECTOR_HOLD + GAME3D_SHOT_SECTOR_OUT
    ret

game3d_shot_duration_reveal:
    mov al, GAME3D_SHOT_REVEAL_IN + GAME3D_SHOT_REVEAL_HOLD + GAME3D_SHOT_REVEAL_OUT
    ret

game3d_shot_duration_interaction:
    mov al, GAME3D_SHOT_INTERACTION_IN + GAME3D_SHOT_INTERACTION_HOLD + GAME3D_SHOT_INTERACTION_OUT
    ret

game3d_shot_duration_warden:
    mov al, GAME3D_SHOT_WARDEN_IN + GAME3D_SHOT_WARDEN_HOLD + GAME3D_SHOT_WARDEN_OUT
    ret

game3d_shot_duration_end:
    mov al, GAME3D_SHOT_END_IN + GAME3D_SHOT_END_HOLD
    ret

game3d_get_shot_primary_frame_variant:
    cmp al, GAME3D_SHOT_MOVE_SETTLE
    je game3d_shot_frame_rail
    cmp al, GAME3D_SHOT_SECTOR_ENTRY
    je game3d_shot_frame_landmark
    cmp al, GAME3D_SHOT_ENEMY_REVEAL
    je game3d_shot_frame_door
    cmp al, GAME3D_SHOT_INTERACTION
    je game3d_shot_frame_door
    cmp al, GAME3D_SHOT_WARDEN_PRESSURE
    je game3d_shot_frame_ceiling
    cmp al, GAME3D_SHOT_END_BEAT
    je game3d_shot_frame_landmark
    mov al, GAME3D_FRAME_VARIANT_NONE
    ret

game3d_shot_frame_rail:
    mov al, GAME3D_FRAME_VARIANT_RAIL
    ret

game3d_shot_frame_door:
    mov al, GAME3D_FRAME_VARIANT_DOOR
    ret

game3d_shot_frame_ceiling:
    mov al, GAME3D_FRAME_VARIANT_CEILING
    ret

game3d_shot_frame_landmark:
    mov al, GAME3D_FRAME_VARIANT_LANDMARK
    ret

game3d_begin_shot:
    push ax
    push bx
    push dx
    cmp byte ptr [game3d_end_state_pending], 0
    je game3d_begin_shot_live
    cmp al, GAME3D_SHOT_END_BEAT
    jne game3d_begin_shot_done

game3d_begin_shot_live:
    mov dl, al
    mov dh, ah
    mov al, dl
    call game3d_get_shot_duration
    mov [game3d_shot_duration], al
    mov [game3d_shot_mode], dl
    mov [game3d_shot_reason], dh
    mov byte ptr [game3d_shot_tick], 0
    mov [game3d_shot_subject_x], bl
    mov [game3d_shot_subject_y], bh
    mov al, dl
    call game3d_get_shot_primary_frame_variant
    mov [game3d_shot_frame_variant], al
    call game3d_mark_room_dirty

game3d_begin_shot_done:
    pop dx
    pop bx
    pop ax
    ret

game3d_start_move_settle_shot:
IF DEBUG_LEGACY_GAMEPLAY EQ 0
    ret
ENDIF
    cmp byte ptr [game3d_end_state_pending], 0
    jne game3d_start_move_settle_done
    mov al, [game3d_shot_mode]
    cmp al, GAME3D_SHOT_MOVE_SETTLE
    ja game3d_start_move_settle_done
    mov al, GAME3D_SHOT_MOVE_SETTLE
    mov ah, GAME3D_SHOT_REASON_MOVE
    mov bl, [player_x]
    mov bh, [player_y]
    call game3d_begin_shot

game3d_start_move_settle_done:
    ret

game3d_start_sector_entry_shot:
    mov al, GAME3D_SHOT_SECTOR_ENTRY
    mov ah, GAME3D_SHOT_REASON_SECTOR
    mov bl, MAP_W / 2
    mov bh, MAP_H / 2
    call game3d_begin_shot
    ret

game3d_start_enemy_reveal_shot:
IF DEBUG_LEGACY_GAMEPLAY EQ 0
    ret
ENDIF
    cmp byte ptr [threat_level], THREAT_NONE
    je game3d_start_enemy_reveal_done
    mov al, [game3d_shot_mode]
    cmp al, GAME3D_SHOT_SECTOR_ENTRY
    je game3d_start_enemy_reveal_done
    cmp al, GAME3D_SHOT_INTERACTION
    je game3d_start_enemy_reveal_done
    cmp byte ptr [threat_level], THREAT_ELITE
    je game3d_start_enemy_reveal_done
    mov al, GAME3D_SHOT_ENEMY_REVEAL
    mov ah, GAME3D_SHOT_REASON_REVEAL
    mov bl, [threat_x]
    mov bh, [threat_y]
    call game3d_begin_shot

game3d_start_enemy_reveal_done:
    ret

game3d_start_terminal_shot:
IF DEBUG_LEGACY_GAMEPLAY EQ 0
    ret
ENDIF
    mov al, GAME3D_SHOT_INTERACTION
    mov ah, GAME3D_SHOT_REASON_TERMINAL
    call game3d_begin_shot
    ret

game3d_start_gate_unlock_shot:
IF DEBUG_LEGACY_GAMEPLAY EQ 0
    ret
ENDIF
    mov al, GAME3D_SHOT_INTERACTION
    mov ah, GAME3D_SHOT_REASON_GATE
    mov bl, [exit_x]
    mov bh, [exit_y]
    call game3d_begin_shot
    ret

game3d_start_warden_pressure_shot:
IF DEBUG_LEGACY_GAMEPLAY EQ 0
    ret
ENDIF
    cmp byte ptr [threat_level], THREAT_ELITE
    jne game3d_start_warden_pressure_done
    mov al, GAME3D_SHOT_WARDEN_PRESSURE
    mov ah, GAME3D_SHOT_REASON_WARDEN
    mov bl, [threat_x]
    mov bh, [threat_y]
    call game3d_begin_shot

game3d_start_warden_pressure_done:
    ret

game3d_note_pressure_change:
IF DEBUG_LEGACY_GAMEPLAY EQ 0
    mov al, [threat_level]
    mov [game3d_last_threat_level], al
    ret
ENDIF
    mov al, [threat_level]
    cmp al, [game3d_last_threat_level]
    je game3d_note_pressure_done
    mov [game3d_last_threat_level], al
    cmp al, THREAT_ELITE
    je game3d_note_pressure_warden
    cmp al, THREAT_NONE
    je game3d_note_pressure_done
    call game3d_start_enemy_reveal_shot
    jmp game3d_note_pressure_done

game3d_note_pressure_warden:
    call game3d_start_warden_pressure_shot

game3d_note_pressure_done:
    ret

game3d_start_endbeat_shot:
    cmp byte ptr [game3d_end_state_pending], 0
    jne game3d_start_endbeat_done
    mov [game3d_end_state_pending], al
    mov ah, GAME3D_SHOT_REASON_WIN
    cmp al, STATE_WIN
    je game3d_start_endbeat_reason_ready
    mov ah, GAME3D_SHOT_REASON_LOSE

game3d_start_endbeat_reason_ready:
    mov al, GAME3D_SHOT_END_BEAT
    mov bl, [player_x]
    mov bh, [player_y]
    call game3d_begin_shot

game3d_start_endbeat_done:
    ret

game3d_update_shot_state:
    cmp byte ptr [game_state], STATE_PLAYING
    je game3d_update_shot_live
    ret

game3d_update_shot_live:
    cmp byte ptr [game3d_shot_mode], GAME3D_SHOT_BASE_CHASE
    jne game3d_update_shot_tick
    cmp byte ptr [game3d_end_state_pending], 0
    jne game3d_update_shot_pending_done
    ret

game3d_update_shot_pending_done:
    ret

game3d_update_shot_tick:
    cmp byte ptr [game3d_shot_tick], 255
    je game3d_update_shot_eval
    inc byte ptr [game3d_shot_tick]

game3d_update_shot_eval:
    mov al, [game3d_shot_tick]
    cmp al, [game3d_shot_duration]
    jb game3d_update_shot_done
    cmp byte ptr [game3d_end_state_pending], 0
    je game3d_update_shot_clear
    mov al, [game3d_end_state_pending]
    mov byte ptr [game3d_end_state_pending], 0
    call game3d_clear_active_shot
    mov [game_state], al
    ret

game3d_update_shot_clear:
    call game3d_clear_active_shot
    call game3d_mark_room_dirty

game3d_update_shot_done:
    ret

game3d_get_facing_yaw:
    cmp byte ptr [last_player_dx], 0
    jg game3d_return_yaw_east
    jl game3d_return_yaw_west
    cmp byte ptr [last_player_dy], 0
    jg game3d_return_yaw_south
    jl game3d_return_yaw_north
    mov al, GAME3D_YAW_DEFAULT
    ret

game3d_return_yaw_east:
    mov al, GAME3D_YAW_EAST
    ret

game3d_return_yaw_west:
    mov al, GAME3D_YAW_WEST
    ret

game3d_return_yaw_south:
    mov al, GAME3D_YAW_SOUTH
    ret

game3d_return_yaw_north:
    mov al, GAME3D_YAW_NORTH
    ret

game3d_get_facing_heading:
    cmp byte ptr [last_player_dx], 0
    jg game3d_return_heading_east
    jl game3d_return_heading_west
    cmp byte ptr [last_player_dy], 0
    jg game3d_return_heading_south
    jl game3d_return_heading_north
    mov al, GAME3D_HEADING_EAST
    ret

game3d_return_heading_east:
    mov al, GAME3D_HEADING_EAST
    ret

game3d_return_heading_west:
    mov al, GAME3D_HEADING_WEST
    ret

game3d_return_heading_south:
    mov al, GAME3D_HEADING_SOUTH
    ret

game3d_return_heading_north:
    mov al, GAME3D_HEADING_NORTH
    ret

game3d_get_room_variant_from_heading:
    cmp al, GAME3D_HEADING_NORTH
    je game3d_room_variant_heading_southwest
    cmp al, GAME3D_HEADING_EAST
    je game3d_room_variant_heading_northwest
    cmp al, GAME3D_HEADING_SOUTH
    je game3d_room_variant_heading_northeast
    mov al, GAME3D_ROOM_VARIANT_SOUTHEAST
    ret

game3d_room_variant_heading_southwest:
    mov al, GAME3D_ROOM_VARIANT_SOUTHWEST
    ret

game3d_room_variant_heading_northwest:
    mov al, GAME3D_ROOM_VARIANT_NORTHWEST
    ret

game3d_room_variant_heading_northeast:
    mov al, GAME3D_ROOM_VARIANT_NORTHEAST
    ret

game3d_get_heading_target_yaw:
    push bx
    mov dl, al
    call game3d_get_kit_index
    xor ah, ah
    mov bx, ax
    mov al, dl
    cmp al, GAME3D_HEADING_NORTH
    je game3d_heading_target_yaw_north
    cmp al, GAME3D_HEADING_SOUTH
    je game3d_heading_target_yaw_south
    cmp al, GAME3D_HEADING_WEST
    je game3d_heading_target_yaw_west
    mov al, cs:[game3d_kit_heading_east_yaw_table + bx]
    jmp game3d_heading_target_yaw_done

game3d_heading_target_yaw_north:
    mov al, cs:[game3d_kit_heading_north_yaw_table + bx]
    jmp game3d_heading_target_yaw_done

game3d_heading_target_yaw_south:
    mov al, cs:[game3d_kit_heading_south_yaw_table + bx]
    jmp game3d_heading_target_yaw_done

game3d_heading_target_yaw_west:
    mov al, cs:[game3d_kit_heading_west_yaw_table + bx]

game3d_heading_target_yaw_done:
    pop bx
    ret

game3d_update_camera_target:
    push bx
    call game3d_get_facing_heading
    mov bl, al
    cmp bl, [game3d_camera_heading]
    je game3d_update_camera_target_done
    mov [game3d_camera_heading], bl
    mov al, bl
    call game3d_get_heading_target_yaw
    mov [game3d_camera_yaw_target], al
    mov al, bl
    call game3d_get_room_variant_from_heading
    cmp al, [game3d_room_variant]
    je game3d_update_camera_target_done
    mov [game3d_room_variant], al
    call game3d_mark_room_dirty

game3d_update_camera_target_done:
    pop bx
    ret

game3d_ease_camera_yaw:
    push bx
    push dx
    mov dl, [game3d_camera_yaw_target]
    mov al, [game3d_camera_yaw_current]
    mov bl, dl
    sub bl, al
    je game3d_ease_camera_yaw_done
    mov al, bl
    cbw
    call game3d_abs_ax
    cmp ax, GAME3D_CAMERA_STEP
    jbe game3d_ease_camera_yaw_snap
    test bl, 80h
    jnz game3d_ease_camera_yaw_negative
    mov al, [game3d_camera_yaw_current]
    add al, GAME3D_CAMERA_STEP
    mov [game3d_camera_yaw_current], al
    jmp game3d_ease_camera_yaw_done

game3d_ease_camera_yaw_negative:
    mov al, [game3d_camera_yaw_current]
    sub al, GAME3D_CAMERA_STEP
    mov [game3d_camera_yaw_current], al
    jmp game3d_ease_camera_yaw_done

game3d_ease_camera_yaw_snap:
    mov [game3d_camera_yaw_current], dl

game3d_ease_camera_yaw_done:
    pop dx
    pop bx
    ret

render_gameplay_3d:
IF DEBUG_LEGACY_GAMEPLAY EQ 0
    jmp render_gameplay_adventure_3d
ENDIF
IF DEBUG_RUNTIME_VERIFY
    cmp byte ptr [demo_active], 0
    je render_gameplay_3d_live
    cmp byte ptr [verify_mode], VERIFY_MODE_REPLAY
    jne render_gameplay_3d_live
    call game3d_update_camera_target
    call game3d_setup_camera
    ret

render_gameplay_3d_live:
ENDIF
    call game3d_update_camera_target
IF DEBUG_RENDER_STAGE GE 0
    call game3d_draw_view_backdrop
ENDIF
IF DEBUG_RENDER_STAGE GE 1
    call game3d_build_room_if_dirty
    call game3d_setup_camera
    call game3d_render_room
ENDIF
IF DEBUG_RENDER_STAGE GE 2
    call render_gameplay_landmark_3d
    call render_gameplay_props_3d
ENDIF
IF DEBUG_RENDER_STAGE GE 4
    call render_gameplay_world_effects_3d
ENDIF
IF DEBUG_RENDER_STAGE GE 3
    call render_enemies_3d
    call render_player_3d
ENDIF
IF DEBUG_RENDER_STAGE GE 5
    call render_gameplay_overlay_effects_3d
ENDIF
    ret

render_gameplay_adventure_3d:
    push cs
    pop ds
IF DEBUG_RENDER_SENTINELS
    mov bx, 0
    mov dx, 20
    mov al, PAL_WHITE
    call draw_debug_render_sentinel_vga
ENDIF
    call game3d_update_adventure_camera_target
IF DEBUG_RENDER_SENTINELS
    mov bx, 8
    mov dx, 20
    mov al, PAL_CYAN
    call draw_debug_render_sentinel_vga
ENDIF
IF DEBUG_RUNTIME_VERIFY
    ; Replay verification only cares about the deterministic gameplay result and
    ; the final PASS/FAIL scene, so keep demo playback on a cheap backdrop pass.
    cmp byte ptr [demo_active], 0
    je render_gameplay_adventure_live
    cmp byte ptr [verify_mode], VERIFY_MODE_REPLAY
    jne render_gameplay_adventure_live
IF DEBUG_RENDER_STAGE GE 0
    call game3d_draw_view_backdrop
IF DEBUG_RENDER_SENTINELS
    mov bx, 16
    mov dx, 20
    mov al, PAL_AMBER
    call draw_debug_render_sentinel_vga
ENDIF
ENDIF
    ret

render_gameplay_adventure_live:
ENDIF
IF DEBUG_RENDER_STAGE GE 0
    call game3d_draw_view_backdrop
IF DEBUG_RENDER_SENTINELS
    mov bx, 16
    mov dx, 20
    mov al, PAL_AMBER
    call draw_debug_render_sentinel_vga
ENDIF
ENDIF
IF DEBUG_RENDER_STAGE GE 1
    call game3d_build_room_if_dirty
IF DEBUG_RENDER_SENTINELS
    mov bx, 24
    mov dx, 20
    mov al, PAL_CYAN2
    call draw_debug_render_sentinel_vga
    mov bx, 246
    mov dx, GAME_HUD_MESSAGE_Y + 2
    mov al, PAL_CYAN2
    call draw_debug_render_sentinel_backbuffer
ENDIF
    call game3d_setup_adventure_camera
IF DEBUG_RENDER_SENTINELS
    mov bx, 32
    mov dx, 20
    mov al, PAL_WHITE
    call draw_debug_render_sentinel_vga
    mov bx, 254
    mov dx, GAME_HUD_MESSAGE_Y + 2
    mov al, PAL_WHITE
    call draw_debug_render_sentinel_backbuffer
ENDIF
    call game3d_render_room
IF DEBUG_RENDER_SENTINELS
    mov bx, 40
    mov dx, 20
    mov al, PAL_AMBER
    call draw_debug_render_sentinel_vga
    mov bx, 262
    mov dx, GAME_HUD_MESSAGE_Y + 2
    mov al, PAL_AMBER
    call draw_debug_render_sentinel_backbuffer
ENDIF
ENDIF
IF DEBUG_RENDER_STAGE GE 2
    call render_gameplay_landmark_3d
    call render_adventure_static_props_3d
    call render_gameplay_props_3d
ENDIF
IF DEBUG_RENDER_STAGE GE 4
    call render_adventure_world_effects_3d
ENDIF
IF DEBUG_RENDER_STAGE GE 3
    call render_enemies_3d
    call render_adventure_player_3d
ENDIF
IF DEBUG_RENDER_STAGE GE 5
    call render_gameplay_overlay_effects_3d
ENDIF
IF DEBUG_RUNTIME_VERIFY
    cmp byte ptr [verify_mode], VERIFY_MODE_REPLAY
    jne render_gameplay_adventure_done

render_gameplay_adventure_done:
ENDIF
    ret

draw_debug_render_sentinel_backbuffer:
IF DEBUG_RENDER_SENTINELS
    push ax
    push bx
    push cx
    push dx
    push bp
    mov cx, SMOKE_SENTINEL_W
    mov bp, SMOKE_SENTINEL_H
    call fill_rect
    pop bp
    pop dx
    pop cx
    pop bx
    pop ax
ENDIF
    ret

game3d_update_adventure_camera_target:
    push bx
    mov al, [adventure_player_yaw]
    mov [game3d_camera_yaw_current], al
    mov [game3d_camera_yaw_target], al
    call game3d_get_adventure_heading_from_yaw
    mov bl, al
    cmp bl, [game3d_camera_heading]
    je game3d_update_adventure_variant
    mov [game3d_camera_heading], bl

game3d_update_adventure_variant:
    mov al, bl
    call game3d_get_room_variant_from_heading
    cmp al, [game3d_room_variant]
    je game3d_update_adventure_done
    mov [game3d_room_variant], al
    call game3d_mark_room_dirty

game3d_update_adventure_done:
    pop bx
    ret

game3d_get_adventure_heading_from_yaw:
    cmp al, 32
    jb game3d_adventure_heading_south
    cmp al, 96
    jb game3d_adventure_heading_east
    cmp al, 160
    jb game3d_adventure_heading_north
    cmp al, 224
    jb game3d_adventure_heading_west

game3d_adventure_heading_south:
    mov al, GAME3D_HEADING_SOUTH
    ret

game3d_adventure_heading_east:
    mov al, GAME3D_HEADING_EAST
    ret

game3d_adventure_heading_north:
    mov al, GAME3D_HEADING_NORTH
    ret

game3d_adventure_heading_west:
    mov al, GAME3D_HEADING_WEST
    ret

game3d_setup_adventure_camera:
    push ax
    push bx
    push cx
    push dx

    mov word ptr [scene3d_clip_left], GAME3D_VIEW_X
    mov word ptr [scene3d_clip_top], GAME3D_VIEW_Y
    mov word ptr [scene3d_clip_right], GAME3D_VIEW_X + GAME3D_VIEW_W - 1
    mov word ptr [scene3d_clip_bottom], GAME3D_VIEW_Y + GAME3D_VIEW_H - 1
    mov word ptr [scene3d_center_x], GAME3D_VIEW_X + (GAME3D_VIEW_W / 2)
    call game3d_get_horizon_y
    xor ah, ah
    add ax, GAME3D_VIEW_Y + GAME3D_CAMERA_HORIZON_CENTER_OFFSET
    mov [scene3d_center_y], ax
    call game3d_get_projection_scale
    mov [scene3d_project_scale], ax
    call game3d_get_projection_pitch
    mov [scene3d_pitch_angle], al
    mov al, [adventure_player_yaw]
    mov [scene3d_yaw_angle], al

    mov ax, [adventure_player_world_x]
    mov [scene3d_temp_v], ax
    mov ax, [adventure_player_world_z]
    mov [scene3d_temp_l], ax

    call game3d_get_camera_look_ahead
    mov [scene3d_temp_r], ax
    mov al, [scene3d_yaw_angle]
    call scene3d_get_sin_cos
    mov ax, [scene3d_temp_r]
    call scene3d_mul_ax_bx_fixed
    add [scene3d_temp_v], ax
    mov ax, [scene3d_temp_r]
    mov bx, dx
    call scene3d_mul_ax_bx_fixed
    add [scene3d_temp_l], ax

    mov al, [scene3d_yaw_angle]
    call scene3d_get_sin_cos

    call game3d_get_camera_distance
    call scene3d_mul_ax_bx_fixed
    mov cx, ax
    mov ax, [scene3d_temp_v]
    sub ax, cx
    mov [scene3d_cam_x], ax

    call game3d_get_camera_distance
    mov bx, dx
    call scene3d_mul_ax_bx_fixed
    mov cx, ax
    mov ax, [scene3d_temp_l]
    sub ax, cx
    mov [scene3d_cam_z], ax

    call game3d_get_camera_height
    mov [scene3d_cam_y], ax

    call game3d_get_shot_blend
    mov ax, cx
    or ax, ax
    jz game3d_setup_adventure_done

    call game3d_get_active_shot_horizon
    xor ah, ah
    add ax, GAME3D_VIEW_Y + GAME3D_CAMERA_HORIZON_CENTER_OFFSET
    mov [scene3d_temp_s], ax
    call game3d_get_active_shot_project_scale
    mov [scene3d_temp_r], ax
    call game3d_get_active_shot_pitch
    xor ah, ah
    mov [scene3d_temp_w], ax

    mov bl, [game3d_shot_subject_x]
    mov bh, [game3d_shot_subject_y]
    call game3d_get_tile_center_world
    mov [scene3d_temp_v], ax
    mov [scene3d_temp_l], dx
    call game3d_get_active_shot_look_ahead
    mov bx, ax
    mov ax, [scene3d_temp_v]
    mov dx, [scene3d_temp_l]
    call game3d_apply_look_ahead_to_focus
    mov [scene3d_temp_v], ax
    mov [scene3d_temp_l], dx
    call game3d_get_active_shot_focus_bias_x
    add [scene3d_temp_v], ax
    call game3d_get_active_shot_focus_bias_z
    add [scene3d_temp_l], ax

    mov al, [scene3d_yaw_angle]
    call scene3d_get_sin_cos

    call game3d_get_active_shot_distance
    call scene3d_mul_ax_bx_fixed
    mov dx, ax
    mov ax, [scene3d_temp_v]
    sub ax, dx
    mov [scene3d_temp_x], ax

    call game3d_get_active_shot_distance
    mov bx, dx
    call scene3d_mul_ax_bx_fixed
    mov dx, ax
    mov ax, [scene3d_temp_l]
    sub ax, dx
    mov [scene3d_temp_y], ax

    call game3d_get_active_shot_height
    mov [scene3d_temp_z], ax

    mov ax, [scene3d_center_y]
    mov dx, [scene3d_temp_s]
    call game3d_blend_word
    mov [scene3d_center_y], ax
    mov ax, [scene3d_project_scale]
    mov dx, [scene3d_temp_r]
    call game3d_blend_word
    mov [scene3d_project_scale], ax
    xor ah, ah
    mov al, [scene3d_pitch_angle]
    mov dx, [scene3d_temp_w]
    call game3d_blend_word
    mov [scene3d_pitch_angle], al
    mov ax, [scene3d_cam_x]
    mov dx, [scene3d_temp_x]
    call game3d_blend_word
    mov [scene3d_cam_x], ax
    mov ax, [scene3d_cam_z]
    mov dx, [scene3d_temp_y]
    call game3d_blend_word
    mov [scene3d_cam_z], ax
    mov ax, [scene3d_cam_y]
    mov dx, [scene3d_temp_z]
    call game3d_blend_word
    mov [scene3d_cam_y], ax
    call game3d_apply_camera_kick

game3d_setup_adventure_done:
    pop dx
    pop cx
    pop bx
    pop ax
    ret

game3d_build_room_if_dirty:
    cmp byte ptr [game3d_room_dirty], 0
    je game3d_build_room_done
    call game3d_compile_room_mesh
    mov byte ptr [game3d_room_dirty], 0

game3d_build_room_done:
    ret

game3d_apply_look_ahead_to_focus:
    cmp byte ptr [last_player_dx], 0
    je game3d_apply_look_ahead_x_done
    cmp byte ptr [last_player_dx], 0
    jg game3d_apply_look_ahead_x_apply
    neg bx

game3d_apply_look_ahead_x_apply:
    add ax, bx

game3d_apply_look_ahead_x_done:
    cmp byte ptr [last_player_dy], 0
    je game3d_apply_look_ahead_done
    mov cx, bx
    cmp byte ptr [last_player_dy], 0
    jg game3d_apply_look_ahead_z_apply
    neg cx

game3d_apply_look_ahead_z_apply:
    add dx, cx

game3d_apply_look_ahead_done:
    ret

game3d_blend_word:
    push bx
    push dx
    mov bx, ax
    sub dx, ax
    mov ax, dx
    mov dx, bx
    mov bx, cx
    call scene3d_mul_ax_bx_fixed
    add ax, dx
    pop dx
    pop bx
    ret

game3d_get_shot_blend:
    xor cx, cx
    mov al, [game3d_shot_mode]
    cmp al, GAME3D_SHOT_MOVE_SETTLE
    je game3d_shot_blend_move
    cmp al, GAME3D_SHOT_SECTOR_ENTRY
    je game3d_shot_blend_sector
    cmp al, GAME3D_SHOT_ENEMY_REVEAL
    je game3d_shot_blend_reveal
    cmp al, GAME3D_SHOT_INTERACTION
    je game3d_shot_blend_interaction
    cmp al, GAME3D_SHOT_WARDEN_PRESSURE
    je game3d_shot_blend_warden
    cmp al, GAME3D_SHOT_END_BEAT
    je game3d_shot_blend_end
    ret

game3d_shot_blend_move:
    mov al, [game3d_shot_tick]
    cmp al, 1
    je game3d_shot_blend_half
    cmp al, 4
    jb game3d_shot_blend_full_label
    cmp al, 6
    jb game3d_shot_blend_half
    ret

game3d_shot_blend_sector:
    mov al, [game3d_shot_tick]
    cmp al, GAME3D_SHOT_SECTOR_HOLD
    jbe game3d_shot_blend_full_label
    cmp al, GAME3D_SHOT_SECTOR_HOLD + 1
    je game3d_shot_blend_192
    cmp al, GAME3D_SHOT_SECTOR_HOLD + 2
    je game3d_shot_blend_half
    cmp al, GAME3D_SHOT_SECTOR_HOLD + 3
    je game3d_shot_blend_64
    ret

game3d_shot_blend_reveal:
    mov al, [game3d_shot_tick]
    cmp al, 1
    je game3d_shot_blend_85
    cmp al, 2
    je game3d_shot_blend_170
    cmp al, 9
    jb game3d_shot_blend_full_label
    cmp al, 9
    je game3d_shot_blend_170
    cmp al, 10
    je game3d_shot_blend_85
    cmp al, 11
    je game3d_shot_blend_43
    ret

game3d_shot_blend_interaction:
    mov al, [game3d_shot_tick]
    cmp al, 1
    je game3d_shot_blend_half
    cmp al, 6
    jb game3d_shot_blend_full_label
    cmp al, 6
    je game3d_shot_blend_half
    cmp al, 7
    je game3d_shot_blend_64
    ret

game3d_shot_blend_warden:
    mov al, [game3d_shot_tick]
    cmp al, 1
    je game3d_shot_blend_85
    cmp al, 2
    je game3d_shot_blend_170
    cmp al, 8
    jb game3d_shot_blend_full_label
    cmp al, 8
    je game3d_shot_blend_170
    cmp al, 9
    je game3d_shot_blend_85
    cmp al, 10
    je game3d_shot_blend_43
    ret

game3d_shot_blend_end:
    mov al, [game3d_shot_tick]
    cmp al, 1
    je game3d_shot_blend_64
    cmp al, 2
    je game3d_shot_blend_half
    cmp al, 3
    je game3d_shot_blend_192
    cmp al, 4
    jb game3d_shot_blend_done
    jmp game3d_shot_blend_full_label

game3d_shot_blend_43:
    mov cx, 43
    ret

game3d_shot_blend_64:
    mov cx, 64
    ret

game3d_shot_blend_85:
    mov cx, 85
    ret

game3d_shot_blend_half:
    mov cx, 128
    ret

game3d_shot_blend_170:
    mov cx, 170
    ret

game3d_shot_blend_192:
    mov cx, 192
    ret

game3d_shot_blend_full_label:
    mov cx, GAME3D_SHOT_BLEND_FULL

game3d_shot_blend_done:
    ret

game3d_apply_camera_kick:
    mov al, [game3d_shot_mode]
    cmp al, GAME3D_SHOT_ENEMY_REVEAL
    je game3d_camera_kick_live
    cmp al, GAME3D_SHOT_INTERACTION
    je game3d_camera_kick_live
    cmp al, GAME3D_SHOT_WARDEN_PRESSURE
    je game3d_camera_kick_live
    cmp al, GAME3D_SHOT_END_BEAT
    jne game3d_camera_kick_done

game3d_camera_kick_live:
    cmp byte ptr [game3d_shot_tick], 1
    jne game3d_camera_kick_soft
    sub word ptr [scene3d_center_y], GAME3D_CAMERA_KICK_PIXELS
    ret

game3d_camera_kick_soft:
    cmp byte ptr [game3d_shot_tick], 2
    jne game3d_camera_kick_done
    dec word ptr [scene3d_center_y]

game3d_camera_kick_done:
    ret

game3d_setup_camera:
    push ax
    push bx
    push dx
    call game3d_ease_camera_yaw
    pop dx
    pop bx
    pop ax

game3d_setup_camera_now:
    push ax
    push bx
    push cx
    push dx

    mov word ptr [scene3d_clip_left], GAME3D_VIEW_X
    mov word ptr [scene3d_clip_top], GAME3D_VIEW_Y
    mov word ptr [scene3d_clip_right], GAME3D_VIEW_X + GAME3D_VIEW_W - 1
    mov word ptr [scene3d_clip_bottom], GAME3D_VIEW_Y + GAME3D_VIEW_H - 1
    mov word ptr [scene3d_center_x], GAME3D_VIEW_X + (GAME3D_VIEW_W / 2)
    call game3d_get_horizon_y
    xor ah, ah
    add ax, GAME3D_VIEW_Y + GAME3D_CAMERA_HORIZON_CENTER_OFFSET
    mov [scene3d_center_y], ax
    call game3d_get_projection_scale
    mov [scene3d_project_scale], ax
    call game3d_get_projection_pitch
    mov [scene3d_pitch_angle], al
    mov al, [game3d_camera_yaw_current]
    mov [scene3d_yaw_angle], al

    mov bl, [player_x]
    mov bh, [player_y]
    call game3d_get_tile_center_world
    mov [scene3d_temp_v], ax
    mov [scene3d_temp_l], dx

    call game3d_get_camera_look_ahead
    mov [scene3d_temp_r], ax
    cmp byte ptr [last_player_dx], 0
    je game3d_camera_look_ahead_x_done
    mov ax, [scene3d_temp_r]
    cmp byte ptr [last_player_dx], 0
    jg game3d_camera_look_ahead_x_apply
    neg ax

game3d_camera_look_ahead_x_apply:
    add [scene3d_temp_v], ax

game3d_camera_look_ahead_x_done:
    cmp byte ptr [last_player_dy], 0
    je game3d_camera_look_ahead_done
    mov ax, [scene3d_temp_r]
    cmp byte ptr [last_player_dy], 0
    jg game3d_camera_look_ahead_z_apply
    neg ax

game3d_camera_look_ahead_z_apply:
    add [scene3d_temp_l], ax

game3d_camera_look_ahead_done:

    mov al, [scene3d_yaw_angle]
    call scene3d_get_sin_cos

    call game3d_get_camera_distance
    call scene3d_mul_ax_bx_fixed
    mov cx, ax
    mov ax, [scene3d_temp_v]
    sub ax, cx
    mov [scene3d_cam_x], ax

    call game3d_get_camera_distance
    mov bx, dx
    call scene3d_mul_ax_bx_fixed
    mov cx, ax
    mov ax, [scene3d_temp_l]
    sub ax, cx
    mov [scene3d_cam_z], ax

    call game3d_get_camera_height
    mov [scene3d_cam_y], ax

    call game3d_get_shot_blend
    mov ax, cx
    or ax, ax
    jz game3d_setup_camera_done

    call game3d_get_active_shot_horizon
    xor ah, ah
    add ax, GAME3D_VIEW_Y + GAME3D_CAMERA_HORIZON_CENTER_OFFSET
    mov [scene3d_temp_s], ax
    call game3d_get_active_shot_project_scale
    mov [scene3d_temp_r], ax
    call game3d_get_active_shot_pitch
    xor ah, ah
    mov [scene3d_temp_w], ax

    mov bl, [game3d_shot_subject_x]
    mov bh, [game3d_shot_subject_y]
    call game3d_get_tile_center_world
    mov [scene3d_temp_v], ax
    mov [scene3d_temp_l], dx
    call game3d_get_active_shot_look_ahead
    mov bx, ax
    mov ax, [scene3d_temp_v]
    mov dx, [scene3d_temp_l]
    call game3d_apply_look_ahead_to_focus
    mov [scene3d_temp_v], ax
    mov [scene3d_temp_l], dx
    call game3d_get_active_shot_focus_bias_x
    add [scene3d_temp_v], ax
    call game3d_get_active_shot_focus_bias_z
    add [scene3d_temp_l], ax

    mov al, [scene3d_yaw_angle]
    call scene3d_get_sin_cos

    call game3d_get_active_shot_distance
    call scene3d_mul_ax_bx_fixed
    mov dx, ax
    mov ax, [scene3d_temp_v]
    sub ax, dx
    mov [scene3d_temp_x], ax

    call game3d_get_active_shot_distance
    mov bx, dx
    call scene3d_mul_ax_bx_fixed
    mov dx, ax
    mov ax, [scene3d_temp_l]
    sub ax, dx
    mov [scene3d_temp_y], ax

    call game3d_get_active_shot_height
    mov [scene3d_temp_z], ax

    mov ax, [scene3d_center_y]
    mov dx, [scene3d_temp_s]
    call game3d_blend_word
    mov [scene3d_center_y], ax
    mov ax, [scene3d_project_scale]
    mov dx, [scene3d_temp_r]
    call game3d_blend_word
    mov [scene3d_project_scale], ax
    xor ah, ah
    mov al, [scene3d_pitch_angle]
    mov dx, [scene3d_temp_w]
    call game3d_blend_word
    mov [scene3d_pitch_angle], al
    mov ax, [scene3d_cam_x]
    mov dx, [scene3d_temp_x]
    call game3d_blend_word
    mov [scene3d_cam_x], ax
    mov ax, [scene3d_cam_z]
    mov dx, [scene3d_temp_y]
    call game3d_blend_word
    mov [scene3d_cam_z], ax
    mov ax, [scene3d_cam_y]
    mov dx, [scene3d_temp_z]
    call game3d_blend_word
    mov [scene3d_cam_y], ax
    call game3d_apply_camera_kick

game3d_setup_camera_done:

    pop dx
    pop cx
    pop bx
    pop ax
    ret

game3d_render_room:
    push ds
    push cs
    pop ds
    mov byte ptr [game3d_rendering_active], 1
    mov word ptr [scene3d_vertex_source], offset game3d_room_vertex_raw
    mov word ptr [scene3d_face_source], offset game3d_room_face_raw
    mov ax, [game3d_room_vertex_count]
    cmp ax, SCENE3D_MAX_VERTICES
    jbe game3d_render_room_vertex_count_ready
    mov ax, SCENE3D_MAX_VERTICES
    mov byte ptr [game3d_room_overflow], 1

game3d_render_room_vertex_count_ready:
    mov [scene3d_vertex_count], ax
    mov al, [game3d_room_face_count]
    cmp al, SCENE3D_MAX_FACES
    jbe game3d_render_room_face_count_ready
    mov al, SCENE3D_MAX_FACES
    mov byte ptr [game3d_room_overflow], 1

game3d_render_room_face_count_ready:
    mov [scene3d_face_count], al
    cmp byte ptr [scene3d_face_count], 0
    je game3d_render_room_done
IF DEBUG_RENDER_SENTINELS
    mov bx, 270
    mov dx, 178
    mov al, PAL_WHITE
    call draw_debug_render_sentinel_backbuffer
ENDIF
IF DEBUG_RENDER_ROOM_STAGE GE 1
    call scene3d_project_vertices
IF DEBUG_RENDER_SENTINELS
    mov bx, 278
    mov dx, 178
    mov al, PAL_CYAN
    call draw_debug_render_sentinel_backbuffer
ENDIF
ENDIF
IF DEBUG_RENDER_ROOM_STAGE GE 2
    call game3d_apply_room_instability
IF DEBUG_RENDER_SENTINELS
    mov bx, 286
    mov dx, 178
    mov al, PAL_CYAN2
    call draw_debug_render_sentinel_backbuffer
ENDIF
ENDIF
IF DEBUG_RENDER_ROOM_STAGE GE 3
    call scene3d_build_face_order
IF DEBUG_RENDER_SENTINELS
    mov bx, 294
    mov dx, 178
    mov al, PAL_WHITE
    call draw_debug_render_sentinel_backbuffer
ENDIF
ENDIF
IF DEBUG_RENDER_ROOM_STAGE GE 4
    call scene3d_draw_face_order
IF DEBUG_RENDER_SENTINELS
    mov bx, 302
    mov dx, 178
    mov al, PAL_AMBER
    call draw_debug_render_sentinel_backbuffer
ENDIF
ENDIF

game3d_render_room_done:
    mov byte ptr [game3d_rendering_active], 0
    pop ds
    ret

game3d_compile_room_mesh:
    mov word ptr [game3d_room_vertex_count], 0
    mov byte ptr [game3d_room_face_count], 0
    mov byte ptr [game3d_room_overflow], 0
    mov byte ptr [game3d_optional_faces_remaining], GAME3D_OPTIONAL_FACE_BUDGET
IF DEBUG_RENDER_SENTINELS
    mov bx, 0
    mov dx, 24
    mov al, PAL_WHITE
    call draw_debug_render_sentinel_vga
ENDIF
    call game3d_compile_floor_strips
IF DEBUG_RENDER_SENTINELS
    mov bx, 8
    mov dx, 24
    mov al, PAL_CYAN
    call draw_debug_render_sentinel_vga
ENDIF
    mov byte ptr [game3d_wall_emit_mode], 0
    call game3d_compile_active_wall_families
IF DEBUG_RENDER_SENTINELS
    mov bx, 16
    mov dx, 24
    mov al, PAL_AMBER
    call draw_debug_render_sentinel_vga
ENDIF
    call game3d_compile_near_occluders
IF DEBUG_RENDER_SENTINELS
    mov bx, 24
    mov dx, 24
    mov al, PAL_CYAN2
    call draw_debug_render_sentinel_vga
ENDIF
    call game3d_compile_shot_framing
IF DEBUG_RENDER_SENTINELS
    mov bx, 32
    mov dx, 24
    mov al, PAL_WHITE
    call draw_debug_render_sentinel_vga
ENDIF
    call game3d_compile_gate_frame
IF DEBUG_RENDER_SENTINELS
    mov bx, 40
    mov dx, 24
    mov al, PAL_CYAN
    call draw_debug_render_sentinel_vga
ENDIF
    call game3d_compile_gate_lane_strips
    call game3d_compile_interactable_frames
IF DEBUG_RENDER_SENTINELS
    mov bx, 48
    mov dx, 24
    mov al, PAL_AMBER
    call draw_debug_render_sentinel_vga
ENDIF
    call game3d_compile_shot_far_mass
IF DEBUG_RENDER_SENTINELS
    mov bx, 56
    mov dx, 24
    mov al, PAL_CYAN2
    call draw_debug_render_sentinel_vga
ENDIF
    cmp byte ptr [game3d_shot_mode], GAME3D_SHOT_BASE_CHASE
    jne game3d_compile_room_skip_classic_far
    call game3d_compile_far_silhouette

game3d_compile_room_skip_classic_far:
    cmp byte ptr [game3d_shot_mode], GAME3D_SHOT_BASE_CHASE
    jne game3d_compile_room_skip_trim
    call game3d_compile_floor_trim_strips

game3d_compile_room_skip_trim:
    mov byte ptr [game3d_wall_emit_mode], 1
    call game3d_compile_active_wall_families
    ret

game3d_draw_view_backdrop:
    push ax
    push bx
    push cx
    push dx
    push bp

    call game3d_get_horizon_y
    xor ah, ah
    mov [scene3d_temp_s], ax
    mov bx, GAME3D_VIEW_X
    mov dx, GAME3D_VIEW_Y
    mov cx, GAME3D_VIEW_W
    mov bp, GAME3D_VIEW_H
    call game3d_get_backdrop_far_color
    call fill_rect

    mov bx, GAME3D_VIEW_X
    mov ax, [scene3d_temp_s]
    add ax, GAME3D_VIEW_Y + 8
    sub ax, 16
    mov dx, ax
    mov cx, GAME3D_VIEW_W
    mov bp, 18
    call game3d_get_backdrop_mid_color
    call fill_rect

    mov bx, GAME3D_VIEW_X
    mov ax, [scene3d_temp_s]
    add ax, GAME3D_VIEW_Y + 18
    mov dx, ax
    mov cx, GAME3D_VIEW_W
    mov ax, GAME3D_VIEW_H - 18
    sub ax, [scene3d_temp_s]
    mov bp, ax
    call game3d_get_backdrop_near_color
    call fill_rect

    mov bx, GAME3D_VIEW_X + 12
    mov ax, [scene3d_temp_s]
    add ax, GAME3D_VIEW_Y
    mov dx, ax
    mov cx, GAME3D_VIEW_W - 24
    mov bp, 1
    call game3d_get_horizon_a_color
    call fill_rect

    mov bx, GAME3D_VIEW_X + 28
    mov ax, [scene3d_temp_s]
    add ax, GAME3D_VIEW_Y + 34
    mov dx, ax
    mov cx, GAME3D_VIEW_W - 56
    mov bp, 1
    call game3d_get_horizon_b_color
    call fill_rect

game3d_view_backdrop_done:
    pop bp
    pop dx
    pop cx
    pop bx
    pop ax
    ret

game3d_chunk_intersects_active_range:
    mov al, [adventure_realm_chunk_max_x_table + si]
    cmp al, [adventure_chunk_min_x]
    jb game3d_chunk_range_no
    mov al, [adventure_realm_chunk_min_x_table + si]
    cmp al, [adventure_chunk_max_x]
    ja game3d_chunk_range_no
    mov al, [adventure_realm_chunk_max_y_table + si]
    cmp al, [adventure_chunk_min_y]
    jb game3d_chunk_range_no
    mov al, [adventure_realm_chunk_min_y_table + si]
    cmp al, [adventure_chunk_max_y]
    ja game3d_chunk_range_no
    mov al, 1
    ret

game3d_chunk_range_no:
    xor al, al
    ret

game3d_emit_chunk_base_floor:
    push ax
    push bx
    push dx
    mov al, [adventure_realm_chunk_min_x_table + si]
    call game3d_world_x_edge_from_al
    mov [scene3d_temp_x], ax
    mov al, [adventure_realm_chunk_max_x_table + si]
    inc al
    call game3d_world_x_edge_from_al
    mov [scene3d_temp_y], ax
    mov bx, si
    shl bx, 1
    mov ax, [adventure_realm_chunk_base_height_table + bx]
    add ax, GAME3D_FLOOR_Y
    mov [scene3d_temp_z], ax
    mov [scene3d_temp_u], ax
    mov al, [adventure_realm_chunk_min_y_table + si]
    call game3d_world_z_edge_from_al
    mov [scene3d_temp_v], ax
    mov al, [adventure_realm_chunk_max_y_table + si]
    inc al
    call game3d_world_z_edge_from_al
    mov [scene3d_temp_w], ax
    call game3d_get_floor_base_material
    mov byte ptr [scene3d_temp_face], GAME3D_FACE_FLAG_NONE
    call game3d_emit_quad_from_temps
    pop dx
    pop bx
    pop ax
    ret

game3d_emit_chunk_step_face:
    push ax
    push bx
    push cx
    push dx
    mov bx, si
    shl bx, 1
    mov dx, [adventure_realm_chunk_base_height_table + bx]
    mov cx, [adventure_realm_chunk_shelf_height_table + bx]
    cmp cx, dx
    jbe game3d_chunk_step_done
    mov al, [adventure_realm_chunk_bridge_span_table + si]
    cmp al, ADVENTURE_BRIDGE_NONE
    jne game3d_chunk_step_done
    mov al, [adventure_realm_chunk_ramp_dir_table + si]
    cmp al, ADVENTURE_DIR_NONE
    je game3d_chunk_step_done
    add dx, GAME3D_FLOOR_Y
    add cx, GAME3D_FLOOR_Y
    mov [scene3d_temp_z], dx
    mov [scene3d_temp_u], cx
    cmp al, ADVENTURE_DIR_EAST
    je game3d_chunk_step_east
    cmp al, ADVENTURE_DIR_WEST
    je game3d_chunk_step_west
    cmp al, ADVENTURE_DIR_NORTH
    je game3d_chunk_step_north
    mov al, [adventure_realm_chunk_min_y_table + si]
    add al, [adventure_realm_chunk_max_y_table + si]
    shr al, 1
    call game3d_world_z_edge_from_al
    mov [scene3d_temp_v], ax
    mov [scene3d_temp_w], ax
    mov al, [adventure_realm_chunk_min_x_table + si]
    call game3d_world_x_edge_from_al
    mov [scene3d_temp_x], ax
    mov al, [adventure_realm_chunk_max_x_table + si]
    inc al
    call game3d_world_x_edge_from_al
    mov [scene3d_temp_y], ax
    jmp game3d_chunk_step_emit

game3d_chunk_step_north:
    mov al, [adventure_realm_chunk_min_y_table + si]
    add al, [adventure_realm_chunk_max_y_table + si]
    inc al
    shr al, 1
    call game3d_world_z_edge_from_al
    mov [scene3d_temp_v], ax
    mov [scene3d_temp_w], ax
    mov al, [adventure_realm_chunk_min_x_table + si]
    call game3d_world_x_edge_from_al
    mov [scene3d_temp_x], ax
    mov al, [adventure_realm_chunk_max_x_table + si]
    inc al
    call game3d_world_x_edge_from_al
    mov [scene3d_temp_y], ax
    jmp game3d_chunk_step_emit

game3d_chunk_step_east:
    mov al, [adventure_realm_chunk_min_x_table + si]
    add al, [adventure_realm_chunk_max_x_table + si]
    shr al, 1
    call game3d_world_x_edge_from_al
    mov [scene3d_temp_x], ax
    mov [scene3d_temp_y], ax
    mov al, [adventure_realm_chunk_min_y_table + si]
    call game3d_world_z_edge_from_al
    mov [scene3d_temp_v], ax
    mov al, [adventure_realm_chunk_max_y_table + si]
    inc al
    call game3d_world_z_edge_from_al
    mov [scene3d_temp_w], ax
    jmp game3d_chunk_step_emit

game3d_chunk_step_west:
    mov al, [adventure_realm_chunk_min_x_table + si]
    add al, [adventure_realm_chunk_max_x_table + si]
    inc al
    shr al, 1
    call game3d_world_x_edge_from_al
    mov [scene3d_temp_x], ax
    mov [scene3d_temp_y], ax
    mov al, [adventure_realm_chunk_min_y_table + si]
    call game3d_world_z_edge_from_al
    mov [scene3d_temp_v], ax
    mov al, [adventure_realm_chunk_max_y_table + si]
    inc al
    call game3d_world_z_edge_from_al
    mov [scene3d_temp_w], ax

game3d_chunk_step_emit:
    call game3d_get_cliff_material
    mov byte ptr [scene3d_temp_face], GAME3D_FACE_FLAG_WALL
    call game3d_emit_quad_from_temps

game3d_chunk_step_done:
    pop dx
    pop cx
    pop bx
    pop ax
    ret

game3d_emit_chunk_shelf_floor:
    push ax
    push bx
    push cx
    push dx
    mov bx, si
    shl bx, 1
    mov dx, [adventure_realm_chunk_base_height_table + bx]
    mov ax, [adventure_realm_chunk_shelf_height_table + bx]
    cmp ax, dx
    jbe game3d_chunk_shelf_done
    add ax, GAME3D_FLOOR_Y
    mov [scene3d_temp_z], ax
    mov [scene3d_temp_u], ax
    mov al, [adventure_realm_chunk_bridge_span_table + si]
    cmp al, ADVENTURE_BRIDGE_EAST_WEST
    je game3d_chunk_bridge_east_west
    cmp al, ADVENTURE_BRIDGE_NORTH_SOUTH
    je game3d_chunk_bridge_north_south
    mov al, [adventure_realm_chunk_ramp_dir_table + si]
    cmp al, ADVENTURE_DIR_EAST
    je game3d_chunk_shelf_east
    cmp al, ADVENTURE_DIR_WEST
    je game3d_chunk_shelf_west
    cmp al, ADVENTURE_DIR_NORTH
    je game3d_chunk_shelf_north
    cmp al, ADVENTURE_DIR_SOUTH
    je game3d_chunk_shelf_south
    mov al, [adventure_realm_chunk_min_x_table + si]
    call game3d_world_x_edge_from_al
    mov [scene3d_temp_x], ax
    mov al, [adventure_realm_chunk_max_x_table + si]
    inc al
    call game3d_world_x_edge_from_al
    mov [scene3d_temp_y], ax
    mov al, [adventure_realm_chunk_min_y_table + si]
    call game3d_world_z_edge_from_al
    mov [scene3d_temp_v], ax
    mov al, [adventure_realm_chunk_max_y_table + si]
    inc al
    call game3d_world_z_edge_from_al
    mov [scene3d_temp_w], ax
    jmp game3d_chunk_shelf_emit

game3d_chunk_shelf_east:
    mov al, [adventure_realm_chunk_min_x_table + si]
    add al, [adventure_realm_chunk_max_x_table + si]
    shr al, 1
    call game3d_world_x_edge_from_al
    mov [scene3d_temp_x], ax
    mov al, [adventure_realm_chunk_max_x_table + si]
    inc al
    call game3d_world_x_edge_from_al
    mov [scene3d_temp_y], ax
    mov al, [adventure_realm_chunk_min_y_table + si]
    call game3d_world_z_edge_from_al
    mov [scene3d_temp_v], ax
    mov al, [adventure_realm_chunk_max_y_table + si]
    inc al
    call game3d_world_z_edge_from_al
    mov [scene3d_temp_w], ax
    jmp game3d_chunk_shelf_emit

game3d_chunk_shelf_west:
    mov al, [adventure_realm_chunk_min_x_table + si]
    call game3d_world_x_edge_from_al
    mov [scene3d_temp_x], ax
    mov al, [adventure_realm_chunk_min_x_table + si]
    add al, [adventure_realm_chunk_max_x_table + si]
    inc al
    shr al, 1
    call game3d_world_x_edge_from_al
    mov [scene3d_temp_y], ax
    mov al, [adventure_realm_chunk_min_y_table + si]
    call game3d_world_z_edge_from_al
    mov [scene3d_temp_v], ax
    mov al, [adventure_realm_chunk_max_y_table + si]
    inc al
    call game3d_world_z_edge_from_al
    mov [scene3d_temp_w], ax
    jmp game3d_chunk_shelf_emit

game3d_chunk_shelf_north:
    mov al, [adventure_realm_chunk_min_x_table + si]
    call game3d_world_x_edge_from_al
    mov [scene3d_temp_x], ax
    mov al, [adventure_realm_chunk_max_x_table + si]
    inc al
    call game3d_world_x_edge_from_al
    mov [scene3d_temp_y], ax
    mov al, [adventure_realm_chunk_min_y_table + si]
    call game3d_world_z_edge_from_al
    mov [scene3d_temp_v], ax
    mov al, [adventure_realm_chunk_min_y_table + si]
    add al, [adventure_realm_chunk_max_y_table + si]
    inc al
    shr al, 1
    call game3d_world_z_edge_from_al
    mov [scene3d_temp_w], ax
    jmp game3d_chunk_shelf_emit

game3d_chunk_shelf_south:
    mov al, [adventure_realm_chunk_min_x_table + si]
    call game3d_world_x_edge_from_al
    mov [scene3d_temp_x], ax
    mov al, [adventure_realm_chunk_max_x_table + si]
    inc al
    call game3d_world_x_edge_from_al
    mov [scene3d_temp_y], ax
    mov al, [adventure_realm_chunk_min_y_table + si]
    add al, [adventure_realm_chunk_max_y_table + si]
    shr al, 1
    call game3d_world_z_edge_from_al
    mov [scene3d_temp_v], ax
    mov al, [adventure_realm_chunk_max_y_table + si]
    inc al
    call game3d_world_z_edge_from_al
    mov [scene3d_temp_w], ax
    jmp game3d_chunk_shelf_emit

game3d_chunk_bridge_east_west:
    mov al, [adventure_realm_chunk_min_x_table + si]
    call game3d_world_x_edge_from_al
    mov [scene3d_temp_x], ax
    mov al, [adventure_realm_chunk_max_x_table + si]
    inc al
    call game3d_world_x_edge_from_al
    mov [scene3d_temp_y], ax
    mov al, [adventure_realm_chunk_min_y_table + si]
    add al, [adventure_realm_chunk_max_y_table + si]
    shr al, 1
    mov dl, al
    call game3d_world_z_edge_from_al
    mov [scene3d_temp_v], ax
    mov al, dl
    inc al
    call game3d_world_z_edge_from_al
    mov [scene3d_temp_w], ax
    jmp game3d_chunk_bridge_emit

game3d_chunk_bridge_north_south:
    mov al, [adventure_realm_chunk_min_x_table + si]
    add al, [adventure_realm_chunk_max_x_table + si]
    shr al, 1
    mov dl, al
    call game3d_world_x_edge_from_al
    mov [scene3d_temp_x], ax
    mov al, dl
    inc al
    call game3d_world_x_edge_from_al
    mov [scene3d_temp_y], ax
    mov al, [adventure_realm_chunk_min_y_table + si]
    call game3d_world_z_edge_from_al
    mov [scene3d_temp_v], ax
    mov al, [adventure_realm_chunk_max_y_table + si]
    inc al
    call game3d_world_z_edge_from_al
    mov [scene3d_temp_w], ax

game3d_chunk_bridge_emit:
    call game3d_get_bridge_material
    mov byte ptr [scene3d_temp_face], GAME3D_FACE_FLAG_FRAME
    call game3d_emit_quad_from_temps
    jmp game3d_chunk_shelf_done

game3d_chunk_shelf_emit:
    call game3d_get_shelf_material
    mov byte ptr [scene3d_temp_face], GAME3D_FACE_FLAG_TRIM
    call game3d_emit_quad_from_temps
    call game3d_emit_chunk_step_face

game3d_chunk_shelf_done:
    pop dx
    pop cx
    pop bx
    pop ax
    ret

game3d_emit_chunk_cliff_face:
    push ax
    push bx
    push dx
    mov al, [adventure_realm_chunk_cliff_side_table + si]
    cmp al, ADVENTURE_DIR_NONE
    je game3d_chunk_cliff_done
    mov bx, si
    shl bx, 1
    mov dx, [adventure_realm_chunk_base_height_table + bx]
    mov ax, [adventure_realm_chunk_shelf_height_table + bx]
    cmp ax, dx
    jbe game3d_chunk_cliff_height_ready
    mov dx, ax

game3d_chunk_cliff_height_ready:
    add dx, GAME3D_FLOOR_Y
    cmp dx, GAME3D_FLOOR_Y
    jle game3d_chunk_cliff_done
    mov word ptr [scene3d_temp_z], GAME3D_FLOOR_Y
    mov [scene3d_temp_u], dx
    cmp al, ADVENTURE_DIR_EAST
    je game3d_chunk_cliff_east
    cmp al, ADVENTURE_DIR_WEST
    je game3d_chunk_cliff_west
    cmp al, ADVENTURE_DIR_NORTH
    je game3d_chunk_cliff_north
    mov al, [adventure_realm_chunk_max_y_table + si]
    inc al
    call game3d_world_z_edge_from_al
    mov [scene3d_temp_v], ax
    mov [scene3d_temp_w], ax
    mov al, [adventure_realm_chunk_min_x_table + si]
    call game3d_world_x_edge_from_al
    mov [scene3d_temp_x], ax
    mov al, [adventure_realm_chunk_max_x_table + si]
    inc al
    call game3d_world_x_edge_from_al
    mov [scene3d_temp_y], ax
    jmp game3d_chunk_cliff_emit

game3d_chunk_cliff_north:
    mov al, [adventure_realm_chunk_min_y_table + si]
    call game3d_world_z_edge_from_al
    mov [scene3d_temp_v], ax
    mov [scene3d_temp_w], ax
    mov al, [adventure_realm_chunk_min_x_table + si]
    call game3d_world_x_edge_from_al
    mov [scene3d_temp_x], ax
    mov al, [adventure_realm_chunk_max_x_table + si]
    inc al
    call game3d_world_x_edge_from_al
    mov [scene3d_temp_y], ax
    jmp game3d_chunk_cliff_emit

game3d_chunk_cliff_east:
    mov al, [adventure_realm_chunk_max_x_table + si]
    inc al
    call game3d_world_x_edge_from_al
    mov [scene3d_temp_x], ax
    mov [scene3d_temp_y], ax
    mov al, [adventure_realm_chunk_min_y_table + si]
    call game3d_world_z_edge_from_al
    mov [scene3d_temp_v], ax
    mov al, [adventure_realm_chunk_max_y_table + si]
    inc al
    call game3d_world_z_edge_from_al
    mov [scene3d_temp_w], ax
    jmp game3d_chunk_cliff_emit

game3d_chunk_cliff_west:
    mov al, [adventure_realm_chunk_min_x_table + si]
    call game3d_world_x_edge_from_al
    mov [scene3d_temp_x], ax
    mov [scene3d_temp_y], ax
    mov al, [adventure_realm_chunk_min_y_table + si]
    call game3d_world_z_edge_from_al
    mov [scene3d_temp_v], ax
    mov al, [adventure_realm_chunk_max_y_table + si]
    inc al
    call game3d_world_z_edge_from_al
    mov [scene3d_temp_w], ax

game3d_chunk_cliff_emit:
    call game3d_get_cliff_material
    mov byte ptr [scene3d_temp_face], GAME3D_FACE_FLAG_WALL
    call game3d_emit_quad_from_temps

game3d_chunk_cliff_done:
    pop dx
    pop bx
    pop ax
    ret

game3d_compile_adventure_terrain:
    push cx
    push si
    mov al, 0
    call game3d_world_x_edge_from_al
    mov [scene3d_temp_x], ax
    mov al, MAP_W
    call game3d_world_x_edge_from_al
    mov [scene3d_temp_y], ax
    mov word ptr [scene3d_temp_z], GAME3D_FLOOR_Y
    mov word ptr [scene3d_temp_u], GAME3D_FLOOR_Y
    mov al, 0
    call game3d_world_z_edge_from_al
    mov [scene3d_temp_v], ax
    mov al, MAP_H
    call game3d_world_z_edge_from_al
    mov [scene3d_temp_w], ax
    call game3d_get_floor_far_material
    mov byte ptr [scene3d_temp_face], GAME3D_FACE_FLAG_NONE
    call game3d_emit_quad_from_temps
    xor si, si
    xor cx, cx
    mov cl, [adventure_realm_chunk_count]
    jcxz game3d_compile_adventure_terrain_done

game3d_compile_adventure_chunk_loop:
    push cx
    call game3d_chunk_intersects_active_range
    cmp al, 0
    je game3d_compile_adventure_chunk_next
    call game3d_emit_chunk_base_floor
    call game3d_emit_chunk_shelf_floor
    call game3d_emit_chunk_cliff_face

game3d_compile_adventure_chunk_next:
    inc si
    pop cx
    loop game3d_compile_adventure_chunk_loop

game3d_compile_adventure_terrain_done:
    pop si
    pop cx
    ret

game3d_compile_floor_strips:
IF DEBUG_LEGACY_GAMEPLAY EQ 0
    call game3d_compile_adventure_terrain
    ret
ENDIF
    mov al, 0
    call game3d_world_x_edge_from_al
    mov [scene3d_temp_x], ax
    mov al, MAP_W
    call game3d_world_x_edge_from_al
    mov [scene3d_temp_y], ax
    mov word ptr [scene3d_temp_z], GAME3D_FLOOR_Y
    mov word ptr [scene3d_temp_u], GAME3D_FLOOR_Y
    mov al, 0
    call game3d_world_z_edge_from_al
    mov [scene3d_temp_v], ax
    mov al, MAP_H
    call game3d_world_z_edge_from_al
    mov [scene3d_temp_w], ax
    call game3d_get_floor_far_material
    mov [scene3d_temp_color], al
    mov [scene3d_temp_dither], ah
    mov byte ptr [scene3d_temp_face], GAME3D_FACE_FLAG_NONE
    call game3d_emit_quad_from_temps
    mov dh, PLAY_MIN_Y

game3d_floor_row_loop:
    cmp dh, PLAY_MAX_Y
    ja game3d_compile_floor_done
    mov ch, PLAY_MIN_X
    mov dl, PLAY_MAX_X + 1
    call game3d_emit_floor_base_run

game3d_compile_floor_next_row:
    inc dh
    jmp game3d_floor_row_loop

game3d_compile_floor_done:
    ret

game3d_compile_floor_trim_strips:
IF DEBUG_LEGACY_GAMEPLAY EQ 0
    ret
ENDIF
    mov dh, PLAY_MIN_Y

game3d_floor_trim_row_loop:
    cmp dh, PLAY_MAX_Y
    jae game3d_compile_floor_trim_done
    mov ch, PLAY_MIN_X
    mov dl, PLAY_MAX_X + 1
    call game3d_emit_floor_trim_run
    inc dh
    jmp game3d_floor_trim_row_loop

game3d_compile_floor_trim_done:
    ret

game3d_compile_active_wall_families:
    mov al, [game3d_room_variant]
    cmp al, GAME3D_ROOM_VARIANT_SOUTHWEST
    je game3d_compile_walls_southwest
    cmp al, GAME3D_ROOM_VARIANT_NORTHEAST
    je game3d_compile_walls_northeast
    cmp al, GAME3D_ROOM_VARIANT_SOUTHEAST
    je game3d_compile_walls_southeast
    call game3d_compile_north_walls
    call game3d_compile_west_walls
    ret

game3d_compile_walls_southwest:
    call game3d_compile_south_walls
    call game3d_compile_west_walls
    ret

game3d_compile_walls_northeast:
    call game3d_compile_north_walls
    call game3d_compile_east_walls
    ret

game3d_compile_walls_southeast:
    call game3d_compile_south_walls
    call game3d_compile_east_walls
    ret

game3d_compile_north_walls:
    xor dh, dh

game3d_north_row_loop:
    cmp dh, MAP_H
    jae game3d_compile_north_done
    xor dl, dl

game3d_north_scan_loop:
    cmp dl, MAP_W
    jae game3d_north_next_row
    mov bl, dl
    mov bh, dh
    call game3d_should_emit_north_face
    cmp al, 0
    je game3d_north_skip
    mov ch, dl

game3d_north_run_loop:
    inc dl
    cmp dl, MAP_W
    jae game3d_north_emit
    mov bl, dl
    mov bh, dh
    call game3d_should_emit_north_face
    cmp al, 0
    jne game3d_north_run_loop

game3d_north_emit:
    mov al, ch
    call game3d_world_x_edge_from_al
    mov [scene3d_temp_x], ax
    mov al, dl
    call game3d_world_x_edge_from_al
    mov [scene3d_temp_y], ax
    mov word ptr [scene3d_temp_z], GAME3D_FLOOR_Y
    mov word ptr [scene3d_temp_u], GAME3D_WALL_TOP_Y
    mov al, dh
    call game3d_world_z_edge_from_al
    mov [scene3d_temp_v], ax
    mov [scene3d_temp_w], ax
    cmp byte ptr [game3d_wall_emit_mode], 0
    jne game3d_north_emit_decor
    call game3d_get_wall_base_material
    mov [scene3d_temp_color], al
    mov [scene3d_temp_dither], ah
    mov byte ptr [scene3d_temp_face], GAME3D_FACE_FLAG_WALL
    call game3d_emit_quad_from_temps
    jmp game3d_north_scan_loop

game3d_north_emit_decor:
    call game3d_emit_north_wall_decor
    jmp game3d_north_scan_loop

game3d_north_skip:
    inc dl
    jmp game3d_north_scan_loop

game3d_north_next_row:
    inc dh
    jmp game3d_north_row_loop

game3d_compile_north_done:
    ret

game3d_compile_south_walls:
    xor dh, dh

game3d_south_row_loop:
    cmp dh, MAP_H
    jae game3d_compile_south_done
    xor dl, dl

game3d_south_scan_loop:
    cmp dl, MAP_W
    jae game3d_south_next_row
    mov bl, dl
    mov bh, dh
    call game3d_should_emit_south_face
    cmp al, 0
    je game3d_south_skip
    mov ch, dl

game3d_south_run_loop:
    inc dl
    cmp dl, MAP_W
    jae game3d_south_emit
    mov bl, dl
    mov bh, dh
    call game3d_should_emit_south_face
    cmp al, 0
    jne game3d_south_run_loop

game3d_south_emit:
    mov al, ch
    call game3d_world_x_edge_from_al
    mov [scene3d_temp_x], ax
    mov al, dl
    call game3d_world_x_edge_from_al
    mov [scene3d_temp_y], ax
    mov word ptr [scene3d_temp_z], GAME3D_FLOOR_Y
    mov word ptr [scene3d_temp_u], GAME3D_WALL_TOP_Y
    mov al, dh
    inc al
    call game3d_world_z_edge_from_al
    mov [scene3d_temp_v], ax
    mov [scene3d_temp_w], ax
    cmp byte ptr [game3d_wall_emit_mode], 0
    jne game3d_south_emit_decor
    call game3d_get_wall_base_material
    mov [scene3d_temp_color], al
    mov [scene3d_temp_dither], ah
    mov byte ptr [scene3d_temp_face], GAME3D_FACE_FLAG_WALL
    call game3d_emit_quad_from_temps
    jmp game3d_south_scan_loop

game3d_south_emit_decor:
    call game3d_emit_south_wall_decor
    jmp game3d_south_scan_loop

game3d_south_skip:
    inc dl
    jmp game3d_south_scan_loop

game3d_south_next_row:
    inc dh
    jmp game3d_south_row_loop

game3d_compile_south_done:
    ret

game3d_compile_west_walls:
    xor dh, dh

game3d_west_col_loop:
    cmp dh, MAP_W
    jae game3d_compile_west_done
    xor dl, dl

game3d_west_scan_loop:
    cmp dl, MAP_H
    jae game3d_west_next_col
    mov bl, dh
    mov bh, dl
    call game3d_should_emit_west_face
    cmp al, 0
    je game3d_west_skip
    mov ch, dl

game3d_west_run_loop:
    inc dl
    cmp dl, MAP_H
    jae game3d_west_emit
    mov bl, dh
    mov bh, dl
    call game3d_should_emit_west_face
    cmp al, 0
    jne game3d_west_run_loop

game3d_west_emit:
    mov al, dh
    call game3d_world_x_edge_from_al
    mov [scene3d_temp_x], ax
    mov [scene3d_temp_y], ax
    mov word ptr [scene3d_temp_z], GAME3D_FLOOR_Y
    mov word ptr [scene3d_temp_u], GAME3D_WALL_TOP_Y
    mov al, ch
    call game3d_world_z_edge_from_al
    mov [scene3d_temp_v], ax
    mov al, dl
    call game3d_world_z_edge_from_al
    mov [scene3d_temp_w], ax
    cmp byte ptr [game3d_wall_emit_mode], 0
    jne game3d_west_emit_decor
    call game3d_get_wall_base_material
    mov [scene3d_temp_color], al
    mov [scene3d_temp_dither], ah
    mov byte ptr [scene3d_temp_face], GAME3D_FACE_FLAG_WALL
    call game3d_emit_quad_from_temps
    jmp game3d_west_scan_loop

game3d_west_emit_decor:
    call game3d_emit_west_wall_decor
    jmp game3d_west_scan_loop

game3d_west_skip:
    inc dl
    jmp game3d_west_scan_loop

game3d_west_next_col:
    inc dh
    jmp game3d_west_col_loop

game3d_compile_west_done:
    ret

game3d_compile_east_walls:
    xor dh, dh

game3d_east_col_loop:
    cmp dh, MAP_W
    jae game3d_compile_east_done
    xor dl, dl

game3d_east_scan_loop:
    cmp dl, MAP_H
    jae game3d_east_next_col
    mov bl, dh
    mov bh, dl
    call game3d_should_emit_east_face
    cmp al, 0
    je game3d_east_skip
    mov ch, dl

game3d_east_run_loop:
    inc dl
    cmp dl, MAP_H
    jae game3d_east_emit
    mov bl, dh
    mov bh, dl
    call game3d_should_emit_east_face
    cmp al, 0
    jne game3d_east_run_loop

game3d_east_emit:
    mov al, dh
    inc al
    call game3d_world_x_edge_from_al
    mov [scene3d_temp_x], ax
    mov [scene3d_temp_y], ax
    mov word ptr [scene3d_temp_z], GAME3D_FLOOR_Y
    mov word ptr [scene3d_temp_u], GAME3D_WALL_TOP_Y
    mov al, ch
    call game3d_world_z_edge_from_al
    mov [scene3d_temp_v], ax
    mov al, dl
    call game3d_world_z_edge_from_al
    mov [scene3d_temp_w], ax
    cmp byte ptr [game3d_wall_emit_mode], 0
    jne game3d_east_emit_decor
    call game3d_get_wall_base_material
    mov [scene3d_temp_color], al
    mov [scene3d_temp_dither], ah
    mov byte ptr [scene3d_temp_face], GAME3D_FACE_FLAG_WALL
    call game3d_emit_quad_from_temps
    jmp game3d_east_scan_loop

game3d_east_emit_decor:
    call game3d_emit_east_wall_decor
    jmp game3d_east_scan_loop

game3d_east_skip:
    inc dl
    jmp game3d_east_scan_loop

game3d_east_next_col:
    inc dh
    jmp game3d_east_col_loop

game3d_compile_east_done:
    ret

game3d_compile_gate_lane_strips:
    xor dh, dh
    xor ch, ch

game3d_lane_row_loop:
    cmp dh, MAP_H
    jae game3d_lane_done
    cmp ch, 5
    jae game3d_lane_done
    mov bl, EXIT_COL
    mov bh, dh
    call get_tile
    cmp al, TILE_WALL
    je game3d_lane_skip_row

    mov dl, dh
    xor cl, cl

game3d_lane_run_loop:
    cmp dh, MAP_H
    jae game3d_lane_emit_run
    cmp ch, 5
    jae game3d_lane_emit_run
    mov bl, EXIT_COL
    mov bh, dh
    call get_tile
    cmp al, TILE_WALL
    je game3d_lane_emit_run
    inc dh
    inc ch
    inc cl
    jmp game3d_lane_run_loop

game3d_lane_emit_run:
    or cl, cl
    jz game3d_lane_row_loop
    mov al, EXIT_COL
    call game3d_world_x_edge_from_al
    add ax, GAME3D_LANE_INSET
    mov [scene3d_temp_x], ax
    mov al, EXIT_COL + 1
    call game3d_world_x_edge_from_al
    sub ax, GAME3D_LANE_INSET
    mov [scene3d_temp_y], ax
    mov word ptr [scene3d_temp_z], GAME3D_FLOOR_TRIM_Y
    mov word ptr [scene3d_temp_u], GAME3D_FLOOR_TRIM_Y
    mov al, dl
    call game3d_world_z_edge_from_al
    add ax, GAME3D_FLOOR_TRIM_INSET
    mov [scene3d_temp_v], ax
    mov al, dl
    add al, cl
    call game3d_world_z_edge_from_al
    sub ax, GAME3D_FLOOR_TRIM_INSET
    mov [scene3d_temp_w], ax
    mov ax, [scene3d_temp_y]
    cmp ax, [scene3d_temp_x]
    jbe game3d_lane_row_loop
    mov ax, [scene3d_temp_w]
    cmp ax, [scene3d_temp_v]
    jbe game3d_lane_row_loop
    call game3d_get_accent_material
    mov [scene3d_temp_color], al
    mov [scene3d_temp_dither], ah
    mov byte ptr [scene3d_temp_face], GAME3D_FACE_FLAG_FRAME
    call game3d_emit_quad_from_temps
    jmp game3d_lane_row_loop

game3d_lane_skip_row:
    inc dh
    jmp game3d_lane_row_loop

game3d_lane_done:
    ret

game3d_compile_gate_frame:
    mov bl, [exit_x]
    mov bh, [exit_y]
    call game3d_emit_tile_gate_frame
    ret

game3d_compile_interactable_frames:
    mov si, offset map_tiles
    xor dh, dh
    mov cx, MAP_H

game3d_frame_row_loop:
    push cx
    xor dl, dl
    mov cx, MAP_W

game3d_frame_col_loop:
    mov al, [si]
    cmp al, TILE_TERMINAL
    je game3d_frame_terminal
    cmp al, TILE_SURGE
    je game3d_frame_surge
    jmp game3d_frame_next

game3d_frame_terminal:
    mov bl, dl
    mov bh, dh
    call game3d_emit_tile_terminal_frame
    jmp game3d_frame_next

game3d_frame_surge:
    mov bl, dl
    mov bh, dh
    call game3d_emit_tile_surge_frame

game3d_frame_next:
    inc si
    inc dl
    dec cx
    jnz game3d_frame_col_loop
    inc dh
    pop cx
    dec cx
    jnz game3d_frame_row_loop
    ret

game3d_get_near_occluder_top_y:
    call game3d_get_near_occluder_height
    add ax, GAME3D_FLOOR_Y
    ret

game3d_get_far_silhouette_bottom_y:
    push dx
    call game3d_get_far_silhouette_height
    mov dx, GAME3D_WALL_TOP_Y
    sub dx, ax
    mov ax, dx
    pop dx
    ret

game3d_compile_near_occluders:
    mov al, [game3d_room_variant]
    cmp al, GAME3D_ROOM_VARIANT_SOUTHWEST
    je game3d_compile_near_northeast
    cmp al, GAME3D_ROOM_VARIANT_NORTHEAST
    je game3d_compile_near_southwest
    cmp al, GAME3D_ROOM_VARIANT_SOUTHEAST
    je game3d_compile_near_northwest
    call game3d_compile_near_southeast
    call game3d_compile_exit_jambs
    ret

game3d_compile_near_northeast:
    call game3d_compile_near_northeast_corner
    call game3d_compile_exit_jambs
    ret

game3d_compile_near_southwest:
    call game3d_compile_near_southwest_corner
    call game3d_compile_exit_jambs
    ret

game3d_compile_near_northwest:
    call game3d_compile_near_northwest_corner
    call game3d_compile_exit_jambs
    ret

game3d_compile_near_southeast:
    call game3d_compile_near_southeast_corner
    ret

game3d_compile_near_southeast_corner:
    push ax
    push bx
    push dx
    mov al, MAP_W
    call game3d_world_x_edge_from_al
    mov [scene3d_temp_s], ax
    mov al, MAP_H
    call game3d_world_z_edge_from_al
    mov [scene3d_temp_r], ax
    call game3d_get_near_occluder_inset
    mov [scene3d_temp_l], ax
    call game3d_get_near_occluder_top_y
    mov [scene3d_temp_u], ax
    mov word ptr [scene3d_temp_z], GAME3D_FLOOR_Y

    mov ax, [scene3d_temp_s]
    sub ax, [scene3d_temp_l]
    mov [scene3d_temp_x], ax
    mov [scene3d_temp_y], ax
    mov ax, [scene3d_temp_r]
    sub ax, [scene3d_temp_l]
    mov [scene3d_temp_w], ax
    call game3d_get_near_occluder_width
    shl ax, 1
    mov dx, ax
    mov ax, [scene3d_temp_w]
    sub ax, dx
    mov [scene3d_temp_v], ax
    call game3d_get_wall_base_material
    mov [scene3d_temp_color], al
    mov [scene3d_temp_dither], ah
    mov byte ptr [scene3d_temp_face], GAME3D_FACE_FLAG_WALL
    call game3d_emit_quad_from_temps

    mov ax, [scene3d_temp_s]
    sub ax, [scene3d_temp_l]
    mov [scene3d_temp_y], ax
    call game3d_get_near_occluder_width
    shl ax, 1
    mov dx, ax
    mov ax, [scene3d_temp_y]
    sub ax, dx
    mov [scene3d_temp_x], ax
    mov ax, [scene3d_temp_r]
    sub ax, [scene3d_temp_l]
    mov [scene3d_temp_v], ax
    mov [scene3d_temp_w], ax
    call game3d_get_wall_trim_material
    mov [scene3d_temp_color], al
    mov [scene3d_temp_dither], ah
    mov byte ptr [scene3d_temp_face], GAME3D_FACE_FLAG_WALL or GAME3D_FACE_FLAG_TRIM
    call game3d_emit_quad_from_temps
    pop dx
    pop bx
    pop ax
    ret

game3d_compile_near_southwest_corner:
    push ax
    push bx
    push dx
    mov al, 0
    call game3d_world_x_edge_from_al
    mov [scene3d_temp_s], ax
    mov al, MAP_H
    call game3d_world_z_edge_from_al
    mov [scene3d_temp_r], ax
    call game3d_get_near_occluder_inset
    mov [scene3d_temp_l], ax
    call game3d_get_near_occluder_top_y
    mov [scene3d_temp_u], ax
    mov word ptr [scene3d_temp_z], GAME3D_FLOOR_Y

    mov ax, [scene3d_temp_s]
    add ax, [scene3d_temp_l]
    mov [scene3d_temp_x], ax
    mov [scene3d_temp_y], ax
    mov ax, [scene3d_temp_r]
    sub ax, [scene3d_temp_l]
    mov [scene3d_temp_w], ax
    call game3d_get_near_occluder_width
    shl ax, 1
    mov dx, ax
    mov ax, [scene3d_temp_w]
    sub ax, dx
    mov [scene3d_temp_v], ax
    call game3d_get_wall_base_material
    mov [scene3d_temp_color], al
    mov [scene3d_temp_dither], ah
    mov byte ptr [scene3d_temp_face], GAME3D_FACE_FLAG_WALL
    call game3d_emit_quad_from_temps

    mov ax, [scene3d_temp_s]
    add ax, [scene3d_temp_l]
    mov [scene3d_temp_x], ax
    call game3d_get_near_occluder_width
    shl ax, 1
    mov dx, ax
    mov ax, [scene3d_temp_x]
    add ax, dx
    mov [scene3d_temp_y], ax
    mov ax, [scene3d_temp_r]
    sub ax, [scene3d_temp_l]
    mov [scene3d_temp_v], ax
    mov [scene3d_temp_w], ax
    call game3d_get_wall_trim_material
    mov [scene3d_temp_color], al
    mov [scene3d_temp_dither], ah
    mov byte ptr [scene3d_temp_face], GAME3D_FACE_FLAG_WALL or GAME3D_FACE_FLAG_TRIM
    call game3d_emit_quad_from_temps
    pop dx
    pop bx
    pop ax
    ret

game3d_compile_near_northwest_corner:
    push ax
    push bx
    push dx
    mov al, 0
    call game3d_world_x_edge_from_al
    mov [scene3d_temp_s], ax
    mov al, 0
    call game3d_world_z_edge_from_al
    mov [scene3d_temp_r], ax
    call game3d_get_near_occluder_inset
    mov [scene3d_temp_l], ax
    call game3d_get_near_occluder_top_y
    mov [scene3d_temp_u], ax
    mov word ptr [scene3d_temp_z], GAME3D_FLOOR_Y

    mov ax, [scene3d_temp_s]
    add ax, [scene3d_temp_l]
    mov [scene3d_temp_x], ax
    mov [scene3d_temp_y], ax
    mov ax, [scene3d_temp_r]
    add ax, [scene3d_temp_l]
    mov [scene3d_temp_v], ax
    call game3d_get_near_occluder_width
    shl ax, 1
    mov dx, ax
    mov ax, [scene3d_temp_v]
    add ax, dx
    mov [scene3d_temp_w], ax
    call game3d_get_wall_base_material
    mov [scene3d_temp_color], al
    mov [scene3d_temp_dither], ah
    mov byte ptr [scene3d_temp_face], GAME3D_FACE_FLAG_WALL
    call game3d_emit_quad_from_temps

    mov ax, [scene3d_temp_s]
    add ax, [scene3d_temp_l]
    mov [scene3d_temp_x], ax
    call game3d_get_near_occluder_width
    shl ax, 1
    mov dx, ax
    mov ax, [scene3d_temp_x]
    add ax, dx
    mov [scene3d_temp_y], ax
    mov ax, [scene3d_temp_r]
    add ax, [scene3d_temp_l]
    mov [scene3d_temp_v], ax
    mov [scene3d_temp_w], ax
    call game3d_get_wall_trim_material
    mov [scene3d_temp_color], al
    mov [scene3d_temp_dither], ah
    mov byte ptr [scene3d_temp_face], GAME3D_FACE_FLAG_WALL or GAME3D_FACE_FLAG_TRIM
    call game3d_emit_quad_from_temps
    pop dx
    pop bx
    pop ax
    ret

game3d_compile_near_northeast_corner:
    push ax
    push bx
    push dx
    mov al, MAP_W
    call game3d_world_x_edge_from_al
    mov [scene3d_temp_s], ax
    mov al, 0
    call game3d_world_z_edge_from_al
    mov [scene3d_temp_r], ax
    call game3d_get_near_occluder_inset
    mov [scene3d_temp_l], ax
    call game3d_get_near_occluder_top_y
    mov [scene3d_temp_u], ax
    mov word ptr [scene3d_temp_z], GAME3D_FLOOR_Y

    mov ax, [scene3d_temp_s]
    sub ax, [scene3d_temp_l]
    mov [scene3d_temp_x], ax
    mov [scene3d_temp_y], ax
    mov ax, [scene3d_temp_r]
    add ax, [scene3d_temp_l]
    mov [scene3d_temp_v], ax
    call game3d_get_near_occluder_width
    shl ax, 1
    mov dx, ax
    mov ax, [scene3d_temp_v]
    add ax, dx
    mov [scene3d_temp_w], ax
    call game3d_get_wall_base_material
    mov [scene3d_temp_color], al
    mov [scene3d_temp_dither], ah
    mov byte ptr [scene3d_temp_face], GAME3D_FACE_FLAG_WALL
    call game3d_emit_quad_from_temps

    mov ax, [scene3d_temp_s]
    sub ax, [scene3d_temp_l]
    mov [scene3d_temp_y], ax
    call game3d_get_near_occluder_width
    shl ax, 1
    mov dx, ax
    mov ax, [scene3d_temp_y]
    sub ax, dx
    mov [scene3d_temp_x], ax
    mov ax, [scene3d_temp_r]
    add ax, [scene3d_temp_l]
    mov [scene3d_temp_v], ax
    mov [scene3d_temp_w], ax
    call game3d_get_wall_trim_material
    mov [scene3d_temp_color], al
    mov [scene3d_temp_dither], ah
    mov byte ptr [scene3d_temp_face], GAME3D_FACE_FLAG_WALL or GAME3D_FACE_FLAG_TRIM
    call game3d_emit_quad_from_temps
    pop dx
    pop bx
    pop ax
    ret

game3d_compile_exit_jambs:
    push ax
    push bx
    push dx
    mov bl, [exit_x]
    mov bh, [exit_y]
    call game3d_get_near_occluder_inset
    mov [scene3d_temp_l], ax
    call game3d_get_near_occluder_width
    mov [scene3d_temp_r], ax
    call game3d_get_near_occluder_top_y
    mov [scene3d_temp_u], ax
    mov word ptr [scene3d_temp_z], GAME3D_FLOOR_Y

    mov al, bl
    call game3d_world_x_edge_from_al
    mov [scene3d_temp_x], ax
    mov [scene3d_temp_y], ax
    mov al, bh
    call game3d_world_z_edge_from_al
    add ax, [scene3d_temp_l]
    mov [scene3d_temp_v], ax
    mov dx, ax
    add dx, [scene3d_temp_r]
    mov [scene3d_temp_w], dx
    call game3d_get_wall_trim_material
    mov [scene3d_temp_color], al
    mov [scene3d_temp_dither], ah
    mov byte ptr [scene3d_temp_face], GAME3D_FACE_FLAG_FRAME
    call game3d_emit_quad_from_temps

    mov al, bl
    inc al
    call game3d_world_x_edge_from_al
    mov [scene3d_temp_x], ax
    mov [scene3d_temp_y], ax
    mov ax, [scene3d_temp_v]
    mov [scene3d_temp_v], ax
    mov dx, ax
    add dx, [scene3d_temp_r]
    mov [scene3d_temp_w], dx
    call game3d_get_wall_trim_material
    mov [scene3d_temp_color], al
    mov [scene3d_temp_dither], ah
    mov byte ptr [scene3d_temp_face], GAME3D_FACE_FLAG_FRAME
    call game3d_emit_quad_from_temps
    pop dx
    pop bx
    pop ax
    ret

game3d_compile_far_silhouette:
    push ax
    push bx
    push dx
    mov al, 0
    call game3d_world_x_edge_from_al
    mov [scene3d_temp_x], ax
    mov al, MAP_W
    call game3d_world_x_edge_from_al
    mov [scene3d_temp_y], ax
    call game3d_get_far_silhouette_inset
    add [scene3d_temp_x], ax
    sub [scene3d_temp_y], ax
    call game3d_get_far_silhouette_bottom_y
    mov [scene3d_temp_z], ax
    mov word ptr [scene3d_temp_u], GAME3D_WALL_TOP_Y
    mov al, [game3d_room_variant]
    cmp al, GAME3D_ROOM_VARIANT_SOUTHWEST
    je game3d_far_south_band
    cmp al, GAME3D_ROOM_VARIANT_SOUTHEAST
    je game3d_far_south_band
    mov al, 0
    call game3d_world_z_edge_from_al
    mov [scene3d_temp_v], ax
    mov [scene3d_temp_w], ax
    jmp game3d_far_band_ready

game3d_far_south_band:
    mov al, MAP_H
    call game3d_world_z_edge_from_al
    mov [scene3d_temp_v], ax
    mov [scene3d_temp_w], ax

game3d_far_band_ready:
    call game3d_get_far_mass_material
    mov [scene3d_temp_color], al
    mov [scene3d_temp_dither], ah
    mov byte ptr [scene3d_temp_face], GAME3D_FACE_FLAG_WALL or GAME3D_FACE_FLAG_TRIM
    call game3d_emit_quad_from_temps
    pop dx
    pop bx
    pop ax
    ret

game3d_get_far_wall_z_edge:
    mov al, [game3d_room_variant]
    cmp al, GAME3D_ROOM_VARIANT_SOUTHWEST
    je game3d_far_wall_south
    cmp al, GAME3D_ROOM_VARIANT_SOUTHEAST
    je game3d_far_wall_south
    mov al, 0
    call game3d_world_z_edge_from_al
    ret

game3d_far_wall_south:
    mov al, MAP_H
    call game3d_world_z_edge_from_al
    ret

game3d_get_near_wall_z_edge:
    mov al, [game3d_room_variant]
    cmp al, GAME3D_ROOM_VARIANT_SOUTHWEST
    je game3d_near_wall_north
    cmp al, GAME3D_ROOM_VARIANT_SOUTHEAST
    je game3d_near_wall_north
    mov al, MAP_H
    call game3d_world_z_edge_from_al
    ret

game3d_near_wall_north:
    mov al, 0
    call game3d_world_z_edge_from_al
    ret

game3d_compile_shot_framing:
    cmp byte ptr [game3d_shot_mode], GAME3D_SHOT_BASE_CHASE
    je game3d_compile_shot_framing_done
    mov al, [game3d_shot_frame_variant]
    cmp al, GAME3D_FRAME_VARIANT_RAIL
    je game3d_compile_shot_framing_rail
    cmp al, GAME3D_FRAME_VARIANT_DOOR
    je game3d_compile_shot_framing_door
    cmp al, GAME3D_FRAME_VARIANT_CEILING
    je game3d_compile_shot_framing_ceiling
    cmp al, GAME3D_FRAME_VARIANT_LANDMARK
    je game3d_compile_shot_framing_landmark
    jmp game3d_compile_shot_framing_done

game3d_compile_shot_framing_rail:
    call game3d_emit_shot_rail_frame
    jmp game3d_compile_shot_framing_done

game3d_compile_shot_framing_door:
    call game3d_emit_shot_door_frame
    jmp game3d_compile_shot_framing_done

game3d_compile_shot_framing_ceiling:
    call game3d_emit_shot_ceiling_beam
    jmp game3d_compile_shot_framing_done

game3d_compile_shot_framing_landmark:
    call game3d_emit_shot_rail_frame

game3d_compile_shot_framing_done:
    ret

game3d_emit_shot_rail_frame:
    push ax
    push bx
    push dx
    mov al, 0
    call game3d_world_x_edge_from_al
    mov [scene3d_temp_x], ax
    mov al, MAP_W
    call game3d_world_x_edge_from_al
    mov [scene3d_temp_y], ax
    call game3d_get_frame_rail_inset
    add [scene3d_temp_x], ax
    sub [scene3d_temp_y], ax
    mov word ptr [scene3d_temp_z], GAME3D_FLOOR_Y
    call game3d_get_frame_rail_height
    add ax, GAME3D_FLOOR_Y
    mov [scene3d_temp_u], ax
    call game3d_get_near_wall_z_edge
    mov [scene3d_temp_s], ax
    call game3d_get_frame_rail_inset
    mov [scene3d_temp_l], ax
    call game3d_get_frame_rail_width
    mov [scene3d_temp_r], ax
    mov al, [game3d_room_variant]
    cmp al, GAME3D_ROOM_VARIANT_SOUTHWEST
    je game3d_emit_shot_rail_north
    cmp al, GAME3D_ROOM_VARIANT_SOUTHEAST
    je game3d_emit_shot_rail_north
    mov ax, [scene3d_temp_s]
    sub ax, [scene3d_temp_l]
    mov [scene3d_temp_w], ax
    mov ax, [scene3d_temp_w]
    sub ax, [scene3d_temp_r]
    mov [scene3d_temp_v], ax
    jmp game3d_emit_shot_rail_ready

game3d_emit_shot_rail_north:
    mov ax, [scene3d_temp_s]
    add ax, [scene3d_temp_l]
    mov [scene3d_temp_v], ax
    mov ax, [scene3d_temp_v]
    add ax, [scene3d_temp_r]
    mov [scene3d_temp_w], ax

game3d_emit_shot_rail_ready:
    call game3d_get_wall_trim_material
    mov [scene3d_temp_color], al
    mov [scene3d_temp_dither], ah
    mov byte ptr [scene3d_temp_face], GAME3D_FACE_FLAG_FRAME or GAME3D_FACE_FLAG_TRIM
    call game3d_emit_quad_from_temps
    pop dx
    pop bx
    pop ax
    ret

game3d_emit_shot_door_frame:
    push ax
    push bx
    push dx
    mov bl, [game3d_shot_subject_x]
    mov bh, [game3d_shot_subject_y]
    mov al, bl
    call game3d_world_x_edge_from_al
    mov [scene3d_temp_s], ax
    mov al, bl
    inc al
    call game3d_world_x_edge_from_al
    mov [scene3d_temp_r], ax
    call game3d_get_frame_door_inset
    mov [scene3d_temp_l], ax
    call game3d_get_frame_door_height
    add ax, GAME3D_FLOOR_Y
    mov [scene3d_temp_u], ax
    mov word ptr [scene3d_temp_z], GAME3D_FLOOR_Y
    mov al, [game3d_room_variant]
    cmp al, GAME3D_ROOM_VARIANT_NORTHWEST
    je game3d_emit_shot_door_north
    cmp al, GAME3D_ROOM_VARIANT_NORTHEAST
    je game3d_emit_shot_door_north
    mov al, bh
    inc al
    call game3d_world_z_edge_from_al
    jmp game3d_emit_shot_door_plane_ready

game3d_emit_shot_door_north:
    mov al, bh
    call game3d_world_z_edge_from_al

game3d_emit_shot_door_plane_ready:
    mov [scene3d_temp_v], ax
    mov [scene3d_temp_w], ax
    mov ax, [scene3d_temp_s]
    add ax, [scene3d_temp_l]
    mov [scene3d_temp_x], ax
    mov ax, [scene3d_temp_r]
    sub ax, [scene3d_temp_l]
    mov [scene3d_temp_y], ax
    call game3d_get_wall_trim_material
    mov [scene3d_temp_color], al
    mov [scene3d_temp_dither], ah
    mov byte ptr [scene3d_temp_face], GAME3D_FACE_FLAG_FRAME or GAME3D_FACE_FLAG_TRIM
    call game3d_emit_quad_from_temps

    call game3d_get_frame_door_width
    mov dx, ax
    mov ax, [scene3d_temp_u]
    sub ax, dx
    mov [scene3d_temp_z], ax
    mov ax, [scene3d_temp_s]
    add ax, [scene3d_temp_l]
    mov [scene3d_temp_x], ax
    mov ax, [scene3d_temp_r]
    sub ax, [scene3d_temp_l]
    mov [scene3d_temp_y], ax
    call game3d_emit_quad_from_temps
    pop dx
    pop bx
    pop ax
    ret

game3d_emit_shot_ceiling_beam:
    push ax
    push bx
    push dx
    mov al, 0
    call game3d_world_x_edge_from_al
    mov [scene3d_temp_x], ax
    mov al, MAP_W
    call game3d_world_x_edge_from_al
    mov [scene3d_temp_y], ax
    call game3d_get_frame_door_inset
    add [scene3d_temp_x], ax
    sub [scene3d_temp_y], ax
    call game3d_get_frame_ceiling_height
    add ax, GAME3D_FLOOR_Y
    mov [scene3d_temp_u], ax
    call game3d_get_frame_ceiling_thickness
    mov dx, ax
    mov ax, [scene3d_temp_u]
    sub ax, dx
    mov [scene3d_temp_z], ax
    mov bl, [game3d_shot_subject_x]
    mov bh, [game3d_shot_subject_y]
    call game3d_get_tile_center_world
    mov [scene3d_temp_s], dx
    call game3d_get_frame_rail_width
    mov [scene3d_temp_l], ax
    mov ax, [scene3d_temp_s]
    sub ax, [scene3d_temp_l]
    mov [scene3d_temp_v], ax
    mov ax, [scene3d_temp_s]
    add ax, [scene3d_temp_l]
    mov [scene3d_temp_w], ax
    call game3d_get_ceiling_material
    mov [scene3d_temp_color], al
    mov [scene3d_temp_dither], ah
    mov byte ptr [scene3d_temp_face], GAME3D_FACE_FLAG_FRAME or GAME3D_FACE_FLAG_TRIM
    call game3d_emit_quad_from_temps
    pop dx
    pop bx
    pop ax
    ret

game3d_compile_shot_far_mass:
    cmp byte ptr [game3d_shot_mode], GAME3D_SHOT_BASE_CHASE
    je game3d_compile_shot_far_mass_done
    push ax
    push bx
    push dx
    mov al, 0
    call game3d_world_x_edge_from_al
    mov [scene3d_temp_x], ax
    mov al, MAP_W
    call game3d_world_x_edge_from_al
    mov [scene3d_temp_y], ax
    call game3d_get_frame_far_mass_inset
    add [scene3d_temp_x], ax
    sub [scene3d_temp_y], ax
    call game3d_get_frame_far_mass_height
    mov dx, GAME3D_WALL_TOP_Y
    sub dx, ax
    mov [scene3d_temp_z], dx
    mov word ptr [scene3d_temp_u], GAME3D_WALL_TOP_Y
    call game3d_get_far_wall_z_edge
    mov [scene3d_temp_s], ax
    call game3d_get_frame_far_mass_width
    mov [scene3d_temp_l], ax
    mov al, [game3d_room_variant]
    cmp al, GAME3D_ROOM_VARIANT_SOUTHWEST
    je game3d_compile_shot_far_mass_south
    cmp al, GAME3D_ROOM_VARIANT_SOUTHEAST
    je game3d_compile_shot_far_mass_south
    mov ax, [scene3d_temp_s]
    mov [scene3d_temp_v], ax
    mov ax, [scene3d_temp_s]
    add ax, [scene3d_temp_l]
    mov [scene3d_temp_w], ax
    jmp game3d_compile_shot_far_mass_ready

game3d_compile_shot_far_mass_south:
    mov ax, [scene3d_temp_s]
    sub ax, [scene3d_temp_l]
    mov [scene3d_temp_v], ax
    mov ax, [scene3d_temp_s]
    mov [scene3d_temp_w], ax

game3d_compile_shot_far_mass_ready:
    call game3d_get_soffit_material
    mov [scene3d_temp_color], al
    mov [scene3d_temp_dither], ah
    mov byte ptr [scene3d_temp_face], GAME3D_FACE_FLAG_WALL or GAME3D_FACE_FLAG_TRIM
    call game3d_emit_quad_from_temps
    pop dx
    pop bx
    pop ax

game3d_compile_shot_far_mass_done:
    ret

game3d_emit_floor_base_run:
    push ax
    push bx
    push dx
    mov al, ch
    call game3d_world_x_edge_from_al
    mov [scene3d_temp_x], ax
    mov al, dl
    call game3d_world_x_edge_from_al
    mov [scene3d_temp_y], ax
    mov word ptr [scene3d_temp_z], GAME3D_FLOOR_Y
    mov word ptr [scene3d_temp_u], GAME3D_FLOOR_Y
    mov al, dh
    call game3d_world_z_edge_from_al
    mov [scene3d_temp_v], ax
    mov al, dh
    inc al
    call game3d_world_z_edge_from_al
    mov [scene3d_temp_w], ax
    call game3d_get_floor_base_material
    mov [scene3d_temp_color], al
    mov [scene3d_temp_dither], ah
    mov byte ptr [scene3d_temp_face], GAME3D_FACE_FLAG_NONE
    call game3d_emit_quad_from_temps
    pop dx
    pop bx
    pop ax
    ret

game3d_emit_floor_trim_run:
    push ax
    push bx
    push dx
    push cx
    mov al, dl
    sub al, ch
    cmp al, 2
    jbe game3d_floor_trim_done
    mov al, dh
    add al, [sector_num]
    test al, 1
    jnz game3d_floor_trim_done

    mov al, ch
    call game3d_world_x_edge_from_al
    add ax, GAME3D_FLOOR_TRIM_INSET
    mov [scene3d_temp_x], ax
    mov al, dl
    call game3d_world_x_edge_from_al
    sub ax, GAME3D_FLOOR_TRIM_INSET
    mov [scene3d_temp_y], ax
    mov word ptr [scene3d_temp_z], GAME3D_FLOOR_TRIM_Y
    mov word ptr [scene3d_temp_u], GAME3D_FLOOR_TRIM_Y
    mov al, dh
    call game3d_world_z_edge_from_al
    add ax, GAME3D_FLOOR_TRIM_INSET
    mov [scene3d_temp_v], ax
    mov al, dh
    inc al
    call game3d_world_z_edge_from_al
    sub ax, GAME3D_FLOOR_TRIM_INSET
    mov [scene3d_temp_w], ax
    mov ax, [scene3d_temp_y]
    cmp ax, [scene3d_temp_x]
    jbe game3d_floor_trim_done
    mov ax, [scene3d_temp_w]
    cmp ax, [scene3d_temp_v]
    jbe game3d_floor_trim_done
    call game3d_get_lane_trim_material
    mov [scene3d_temp_color], al
    mov [scene3d_temp_dither], ah
    mov byte ptr [scene3d_temp_face], GAME3D_FACE_FLAG_TRIM
    call game3d_emit_optional_quad_from_temps

game3d_floor_trim_done:
    pop cx
    pop dx
    pop bx
    pop ax
    ret

game3d_emit_north_wall_decor:
    push ax
    mov ax, [scene3d_temp_y]
    sub ax, [scene3d_temp_x]
    cmp ax, GAME3D_TILE_UNIT * 3
    jb game3d_emit_north_wall_cap
    mov word ptr [scene3d_temp_z], GAME3D_WALL_BAND_BOTTOM_Y
    mov word ptr [scene3d_temp_u], GAME3D_WALL_BAND_TOP_Y
    call game3d_get_wall_trim_material
    mov [scene3d_temp_color], al
    mov [scene3d_temp_dither], ah
    mov byte ptr [scene3d_temp_face], GAME3D_FACE_FLAG_WALL or GAME3D_FACE_FLAG_TRIM
    call game3d_emit_optional_quad_from_temps
    jmp game3d_emit_north_wall_decor_done

game3d_emit_north_wall_cap:
    mov ax, [scene3d_temp_v]
    mov [scene3d_temp_s], ax
    sub ax, GAME3D_WALL_CAP_OUTSET
    mov [scene3d_temp_v], ax
    mov ax, [scene3d_temp_s]
    mov [scene3d_temp_w], ax
    mov word ptr [scene3d_temp_z], GAME3D_WALL_TOP_Y
    mov word ptr [scene3d_temp_u], GAME3D_WALL_TOP_Y
    call game3d_get_wall_cap_material
    mov [scene3d_temp_color], al
    mov [scene3d_temp_dither], ah
    mov byte ptr [scene3d_temp_face], GAME3D_FACE_FLAG_TRIM
    call game3d_emit_optional_quad_from_temps

game3d_emit_north_wall_decor_done:
    pop ax
    ret

game3d_emit_south_wall_decor:
    push ax
    mov ax, [scene3d_temp_y]
    sub ax, [scene3d_temp_x]
    cmp ax, GAME3D_TILE_UNIT * 3
    jb game3d_emit_south_wall_cap
    mov word ptr [scene3d_temp_z], GAME3D_WALL_BAND_BOTTOM_Y
    mov word ptr [scene3d_temp_u], GAME3D_WALL_BAND_TOP_Y
    call game3d_get_wall_trim_material
    mov [scene3d_temp_color], al
    mov [scene3d_temp_dither], ah
    mov byte ptr [scene3d_temp_face], GAME3D_FACE_FLAG_WALL or GAME3D_FACE_FLAG_TRIM
    call game3d_emit_optional_quad_from_temps
    jmp game3d_emit_south_wall_decor_done

game3d_emit_south_wall_cap:
    mov ax, [scene3d_temp_v]
    mov [scene3d_temp_s], ax
    mov [scene3d_temp_v], ax
    add ax, GAME3D_WALL_CAP_OUTSET
    mov [scene3d_temp_w], ax
    mov word ptr [scene3d_temp_z], GAME3D_WALL_TOP_Y
    mov word ptr [scene3d_temp_u], GAME3D_WALL_TOP_Y
    call game3d_get_wall_cap_material
    mov [scene3d_temp_color], al
    mov [scene3d_temp_dither], ah
    mov byte ptr [scene3d_temp_face], GAME3D_FACE_FLAG_TRIM
    call game3d_emit_optional_quad_from_temps

game3d_emit_south_wall_decor_done:
    pop ax
    ret

game3d_emit_west_wall_decor:
    push ax
    mov ax, [scene3d_temp_w]
    sub ax, [scene3d_temp_v]
    cmp ax, GAME3D_TILE_UNIT * 3
    jb game3d_emit_west_wall_cap
    mov word ptr [scene3d_temp_z], GAME3D_WALL_BAND_BOTTOM_Y
    mov word ptr [scene3d_temp_u], GAME3D_WALL_BAND_TOP_Y
    call game3d_get_wall_trim_material
    mov [scene3d_temp_color], al
    mov [scene3d_temp_dither], ah
    mov byte ptr [scene3d_temp_face], GAME3D_FACE_FLAG_WALL or GAME3D_FACE_FLAG_TRIM
    call game3d_emit_optional_quad_from_temps
    jmp game3d_emit_west_wall_decor_done

game3d_emit_west_wall_cap:
    mov ax, [scene3d_temp_x]
    mov [scene3d_temp_s], ax
    sub ax, GAME3D_WALL_CAP_OUTSET
    mov [scene3d_temp_x], ax
    mov ax, [scene3d_temp_s]
    mov [scene3d_temp_y], ax
    mov word ptr [scene3d_temp_z], GAME3D_WALL_TOP_Y
    mov word ptr [scene3d_temp_u], GAME3D_WALL_TOP_Y
    call game3d_get_wall_cap_material
    mov [scene3d_temp_color], al
    mov [scene3d_temp_dither], ah
    mov byte ptr [scene3d_temp_face], GAME3D_FACE_FLAG_TRIM
    call game3d_emit_optional_quad_from_temps

game3d_emit_west_wall_decor_done:
    pop ax
    ret

game3d_emit_east_wall_decor:
    push ax
    mov ax, [scene3d_temp_w]
    sub ax, [scene3d_temp_v]
    cmp ax, GAME3D_TILE_UNIT * 3
    jb game3d_emit_east_wall_cap
    mov word ptr [scene3d_temp_z], GAME3D_WALL_BAND_BOTTOM_Y
    mov word ptr [scene3d_temp_u], GAME3D_WALL_BAND_TOP_Y
    call game3d_get_wall_trim_material
    mov [scene3d_temp_color], al
    mov [scene3d_temp_dither], ah
    mov byte ptr [scene3d_temp_face], GAME3D_FACE_FLAG_WALL or GAME3D_FACE_FLAG_TRIM
    call game3d_emit_optional_quad_from_temps
    jmp game3d_emit_east_wall_decor_done

game3d_emit_east_wall_cap:
    mov ax, [scene3d_temp_x]
    mov [scene3d_temp_s], ax
    mov [scene3d_temp_x], ax
    add ax, GAME3D_WALL_CAP_OUTSET
    mov [scene3d_temp_y], ax
    mov word ptr [scene3d_temp_z], GAME3D_WALL_TOP_Y
    mov word ptr [scene3d_temp_u], GAME3D_WALL_TOP_Y
    call game3d_get_wall_cap_material
    mov [scene3d_temp_color], al
    mov [scene3d_temp_dither], ah
    mov byte ptr [scene3d_temp_face], GAME3D_FACE_FLAG_TRIM
    call game3d_emit_optional_quad_from_temps

game3d_emit_east_wall_decor_done:
    pop ax
    ret

game3d_emit_tile_gate_frame:
    push bx
    call game3d_emit_tile_pad_lane
    call game3d_emit_tile_back_panel_cap
    pop bx
    ret

game3d_emit_tile_terminal_frame:
    push bx
    call game3d_emit_tile_pad_trim
    call game3d_emit_tile_back_panel_trim
    pop bx
    ret

game3d_emit_tile_surge_frame:
    push bx
    call game3d_emit_tile_pad_lane
    call game3d_emit_tile_back_panel_trim
    pop bx
    ret

game3d_emit_tile_pad_trim:
    call game3d_set_tile_pad_temps
    call game3d_get_wall_trim_material
    mov [scene3d_temp_color], al
    mov [scene3d_temp_dither], ah
    mov byte ptr [scene3d_temp_face], GAME3D_FACE_FLAG_FRAME
    call game3d_emit_quad_from_temps
    ret

game3d_emit_tile_pad_lane:
    call game3d_set_tile_pad_temps
    call game3d_get_lane_material
    mov [scene3d_temp_color], al
    mov [scene3d_temp_dither], ah
    mov byte ptr [scene3d_temp_face], GAME3D_FACE_FLAG_FRAME
    call game3d_emit_quad_from_temps
    ret

game3d_emit_tile_back_panel_trim:
    mov word ptr [scene3d_temp_z], GAME3D_FLOOR_Y
    mov word ptr [scene3d_temp_u], GAME3D_WALL_BAND_TOP_Y
    call game3d_set_tile_back_panel_temps
    call game3d_get_wall_trim_material
    mov [scene3d_temp_color], al
    mov [scene3d_temp_dither], ah
    mov byte ptr [scene3d_temp_face], GAME3D_FACE_FLAG_FRAME
    call game3d_emit_quad_from_temps
    ret

game3d_emit_tile_back_panel_cap:
    mov word ptr [scene3d_temp_z], GAME3D_FLOOR_Y
    mov word ptr [scene3d_temp_u], GAME3D_WALL_TOP_Y
    call game3d_set_tile_back_panel_temps
    call game3d_get_wall_cap_material
    mov [scene3d_temp_color], al
    mov [scene3d_temp_dither], ah
    mov byte ptr [scene3d_temp_face], GAME3D_FACE_FLAG_FRAME
    call game3d_emit_quad_from_temps
    ret

game3d_set_tile_pad_temps:
    push ax
    mov al, bl
    call game3d_world_x_edge_from_al
    add ax, GAME3D_FLOOR_TRIM_INSET + 8
    mov [scene3d_temp_x], ax
    mov al, bl
    inc al
    call game3d_world_x_edge_from_al
    sub ax, GAME3D_FLOOR_TRIM_INSET + 8
    mov [scene3d_temp_y], ax
    mov word ptr [scene3d_temp_z], GAME3D_FLOOR_TRIM_Y
    mov word ptr [scene3d_temp_u], GAME3D_FLOOR_TRIM_Y
    mov al, bh
    call game3d_world_z_edge_from_al
    add ax, GAME3D_FLOOR_TRIM_INSET + 8
    mov [scene3d_temp_v], ax
    mov al, bh
    inc al
    call game3d_world_z_edge_from_al
    sub ax, GAME3D_FLOOR_TRIM_INSET + 8
    mov [scene3d_temp_w], ax
    pop ax
    ret

game3d_set_tile_back_panel_temps:
    push ax
    mov al, bl
    call game3d_world_x_edge_from_al
    add ax, GAME3D_FLOOR_TRIM_INSET
    mov [scene3d_temp_x], ax
    mov al, bl
    inc al
    call game3d_world_x_edge_from_al
    sub ax, GAME3D_FLOOR_TRIM_INSET
    mov [scene3d_temp_y], ax
    mov al, [game3d_room_variant]
    cmp al, GAME3D_ROOM_VARIANT_NORTHWEST
    je game3d_set_tile_back_panel_north
    cmp al, GAME3D_ROOM_VARIANT_NORTHEAST
    je game3d_set_tile_back_panel_north
    mov al, bh
    inc al
    call game3d_world_z_edge_from_al
    mov [scene3d_temp_v], ax
    mov [scene3d_temp_w], ax
    pop ax
    ret

game3d_set_tile_back_panel_north:
    mov al, bh
    call game3d_world_z_edge_from_al
    mov [scene3d_temp_v], ax
    mov [scene3d_temp_w], ax
    pop ax
    ret

game3d_emit_quad_from_temps:
    push ax
    push bx
    push cx
    push dx
    push si
    push di
    push bp
    push es
    push ds
    pop es

    mov ax, [game3d_room_vertex_count]
    add ax, 4
    jc game3d_emit_quad_overflow
    cmp ax, SCENE3D_MAX_VERTICES
    ja game3d_emit_quad_overflow
    mov al, [game3d_room_face_count]
    add al, 2
    jc game3d_emit_quad_overflow
    cmp al, SCENE3D_MAX_FACES
    ja game3d_emit_quad_overflow

    mov al, [scene3d_temp_face]
    mov [game3d_emit_flags], al
    mov ax, [game3d_room_vertex_count]
    mov bl, al
    mov di, ax
    mov ax, SCENE3D_VERTEX_BYTES
    mul di
    mov di, offset game3d_room_vertex_raw
    add di, ax

    mov ax, [scene3d_temp_x]
    stosw
    mov ax, [scene3d_temp_z]
    stosw
    mov ax, [scene3d_temp_v]
    stosw

    mov ax, [scene3d_temp_y]
    stosw
    mov ax, [scene3d_temp_z]
    stosw
    mov ax, [scene3d_temp_v]
    stosw

    mov ax, [scene3d_temp_y]
    stosw
    mov ax, [scene3d_temp_u]
    stosw
    mov ax, [scene3d_temp_w]
    stosw

    mov ax, [scene3d_temp_x]
    stosw
    mov ax, [scene3d_temp_u]
    stosw
    mov ax, [scene3d_temp_w]
    stosw

    mov al, [game3d_room_face_count]
    xor ah, ah
    mov di, ax
    mov ax, SCENE3D_FACE_BYTES
    mul di
    mov di, offset game3d_room_face_raw
    add di, ax

    mov al, bl
    stosb
    mov al, bl
    inc al
    stosb
    mov al, bl
    add al, 2
    stosb
    mov al, [scene3d_temp_color]
    stosb
    mov al, [scene3d_temp_dither]
    stosb
    mov al, [game3d_emit_flags]
    stosb
    mov al, [scene3d_temp_texture]
    stosb

    mov al, bl
    stosb
    mov al, bl
    add al, 2
    stosb
    mov al, bl
    add al, 3
    stosb
    mov al, [scene3d_temp_color]
    stosb
    mov al, [scene3d_temp_dither]
    stosb
    mov al, [game3d_emit_flags]
    stosb
    mov al, [scene3d_temp_texture]
    stosb

    mov ax, [game3d_room_vertex_count]
    add ax, 4
    mov [game3d_room_vertex_count], ax
    mov al, [game3d_room_face_count]
    add al, 2
    mov [game3d_room_face_count], al
    jmp game3d_emit_quad_done

game3d_emit_quad_overflow:
    mov byte ptr [game3d_room_overflow], 1

game3d_emit_quad_done:
    pop es
    pop bp
    pop di
    pop si
    pop dx
    pop cx
    pop bx
    pop ax
    ret

game3d_emit_optional_quad_from_temps:
    push ax
    mov al, [game3d_optional_faces_remaining]
    cmp al, 2
    jb game3d_emit_optional_quad_done
    mov al, [game3d_room_face_count]
    cmp al, SCENE3D_MAX_FACES - 2
    ja game3d_emit_optional_quad_done
    call game3d_emit_quad_from_temps
    cmp byte ptr [game3d_room_overflow], 0
    jne game3d_emit_optional_quad_done
    sub byte ptr [game3d_optional_faces_remaining], 2

game3d_emit_optional_quad_done:
    pop ax
    ret

game3d_get_kit_index:
    mov al, [sector_num]
    dec al
    ret

game3d_get_floor_base_material:
    push bx
    call game3d_get_kit_index
    xor ah, ah
    mov bx, ax
    mov al, cs:[game3d_kit_floor_base_color_table + bx]
    mov ah, cs:[game3d_kit_floor_base_dither_table + bx]
    mov dl, cs:[game3d_kit_floor_base_texture_table + bx]
    mov [scene3d_temp_texture], dl
    pop bx
    ret

game3d_get_floor_trim_material:
    push bx
    call game3d_get_kit_index
    xor ah, ah
    mov bx, ax
    mov al, cs:[game3d_kit_floor_trim_color_table + bx]
    mov ah, cs:[game3d_kit_floor_trim_dither_table + bx]
    mov dl, cs:[game3d_kit_floor_trim_texture_table + bx]
    mov [scene3d_temp_texture], dl
    pop bx
    ret

game3d_get_floor_far_material:
    call game3d_get_lane_trim_material
    ret

game3d_get_wall_far_material:
    call game3d_get_far_mass_material
    ret

game3d_get_wall_base_material:
    push bx
    call game3d_get_kit_index
    xor ah, ah
    mov bx, ax
    mov al, cs:[game3d_kit_wall_base_color_table + bx]
    mov ah, cs:[game3d_kit_wall_base_dither_table + bx]
    mov dl, cs:[game3d_kit_wall_base_texture_table + bx]
    mov [scene3d_temp_texture], dl
    pop bx
    ret

game3d_get_wall_trim_material:
    push bx
    call game3d_get_kit_index
    xor ah, ah
    mov bx, ax
    mov al, cs:[game3d_kit_wall_trim_color_table + bx]
    mov ah, cs:[game3d_kit_wall_trim_dither_table + bx]
    mov dl, cs:[game3d_kit_wall_trim_texture_table + bx]
    mov [scene3d_temp_texture], dl
    pop bx
    ret

game3d_get_wall_cap_material:
    push bx
    call game3d_get_kit_index
    xor ah, ah
    mov bx, ax
    mov al, cs:[game3d_kit_wall_cap_color_table + bx]
    mov ah, cs:[game3d_kit_wall_cap_dither_table + bx]
    mov dl, cs:[game3d_kit_wall_cap_texture_table + bx]
    mov [scene3d_temp_texture], dl
    pop bx
    ret

game3d_get_lane_material:
    push bx
    call game3d_get_kit_index
    xor ah, ah
    mov bx, ax
    mov al, cs:[game3d_kit_lane_color_table + bx]
    mov ah, cs:[game3d_kit_lane_dither_table + bx]
    mov dl, cs:[game3d_kit_lane_texture_table + bx]
    mov [scene3d_temp_texture], dl
    pop bx
    ret

game3d_get_ceiling_material:
    push bx
    call game3d_get_kit_index
    xor ah, ah
    mov bx, ax
    mov al, cs:[game3d_kit_ceiling_color_table + bx]
    mov ah, cs:[game3d_kit_ceiling_dither_table + bx]
    mov dl, cs:[game3d_kit_ceiling_texture_table + bx]
    mov [scene3d_temp_texture], dl
    pop bx
    ret

game3d_get_soffit_material:
    push bx
    call game3d_get_kit_index
    xor ah, ah
    mov bx, ax
    mov al, cs:[game3d_kit_soffit_color_table + bx]
    mov ah, cs:[game3d_kit_soffit_dither_table + bx]
    mov dl, cs:[game3d_kit_soffit_texture_table + bx]
    mov [scene3d_temp_texture], dl
    pop bx
    ret

game3d_get_lane_trim_material:
    push bx
    call game3d_get_kit_index
    xor ah, ah
    mov bx, ax
    mov al, cs:[game3d_kit_lane_trim_color_table + bx]
    mov ah, cs:[game3d_kit_lane_trim_dither_table + bx]
    mov dl, cs:[game3d_kit_lane_trim_texture_table + bx]
    mov [scene3d_temp_texture], dl
    pop bx
    ret

game3d_get_far_mass_material:
    push bx
    call game3d_get_kit_index
    xor ah, ah
    mov bx, ax
    mov al, cs:[game3d_kit_far_mass_color_table + bx]
    mov ah, cs:[game3d_kit_far_mass_dither_table + bx]
    mov dl, cs:[game3d_kit_far_mass_texture_table + bx]
    mov [scene3d_temp_texture], dl
    pop bx
    ret

game3d_get_accent_material:
    push bx
    call game3d_get_kit_index
    xor ah, ah
    mov bx, ax
    mov al, cs:[game3d_kit_accent_color_table + bx]
    mov ah, cs:[game3d_kit_accent_dither_table + bx]
    mov dl, cs:[game3d_kit_accent_texture_table + bx]
    mov [scene3d_temp_texture], dl
    pop bx
    ret

game3d_get_cliff_material:
    push bx
    call game3d_get_kit_index
    xor ah, ah
    mov bx, ax
    mov al, cs:[game3d_kit_cliff_color_table + bx]
    mov ah, cs:[game3d_kit_cliff_dither_table + bx]
    mov dl, cs:[game3d_kit_cliff_texture_table + bx]
    mov [scene3d_temp_texture], dl
    pop bx
    ret

game3d_get_shelf_material:
    push bx
    call game3d_get_kit_index
    xor ah, ah
    mov bx, ax
    mov al, cs:[game3d_kit_shelf_color_table + bx]
    mov ah, cs:[game3d_kit_shelf_dither_table + bx]
    mov dl, cs:[game3d_kit_shelf_texture_table + bx]
    mov [scene3d_temp_texture], dl
    pop bx
    ret

game3d_get_bridge_material:
    push bx
    call game3d_get_kit_index
    xor ah, ah
    mov bx, ax
    mov al, cs:[game3d_kit_bridge_color_table + bx]
    mov ah, cs:[game3d_kit_bridge_dither_table + bx]
    mov dl, cs:[game3d_kit_bridge_texture_table + bx]
    mov [scene3d_temp_texture], dl
    pop bx
    ret

game3d_get_landmark_lift:
    push bx
    call game3d_get_kit_index
    xor ah, ah
    mov bx, ax
    shl bx, 1
    mov ax, cs:[game3d_kit_landmark_lift_table + bx]
    pop bx
    ret

IF DEBUG_LEGACY_GAMEPLAY
game3d_get_tile_ground_y:
    mov ax, GAME3D_FLOOR_Y
    ret
ENDIF

game3d_get_shot_table_index:
    push bx
    mov bl, al
    call game3d_get_kit_index
    mov bh, GAME3D_SHOT_COUNT
    mul bh
    add al, bl
    adc ah, 0
    pop bx
    ret

game3d_get_shot_height_for_mode:
    push bx
    call game3d_get_shot_table_index
    mov bx, ax
    shl bx, 1
    mov ax, cs:[game3d_kit_shot_height_table + bx]
    pop bx
    ret

game3d_get_shot_distance_for_mode:
    push bx
    call game3d_get_shot_table_index
    mov bx, ax
    shl bx, 1
    mov ax, cs:[game3d_kit_shot_distance_table + bx]
    pop bx
    ret

game3d_get_shot_look_ahead_for_mode:
    push bx
    call game3d_get_shot_table_index
    mov bx, ax
    shl bx, 1
    mov ax, cs:[game3d_kit_shot_look_ahead_table + bx]
    pop bx
    ret

game3d_get_shot_pitch_for_mode:
    push bx
    call game3d_get_shot_table_index
    mov bx, ax
    mov al, cs:[game3d_kit_shot_pitch_table + bx]
    pop bx
    ret

game3d_get_shot_project_scale_for_mode:
    push bx
    call game3d_get_shot_table_index
    mov bx, ax
    shl bx, 1
    mov ax, cs:[game3d_kit_shot_project_scale_table + bx]
    pop bx
    ret

game3d_get_shot_horizon_for_mode:
    push bx
    call game3d_get_shot_table_index
    mov bx, ax
    mov al, cs:[game3d_kit_shot_horizon_table + bx]
    pop bx
    ret

game3d_get_shot_focus_bias_x_for_mode:
    push bx
    call game3d_get_shot_table_index
    mov bx, ax
    shl bx, 1
    mov ax, cs:[game3d_kit_shot_focus_bias_x_table + bx]
    pop bx
    ret

game3d_get_shot_focus_bias_z_for_mode:
    push bx
    call game3d_get_shot_table_index
    mov bx, ax
    shl bx, 1
    mov ax, cs:[game3d_kit_shot_focus_bias_z_table + bx]
    pop bx
    ret

game3d_get_camera_height:
    mov al, GAME3D_SHOT_BASE_CHASE
    call game3d_get_shot_height_for_mode
    ret

game3d_get_camera_distance:
    mov al, GAME3D_SHOT_BASE_CHASE
    call game3d_get_shot_distance_for_mode
    ret

game3d_get_camera_look_ahead:
    mov al, GAME3D_SHOT_BASE_CHASE
    call game3d_get_shot_look_ahead_for_mode
    ret

game3d_get_projection_pitch:
    mov al, GAME3D_SHOT_BASE_CHASE
    call game3d_get_shot_pitch_for_mode
    ret

game3d_get_projection_scale:
    mov al, GAME3D_SHOT_BASE_CHASE
    call game3d_get_shot_project_scale_for_mode
    ret

game3d_get_near_occluder_inset:
    push bx
    call game3d_get_kit_index
    xor ah, ah
    mov bx, ax
    shl bx, 1
    mov ax, cs:[game3d_kit_near_occluder_inset_table + bx]
    pop bx
    ret

game3d_get_near_occluder_width:
    push bx
    call game3d_get_kit_index
    xor ah, ah
    mov bx, ax
    shl bx, 1
    mov ax, cs:[game3d_kit_near_occluder_width_table + bx]
    pop bx
    ret

game3d_get_near_occluder_height:
    push bx
    call game3d_get_kit_index
    xor ah, ah
    mov bx, ax
    shl bx, 1
    mov ax, cs:[game3d_kit_near_occluder_height_table + bx]
    pop bx
    ret

game3d_get_far_silhouette_inset:
    push bx
    call game3d_get_kit_index
    xor ah, ah
    mov bx, ax
    shl bx, 1
    mov ax, cs:[game3d_kit_far_silhouette_inset_table + bx]
    pop bx
    ret

game3d_get_far_silhouette_height:
    push bx
    call game3d_get_kit_index
    xor ah, ah
    mov bx, ax
    shl bx, 1
    mov ax, cs:[game3d_kit_far_silhouette_height_table + bx]
    pop bx
    ret

game3d_get_backdrop_far_color:
    push bx
    call game3d_get_kit_index
    xor ah, ah
    mov bx, ax
    mov al, cs:[game3d_kit_backdrop_far_color_table + bx]
    pop bx
    ret

game3d_get_backdrop_mid_color:
    push bx
    call game3d_get_kit_index
    xor ah, ah
    mov bx, ax
    mov al, cs:[game3d_kit_backdrop_mid_color_table + bx]
    pop bx
    ret

game3d_get_backdrop_near_color:
    push bx
    call game3d_get_kit_index
    xor ah, ah
    mov bx, ax
    mov al, cs:[game3d_kit_backdrop_near_color_table + bx]
    pop bx
    ret

game3d_get_horizon_a_color:
    push bx
    call game3d_get_kit_index
    xor ah, ah
    mov bx, ax
    mov al, cs:[game3d_kit_horizon_a_color_table + bx]
    pop bx
    ret

game3d_get_horizon_b_color:
    push bx
    call game3d_get_kit_index
    xor ah, ah
    mov bx, ax
    mov al, cs:[game3d_kit_horizon_b_color_table + bx]
    pop bx
    ret

game3d_get_horizon_y:
    mov al, GAME3D_SHOT_BASE_CHASE
    call game3d_get_shot_horizon_for_mode
    ret

game3d_get_wobble_strength:
    push bx
    call game3d_get_kit_index
    xor ah, ah
    mov bx, ax
    mov al, cs:[game3d_kit_wobble_strength_table + bx]
    pop bx
    ret

game3d_get_fog_near_depth:
    push bx
    call game3d_get_kit_index
    xor ah, ah
    mov bx, ax
    shl bx, 1
    mov ax, cs:[game3d_kit_fog_near_table + bx]
    pop bx
    ret

game3d_get_fog_far_depth:
    push bx
    call game3d_get_kit_index
    xor ah, ah
    mov bx, ax
    shl bx, 1
    mov ax, cs:[game3d_kit_fog_far_table + bx]
    pop bx
    ret

game3d_get_active_shot_height:
    mov al, [game3d_shot_mode]
    call game3d_get_shot_height_for_mode
    ret

game3d_get_active_shot_distance:
    mov al, [game3d_shot_mode]
    call game3d_get_shot_distance_for_mode
    ret

game3d_get_active_shot_look_ahead:
    mov al, [game3d_shot_mode]
    call game3d_get_shot_look_ahead_for_mode
    ret

game3d_get_active_shot_pitch:
    mov al, [game3d_shot_mode]
    call game3d_get_shot_pitch_for_mode
    ret

game3d_get_active_shot_project_scale:
    mov al, [game3d_shot_mode]
    call game3d_get_shot_project_scale_for_mode
    ret

game3d_get_active_shot_horizon:
    mov al, [game3d_shot_mode]
    call game3d_get_shot_horizon_for_mode
    ret

game3d_get_active_shot_focus_bias_x:
    mov al, [game3d_shot_mode]
    call game3d_get_shot_focus_bias_x_for_mode
    ret

game3d_get_active_shot_focus_bias_z:
    mov al, [game3d_shot_mode]
    call game3d_get_shot_focus_bias_z_for_mode
    ret

game3d_get_frame_door_inset:
    push bx
    call game3d_get_kit_index
    xor ah, ah
    mov bx, ax
    shl bx, 1
    mov ax, cs:[game3d_kit_frame_door_inset_table + bx]
    pop bx
    ret

game3d_get_frame_door_width:
    push bx
    call game3d_get_kit_index
    xor ah, ah
    mov bx, ax
    shl bx, 1
    mov ax, cs:[game3d_kit_frame_door_width_table + bx]
    pop bx
    ret

game3d_get_frame_door_height:
    push bx
    call game3d_get_kit_index
    xor ah, ah
    mov bx, ax
    shl bx, 1
    mov ax, cs:[game3d_kit_frame_door_height_table + bx]
    pop bx
    ret

game3d_get_frame_rail_inset:
    push bx
    call game3d_get_kit_index
    xor ah, ah
    mov bx, ax
    shl bx, 1
    mov ax, cs:[game3d_kit_frame_rail_inset_table + bx]
    pop bx
    ret

game3d_get_frame_rail_width:
    push bx
    call game3d_get_kit_index
    xor ah, ah
    mov bx, ax
    shl bx, 1
    mov ax, cs:[game3d_kit_frame_rail_width_table + bx]
    pop bx
    ret

game3d_get_frame_rail_height:
    push bx
    call game3d_get_kit_index
    xor ah, ah
    mov bx, ax
    shl bx, 1
    mov ax, cs:[game3d_kit_frame_rail_height_table + bx]
    pop bx
    ret

game3d_get_frame_ceiling_height:
    push bx
    call game3d_get_kit_index
    xor ah, ah
    mov bx, ax
    shl bx, 1
    mov ax, cs:[game3d_kit_frame_ceiling_height_table + bx]
    pop bx
    ret

game3d_get_frame_ceiling_thickness:
    push bx
    call game3d_get_kit_index
    xor ah, ah
    mov bx, ax
    shl bx, 1
    mov ax, cs:[game3d_kit_frame_ceiling_thickness_table + bx]
    pop bx
    ret

game3d_get_frame_far_mass_inset:
    push bx
    call game3d_get_kit_index
    xor ah, ah
    mov bx, ax
    shl bx, 1
    mov ax, cs:[game3d_kit_frame_far_mass_inset_table + bx]
    pop bx
    ret

game3d_get_frame_far_mass_width:
    push bx
    call game3d_get_kit_index
    xor ah, ah
    mov bx, ax
    shl bx, 1
    mov ax, cs:[game3d_kit_frame_far_mass_width_table + bx]
    pop bx
    ret

game3d_get_frame_far_mass_height:
    push bx
    call game3d_get_kit_index
    xor ah, ah
    mov bx, ax
    shl bx, 1
    mov ax, cs:[game3d_kit_frame_far_mass_height_table + bx]
    pop bx
    ret

game3d_get_landmark_mesh_index:
    push bx
    call game3d_get_kit_index
    xor ah, ah
    mov bx, ax
    mov al, cs:[game3d_kit_landmark_mesh_table + bx]
    pop bx
    ret

game3d_get_gate_mesh_index:
    push bx
    call game3d_get_kit_index
    xor ah, ah
    mov bx, ax
    mov al, cs:[game3d_kit_gate_mesh_table + bx]
    pop bx
    ret

game3d_get_terminal_mesh_index:
    push bx
    call game3d_get_kit_index
    xor ah, ah
    mov bx, ax
    mov al, cs:[game3d_kit_terminal_mesh_table + bx]
    pop bx
    ret

game3d_get_surge_mesh_index:
    push bx
    call game3d_get_kit_index
    xor ah, ah
    mov bx, ax
    mov al, cs:[game3d_kit_surge_mesh_table + bx]
    pop bx
    ret

game3d_get_shard_mesh_index:
    push bx
    call game3d_get_kit_index
    xor ah, ah
    mov bx, ax
    mov al, cs:[game3d_kit_shard_mesh_table + bx]
    pop bx
    ret

game3d_tile_in_active_chunk_range:
IF DEBUG_LEGACY_GAMEPLAY
    mov al, 1
    ret
ENDIF
    mov al, bl
    cmp al, [adventure_chunk_min_x]
    jb game3d_tile_chunk_no
    cmp al, [adventure_chunk_max_x]
    ja game3d_tile_chunk_no
    mov al, bh
    cmp al, [adventure_chunk_min_y]
    jb game3d_tile_chunk_no
    cmp al, [adventure_chunk_max_y]
    ja game3d_tile_chunk_no
    mov al, 1
    ret

game3d_tile_chunk_no:
    xor al, al
    ret

game3d_should_emit_north_face:
IF DEBUG_LEGACY_GAMEPLAY EQ 0
    call game3d_tile_in_active_chunk_range
    cmp al, 0
    je game3d_face_no
ENDIF
    call game3d_is_wall_tile
    cmp al, 0
    je game3d_face_no
    cmp bh, 0
    je game3d_face_yes
    dec bh
    call game3d_is_wall_tile
    cmp al, 0
    je game3d_face_yes
    jmp game3d_face_no

game3d_should_emit_south_face:
IF DEBUG_LEGACY_GAMEPLAY EQ 0
    call game3d_tile_in_active_chunk_range
    cmp al, 0
    je game3d_face_no
ENDIF
    call game3d_is_wall_tile
    cmp al, 0
    je game3d_face_no
    cmp bh, MAP_H - 1
    je game3d_face_yes
    inc bh
    call game3d_is_wall_tile
    cmp al, 0
    je game3d_face_yes
    jmp game3d_face_no

game3d_should_emit_west_face:
IF DEBUG_LEGACY_GAMEPLAY EQ 0
    call game3d_tile_in_active_chunk_range
    cmp al, 0
    je game3d_face_no
ENDIF
    call game3d_is_wall_tile
    cmp al, 0
    je game3d_face_no
    cmp bl, 0
    je game3d_face_yes
    dec bl
    call game3d_is_wall_tile
    cmp al, 0
    je game3d_face_yes
    jmp game3d_face_no

game3d_should_emit_east_face:
IF DEBUG_LEGACY_GAMEPLAY EQ 0
    call game3d_tile_in_active_chunk_range
    cmp al, 0
    je game3d_face_no
ENDIF
    call game3d_is_wall_tile
    cmp al, 0
    je game3d_face_no
    cmp bl, MAP_W - 1
    je game3d_face_yes
    inc bl
    call game3d_is_wall_tile
    cmp al, 0
    je game3d_face_yes
    jmp game3d_face_no

game3d_face_yes:
    mov al, 1
    ret

game3d_face_no:
    xor al, al
    ret

game3d_is_wall_tile:
    push bx
    call get_tile
    pop bx
    cmp al, TILE_WALL
    jne game3d_is_wall_no
    mov al, 1
    ret

game3d_is_wall_no:
    xor al, al
    ret

game3d_world_x_edge_from_al:
    mov ah, al
    xor al, al
    sub ax, GAME3D_WORLD_ORIGIN_X
    ret

game3d_world_z_edge_from_al:
    mov ah, al
    xor al, al
    sub ax, GAME3D_WORLD_ORIGIN_Z
    ret

game3d_get_tile_center_world:
    xor ax, ax
    mov ah, bl
    add ax, 128
    sub ax, GAME3D_WORLD_ORIGIN_X
    xor dx, dx
    mov dh, bh
    add dx, 128
    sub dx, GAME3D_WORLD_ORIGIN_Z
    ret

game3d_project_world_point:
    ; Input: AX = world X, BX = world Y, DX = world Z
    ; Output: AX = screen X, DX = screen Y, CX = depth. Carry = visible.
    push si
    push di
    push bp

    sub ax, [scene3d_cam_x]
    mov [scene3d_temp_v], ax
    mov ax, bx
    sub ax, [scene3d_cam_y]
    mov [scene3d_temp_w], ax
    mov ax, dx
    sub ax, [scene3d_cam_z]
    mov [scene3d_temp_l], ax

    mov al, [scene3d_yaw_angle]
    call scene3d_get_sin_cos
    mov [scene3d_temp_x], bx
    mov [scene3d_temp_y], dx

    mov al, [scene3d_pitch_angle]
    call scene3d_get_sin_cos
    mov [scene3d_temp_z], bx
    mov [scene3d_temp_u], dx

    mov ax, [scene3d_temp_v]
    mov [scene3d_temp_r], ax
    mov ax, [scene3d_temp_v]
    mov bx, [scene3d_temp_y]
    call scene3d_mul_ax_bx_fixed
    mov di, ax
    mov ax, [scene3d_temp_l]
    mov bx, [scene3d_temp_x]
    call scene3d_mul_ax_bx_fixed
    sub di, ax
    mov [scene3d_temp_v], di

    mov ax, [scene3d_temp_r]
    mov bx, [scene3d_temp_x]
    call scene3d_mul_ax_bx_fixed
    mov [scene3d_temp_r], ax
    mov ax, [scene3d_temp_l]
    mov bx, [scene3d_temp_y]
    call scene3d_mul_ax_bx_fixed
    add ax, [scene3d_temp_r]
    mov [scene3d_temp_l], ax

    mov ax, [scene3d_temp_w]
    mov [scene3d_temp_r], ax
    mov ax, [scene3d_temp_w]
    mov bx, [scene3d_temp_u]
    call scene3d_mul_ax_bx_fixed
    mov di, ax
    mov ax, [scene3d_temp_l]
    mov bx, [scene3d_temp_z]
    call scene3d_mul_ax_bx_fixed
    sub di, ax
    mov [scene3d_temp_w], di

    mov ax, [scene3d_temp_r]
    mov bx, [scene3d_temp_z]
    call scene3d_mul_ax_bx_fixed
    mov [scene3d_temp_r], ax
    mov ax, [scene3d_temp_l]
    mov bx, [scene3d_temp_u]
    call scene3d_mul_ax_bx_fixed
    add ax, [scene3d_temp_r]
    mov [scene3d_temp_l], ax

    mov cx, [scene3d_temp_l]
    cmp cx, SCENE3D_NEAR_Z
    jg game3d_project_visible
    clc
    jmp game3d_project_done

game3d_project_visible:
    mov bx, [scene3d_project_scale]
    mov ax, [scene3d_temp_v]
    call scene3d_project_ax
    add ax, [scene3d_center_x]
    mov si, ax

    mov cx, [scene3d_temp_l]
    mov bx, [scene3d_project_scale]
    mov ax, [scene3d_temp_w]
    call scene3d_project_ax
    neg ax
    add ax, [scene3d_center_y]
    mov dx, ax
    mov ax, si
    stc

game3d_project_done:
    pop bp
    pop di
    pop si
    ret

game3d_project_tile_center:
    call game3d_get_tile_center_world
    push ax
    push dx
IF DEBUG_LEGACY_GAMEPLAY
    call game3d_get_tile_ground_y
ELSE
    call adventure_get_tile_ground_y
ENDIF
    mov bx, ax
    pop dx
    pop ax
    call game3d_project_world_point
    ret

game3d_setup_signature_camera:
    call game3d_setup_camera_now
    ret

game3d_tile_requires_cue_fallback:
    call game3d_project_tile_center
    jnc game3d_tile_fallback_yes
    call game3d_is_projected_point_cue_ready
    jc game3d_tile_fallback_no

game3d_tile_fallback_yes:
    stc
    ret

game3d_tile_fallback_no:
    clc
    ret

game3d_get_runtime_cue_flags:
    push bx
    push cx
    push dx
    xor dl, dl
    call game3d_setup_signature_camera

    mov bl, [player_x]
    mov bh, [player_y]
    call game3d_project_tile_center
    jnc game3d_runtime_player_fallback
    cmp cx, GAME3D_PLAYER_LOCATOR_FAR_DEPTH
    jg game3d_runtime_player_fallback
    call game3d_is_projected_point_cue_ready
    jc game3d_runtime_exit_check

game3d_runtime_player_fallback:
    or dl, GAME3D_CUE_FLAG_PLAYER_FALLBACK

game3d_runtime_exit_check:
    mov bl, [exit_x]
    mov bh, [exit_y]
    call game3d_tile_requires_cue_fallback
    jnc game3d_runtime_spoof_check
    or dl, GAME3D_CUE_FLAG_EXIT_FALLBACK

game3d_runtime_spoof_check:
    cmp byte ptr [spoof_timer], 0
    je game3d_runtime_threat_check
    mov bl, [spoof_x]
    mov bh, [spoof_y]
    call game3d_tile_requires_cue_fallback
    jnc game3d_runtime_threat_check
    or dl, GAME3D_CUE_FLAG_SPOOF_FALLBACK

game3d_runtime_threat_check:
    cmp byte ptr [threat_level], THREAT_NONE
    je game3d_runtime_flags_done
    mov bl, [threat_x]
    mov bh, [threat_y]
    call game3d_tile_requires_cue_fallback
    jnc game3d_runtime_flags_done
    or dl, GAME3D_CUE_FLAG_THREAT_FALLBACK

game3d_runtime_flags_done:
    mov al, dl
    pop dx
    pop cx
    pop bx
    ret

game3d_get_scale_for_depth:
    mov al, 1
    cmp cx, GAME3D_BILLBOARD_NEAR_DEPTH
    ja game3d_scale_ready
    mov al, 2

game3d_scale_ready:
    ret

game3d_draw_mesh_instance:
    push ax
    push bx
    push cx
    push dx
    push si
    push di
    push bp
    push es

    xor bx, bx
    mov bl, [game3d_mesh_index]
    mov al, cs:[game3d_mesh_vertex_count_table + bx]
    xor ah, ah
    mov [scene3d_vertex_count], ax
    mov al, cs:[game3d_mesh_face_count_table + bx]
    mov [scene3d_face_count], al
    or al, al
    jz game3d_draw_mesh_instance_done

    mov word ptr [scene3d_vertex_source], offset scene3d_vertex_raw
    mov word ptr [scene3d_face_source], offset scene3d_face_raw

    mov al, [game3d_mesh_yaw]
    call scene3d_get_sin_cos
    mov [scene3d_temp_x], bx
    mov [scene3d_temp_y], dx

    mov ax, GEOMETRY_BANK_SEG
    mov es, ax

    xor bx, bx
    mov bl, [game3d_mesh_index]
    shl bx, 1
    mov si, cs:[game3d_mesh_vertex_offset_table + bx]
    mov di, offset scene3d_vertex_raw
    xor bp, bp

game3d_mesh_vertex_loop:
    mov ax, bp
    cmp ax, [scene3d_vertex_count]
    jae game3d_mesh_faces_begin

    mov ax, es:[si]
    mov [scene3d_temp_v], ax
    mov ax, es:[si + 2]
    mov [scene3d_temp_w], ax
    mov ax, es:[si + 4]
    mov [scene3d_temp_l], ax

    mov ax, [scene3d_temp_v]
    mov bx, [scene3d_temp_y]
    call scene3d_mul_ax_bx_fixed
    mov [scene3d_temp_r], ax
    mov ax, [scene3d_temp_l]
    mov bx, [scene3d_temp_x]
    call scene3d_mul_ax_bx_fixed
    mov dx, [scene3d_temp_r]
    sub dx, ax
    mov ax, dx
    add ax, [game3d_mesh_world_x]
    mov [di], ax

    mov ax, [scene3d_temp_w]
    add ax, [game3d_mesh_world_y]
    mov [di + 2], ax

    mov ax, [scene3d_temp_v]
    mov bx, [scene3d_temp_x]
    call scene3d_mul_ax_bx_fixed
    mov [scene3d_temp_r], ax
    mov ax, [scene3d_temp_l]
    mov bx, [scene3d_temp_y]
    call scene3d_mul_ax_bx_fixed
    add ax, [scene3d_temp_r]
    add ax, [game3d_mesh_world_z]
    mov [di + 4], ax

    add si, SCENE3D_VERTEX_BYTES
    add di, SCENE3D_VERTEX_BYTES
    inc bp
    jmp game3d_mesh_vertex_loop

game3d_mesh_faces_begin:
    xor bx, bx
    mov bl, [game3d_mesh_index]
    shl bx, 1
    mov si, cs:[game3d_mesh_face_offset_table + bx]
    mov di, offset scene3d_face_raw
    xor bp, bp

game3d_mesh_face_loop:
    mov al, [scene3d_face_count]
    xor ah, ah
    cmp bp, ax
    jae game3d_mesh_render_ready

    mov al, es:[si]
    mov [di], al
    mov al, es:[si + 1]
    mov [di + 1], al
    mov al, es:[si + 2]
    mov [di + 2], al
    mov al, es:[si + 3]
    mov [di + 3], al
    mov al, es:[si + 4]
    mov [di + 4], al
    mov al, [game3d_mesh_face_flags]
    or al, al
    jnz game3d_mesh_face_flags_ready
    mov al, es:[si + 5]

game3d_mesh_face_flags_ready:
    mov [di + 5], al
    mov al, es:[si + 6]
    mov [di + 6], al
    add si, SCENE3D_FACE_BYTES
    add di, SCENE3D_FACE_BYTES
    inc bp
    jmp game3d_mesh_face_loop

game3d_mesh_render_ready:
    call scene3d_project_vertices
    call scene3d_build_face_order
    call scene3d_draw_face_order

game3d_draw_mesh_instance_done:
    pop es
    pop bp
    pop di
    pop si
    pop dx
    pop cx
    pop bx
    pop ax
    ret

game3d_draw_shadow_at_projected_point:
    push ax
    push bx
    push cx
    push dx
    push bp
    push si
    mov si, ax
    call game3d_get_scale_for_depth
    mov cl, 6
    cmp al, 2
    jne game3d_shadow_size_ready
    mov cl, 8

game3d_shadow_size_ready:
    xor ax, ax
    mov al, cl
    mov bx, si
    sub bx, ax
    sub dx, 1
    shl ax, 1
    inc ax
    mov cx, ax
    mov bp, 4
    mov al, PAL_PANEL
    call fill_rect
    pop si
    pop bp
    pop dx
    pop cx
    pop bx
    pop ax
    ret

game3d_draw_marker_at_projected_point:
    push ax
    push bx
    push cx
    push dx
    push bp
    push si
    mov si, ax
    mov [text_color], bl
    call game3d_get_scale_for_depth
    mov cl, 2
    cmp al, 2
    jne game3d_marker_size_ready
    mov cl, 3

game3d_marker_size_ready:
    xor ax, ax
    mov al, cl
    mov bx, si
    sub bx, ax
    sub dx, ax
    shl ax, 1
    inc ax
    mov cx, ax
    mov bp, ax
    mov al, [text_color]
    call draw_rect_outline
    pop si
    pop bp
    pop dx
    pop cx
    pop bx
    pop ax
    ret

game3d_draw_sprite8_2x:
    push ax
    push bx
    push cx
    push dx
    push si
    push di
    push bp
    mov [glyph_base_x], bx
    mov [glyph_base_y], dx
    xor bp, bp

game3d_sprite2x_row:
    cmp bp, 8
    jae game3d_sprite2x_done
    xor di, di

game3d_sprite2x_col:
    cmp di, 8
    jae game3d_sprite2x_next_row
    lodsb
    or al, al
    jz game3d_sprite2x_skip
    push bp
    push di
    mov bx, [glyph_base_x]
    mov dx, [glyph_base_y]
    mov ax, di
    shl ax, 1
    add bx, ax
    mov ax, bp
    shl ax, 1
    add dx, ax
    mov cx, 2
    mov bp, 2
    call fill_rect
    pop di
    pop bp

game3d_sprite2x_skip:
    inc di
    jmp game3d_sprite2x_col

game3d_sprite2x_next_row:
    inc bp
    jmp game3d_sprite2x_row

game3d_sprite2x_done:
    pop bp
    pop di
    pop si
    pop dx
    pop cx
    pop bx
    pop ax
    ret

game3d_draw_sprite_billboard:
    ; Input: AX = projected X, DX = projected Y, CX = depth, SI = sprite.
    push ax
    push bx
    push cx
    push dx
    push bp
    mov bp, ax
    call game3d_get_scale_for_depth
    cmp al, 2
    jne game3d_draw_sprite_billboard_1x
    mov bx, bp
    sub bx, 8
    sub dx, 15
    call game3d_draw_sprite8_2x
    jmp game3d_draw_sprite_billboard_done

game3d_draw_sprite_billboard_1x:
    mov bx, bp
    sub bx, 4
    sub dx, 7
    call draw_sprite8

game3d_draw_sprite_billboard_done:
    pop bp
    pop dx
    pop cx
    pop bx
    pop ax
    ret

game3d_is_projected_point_cue_ready:
    push bx
    push dx
    mov bx, GAME3D_VIEW_X + GAME3D_CUE_EDGE_MARGIN
    cmp ax, bx
    jb game3d_cue_not_ready
    mov bx, GAME3D_VIEW_X + GAME3D_VIEW_W - 1 - GAME3D_CUE_EDGE_MARGIN
    cmp ax, bx
    ja game3d_cue_not_ready
    mov bx, GAME3D_VIEW_Y + GAME3D_CUE_EDGE_MARGIN
    cmp dx, bx
    jb game3d_cue_not_ready
    mov bx, GAME3D_VIEW_Y + GAME3D_VIEW_H - 1 - GAME3D_CUE_EDGE_MARGIN
    cmp dx, bx
    ja game3d_cue_not_ready
    stc
    jmp game3d_cue_ready_done

game3d_cue_not_ready:
    clc

game3d_cue_ready_done:
    pop dx
    pop bx
    ret

game3d_clamp_projected_point_to_view:
    cmp ax, GAME3D_VIEW_X + GAME3D_CUE_EDGE_MARGIN
    jge game3d_clamp_x_high
    mov ax, GAME3D_VIEW_X + GAME3D_CUE_EDGE_MARGIN
    jmp game3d_clamp_y_low

game3d_clamp_x_high:
    cmp ax, GAME3D_VIEW_X + GAME3D_VIEW_W - 1 - GAME3D_CUE_EDGE_MARGIN
    jle game3d_clamp_y_low
    mov ax, GAME3D_VIEW_X + GAME3D_VIEW_W - 1 - GAME3D_CUE_EDGE_MARGIN

game3d_clamp_y_low:
    cmp dx, GAME3D_VIEW_Y + GAME3D_CUE_EDGE_MARGIN
    jge game3d_clamp_y_high
    mov dx, GAME3D_VIEW_Y + GAME3D_CUE_EDGE_MARGIN
    ret

game3d_clamp_y_high:
    cmp dx, GAME3D_VIEW_Y + GAME3D_VIEW_H - 1 - GAME3D_CUE_EDGE_MARGIN
    jle game3d_clamp_done
    mov dx, GAME3D_VIEW_Y + GAME3D_VIEW_H - 1 - GAME3D_CUE_EDGE_MARGIN

game3d_clamp_done:
    ret

game3d_draw_beacon_mesh_at_tile:
    push ax
    push bx
    push dx
    mov al, [game3d_mesh_index]
    mov dl, [anim_phase]
    shl dl, 4
    call game3d_prepare_mesh_at_tile
    mov word ptr [game3d_mesh_world_y], GAME3D_BEACON_BASE_Y
    test byte ptr [anim_phase], 1
    jz game3d_draw_beacon_mesh_ready
    add word ptr [game3d_mesh_world_y], GAME3D_BEACON_BOB_Y

game3d_draw_beacon_mesh_ready:
    call game3d_draw_mesh_instance
    pop dx
    pop bx
    pop ax
    ret

game3d_tile_matches_shot_subject:
    mov al, [game3d_shot_subject_x]
    cmp bl, al
    jne game3d_tile_matches_shot_subject_no
    mov al, [game3d_shot_subject_y]
    cmp bh, al
    jne game3d_tile_matches_shot_subject_no
    stc
    ret

game3d_tile_matches_shot_subject_no:
    clc
    ret

game3d_draw_cue_with_beacon:
    ; Input: BL/BH tile x/y, AL/AH glow colors, DL mesh index, CL fallback color.
    push ax
    push bx
    push cx
    push dx
    mov [scene3d_temp_s], bx
    mov [game3d_mesh_index], dl
    mov [text_color], cl
    call game3d_draw_tile_glow_3d
    mov bx, [scene3d_temp_s]
    cmp byte ptr [game3d_shot_mode], GAME3D_SHOT_BASE_CHASE
    je game3d_draw_cue_projection
    call game3d_tile_matches_shot_subject
    jnc game3d_draw_cue_projection
    mov al, ah
    mov ah, PAL_WHITE
    call game3d_draw_tile_glow_3d

game3d_draw_cue_projection:
    call game3d_project_tile_center
    jnc game3d_draw_cue_done
    call game3d_is_projected_point_cue_ready
    jc game3d_draw_cue_beacon
    call game3d_clamp_projected_point_to_view
    mov bl, [text_color]
    call game3d_draw_marker_at_projected_point
    jmp game3d_draw_cue_done

game3d_draw_cue_beacon:
    mov bx, [scene3d_temp_s]
    call game3d_draw_beacon_mesh_at_tile

game3d_draw_cue_done:
    pop dx
    pop cx
    pop bx
    pop ax
    ret

game3d_get_enemy_mesh_index:
    cmp byte ptr [si + ENEMY_KIND], ENEMY_WARDEN
    je game3d_enemy_mesh_warden
    cmp byte ptr [si + ENEMY_KIND], ENEMY_FLANKER
    je game3d_enemy_mesh_flanker
    mov al, GAME3D_MESH_ENEMY_RUSHER_INDEX
    cmp byte ptr [game3d_shot_mode], GAME3D_SHOT_ENEMY_REVEAL
    jne game3d_enemy_mesh_done
    call game3d_tile_matches_shot_subject
    jnc game3d_enemy_mesh_done
    mov al, GAME3D_MESH_ENEMY_RUSHER_ALT_INDEX
    jmp game3d_enemy_mesh_done

game3d_enemy_mesh_flanker:
    mov al, GAME3D_MESH_ENEMY_FLANKER_INDEX
    cmp byte ptr [game3d_shot_mode], GAME3D_SHOT_ENEMY_REVEAL
    jne game3d_enemy_mesh_done
    call game3d_tile_matches_shot_subject
    jnc game3d_enemy_mesh_done
    mov al, GAME3D_MESH_ENEMY_FLANKER_ALT_INDEX
    jmp game3d_enemy_mesh_done

game3d_enemy_mesh_warden:
    mov al, GAME3D_MESH_WARDEN_INDEX
    cmp byte ptr [game3d_shot_mode], GAME3D_SHOT_WARDEN_PRESSURE
    jne game3d_enemy_mesh_done
    call game3d_tile_matches_shot_subject
    jnc game3d_enemy_mesh_done
    mov al, GAME3D_MESH_WARDEN_PRESSURE_INDEX

game3d_enemy_mesh_done:
    ret

game3d_get_player_mesh_index:
    mov al, GAME3D_MESH_PLAYER_RUNNER_INDEX
    cmp byte ptr [game3d_shot_mode], GAME3D_SHOT_MOVE_SETTLE
    jne game3d_player_mesh_done
    mov al, GAME3D_MESH_PLAYER_RUNNER_LEAN_INDEX

game3d_player_mesh_done:
    ret

game3d_apply_actor_motion:
    ; Input: DL = yaw.
    test byte ptr [anim_phase], 1
    jz game3d_actor_motion_done
    add word ptr [game3d_mesh_world_y], GAME3D_ACTOR_BOB_Y
    cmp dl, GAME3D_YAW_EAST
    je game3d_actor_lean_east
    cmp dl, GAME3D_YAW_WEST
    je game3d_actor_lean_west
    cmp dl, GAME3D_YAW_NORTH
    je game3d_actor_lean_north
    add word ptr [game3d_mesh_world_z], GAME3D_ACTOR_LEAN_STEP
    ret

game3d_actor_lean_east:
    add word ptr [game3d_mesh_world_x], GAME3D_ACTOR_LEAN_STEP
    ret

game3d_actor_lean_west:
    sub word ptr [game3d_mesh_world_x], GAME3D_ACTOR_LEAN_STEP
    ret

game3d_actor_lean_north:
    sub word ptr [game3d_mesh_world_z], GAME3D_ACTOR_LEAN_STEP

game3d_actor_motion_done:
    ret

game3d_prepare_mesh_at_tile:
    ; Input: AL = mesh index, BL/BH = tile x/y, DL = yaw.
    mov [game3d_mesh_index], al
    mov [game3d_mesh_yaw], dl
    mov byte ptr [game3d_mesh_face_flags], GAME3D_FACE_FLAG_NONE
    call game3d_get_tile_center_world
    mov [game3d_mesh_world_x], ax
    mov [game3d_mesh_world_z], dx
IF DEBUG_LEGACY_GAMEPLAY
    call game3d_get_tile_ground_y
ELSE
    call adventure_get_tile_ground_y
ENDIF
    mov [game3d_mesh_world_y], ax
    ret

game3d_draw_world_floor_quad:
    push ax
    push bx
    push cx
    push dx
    push si

    mov ax, [scene3d_temp_x]
    mov bx, [scene3d_temp_z]
    mov dx, [scene3d_temp_v]
    call game3d_project_world_point
    jnc game3d_draw_world_floor_quad_done
    mov [scene3d_tri_x0], ax
    mov [scene3d_tri_y0], dx

    mov ax, [scene3d_temp_y]
    mov bx, [scene3d_temp_z]
    mov dx, [scene3d_temp_v]
    call game3d_project_world_point
    jnc game3d_draw_world_floor_quad_done
    mov [scene3d_tri_x1], ax
    mov [scene3d_tri_y1], dx

    mov ax, [scene3d_temp_y]
    mov bx, [scene3d_temp_z]
    mov dx, [scene3d_temp_w]
    call game3d_project_world_point
    jnc game3d_draw_world_floor_quad_done
    mov [scene3d_tri_x2], ax
    mov [scene3d_tri_y2], dx

    mov ax, [scene3d_temp_x]
    mov bx, [scene3d_temp_z]
    mov dx, [scene3d_temp_w]
    call game3d_project_world_point
    jnc game3d_draw_world_floor_quad_done
    mov [scene3d_temp_l], ax
    mov [scene3d_temp_r], dx

    call scene3d_draw_triangle
    mov ax, [scene3d_tri_x0]
    mov [scene3d_tri_x1], ax
    mov ax, [scene3d_tri_y0]
    mov [scene3d_tri_y1], ax
    mov ax, [scene3d_tri_x2]
    mov [scene3d_tri_x0], ax
    mov ax, [scene3d_tri_y2]
    mov [scene3d_tri_y0], ax
    mov ax, [scene3d_temp_l]
    mov [scene3d_tri_x2], ax
    mov ax, [scene3d_temp_r]
    mov [scene3d_tri_y2], ax
    call scene3d_draw_triangle

game3d_draw_world_floor_quad_done:
    pop si
    pop dx
    pop cx
    pop bx
    pop ax
    ret

game3d_draw_tile_glow_3d:
    ; Input: BL/BH = tile x/y, AL = base color, AH = dither color.
    push ax
    push bx
    push dx

    cmp bl, PLAY_MIN_X
    jb game3d_draw_tile_glow_done
    cmp bl, PLAY_MAX_X
    ja game3d_draw_tile_glow_done
    cmp bh, PLAY_MIN_Y
    jb game3d_draw_tile_glow_done
    cmp bh, PLAY_MAX_Y
    ja game3d_draw_tile_glow_done

    mov [scene3d_temp_color], al
    mov [scene3d_temp_dither], ah
    mov al, bl
    call game3d_world_x_edge_from_al
    add ax, GAME3D_FLOOR_TRIM_INSET
    mov [scene3d_temp_x], ax
    mov al, bl
    inc al
    call game3d_world_x_edge_from_al
    sub ax, GAME3D_FLOOR_TRIM_INSET
    mov [scene3d_temp_y], ax
    mov al, bh
    call game3d_world_z_edge_from_al
    add ax, GAME3D_FLOOR_TRIM_INSET
    mov [scene3d_temp_v], ax
    mov al, bh
    inc al
    call game3d_world_z_edge_from_al
    sub ax, GAME3D_FLOOR_TRIM_INSET
    mov [scene3d_temp_w], ax
IF DEBUG_LEGACY_GAMEPLAY
    call game3d_get_tile_ground_y
ELSE
    call adventure_get_tile_ground_y
ENDIF
    add ax, GAME3D_TERRAIN_TRIM_OFFSET
    mov [scene3d_temp_z], ax
    call game3d_draw_world_floor_quad

game3d_draw_tile_glow_done:
    pop dx
    pop bx
    pop ax
    ret

game3d_get_effect_colors:
    mov al, [message_id]
    cmp al, MSG_GATE
    je game3d_effect_color_gate
    cmp al, MSG_SURGE
    je game3d_effect_color_surge
    cmp al, MSG_TRAP
    je game3d_effect_color_surge
    cmp al, MSG_HIT
    je game3d_effect_color_hit
    cmp al, MSG_KILL
    je game3d_effect_color_kill
    mov al, PAL_WHITE
    mov ah, PAL_CYAN2
    ret

game3d_effect_color_gate:
    mov al, PAL_GATE
    mov ah, PAL_WHITE
    ret

game3d_effect_color_surge:
    mov al, PAL_AMBER
    mov ah, PAL_RED2
    ret

game3d_effect_color_hit:
    mov al, PAL_RED2
    mov ah, PAL_WHITE
    ret

game3d_effect_color_kill:
    mov al, PAL_WHITE
    mov ah, PAL_CYAN
    ret

game3d_draw_player_locator_3d:
    mov bl, [player_x]
    mov bh, [player_y]
    call game3d_project_tile_center
    jnc game3d_player_locator_done
    cmp cx, GAME3D_PLAYER_LOCATOR_FAR_DEPTH
    jg game3d_player_locator_marker
    call game3d_is_projected_point_cue_ready
    jc game3d_player_locator_done

game3d_player_locator_marker:
    call game3d_clamp_projected_point_to_view
    mov bl, PAL_WHITE
    call game3d_draw_marker_at_projected_point

game3d_player_locator_done:
    ret

game3d_get_enemy_floor_colors:
    cmp byte ptr [si + ENEMY_KIND], ENEMY_WARDEN
    je game3d_enemy_floor_warden
    cmp byte ptr [si + ENEMY_KIND], ENEMY_FLANKER
    je game3d_enemy_floor_flanker
    mov al, PAL_RED
    mov ah, PAL_WHITE
    ret

game3d_enemy_floor_flanker:
    mov al, PAL_AMBER
    mov ah, PAL_WHITE
    ret

game3d_enemy_floor_warden:
    mov al, PAL_RED2
    mov ah, PAL_WHITE
    ret

game3d_get_warden_yaw:
    push bx
    push cx
    push dx
    xor ax, ax
    mov al, [player_x]
    sub al, bl
    cbw
    mov dx, ax
    call game3d_abs_ax
    mov cx, ax

    xor ax, ax
    mov al, [player_y]
    sub al, bh
    cbw
    mov bx, ax
    call game3d_abs_ax
    cmp cx, ax
    jae game3d_warden_yaw_horizontal

    mov ax, bx
    or ax, ax
    jg game3d_warden_yaw_south
    mov al, GAME3D_YAW_NORTH
    jmp game3d_warden_yaw_done

game3d_warden_yaw_south:
    mov al, GAME3D_YAW_SOUTH
    jmp game3d_warden_yaw_done

game3d_warden_yaw_horizontal:
    mov ax, dx
    or ax, ax
    jg game3d_warden_yaw_east
    mov al, GAME3D_YAW_WEST
    jmp game3d_warden_yaw_done

game3d_warden_yaw_east:
    mov al, GAME3D_YAW_EAST

game3d_warden_yaw_done:
    pop dx
    pop cx
    pop bx
    ret

game3d_find_active_landmark_anchor:
IF DEBUG_LEGACY_GAMEPLAY
    clc
    ret
ELSE
    xor si, si
    xor cx, cx
    mov cl, [adventure_realm_chunk_count]
    jcxz game3d_landmark_anchor_none

game3d_landmark_anchor_loop:
    mov bl, [adventure_realm_chunk_landmark_x_table + si]
    mov bh, [adventure_realm_chunk_landmark_y_table + si]
    call game3d_tile_in_active_chunk_range
    cmp al, 0
    jne game3d_landmark_anchor_found
    inc si
    loop game3d_landmark_anchor_loop

game3d_landmark_anchor_none:
    clc
    ret

game3d_landmark_anchor_found:
    mov bl, [adventure_realm_chunk_landmark_x_table + si]
    mov bh, [adventure_realm_chunk_landmark_y_table + si]
    stc
    ret
ENDIF

render_gameplay_landmark_3d:
IF DEBUG_LEGACY_GAMEPLAY EQ 0
    call game3d_find_active_landmark_anchor
    jnc render_gameplay_landmark_done
    mov dl, [scene3d_yaw_angle]
    call game3d_get_landmark_mesh_index
    call game3d_prepare_mesh_at_tile
    call game3d_get_landmark_lift
    add [game3d_mesh_world_y], ax
    call game3d_draw_mesh_instance
    ret
ENDIF
    cmp byte ptr [game3d_shot_frame_variant], GAME3D_FRAME_VARIANT_LANDMARK
    jne render_gameplay_landmark_done
    mov bl, (PLAY_MIN_X + PLAY_MAX_X) / 2
    mov al, [game3d_room_variant]
    cmp al, GAME3D_ROOM_VARIANT_SOUTHWEST
    je render_gameplay_landmark_south
    cmp al, GAME3D_ROOM_VARIANT_SOUTHEAST
    je render_gameplay_landmark_south
    mov bh, PLAY_MIN_Y + 1
    jmp render_gameplay_landmark_tile_ready

render_gameplay_landmark_south:
    mov bh, PLAY_MAX_Y - 1

render_gameplay_landmark_tile_ready:
    push bx
    call game3d_project_tile_center
    jnc render_gameplay_landmark_done_pop
    pop bx
    mov dl, [scene3d_yaw_angle]
    call game3d_get_landmark_mesh_index
    call game3d_prepare_mesh_at_tile
    call game3d_draw_mesh_instance
    jmp render_gameplay_landmark_done

render_gameplay_landmark_done_pop:
    pop bx

render_gameplay_landmark_done:
    ret

render_gameplay_props_3d:
    mov si, offset map_tiles
    xor dh, dh
    mov cx, MAP_H

game3d_prop_row_loop:
    push cx
    xor dl, dl
    mov cx, MAP_W

game3d_prop_col_loop:
IF DEBUG_LEGACY_GAMEPLAY EQ 0
    mov bl, dl
    mov bh, dh
    call game3d_tile_in_active_chunk_range
    cmp al, 0
    je game3d_prop_next
ENDIF
    mov al, [si]
    cmp al, TILE_SHARD
    je game3d_prop_shard
    cmp al, TILE_TERMINAL
    je game3d_prop_terminal
    cmp al, TILE_SURGE
    je game3d_prop_surge
    cmp al, TILE_KEY
    je game3d_prop_key
    cmp al, TILE_EXIT_LOCKED
    je game3d_prop_gate_locked
    cmp al, TILE_EXIT_OPEN
    je game3d_prop_gate_open
    jmp game3d_prop_next

game3d_prop_shard:
    mov bl, dl
    mov bh, dh
    mov al, PAL_CYAN2
    mov ah, PAL_WHITE
    call game3d_draw_tile_glow_3d
    push si
    push dx
    call game3d_get_shard_mesh_index
    mov bl, dl
    mov bh, dh
    xor dl, dl
    call game3d_prepare_mesh_at_tile
    call game3d_draw_mesh_instance
    pop dx
    pop si
    jmp game3d_prop_next

game3d_prop_terminal:
    mov bl, dl
    mov bh, dh
    mov al, PAL_WHITE
    mov ah, PAL_CYAN2
    call game3d_draw_tile_glow_3d
    push si
    push dx
    call game3d_get_terminal_mesh_index
    mov bl, dl
    mov bh, dh
    xor dl, dl
    call game3d_prepare_mesh_at_tile
    call game3d_draw_mesh_instance
    pop dx
    pop si
    jmp game3d_prop_next

game3d_prop_surge:
    mov bl, dl
    mov bh, dh
    mov al, PAL_AMBER
    mov ah, PAL_RED2
    call game3d_draw_tile_glow_3d
    push si
    push dx
    call game3d_get_surge_mesh_index
    mov bl, dl
    mov bh, dh
    xor dl, dl
    call game3d_prepare_mesh_at_tile
    call game3d_draw_mesh_instance
    pop dx
    pop si
    jmp game3d_prop_next

game3d_prop_key:
    mov bl, dl
    mov bh, dh
    mov al, PAL_AMBER
    mov ah, PAL_WHITE
    call game3d_draw_tile_glow_3d
    push si
    push dx
    call game3d_get_shard_mesh_index
    mov bl, dl
    mov bh, dh
    xor dl, dl
    call game3d_prepare_mesh_at_tile
    call game3d_draw_mesh_instance
    pop dx
    pop si
    jmp game3d_prop_next

game3d_prop_gate_locked:
    mov bl, dl
    mov bh, dh
    mov al, PAL_RED
    mov ah, PAL_RED2
    call game3d_draw_tile_glow_3d
    push si
    push dx
    call game3d_get_gate_mesh_index
    mov bl, dl
    mov bh, dh
    xor dl, dl
    call game3d_prepare_mesh_at_tile
    call game3d_draw_mesh_instance
    pop dx
    pop si
    jmp game3d_prop_next

game3d_prop_gate_open:
    mov bl, dl
    mov bh, dh
    mov al, PAL_GATE
    mov ah, PAL_WHITE
    call game3d_draw_tile_glow_3d
    push si
    push dx
    call game3d_get_gate_mesh_index
    mov bl, dl
    mov bh, dh
    xor dl, dl
    call game3d_prepare_mesh_at_tile
    call game3d_draw_mesh_instance
    pop dx
    pop si

game3d_prop_next:
    inc si
    inc dl
    dec cx
    jnz game3d_prop_col_loop
    inc dh
    pop cx
    dec cx
    jnz game3d_prop_row_loop
    ret

render_enemies_3d:
    mov si, offset enemies
    mov cx, MAX_ENEMIES

game3d_enemy_loop:
    cmp byte ptr [si + ENEMY_ALIVE], 0
    je game3d_enemy_next
IF DEBUG_LEGACY_GAMEPLAY EQ 0
    mov bl, [si + ENEMY_X]
    mov bh, [si + ENEMY_Y]
    call game3d_tile_in_active_chunk_range
    cmp al, 0
    je game3d_enemy_next
ENDIF
    push cx
    call game3d_get_enemy_floor_colors
    mov bl, [si + ENEMY_X]
    mov bh, [si + ENEMY_Y]
    call game3d_draw_tile_glow_3d
    mov bl, [si + ENEMY_X]
    mov bh, [si + ENEMY_Y]
    call game3d_project_tile_center
    jnc game3d_enemy_skip_visible
    push si
    push ax
    push dx
    call game3d_draw_shadow_at_projected_point
    pop dx
    pop ax
    push dx
    mov bl, [si + ENEMY_X]
    mov bh, [si + ENEMY_Y]
    call game3d_get_warden_yaw
    mov dl, al
    call game3d_get_enemy_mesh_index
    call game3d_prepare_mesh_at_tile
    call game3d_apply_actor_motion
    call game3d_draw_mesh_instance
    pop dx

game3d_enemy_done:
    pop si
game3d_enemy_skip_visible:
    pop cx

game3d_enemy_next:
    add si, ENEMY_SIZE
    dec cx
    jnz game3d_enemy_loop
    ret

render_player_3d:
    call game3d_draw_player_locator_3d
    mov bl, [player_x]
    mov bh, [player_y]
    call game3d_project_tile_center
    jnc render_player_3d_done
    push ax
    push cx
    push dx
    call game3d_draw_shadow_at_projected_point
    pop dx
    pop cx
    pop ax
    push dx
    mov bl, [player_x]
    mov bh, [player_y]
    call game3d_get_facing_yaw
    mov dl, al
    call game3d_get_player_mesh_index
    call game3d_prepare_mesh_at_tile
    call game3d_apply_actor_motion
    call game3d_draw_mesh_instance
    pop dx

render_player_3d_done:
    ret

render_adventure_static_props_3d:
    xor cx, cx
    mov cl, [adventure_realm_prop_count]
    jcxz render_adventure_static_props_done
    xor si, si

render_adventure_static_prop_loop:
    push cx
    mov bl, [adventure_realm_prop_x_table + si]
    mov bh, [adventure_realm_prop_y_table + si]
    call game3d_tile_in_active_chunk_range
    cmp al, 0
    je render_adventure_static_prop_next
    mov al, [adventure_realm_prop_mesh_table + si]
    mov dl, [adventure_realm_prop_yaw_table + si]
    call game3d_prepare_mesh_at_tile
    call game3d_draw_mesh_instance

render_adventure_static_prop_next:
    inc si
    pop cx
    loop render_adventure_static_prop_loop

render_adventure_static_props_done:
    ret

render_adventure_player_3d:
    mov ax, [adventure_player_world_x]
    mov bl, [player_x]
    mov bh, [player_y]
IF DEBUG_LEGACY_GAMEPLAY
    call game3d_get_tile_ground_y
ELSE
    call adventure_get_tile_ground_y
ENDIF
    mov bx, ax
    mov dx, [adventure_player_world_z]
    call game3d_project_world_point
    jnc render_adventure_player_done
    push ax
    push dx
    call game3d_draw_shadow_at_projected_point
    pop dx
    pop ax

    mov ax, [adventure_player_world_x]
    mov [game3d_mesh_world_x], ax
    mov ax, [adventure_player_world_y]
    mov [game3d_mesh_world_y], ax
    mov ax, [adventure_player_world_z]
    mov [game3d_mesh_world_z], ax
    mov byte ptr [game3d_mesh_face_flags], GAME3D_FACE_FLAG_NONE
    mov al, [adventure_player_yaw]
    mov [game3d_mesh_yaw], al
    call game3d_get_adventure_player_mesh_index
    mov [game3d_mesh_index], al
    call game3d_draw_mesh_instance

render_adventure_player_done:
    ret

game3d_get_adventure_player_mesh_index:
    mov al, GAME3D_MESH_PLAYER_RUNNER_INDEX
    cmp byte ptr [adventure_charge_timer], 0
    jne game3d_get_adventure_player_mesh_lean
    cmp byte ptr [action_taken], 0
    je game3d_get_adventure_player_mesh_done

game3d_get_adventure_player_mesh_lean:
    mov al, GAME3D_MESH_PLAYER_RUNNER_LEAN_INDEX

game3d_get_adventure_player_mesh_done:
    ret

render_adventure_world_effects_3d:
    call game3d_draw_exit_marker_adventure_3d
    cmp byte ptr [feedback_timer], 0
    je render_adventure_world_effects_done
    mov al, [message_id]
    cmp al, MSG_SHARD
    je game3d_draw_focus_marker_adventure_3d
    cmp al, MSG_GATE
    je game3d_draw_focus_marker_adventure_3d
    cmp al, MSG_HIT
    je game3d_draw_focus_marker_adventure_3d
    cmp al, MSG_SURGE
    je game3d_draw_focus_marker_adventure_3d
    cmp al, MSG_KILL
    je game3d_draw_focus_marker_adventure_3d
    cmp al, MSG_SPOOF
    je game3d_draw_focus_marker_adventure_3d
    cmp al, MSG_KEY
    je game3d_draw_focus_marker_adventure_3d

render_adventure_world_effects_done:
    ret

render_gameplay_world_effects_3d:
    call game3d_draw_exit_marker_3d
    call game3d_draw_spoof_marker_3d
    call game3d_draw_threat_marker_3d
    cmp byte ptr [feedback_timer], 0
    je render_gameplay_world_effects_done
    mov al, [message_id]
    cmp al, MSG_PULSE
    je game3d_draw_pulse_effect_3d
    cmp al, MSG_SHARD
    je game3d_draw_focus_marker_3d
    cmp al, MSG_SPOOF
    je game3d_draw_spoof_marker_3d
    cmp al, MSG_HIT
    je game3d_draw_focus_marker_3d
    cmp al, MSG_SURGE
    je game3d_draw_focus_marker_3d
    cmp al, MSG_KILL
    je game3d_draw_focus_marker_3d
    cmp al, MSG_TRAP
    je game3d_draw_focus_marker_3d

render_gameplay_world_effects_done:
    ret

game3d_draw_cue_fallback_only:
    push ax
    push bx
    push cx
    push dx
    mov [text_color], cl
    call game3d_draw_tile_glow_3d
    call game3d_project_tile_center
    jnc game3d_draw_cue_fallback_done
    call game3d_is_projected_point_cue_ready
    jc game3d_draw_cue_fallback_done
    call game3d_clamp_projected_point_to_view
    mov bl, [text_color]
    call game3d_draw_marker_at_projected_point

game3d_draw_cue_fallback_done:
    pop dx
    pop cx
    pop bx
    pop ax
    ret

game3d_draw_focus_marker_adventure_3d:
    mov bl, [effect_x]
    mov bh, [effect_y]
    call game3d_get_effect_colors
    mov cl, al
    call game3d_draw_cue_fallback_only
    ret

game3d_draw_exit_marker_adventure_3d:
    mov bl, [exit_x]
    mov bh, [exit_y]
    call game3d_get_lane_material
    mov cl, al
    call game3d_draw_cue_fallback_only
    ret

game3d_draw_focus_marker_3d:
    mov bl, [effect_x]
    mov bh, [effect_y]
    call game3d_get_effect_colors
    mov cl, al
    mov dl, GAME3D_MESH_BEACON_FOCUS_INDEX
    call game3d_draw_cue_with_beacon

game3d_focus_marker_done:
    ret

game3d_draw_exit_marker_3d:
    push ax
    push bx
    push cx
    push dx
IF DEBUG_LEGACY_GAMEPLAY
    call game3d_get_lane_material
    mov [scene3d_temp_color], al
    mov [scene3d_temp_dither], ah
    xor dh, dh
    xor cl, cl

game3d_exit_lane_loop:
    cmp dh, MAP_H
    jae game3d_exit_lane_done
    cmp cl, 5
    jae game3d_exit_lane_done
    mov bl, [exit_x]
    mov bh, dh
    call get_tile
    cmp al, TILE_WALL
    je game3d_exit_lane_next
    mov bl, [exit_x]
    mov bh, dh
    mov al, [scene3d_temp_color]
    mov ah, [scene3d_temp_dither]
    call game3d_draw_tile_glow_3d
    inc cl

game3d_exit_lane_next:
    inc dh
    jmp game3d_exit_lane_loop

game3d_exit_lane_done:
ENDIF
    pop dx
    pop cx
    pop bx
    pop ax
    mov bl, [exit_x]
    mov bh, [exit_y]
    call game3d_get_lane_material
    mov cl, al
    mov dl, GAME3D_MESH_BEACON_EXIT_INDEX
    call game3d_draw_cue_with_beacon

game3d_exit_marker_done:
    ret

game3d_draw_spoof_marker_3d:
    cmp byte ptr [spoof_timer], 0
    je game3d_spoof_marker_done
    mov bl, [spoof_x]
    mov bh, [spoof_y]
    mov al, PAL_CYAN2
    mov ah, PAL_WHITE
    mov cl, PAL_CYAN2
    mov dl, GAME3D_MESH_BEACON_SPOOF_INDEX
    call game3d_draw_cue_with_beacon

game3d_spoof_exit_marker:
    mov bl, [exit_x]
    mov bh, [exit_y]
    mov al, PAL_WHITE
    mov ah, PAL_GATE
    mov cl, PAL_WHITE
    mov dl, GAME3D_MESH_BEACON_EXIT_INDEX
    call game3d_draw_cue_with_beacon

game3d_spoof_marker_done:
    ret

game3d_draw_threat_marker_3d:
    cmp byte ptr [threat_level], THREAT_NONE
    je game3d_threat_marker_done
    mov bl, [threat_x]
    mov bh, [threat_y]
    cmp byte ptr [threat_level], THREAT_ELITE
    jne game3d_threat_near
    mov al, PAL_RED2
    mov ah, PAL_WHITE
    mov cl, PAL_RED2
    mov dl, GAME3D_MESH_BEACON_THREAT_INDEX
    call game3d_draw_cue_with_beacon
    jmp game3d_threat_marker_done

game3d_threat_near:
    mov al, PAL_AMBER
    mov ah, PAL_WHITE
    mov cl, PAL_AMBER
    mov dl, GAME3D_MESH_BEACON_THREAT_INDEX
    call game3d_draw_cue_with_beacon

game3d_threat_marker_done:
    ret

game3d_draw_pulse_effect_3d:
    mov bl, [player_x]
    mov bh, [player_y]
    mov al, PAL_WHITE
    mov ah, PAL_CYAN2
    call game3d_draw_tile_glow_3d
    mov bl, [player_x]
    dec bl
    mov bh, [player_y]
    call game3d_draw_neighbor_glow_3d
    mov bl, [player_x]
    inc bl
    mov bh, [player_y]
    call game3d_draw_neighbor_glow_3d
    mov bl, [player_x]
    mov bh, [player_y]
    dec bh
    call game3d_draw_neighbor_glow_3d
    mov bl, [player_x]
    mov bh, [player_y]
    inc bh
    call game3d_draw_neighbor_glow_3d
    mov bl, [player_x]
    mov bh, [player_y]
    call game3d_project_tile_center
    jnc game3d_pulse_effect_done
    mov bl, PAL_WHITE
    call game3d_draw_marker_at_projected_point

game3d_pulse_effect_done:
    ret

game3d_draw_neighbor_glow_3d:
    cmp bl, PLAY_MIN_X
    jb game3d_neighbor_done
    cmp bl, PLAY_MAX_X
    ja game3d_neighbor_done
    cmp bh, PLAY_MIN_Y
    jb game3d_neighbor_done
    cmp bh, PLAY_MAX_Y
    ja game3d_neighbor_done
    mov al, PAL_CYAN2
    mov ah, PAL_WHITE
    call game3d_draw_tile_glow_3d

game3d_neighbor_done:
    ret

render_gameplay_overlay_effects_3d:
    cmp byte ptr [feedback_timer], 0
    je render_gameplay_overlay_done
    cmp byte ptr [message_id], MSG_SECTOR
    jne render_gameplay_overlay_done
    call draw_sector_entry_card

render_gameplay_overlay_done:
    ret

game3d_apply_room_instability:
    push ax
    push bx
    push cx
    push dx
    push di

    call game3d_get_wobble_strength
    or al, al
    jz game3d_apply_room_instability_done
    xor ah, ah
    mov bx, ax
    xor dx, dx

game3d_room_instability_loop:
    cmp dx, [scene3d_vertex_count]
    jae game3d_apply_room_instability_done
    mov di, dx
    shl di, 1
    mov ax, [scene3d_vertex_z + di]
    cmp ax, GAME3D_FACE_DEPTH_FAR
    jle game3d_room_instability_next
    mov al, [anim_phase]
    add al, dl
    add al, [sector_num]
    test al, 1
    jz game3d_room_instability_negative
    add [scene3d_vertex_x + di], bx
    inc word ptr [scene3d_vertex_y + di]
    jmp game3d_room_instability_next

game3d_room_instability_negative:
    sub [scene3d_vertex_x + di], bx
    dec word ptr [scene3d_vertex_y + di]

game3d_room_instability_next:
    inc dx
    jmp game3d_room_instability_loop

game3d_apply_room_instability_done:
    pop di
    pop dx
    pop cx
    pop bx
    pop ax
    ret

game3d_apply_room_face_palette:
    push ax
    push bx
    push dx

    xor bh, bh
    shl bx, 1
    mov dx, [scene3d_face_depth + bx]
    call game3d_get_fog_far_depth
    cmp dx, ax
    jg game3d_room_face_far
    call game3d_get_fog_near_depth
    cmp dx, ax
    jg game3d_room_face_mid
    jmp game3d_room_face_palette_done

game3d_room_face_mid:
    mov dl, [si + 5]
    test dl, GAME3D_FACE_FLAG_WALL
    jz game3d_room_face_mid_floor
    call game3d_get_wall_trim_material
    jmp game3d_room_face_apply

game3d_room_face_mid_floor:
    test dl, GAME3D_FACE_FLAG_TRIM
    jnz game3d_room_face_palette_done
    test dl, GAME3D_FACE_FLAG_FRAME
    jnz game3d_room_face_palette_done
    call game3d_get_floor_trim_material
    jmp game3d_room_face_apply

game3d_room_face_far:
    mov dl, [si + 5]
    test dl, GAME3D_FACE_FLAG_WALL
    jnz game3d_room_face_far_solid
    test dl, GAME3D_FACE_FLAG_TRIM
    jnz game3d_room_face_far_solid
    test dl, GAME3D_FACE_FLAG_FRAME
    jnz game3d_room_face_far_solid
    call game3d_get_floor_far_material
    jmp game3d_room_face_apply

game3d_room_face_far_solid:
    call game3d_get_wall_far_material

game3d_room_face_apply:
    mov [scene3d_temp_color], al
    mov [scene3d_temp_dither], ah

game3d_room_face_palette_done:
    pop dx
    pop bx
    pop ax
    ret

game3d_should_draw_face:
    ; Input: SI = face record in the active source buffer. Output: AL = 1/0.
    push bx
    push cx
    push dx
    push si
    push di
    push bp

    mov al, [si + 5]
    test al, GAME3D_FACE_FLAG_WALL
    jz game3d_should_draw_yes

    mov di, [scene3d_vertex_source]
    xor dx, dx
    xor bp, bp

    mov al, [si]
    xor ah, ah
    mov bx, SCENE3D_VERTEX_BYTES
    mul bx
    mov bx, di
    add bx, ax
    mov ax, [bx]
    add dx, ax
    mov ax, [bx + 4]
    add bp, ax

    mov al, [si + 1]
    xor ah, ah
    mov bx, SCENE3D_VERTEX_BYTES
    mul bx
    mov bx, di
    add bx, ax
    mov ax, [bx]
    add dx, ax
    mov ax, [bx + 4]
    add bp, ax

    mov al, [si + 2]
    xor ah, ah
    mov bx, SCENE3D_VERTEX_BYTES
    mul bx
    mov bx, di
    add bx, ax
    mov ax, [bx]
    add dx, ax
    mov ax, [bx + 4]
    add bp, ax

    mov ax, dx
    cwd
    mov cx, 3
    idiv cx
    mov [scene3d_temp_v], ax

    mov ax, bp
    cwd
    mov cx, 3
    idiv cx
    mov [scene3d_temp_w], ax

    mov bl, [player_x]
    mov bh, [player_y]
    call game3d_get_tile_center_world
    mov [scene3d_temp_x], ax
    mov [scene3d_temp_y], dx

    mov ax, [scene3d_temp_v]
    cmp ax, [scene3d_temp_x]
    jg game3d_should_draw_yes
    mov ax, [scene3d_temp_w]
    cmp ax, [scene3d_temp_y]
    jg game3d_should_draw_yes

    mov ax, [scene3d_temp_x]
    sub ax, [scene3d_temp_v]
    call game3d_abs_ax
    cmp ax, GAME3D_CUTAWAY_RADIUS
    jg game3d_should_draw_yes

    mov ax, [scene3d_temp_y]
    sub ax, [scene3d_temp_w]
    call game3d_abs_ax
    cmp ax, GAME3D_CUTAWAY_RADIUS
    jg game3d_should_draw_yes
    jmp game3d_should_draw_no

game3d_should_draw_yes:
    mov al, 1
    jmp game3d_should_draw_done

game3d_should_draw_no:
    xor al, al

game3d_should_draw_done:
    pop bp
    pop di
    pop si
    pop dx
    pop cx
    pop bx
    ret

game3d_abs_ax:
    or ax, ax
    jns game3d_abs_done
    neg ax

game3d_abs_done:
    ret
