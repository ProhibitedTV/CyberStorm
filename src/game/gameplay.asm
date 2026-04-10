process_play_input:
IF DEBUG_LEGACY_GAMEPLAY EQ 0
    jmp process_adventure_play_input
ENDIF
    ; Only consumed actions set action_taken; that flag is what grants hunters
    ; exactly one responding turn.
    mov byte ptr [action_taken], 0
    mov byte ptr [frontend_action], FRONTEND_ACTION_NONE
IF DEBUG_RUNTIME_VERIFY
    mov byte ptr [verify_action_pending], 0
ENDIF

    ; Release builds keep Enter on the frontend. In live play, R is the reset
    ; key and the short start guard debounces it for the first few ticks.
    cmp byte ptr [run_start_enter_guard], 0
    je check_reset_r
    mov byte ptr [pressed_r], 0
    jmp check_pulse_lower

check_reset_r:
    cmp byte ptr [pressed_r], 0
    je check_pulse_lower
    mov byte ptr [pressed_r], 0
    mov byte ptr [any_key_pending], 0
    call start_new_run
    ret

check_pulse_lower:
    cmp byte ptr [pressed_c], 0
    jne consume_pulse

    cmp byte ptr [pressed_a], 0
    jne consume_left
    cmp byte ptr [pressed_left], 0
    jne consume_left

    cmp byte ptr [pressed_d], 0
    jne consume_right
    cmp byte ptr [pressed_right], 0
    jne consume_right

    cmp byte ptr [pressed_w], 0
    jne consume_up
    cmp byte ptr [pressed_up], 0
    jne consume_up

    cmp byte ptr [pressed_s], 0
    jne consume_down
    cmp byte ptr [pressed_down], 0
    jne consume_down

    ret

consume_pulse:
    mov byte ptr [pressed_c], 0
    mov byte ptr [any_key_pending], 0
IF DEBUG_RUNTIME_VERIFY
    mov byte ptr [verify_action_pending], 1
ENDIF
    jmp do_pulse

consume_left:
    mov byte ptr [pressed_a], 0
    mov byte ptr [pressed_left], 0
    mov byte ptr [any_key_pending], 0
IF DEBUG_RUNTIME_VERIFY
    mov byte ptr [verify_action_pending], 1
ENDIF
    jmp move_left

consume_right:
    mov byte ptr [pressed_d], 0
    mov byte ptr [pressed_right], 0
    mov byte ptr [any_key_pending], 0
IF DEBUG_RUNTIME_VERIFY
    mov byte ptr [verify_action_pending], 1
ENDIF
    jmp move_right

consume_up:
    mov byte ptr [pressed_w], 0
    mov byte ptr [pressed_up], 0
    mov byte ptr [any_key_pending], 0
IF DEBUG_RUNTIME_VERIFY
    mov byte ptr [verify_action_pending], 1
ENDIF
    jmp move_up

consume_down:
    mov byte ptr [pressed_s], 0
    mov byte ptr [pressed_down], 0
    mov byte ptr [any_key_pending], 0
IF DEBUG_RUNTIME_VERIFY
    mov byte ptr [verify_action_pending], 1
ENDIF
    jmp move_down

process_adventure_play_input:
    mov byte ptr [action_taken], 0
    mov byte ptr [frontend_action], FRONTEND_ACTION_NONE

    cmp byte ptr [game_state], STATE_PLAYING
    jne adventure_input_done

    cmp byte ptr [pressed_r], 0
    je adventure_skip_reset
    mov byte ptr [pressed_r], 0
    mov byte ptr [any_key_pending], 0
    call start_new_run
    ret

adventure_skip_reset:
    call adventure_tick_timers
    cmp byte ptr [game3d_end_state_pending], 0
    jne adventure_input_done
    call adventure_handle_turn
    call adventure_handle_jump
    call adventure_handle_charge
    call adventure_handle_flame
    call adventure_handle_movement
    call adventure_apply_vertical_motion
    call adventure_sync_player_tile_from_world
    call adventure_collect_gem_if_present
    call adventure_apply_hazard_if_present
    call adventure_check_charge_contact
    call adventure_check_portal_ready
    call adventure_try_enter_portal
    call adventure_maybe_step_enemies

adventure_input_done:
    call clear_pressed_latches
    ret

initialize_adventure_run_state:
    mov byte ptr [game_state], STATE_PLAYING
    mov byte ptr [sector_num], 1
    mov byte ptr [title_idle_ticks], 0
    mov byte ptr [run_start_enter_guard], RUN_START_ENTER_GUARD_TICKS
    mov byte ptr [shield_count], START_SHIELDS
    mov byte ptr [pulse_count], 0
    mov byte ptr [data_count], 0
    mov byte ptr [kill_count], 0
    mov byte ptr [action_taken], 0
    mov byte ptr [last_player_dx], 0
    mov byte ptr [last_player_dy], 0
    mov byte ptr [spoof_timer], 0
    mov byte ptr [threat_level], THREAT_NONE
    mov byte ptr [adventure_charge_timer], 0
    mov byte ptr [adventure_flame_timer], 0
    mov byte ptr [adventure_enemy_tick], 0
    mov byte ptr [adventure_hazard_timer], 0
    mov byte ptr [adventure_objectives_done], 0
    mov byte ptr [adventure_objectives_total], 0
    mov byte ptr [adventure_intro_timer], 0
    mov word ptr [adventure_player_vel_y], 0
    mov word ptr [adventure_player_world_y], GAME3D_FLOOR_Y
    call reset_run_mastery
    call load_adventure_realm
    mov al, MSG_SECTOR
    call set_message_event
    ret

load_adventure_realm:
    call game3d_reset_room_state
    call clear_enemy_pressure
    call clear_enemy_table
    call copy_adventure_realm_layout

    mov al, [adventure_realm_start_x]
    mov [player_x], al
    mov [spoof_x], al
    mov al, [adventure_realm_start_y]
    mov [player_y], al
    mov [spoof_y], al

    mov al, [adventure_realm_portal_x]
    mov [exit_x], al
    mov al, [adventure_realm_portal_y]
    mov [exit_y], al
    call set_exit_locked

    mov al, [adventure_realm_switch_count]
    mov [adventure_objectives_total], al

    mov si, offset adventure_realm_gem_table
    xor cx, cx
    mov cl, [adventure_realm_gem_count]
    mov dl, TILE_SHARD
    call adventure_place_coord_table

    mov si, offset adventure_realm_switch_table
    xor cx, cx
    mov cl, [adventure_realm_switch_count]
    mov dl, TILE_TERMINAL
    call adventure_place_coord_table

    mov si, offset adventure_realm_hazard_table
    xor cx, cx
    mov cl, [adventure_realm_hazard_count]
    mov dl, TILE_SURGE
    call adventure_place_coord_table

    mov si, offset adventure_realm_enemy_table
    xor cx, cx
    mov cl, [adventure_realm_enemy_count]
    call adventure_place_enemy_table

    mov bl, [player_x]
    mov bh, [player_y]
    call game3d_get_tile_center_world
    mov [adventure_player_world_x], ax
    mov [adventure_player_world_z], dx
    mov word ptr [adventure_player_world_y], GAME3D_FLOOR_Y
    mov word ptr [adventure_player_vel_y], 0
    mov byte ptr [adventure_player_grounded], 1
    mov byte ptr [adventure_player_yaw], GAME3D_YAW_EAST
    mov byte ptr [adventure_intro_timer], ADVENTURE_INTRO_TICKS
    call game3d_start_sector_entry_shot
    ret

copy_adventure_realm_layout:
    mov si, offset adventure_realm_map
    mov di, offset map_tiles
    mov cx, MAP_SIZE

copy_adventure_realm_loop:
    mov al, [si]
    inc si
    cmp al, '#'
    je copy_adventure_wall
    mov al, TILE_FLOOR
    jmp copy_adventure_store

copy_adventure_wall:
    mov al, TILE_WALL

copy_adventure_store:
    mov [di], al
    inc di
    loop copy_adventure_realm_loop
    ret

adventure_place_coord_table:
    jcxz adventure_place_coord_done

adventure_place_coord_loop:
    mov bl, [si]
    mov bh, [si + 1]
    call set_tile
    add si, 2
    loop adventure_place_coord_loop

adventure_place_coord_done:
    ret

adventure_place_enemy_table:
    jcxz adventure_place_enemy_done

adventure_place_enemy_loop:
    push cx
    mov di, si
    call find_free_enemy_slot
    mov byte ptr [si + ENEMY_ALIVE], 1
    mov al, [di]
    mov [si + ENEMY_X], al
    mov al, [di + 1]
    mov [si + ENEMY_Y], al
    mov al, [di + 2]
    mov [si + ENEMY_KIND], al
    mov si, di
    add si, 3
    pop cx
    loop adventure_place_enemy_loop

adventure_place_enemy_done:
    ret

adventure_tick_timers:
    cmp byte ptr [adventure_charge_timer], 0
    je adventure_charge_tick_done
    dec byte ptr [adventure_charge_timer]

adventure_charge_tick_done:
    cmp byte ptr [adventure_flame_timer], 0
    je adventure_flame_tick_done
    dec byte ptr [adventure_flame_timer]

adventure_flame_tick_done:
    cmp byte ptr [adventure_hazard_timer], 0
    je adventure_hazard_tick_done
    dec byte ptr [adventure_hazard_timer]

adventure_hazard_tick_done:
    cmp byte ptr [adventure_intro_timer], 0
    je adventure_tick_done
    dec byte ptr [adventure_intro_timer]

adventure_tick_done:
    ret

adventure_handle_turn:
    mov al, [key_down + SCAN_A]
    or al, [key_down + SCAN_LEFT_EXT]
    jz adventure_turn_check_right
    mov al, [key_down + SCAN_D]
    or al, [key_down + SCAN_RIGHT_EXT]
    jnz adventure_turn_done
    sub byte ptr [adventure_player_yaw], ADVENTURE_TURN_STEP
    ret

adventure_turn_check_right:
    mov al, [key_down + SCAN_D]
    or al, [key_down + SCAN_RIGHT_EXT]
    jz adventure_turn_done
    add byte ptr [adventure_player_yaw], ADVENTURE_TURN_STEP

adventure_turn_done:
    ret

adventure_handle_jump:
    cmp byte ptr [pressed_space], 0
    je adventure_jump_done
    cmp byte ptr [adventure_player_grounded], 0
    je adventure_jump_done
    mov word ptr [adventure_player_vel_y], ADVENTURE_JUMP_VEL
    mov byte ptr [adventure_player_grounded], 0

adventure_jump_done:
    ret

adventure_handle_charge:
    cmp byte ptr [pressed_shift], 0
    je adventure_charge_done
    cmp byte ptr [adventure_player_grounded], 0
    je adventure_charge_done
    cmp byte ptr [adventure_charge_timer], 0
    jne adventure_charge_done
    mov byte ptr [adventure_charge_timer], ADVENTURE_CHARGE_TICKS

adventure_charge_done:
    ret

adventure_handle_flame:
    cmp byte ptr [pressed_c], 0
    je adventure_flame_done
    cmp byte ptr [adventure_flame_timer], 0
    jne adventure_flame_done
    mov byte ptr [adventure_flame_timer], ADVENTURE_FLAME_TICKS
    call adventure_fire_flame

adventure_flame_done:
    ret

adventure_handle_movement:
    call adventure_get_move_speed
    or ax, ax
    jz adventure_movement_done
    mov [scene3d_temp_v], ax
    mov al, [adventure_player_yaw]
    call scene3d_get_sin_cos
    mov ax, [scene3d_temp_v]
    call scene3d_mul_ax_bx_fixed
    mov [scene3d_temp_w], ax
    mov ax, [scene3d_temp_v]
    mov bx, dx
    call scene3d_mul_ax_bx_fixed
    mov [scene3d_temp_l], ax

    mov ax, [adventure_player_world_x]
    add ax, [scene3d_temp_w]
    mov dx, [adventure_player_world_z]
    call adventure_try_move_to_world
    jnc adventure_move_z
    mov [adventure_player_world_x], ax
    mov [adventure_player_world_z], dx
    mov byte ptr [action_taken], 1

adventure_move_z:
    mov ax, [adventure_player_world_x]
    mov dx, [adventure_player_world_z]
    add dx, [scene3d_temp_l]
    call adventure_try_move_to_world
    jnc adventure_movement_done
    mov [adventure_player_world_x], ax
    mov [adventure_player_world_z], dx
    mov byte ptr [action_taken], 1

adventure_movement_done:
    ret

adventure_get_move_speed:
    cmp byte ptr [adventure_charge_timer], 0
    je adventure_speed_forward
    mov ax, ADVENTURE_CHARGE_SPEED
    ret

adventure_speed_forward:
    mov al, [key_down + SCAN_W]
    or al, [key_down + SCAN_UP_EXT]
    jz adventure_speed_back
    mov ax, ADVENTURE_MOVE_SPEED
    ret

adventure_speed_back:
    mov al, [key_down + SCAN_S]
    or al, [key_down + SCAN_DOWN_EXT]
    jz adventure_speed_stop
    mov ax, -ADVENTURE_BACK_SPEED
    ret

adventure_speed_stop:
    xor ax, ax
    ret

adventure_try_move_to_world:
    push bx
    push di
    call adventure_world_to_tile
    cmp bl, PLAY_MIN_X
    jb adventure_try_move_fail
    cmp bl, PLAY_MAX_X
    ja adventure_try_move_fail
    cmp bh, PLAY_MIN_Y
    jb adventure_try_move_fail
    cmp bh, PLAY_MAX_Y
    ja adventure_try_move_fail
    push bx
    call get_tile
    pop bx
    cmp al, TILE_WALL
    je adventure_try_move_fail
    cmp al, TILE_EXIT_LOCKED
    je adventure_try_move_fail
    mov di, 0FFFFh
    call find_enemy_at
    jnc adventure_try_move_ok
    cmp byte ptr [adventure_charge_timer], 0
    je adventure_try_move_fail
    cmp byte ptr [si + ENEMY_KIND], ENEMY_FLANKER
    je adventure_try_move_fail

adventure_try_move_ok:
    pop di
    pop bx
    stc
    ret

adventure_try_move_fail:
    pop di
    pop bx
    clc
    ret

adventure_world_to_tile:
    add ax, GAME3D_WORLD_ORIGIN_X
    mov bl, ah
    add dx, GAME3D_WORLD_ORIGIN_Z
    mov bh, dh
    ret

adventure_apply_vertical_motion:
    cmp byte ptr [adventure_player_grounded], 0
    jne adventure_grounded_motion
    mov ax, [adventure_player_vel_y]
    cmp ax, ADVENTURE_GLIDE_FALL_LIMIT
    jge adventure_glide_ready
    cmp byte ptr [key_down + SCAN_SPACE], 0
    je adventure_glide_ready
    mov ax, ADVENTURE_GLIDE_FALL_LIMIT

adventure_glide_ready:
    mov [adventure_player_vel_y], ax
    add [adventure_player_world_y], ax
    sub word ptr [adventure_player_vel_y], ADVENTURE_GRAVITY
    mov ax, [adventure_player_world_y]
    cmp ax, GAME3D_FLOOR_Y
    jg adventure_airborne_done
    mov word ptr [adventure_player_world_y], GAME3D_FLOOR_Y
    mov word ptr [adventure_player_vel_y], 0
    mov byte ptr [adventure_player_grounded], 1
    ret

adventure_airborne_done:
    ret

adventure_grounded_motion:
    mov word ptr [adventure_player_world_y], GAME3D_FLOOR_Y
    mov word ptr [adventure_player_vel_y], 0
    ret

adventure_sync_player_tile_from_world:
    mov cl, [player_x]
    mov ch, [player_y]
    mov ax, [adventure_player_world_x]
    mov dx, [adventure_player_world_z]
    call adventure_world_to_tile
    mov [player_x], bl
    mov [player_y], bh
    mov al, bl
    sub al, cl
    mov [last_player_dx], al
    mov al, bh
    sub al, ch
    mov [last_player_dy], al
    ret

adventure_collect_gem_if_present:
    mov bl, [player_x]
    mov bh, [player_y]
    call get_tile
    cmp al, TILE_SHARD
    jne adventure_collect_done
    mov bl, [player_x]
    mov bh, [player_y]
    mov dl, TILE_FLOOR
    call set_tile
    mov bl, [player_x]
    mov bh, [player_y]
    call set_effect_focus_tile
    inc byte ptr [data_count]
    mov ax, SCORE_SHARD_POINTS
    call award_score_ax
    mov al, MSG_SHARD
    call set_message_event
    call adventure_check_portal_ready

adventure_collect_done:
    ret

adventure_apply_hazard_if_present:
    cmp byte ptr [adventure_player_grounded], 0
    je adventure_hazard_done
    cmp byte ptr [adventure_hazard_timer], 0
    jne adventure_hazard_done
    mov bl, [player_x]
    mov bh, [player_y]
    call get_tile
    cmp al, TILE_SURGE
    jne adventure_hazard_done
    mov byte ptr [adventure_hazard_timer], ADVENTURE_HAZARD_COOLDOWN
    mov bl, [player_x]
    mov bh, [player_y]
    call set_effect_focus_tile
    call record_sector_hit
    dec byte ptr [shield_count]
    mov al, MSG_SURGE
    call set_message_event
    cmp byte ptr [shield_count], 0
    jne adventure_hazard_done
    mov al, STATE_LOSE
    call game3d_start_endbeat_shot

adventure_hazard_done:
    ret

adventure_check_charge_contact:
    mov di, 0FFFFh
    mov bl, [player_x]
    mov bh, [player_y]
    call find_enemy_at
    jnc adventure_charge_contact_done
    cmp byte ptr [adventure_charge_timer], 0
    je adventure_charge_contact_done
    cmp byte ptr [si + ENEMY_KIND], ENEMY_FLANKER
    je adventure_charge_contact_done
    mov bl, [si + ENEMY_X]
    mov bh, [si + ENEMY_Y]
    call set_effect_focus_tile
    mov byte ptr [si + ENEMY_ALIVE], 0
    call award_kill
    mov al, MSG_KILL
    call set_message_event

adventure_charge_contact_done:
    ret

adventure_check_portal_ready:
    mov bl, [exit_x]
    mov bh, [exit_y]
    call get_tile
    cmp al, TILE_EXIT_OPEN
    je adventure_portal_ready_done
    mov al, [data_count]
    cmp al, [adventure_realm_gem_count]
    jb adventure_portal_ready_done
    mov al, [adventure_objectives_done]
    cmp al, [adventure_objectives_total]
    jb adventure_portal_ready_done
    call open_exit
    mov al, MSG_GATE
    call set_message_event

adventure_portal_ready_done:
    ret

adventure_try_enter_portal:
    cmp byte ptr [pressed_enter], 0
    je adventure_portal_enter_done
    mov bl, [player_x]
    mov bh, [player_y]
    call get_tile
    cmp al, TILE_EXIT_OPEN
    jne adventure_portal_enter_done
    mov al, STATE_WIN
    call game3d_start_endbeat_shot

adventure_portal_enter_done:
    ret

adventure_maybe_step_enemies:
    cmp byte ptr [adventure_intro_timer], 0
    jne adventure_enemy_step_done
    cmp byte ptr [game_state], STATE_PLAYING
    jne adventure_enemy_step_done
    cmp byte ptr [game3d_end_state_pending], 0
    jne adventure_enemy_step_done
    inc byte ptr [adventure_enemy_tick]
    cmp byte ptr [adventure_enemy_tick], ADVENTURE_ENEMY_STEP_TICKS
    jb adventure_enemy_step_done
    mov byte ptr [adventure_enemy_tick], 0
    call enemy_turn

adventure_enemy_step_done:
    ret

adventure_fire_flame:
    mov bl, [player_x]
    mov bh, [player_y]
    call adventure_flame_hit_tile
    jc adventure_fire_done
    call adventure_get_forward_target_tile
    call adventure_flame_hit_tile

adventure_fire_done:
    ret

adventure_get_forward_target_tile:
    mov bl, [player_x]
    mov bh, [player_y]
    mov al, [adventure_player_yaw]
    call adventure_get_step_from_yaw
    add bl, al
    add bh, ah
    ret

adventure_get_step_from_yaw:
    cmp al, 32
    jb adventure_step_south
    cmp al, 96
    jb adventure_step_east
    cmp al, 160
    jb adventure_step_north
    cmp al, 224
    jb adventure_step_west

adventure_step_south:
    xor ah, ah
    mov al, 0
    mov ah, 1
    ret

adventure_step_east:
    mov al, 1
    xor ah, ah
    ret

adventure_step_north:
    mov al, 0
    mov ah, -1
    ret

adventure_step_west:
    mov al, -1
    xor ah, ah
    ret

adventure_flame_hit_tile:
    cmp bl, PLAY_MIN_X
    jb adventure_flame_miss
    cmp bl, PLAY_MAX_X
    ja adventure_flame_miss
    cmp bh, PLAY_MIN_Y
    jb adventure_flame_miss
    cmp bh, PLAY_MAX_Y
    ja adventure_flame_miss
    push bx
    call get_tile
    pop bx
    cmp al, TILE_TERMINAL
    je adventure_flame_switch
    mov di, 0FFFFh
    call find_enemy_at
    jnc adventure_flame_miss
    cmp byte ptr [si + ENEMY_KIND], ENEMY_FLANKER
    jne adventure_flame_miss
    call set_effect_focus_tile
    mov byte ptr [si + ENEMY_ALIVE], 0
    call award_kill
    mov al, MSG_KILL
    call set_message_event
    stc
    ret

adventure_flame_switch:
    mov dl, TILE_FLOOR
    call set_tile
    call set_effect_focus_tile
    inc byte ptr [adventure_objectives_done]
    mov al, MSG_SPOOF
    call set_message_event
    call adventure_check_portal_ready
    stc
    ret

adventure_flame_miss:
    clc
    ret

move_left:
    mov bl, [player_x]
    cmp bl, PLAY_MIN_X
    jbe blocked_move
    dec bl
    mov bh, [player_y]
    call attempt_move_to
    jmp maybe_enemy_turn

move_right:
    mov bl, [player_x]
    cmp bl, PLAY_MAX_X
    jae blocked_move
    inc bl
    mov bh, [player_y]
    call attempt_move_to
    jmp maybe_enemy_turn

move_up:
    mov bl, [player_x]
    mov bh, [player_y]
    cmp bh, PLAY_MIN_Y
    jbe blocked_move
    dec bh
    call attempt_move_to
    jmp maybe_enemy_turn

move_down:
    mov bl, [player_x]
    mov bh, [player_y]
    cmp bh, PLAY_MAX_Y
    jae blocked_move
    inc bh
    call attempt_move_to
    jmp maybe_enemy_turn

blocked_move:
    mov al, MSG_BLOCK
    call set_message_event
    ret

do_pulse:
    call use_pulse

maybe_enemy_turn:
    cmp byte ptr [game_state], STATE_PLAYING
    jne input_done
    cmp byte ptr [action_taken], 0
    je input_done
    call record_sector_action
    call enemy_turn

input_done:
IF DEBUG_RUNTIME_VERIFY
    cmp byte ptr [demo_active], 0
    je input_done_ready
    cmp byte ptr [verify_action_pending], 0
    je input_done_ready
    call verify_runtime_checkpoint

input_done_ready:
ENDIF
    ret

attempt_move_to:
    push bx
    mov di, 0FFFFh
    call find_enemy_at
    jc stepped_into_enemy
    pop bx

    call get_tile
    cmp al, TILE_WALL
    je move_blocked
    cmp al, TILE_EXIT_LOCKED
    je move_blocked
    cmp al, TILE_SHARD
    je move_collect_shard
    cmp al, TILE_TERMINAL
    je move_trigger_terminal
    cmp al, TILE_EXIT_OPEN
    je move_use_exit
    cmp al, TILE_SURGE
    je move_trigger_surge

move_floor:
    call commit_player_move
    ret

move_blocked:
    mov al, MSG_BLOCK
    call set_message_event
    ret

stepped_into_enemy:
    pop bx
    call set_effect_focus_tile
    mov byte ptr [si + ENEMY_ALIVE], 0
    call award_kill
    call commit_player_move
    mov al, MSG_KILL
    call set_message_event
    ret

move_collect_shard:
    mov dl, TILE_FLOOR
    call set_tile
    call commit_player_move
    inc byte ptr [data_count]
    mov ax, SCORE_SHARD_POINTS
    call award_score_ax
    mov al, [data_count]
    cmp al, SHARD_COUNT
    jb shard_message
    call open_exit
    mov al, MSG_GATE
    call set_message_event
    ret

shard_message:
    mov al, MSG_SHARD
    call set_message_event
    ret

move_trigger_terminal:
    mov dl, TILE_FLOOR
    call set_tile
    call set_effect_focus_tile
    call commit_player_move
    call set_spoof_anchor
    mov byte ptr [spoof_timer], SPOOF_TURNS
    call game3d_start_terminal_shot
    mov al, MSG_SPOOF
    call set_message_event
    ret

move_use_exit:
    call record_sector_action
    call finalize_sector_mastery
    mov al, [sector_num]
    cmp al, TOTAL_SECTORS
    jne move_use_exit_advance
    call award_final_mastery_bonus
    mov al, STATE_WIN
    call game3d_start_endbeat_shot
    ret

move_use_exit_advance:
    inc byte ptr [sector_num]
    mov al, [sector_num]
    cmp al, TOTAL_SECTORS
    jbe advance_sector
    mov al, STATE_WIN
    call game3d_start_endbeat_shot
    ret

move_trigger_surge:
    mov dl, TILE_FLOOR
    call set_tile
    call set_effect_focus_tile
    call commit_player_move
    call record_sector_hit
    sub byte ptr [shield_count], SURGE_PLAYER_DAMAGE
    mov al, MSG_SURGE
    call set_message_event
    cmp byte ptr [shield_count], 0
    jne surge_done
    mov al, STATE_LOSE
    call game3d_start_endbeat_shot

surge_done:
    ret

advance_sector:
    call load_sector
    mov al, MSG_SECTOR
    call set_message_event
    ret

use_pulse:
    cmp byte ptr [pulse_count], 0
    jne pulse_live
    mov al, MSG_NOPULSE
    call set_message_event
    ret

pulse_live:
    dec byte ptr [pulse_count]
    call record_sector_pulse
    mov al, MSG_PULSE
    call set_message_event
    mov byte ptr [action_taken], 1
    mov si, offset enemies
    mov cx, MAX_ENEMIES
    xor di, di

pulse_loop:
    cmp byte ptr [si + ENEMY_ALIVE], 0
    je pulse_next

    mov al, [si + ENEMY_X]
    mov bl, [player_x]
    cmp al, bl
    je pulse_x_ok
    jb pulse_x_left
    sub al, bl
    cmp al, PULSE_RADIUS
    ja pulse_next
    jmp pulse_x_ok

pulse_x_left:
    mov dl, bl
    sub dl, al
    cmp dl, PULSE_RADIUS
    ja pulse_next

pulse_x_ok:
    mov al, [si + ENEMY_Y]
    mov bl, [player_y]
    cmp al, bl
    je pulse_hit
    jb pulse_y_up
    sub al, bl
    cmp al, PULSE_RADIUS
    ja pulse_next
    jmp pulse_hit

pulse_y_up:
    mov dl, bl
    sub dl, al
    cmp dl, PULSE_RADIUS
    ja pulse_next

pulse_hit:
    mov bl, [si + ENEMY_X]
    mov bh, [si + ENEMY_Y]
    call set_effect_focus_tile
    mov byte ptr [si + ENEMY_ALIVE], 0
    call award_kill
    inc di

pulse_next:
    add si, ENEMY_SIZE
    loop pulse_loop
    mov ax, di
    call award_pulse_chain_bonus
    cmp di, PULSE_RECHARGE_KILLS
    jb pulse_done
    cmp byte ptr [pulse_count], MAX_PULSES
    jae pulse_done
    inc byte ptr [pulse_count]
    mov al, MSG_RECHARGE
    call set_message_event

pulse_done:
    ret

enemy_turn:
    call clear_enemy_pressure
    mov si, offset enemies
    mov cx, MAX_ENEMIES

enemy_turn_loop:
    cmp byte ptr [si + ENEMY_ALIVE], 0
    je enemy_turn_next
    push cx
    call move_enemy
    pop cx
    cmp byte ptr [game_state], STATE_PLAYING
    jne enemy_turn_done

enemy_turn_next:
    add si, ENEMY_SIZE
    loop enemy_turn_loop

enemy_turn_done:
    cmp byte ptr [game_state], STATE_PLAYING
    jne enemy_turn_done_skip
    call update_enemy_pressure
    call game3d_note_pressure_change
    cmp byte ptr [spoof_timer], 0
    je enemy_turn_done_skip
    dec byte ptr [spoof_timer]

enemy_turn_done_skip:
    ret

move_enemy:
    cmp byte ptr [spoof_timer], 0
    jne move_enemy_spoof
    mov al, [si + ENEMY_KIND]
    cmp al, ENEMY_FLANKER
    je move_enemy_flanker
    cmp al, ENEMY_WARDEN
    je move_enemy_warden
    jmp enemy_player_horizontal_first

move_enemy_spoof:
    ; A live spoof route only changes the hunters' target beacon. They still
    ; take one normal step, but the redirected line can bunch up near the gate.
    call get_enemy_exit_delta
    cmp ch, cl
    jae enemy_target_vertical_first
    jmp enemy_target_horizontal_first

move_enemy_flanker:
    ; Flankers do not get extra movement; they simply aim one tile ahead of the
    ; runner's last committed step so they produce cleaner cut-offs.
    call get_projected_player_target
    call get_enemy_target_delta
move_enemy_flanker_ready:
    cmp ch, cl
    jae enemy_target_vertical_first
    jmp enemy_target_horizontal_first

move_enemy_warden:
    call get_enemy_player_delta
    mov al, cl
    add al, ch
    mov bl, al
    call get_sector_warden_engage_distance
    cmp bl, al
    jbe move_enemy_warden_hunt
    call get_enemy_exit_delta
    cmp ch, cl
    jae enemy_target_vertical_first
    jmp enemy_target_horizontal_first

move_enemy_warden_hunt:
    cmp byte ptr [sector_num], 3
    jne move_enemy_warden_direct
    call get_projected_player_target
    call get_enemy_target_delta
    cmp ch, cl
    jae enemy_target_vertical_first
    jmp enemy_target_horizontal_first

move_enemy_warden_direct:
    mov bl, [player_x]
    mov bh, [player_y]
    call get_enemy_target_delta
    cmp ch, cl
    jae enemy_target_vertical_first
    jmp enemy_target_horizontal_first

enemy_player_horizontal_first:
    mov bl, [player_x]
    mov bh, [player_y]
    jmp enemy_target_horizontal_first

enemy_player_vertical_first:
    ; Vertical-first paths are used when the target delta is taller than it is
    ; wide, which keeps hunter intent readable without pathfinding.
    mov bl, [player_x]
    mov bh, [player_y]
    jmp enemy_target_vertical_first

enemy_exit_horizontal_first:
    mov bl, [exit_x]
    mov bh, [exit_y]
    jmp enemy_target_horizontal_first

enemy_exit_vertical_first:
    mov bl, [exit_x]
    mov bh, [exit_y]
    jmp enemy_target_vertical_first

enemy_target_horizontal_first:
    call enemy_try_horizontal_to_target
    jc enemy_done
    call enemy_try_vertical_to_target

enemy_done:
    ret

enemy_target_vertical_first:
    call enemy_try_vertical_to_target
    jc enemy_done
    call enemy_try_horizontal_to_target
    jmp enemy_done

get_enemy_player_delta:
    mov bl, [player_x]
    mov bh, [player_y]
    jmp get_enemy_target_delta

get_enemy_exit_delta:
    mov bl, [exit_x]
    mov bh, [exit_y]

get_enemy_target_delta:
    mov al, bl
    sub al, [si + ENEMY_X]
    jns enemy_player_dx_ready
    neg al

enemy_player_dx_ready:
    mov cl, al
    mov al, bh
    sub al, [si + ENEMY_Y]
    jns enemy_player_dy_ready
    neg al

enemy_player_dy_ready:
    mov ch, al
    ret

get_projected_player_target:
    mov bl, [player_x]
    mov bh, [player_y]
    mov al, [last_player_dx]
    or al, [last_player_dy]
    jz projected_target_ready

    mov al, [last_player_dx]
    or al, al
    jz projected_target_y
    add bl, al
    cmp bl, PLAY_MIN_X
    jb projected_target_reset_x
    cmp bl, PLAY_MAX_X
    ja projected_target_reset_x
    jmp projected_target_y

projected_target_reset_x:
    mov bl, [player_x]

projected_target_y:
    mov al, [last_player_dy]
    or al, al
    jz projected_target_ready
    add bh, al
    cmp bh, PLAY_MIN_Y
    jb projected_target_reset_y
    cmp bh, PLAY_MAX_Y
    ja projected_target_reset_y
    ret

projected_target_reset_y:
    mov bh, [player_y]

projected_target_ready:
    ret

enemy_try_horizontal_to_target:
    mov al, [si + ENEMY_X]
    cmp al, bl
    je enemy_axis_fail
    jb enemy_step_right

enemy_step_left:
    mov dl, al
    dec dl
    mov dh, [si + ENEMY_Y]
    call try_enemy_step
    ret

enemy_step_right:
    mov dl, al
    inc dl
    mov dh, [si + ENEMY_Y]
    call try_enemy_step
    ret

enemy_try_vertical_to_target:
    mov al, [si + ENEMY_Y]
    cmp al, bh
    je enemy_axis_fail
    jb enemy_step_down

enemy_step_up:
    mov dl, [si + ENEMY_X]
    mov dh, al
    dec dh
    call try_enemy_step
    ret

enemy_step_down:
    mov dl, [si + ENEMY_X]
    mov dh, al
    inc dh
    call try_enemy_step
    ret

enemy_axis_fail:
    clc
    ret

try_enemy_step:
    mov bl, [player_x]
    cmp dl, bl
    jne step_not_player
    mov bl, [player_y]
    cmp dh, bl
    jne step_not_player
    mov bl, dl
    mov bh, dh
    call set_effect_focus_tile
    call record_sector_hit
    dec byte ptr [shield_count]
    mov byte ptr [si + ENEMY_ALIVE], 0
    mov al, MSG_HIT
    call set_message_event
    cmp byte ptr [shield_count], 0
    jne step_success
    mov al, STATE_LOSE
    call game3d_start_endbeat_shot
step_success:
    stc
    ret

step_not_player:
    mov di, si
    mov bl, dl
    mov bh, dh
    push si
    call get_tile
    pop si
    cmp al, TILE_WALL
    je step_fail
    cmp al, TILE_EXIT_LOCKED
    je step_fail
    cmp al, TILE_EXIT_OPEN
    je step_fail
    cmp al, TILE_SURGE
    je step_hit_surge

    mov bl, dl
    mov bh, dh
    call find_enemy_at
    jc step_fail

    mov si, di
    mov [si + ENEMY_X], dl
    mov [si + ENEMY_Y], dh
    stc
    ret

step_hit_surge:
    mov bl, dl
    mov bh, dh
    mov dl, TILE_FLOOR
    call set_tile
    mov si, di
    call set_effect_focus_tile
    mov byte ptr [si + ENEMY_ALIVE], 0
    call award_kill
    mov ax, SCORE_TRAP_BONUS
    call award_score_ax
    mov al, MSG_TRAP
    call set_message_event
    stc
    ret

step_fail:
    clc
    ret

load_sector:
    cmp byte ptr [sector_num], 1
    je keep_pulse_count
    cmp byte ptr [pulse_count], MAX_PULSES
    jae keep_pulse_count
    inc byte ptr [pulse_count]

keep_pulse_count:
    mov byte ptr [data_count], 0
    mov byte ptr [action_taken], 0
    mov byte ptr [last_player_dx], 0
    mov byte ptr [last_player_dy], 0
    mov byte ptr [spoof_timer], 0
    mov byte ptr [spoof_x], START_X
    mov byte ptr [spoof_y], START_Y
    call game3d_reset_room_state
    call reset_sector_mastery
    call clear_enemy_pressure
    call clear_enemy_table
    call copy_sector_layout
    mov byte ptr [player_x], START_X
    mov byte ptr [player_y], START_Y
    mov byte ptr [exit_x], EXIT_COL
    mov byte ptr [exit_y], EXIT_ROW
    call set_exit_locked
    call place_anchored_terminals
    call place_anchored_surge_fields
    call place_anchored_enemies
    call place_template_shards
    call place_terminals
    call place_surge_fields
    call place_enemies
    call game3d_start_sector_entry_shot
    ret

clear_enemy_table:
    mov di, offset enemies
    mov cx, MAX_ENEMIES * ENEMY_SIZE
    xor ax, ax

clear_enemy_loop:
    mov [di], al
    inc di
    loop clear_enemy_loop
    ret

copy_sector_layout:
    ; Sector templates are raw ASCII bytes inside the read-only map bank loaded
    ; to MAP_BANK_SEG. Only '#' survives as a wall; everything else becomes
    ; floor before dynamic objects are placed.
    call select_sector_template
    push es
    mov ax, MAP_BANK_SEG
    mov es, ax
    mov di, offset map_tiles
    mov cx, MAP_SIZE

copy_layout_loop:
    mov al, es:[si]
    inc si
    cmp al, '#'
    je copy_wall
    mov al, TILE_FLOOR
    jmp copy_store

copy_wall:
    mov al, TILE_WALL

copy_store:
    mov [di], al
    inc di
    loop copy_layout_loop
    pop es
    ret

select_sector_template:
    call get_sector_rule_index
    mov ch, [sector_template_start + bx]
    mov cl, [sector_template_count + bx]
    mov al, ch
    cmp cl, 1
    jbe template_index_ready
    call random_word
    xor dx, dx
    mov bl, cl
    xor bh, bh
    div bx
    mov al, ch
    add al, dl

template_index_ready:
    mov [current_template_index], al
    xor ah, ah
    shl ax, 1
    mov bx, ax
    mov si, word ptr [template_offset_table + bx]
    ret

get_sector_rule_index:
    ; Sector rule and template tables are all 0-based arrays keyed from the
    ; 1-based sector_num runtime state.
    mov al, [sector_num]
    dec al
    xor ah, ah
    mov bx, ax
    ret

set_exit_locked:
    mov bl, [exit_x]
    mov bh, [exit_y]
    mov dl, TILE_EXIT_LOCKED
    call set_tile
    ret

open_exit:
    mov bl, [exit_x]
    mov bh, [exit_y]
    mov dl, TILE_EXIT_OPEN
    call set_tile
    call set_effect_focus_tile
IF DEBUG_LEGACY_GAMEPLAY EQ 1
    call game3d_start_gate_unlock_shot
ENDIF
    ret

place_template_shards:
    mov byte ptr [shard_pool_pick_mask], 0
    mov cx, SHARD_COUNT

place_template_shard_loop:
    push cx
    call choose_template_shard_position
    mov dl, TILE_SHARD
    call set_tile
    pop cx
    loop place_template_shard_loop
    ret

get_sector_surge_count:
    xor cx, cx
    call get_sector_rule_index
    mov cl, [sector_rule_surge_count + bx]
    ret

get_sector_terminal_count:
    xor cx, cx
    call get_sector_rule_index
    mov cl, [sector_rule_terminal_count + bx]
    ret

get_sector_enemy_count:
    mov al, [sector_num]
    mov bl, ENEMY_SPAWN_STEP
    mul bl
    add al, ENEMY_SPAWN_BASE
    mov dl, al
    call get_sector_rule_index
    xor cx, cx
    mov al, dl
    add al, [sector_rule_enemy_bonus + bx]
    mov cl, al
    ret

get_sector_warden_engage_distance:
    call get_sector_rule_index
    mov al, [sector_rule_warden_engage_distance + bx]
    ret

get_current_template_terminal_anchor_count:
    xor cx, cx
    xor bx, bx
    mov bl, [current_template_index]
    mov cl, [template_terminal_anchor_count + bx]
    ret

get_current_template_surge_anchor_count:
    xor cx, cx
    xor bx, bx
    mov bl, [current_template_index]
    mov cl, [template_surge_anchor_count + bx]
    ret

get_current_template_enemy_anchor_count:
    xor cx, cx
    xor bx, bx
    mov bl, [current_template_index]
    mov cl, [template_enemy_anchor_count + bx]
    ret

load_current_template_terminal_anchor_data:
    xor bx, bx
    mov bl, [current_template_index]
    xor cx, cx
    mov cl, [template_terminal_anchor_count + bx]
    shl bx, 1
    mov di, word ptr [template_terminal_anchor_offset + bx]
    add di, offset terminal_anchor_table
    ret

load_current_template_surge_anchor_data:
    xor bx, bx
    mov bl, [current_template_index]
    xor cx, cx
    mov cl, [template_surge_anchor_count + bx]
    shl bx, 1
    mov di, word ptr [template_surge_anchor_offset + bx]
    add di, offset surge_anchor_table
    ret

load_current_template_enemy_anchor_data:
    ; Generated encounter anchors stay flat and tiny: each selected template
    ; points into compact [x,y] or [x,y,kind] byte tables.
    xor bx, bx
    mov bl, [current_template_index]
    xor cx, cx
    mov cl, [template_enemy_anchor_count + bx]
    shl bx, 1
    mov di, word ptr [template_enemy_anchor_offset + bx]
    add di, offset enemy_anchor_table
    ret

get_current_template_shard_pool_count:
    xor cx, cx
    xor bx, bx
    mov bl, [current_template_index]
    mov cl, [template_shard_pool_count + bx]
    ret

load_current_template_shard_pool_data:
    ; Scenario shard pools stay small on purpose: each selected template points
    ; at a compact [x,y] list, and sector load chooses SHARD_COUNT unique picks.
    xor bx, bx
    mov bl, [current_template_index]
    xor cx, cx
    mov cl, [template_shard_pool_count + bx]
    shl bx, 1
    mov di, word ptr [template_shard_pool_offset + bx]
    add di, offset shard_pool_table
    ret

place_anchored_terminals:
    call load_current_template_terminal_anchor_data
    jcxz place_anchored_terminals_done

place_anchored_terminal_loop:
    mov bl, [di]
    mov bh, [di + 1]
    mov dl, TILE_TERMINAL
    call set_tile
    add di, 2
    loop place_anchored_terminal_loop

place_anchored_terminals_done:
    ret

place_anchored_surge_fields:
    call load_current_template_surge_anchor_data
    jcxz place_anchored_surges_done

place_anchored_surges_loop:
    mov bl, [di]
    mov bh, [di + 1]
    mov dl, TILE_SURGE
    call set_tile
    add di, 2
    loop place_anchored_surges_loop

place_anchored_surges_done:
    ret

find_free_enemy_slot:
    mov si, offset enemies

find_free_enemy_slot_loop:
    cmp byte ptr [si + ENEMY_ALIVE], 0
    je find_free_enemy_slot_done
    add si, ENEMY_SIZE
    jmp find_free_enemy_slot_loop

find_free_enemy_slot_done:
    ret

place_anchored_enemies:
    call load_current_template_enemy_anchor_data
    jcxz place_anchored_enemies_done

place_anchored_enemy_loop:
    push cx
    call find_free_enemy_slot
    mov byte ptr [si + ENEMY_ALIVE], 1
    mov al, [di]
    mov [si + ENEMY_X], al
    mov al, [di + 1]
    mov [si + ENEMY_Y], al
    mov al, [di + 2]
    mov [si + ENEMY_KIND], al
    add di, 3
    pop cx
    loop place_anchored_enemy_loop

place_anchored_enemies_done:
    ret

choose_template_shard_position:
    call load_current_template_shard_pool_data
    mov dl, cl

choose_template_shard_retry:
    call random_word
    mov bl, dl
    xor ah, ah
    div bl
    mov bl, ah
    xor bh, bh
    mov al, 1
    mov cl, bl
    shl al, cl
    mov ah, [shard_pool_pick_mask]
    test ah, al
    jnz choose_template_shard_retry
    or ah, al
    mov [shard_pool_pick_mask], ah
    shl bx, 1
    mov si, di
    add si, bx
    mov bl, [si]
    mov bh, [si + 1]
    ret

place_surge_fields:
    call get_sector_surge_count
    mov al, cl
    call get_current_template_surge_anchor_count
    sub al, cl
    mov cl, al
    xor ch, ch
    jcxz place_surge_done

place_surge_loop:
    call random_floor_position
    mov dl, TILE_SURGE
    call set_tile
    loop place_surge_loop

place_surge_done:
    ret

place_terminals:
    call get_sector_terminal_count
    mov al, cl
    call get_current_template_terminal_anchor_count
    sub al, cl
    mov cl, al
    xor ch, ch
    jcxz place_terminals_done

place_terminal_loop:
    call random_terminal_position
    mov dl, TILE_TERMINAL
    call set_tile
    loop place_terminal_loop

place_terminals_done:
    ret

place_enemies:
    call get_sector_enemy_count
    mov al, cl
    call get_current_template_enemy_anchor_count
    sub al, cl
    mov cl, al
    xor ch, ch
    jcxz place_enemies_done
    mov si, offset enemies

place_enemy_find_slot:
    cmp byte ptr [si + ENEMY_ALIVE], 0
    je place_enemy_here
    add si, ENEMY_SIZE
    jmp place_enemy_find_slot

place_enemy_here:
    call random_enemy_position
    mov byte ptr [si + ENEMY_ALIVE], 1
    mov [si + ENEMY_X], bl
    mov [si + ENEMY_Y], bh
    call roll_enemy_kind
    mov [si + ENEMY_KIND], al
    add si, ENEMY_SIZE
    dec cl
    jnz place_enemy_find_slot
place_enemies_done:
    ret

roll_enemy_kind:
    call random_word
    mov dl, al
    call get_sector_rule_index
    mov al, [sector_rule_warden_threshold + bx]
    or al, al
    jz roll_enemy_kind_check_flanker
    cmp dl, al
    jb roll_enemy_kind_warden

roll_enemy_kind_check_flanker:
    mov al, [sector_rule_flanker_threshold + bx]
    cmp dl, al
    jb roll_enemy_kind_flanker

roll_enemy_kind_rusher:
    mov al, ENEMY_RUSHER
    ret

roll_enemy_kind_flanker:
    mov al, ENEMY_FLANKER
    ret

roll_enemy_kind_warden:
    mov al, ENEMY_WARDEN
    ret

random_floor_position:
rand_floor_retry:
    call random_x
    mov bl, al
    call random_y
    mov bh, al
    cmp bl, START_X
    jne rand_floor_not_start
    cmp bh, START_Y
    je rand_floor_retry

rand_floor_not_start:
    cmp bl, EXIT_COL
    jne rand_floor_tile
    cmp bh, EXIT_ROW
    je rand_floor_retry

rand_floor_tile:
    call get_tile
    cmp al, TILE_FLOOR
    jne rand_floor_retry
    ret

random_terminal_position:
rand_terminal_retry:
    call random_floor_position
    cmp bl, SAFE_X_MAX
    ja rand_terminal_ready
    cmp bh, SAFE_Y_MIN
    jae rand_terminal_retry

rand_terminal_ready:
    ret

random_enemy_position:
    ; Callers expect the active enemy slot to stay live in SI while we search.
    push si
rand_enemy_retry:
    call random_floor_position
    cmp bl, SAFE_X_MAX
    ja rand_enemy_space_ok
    cmp bh, SAFE_Y_MIN
    jae rand_enemy_retry

rand_enemy_space_ok:
    mov di, 0FFFFh
    call find_enemy_at
    jc rand_enemy_retry
    pop si
    ret

random_shard_position:
    ; Shards still use the normal random floor flow, but the authored encounter
    ; pass places enemies earlier, so shard rolls now skip occupied enemy tiles.
    push si
rand_shard_retry:
    call random_floor_position
    mov di, 0FFFFh
    call find_enemy_at
    jc rand_shard_retry
    pop si
    ret

random_x:
    call random_word
    mov bl, PLAY_MAX_X
    ; Use the low byte as the bounded dividend so the 8-bit divide cannot
    ; trap while we map RNG output into the playable column range.
    xor ah, ah
    div bl
    mov al, ah
    inc al
    ret

random_y:
    call random_word
    mov bl, PLAY_MAX_Y
    xor ah, ah
    div bl
    mov al, ah
    inc al
    ret

random_word:
    mov ax, [rng_state]
    shr ax, 1
    jnc random_store
    xor ax, 0B400h

random_store:
    mov [rng_state], ax
    ret

commit_player_move:
    mov al, bl
    sub al, [player_x]
    mov [last_player_dx], al
    mov al, bh
    sub al, [player_y]
    mov [last_player_dy], al
    mov [player_x], bl
    mov [player_y], bh
    mov byte ptr [action_taken], 1
    call game3d_start_move_settle_shot
    ret

set_effect_focus_tile:
    mov [effect_x], bl
    mov [effect_y], bh
    ret

set_spoof_anchor:
    mov [spoof_x], bl
    mov [spoof_y], bh
    ret

clear_enemy_pressure:
    mov byte ptr [threat_level], THREAT_NONE
    ret

update_enemy_pressure:
    ; Pressure telegraphing is read-only state: it highlights the most dangerous
    ; hunter after their turn so deaths stay explainable on the next input.
    push si
    push cx
    mov si, offset enemies
    mov cx, MAX_ENEMIES

pressure_loop:
    cmp byte ptr [si + ENEMY_ALIVE], 0
    je pressure_next
    call evaluate_enemy_threat
    cmp al, [threat_level]
    jbe pressure_next
    mov [threat_level], al
    mov al, [si + ENEMY_X]
    mov [threat_x], al
    mov al, [si + ENEMY_Y]
    mov [threat_y], al
    cmp byte ptr [threat_level], THREAT_ELITE
    je pressure_done

pressure_next:
    add si, ENEMY_SIZE
    loop pressure_loop

pressure_done:
    pop cx
    pop si
    ret

evaluate_enemy_threat:
    call get_enemy_player_delta
    mov al, cl
    add al, ch
    cmp al, NEAR_THREAT_DISTANCE
    jbe threat_is_near
    cmp byte ptr [si + ENEMY_KIND], ENEMY_WARDEN
    jne enemy_threat_none
    cmp byte ptr [sector_num], 3
    jne enemy_threat_none
    cmp al, ELITE_THREAT_DISTANCE
    ja enemy_threat_none
    mov al, THREAT_ELITE
    ret

threat_is_near:
    mov al, THREAT_NEAR
    cmp byte ptr [si + ENEMY_KIND], ENEMY_WARDEN
    jne threat_ready
    cmp byte ptr [sector_num], 3
    jne threat_ready
    mov al, THREAT_ELITE
    ret

threat_ready:
    ret

enemy_threat_none:
    mov al, THREAT_NONE
    ret

reset_run_mastery:
    push ax
    push cx
    push di
    push es
    mov word ptr [score_total], 0
    mov word ptr [sector_score], 0
    mov byte ptr [sector_actions], 0
    mov byte ptr [sector_hits], 0
    mov byte ptr [sector_pulses_used], 0
    push ds
    pop es
    mov di, offset sector_score_table
    mov cx, TOTAL_SECTORS
    xor ax, ax
    rep stosw
    pop es
    pop di
    pop cx
    pop ax
    ret

reset_sector_mastery:
    mov word ptr [sector_score], 0
    mov byte ptr [sector_actions], 0
    mov byte ptr [sector_hits], 0
    mov byte ptr [sector_pulses_used], 0
    call sync_current_sector_score
    ret

record_sector_action:
    cmp byte ptr [sector_actions], 255
    jae record_sector_action_done
    inc byte ptr [sector_actions]
record_sector_action_done:
    ret

record_sector_hit:
    cmp byte ptr [sector_hits], 255
    jae record_sector_hit_done
    inc byte ptr [sector_hits]
record_sector_hit_done:
    ret

record_sector_pulse:
    cmp byte ptr [sector_pulses_used], 255
    jae record_sector_pulse_done
    inc byte ptr [sector_pulses_used]
record_sector_pulse_done:
    ret

award_pulse_chain_bonus:
    ; Pulse chains only pay extra for kills beyond the first, so safe single
    ; clears still feel good while bigger wipes become the stylish score play.
    cmp ax, 1
    jbe award_pulse_chain_done
    dec ax
    mov bl, SCORE_CHAIN_STEP
    mul bl
    call award_score_ax
award_pulse_chain_done:
    ret

finalize_sector_mastery:
    ; Sector-end mastery is intentionally legible: clean sectors, restrained EMP
    ; use, and faster clears all pay out, but none of them override survival.
    cmp byte ptr [sector_hits], 0
    jne sector_mastery_check_pulse
    mov ax, SCORE_NO_HIT_BONUS
    call award_score_ax

sector_mastery_check_pulse:
    mov al, [sector_pulses_used]
    cmp al, SCORE_EFFICIENT_PULSE_LIMIT
    ja sector_mastery_fast_clear
    mov ax, SCORE_EFFICIENT_PULSE_BONUS
    call award_score_ax

sector_mastery_fast_clear:
    push bx
    xor ax, ax
    mov al, [sector_actions]
    mov bl, SCORE_FAST_CLEAR_STEP
    mul bl
    cmp ax, SCORE_FAST_CLEAR_BASE
    jae sector_mastery_fast_done
    mov bx, SCORE_FAST_CLEAR_BASE
    sub bx, ax
    mov ax, bx
    call award_score_ax

sector_mastery_fast_done:
    pop bx
    ret

award_final_mastery_bonus:
    push bx
    xor ax, ax
    mov al, [shield_count]
    mov bl, SCORE_WIN_SHIELD_BONUS
    mul bl
    call award_score_ax
    xor ax, ax
    mov al, [pulse_count]
    mov bl, SCORE_WIN_PULSE_BONUS
    mul bl
    call award_score_ax
    pop bx
    ret

award_score_ax:
    push bx
    mov bx, [score_total]
    add bx, ax
    jnc award_score_total_ready
    mov bx, 0FFFFh

award_score_total_ready:
    mov [score_total], bx
    mov bx, [sector_score]
    add bx, ax
    jnc award_score_sector_ready
    mov bx, 0FFFFh

award_score_sector_ready:
    mov [sector_score], bx
    call sync_current_sector_score
    pop bx
    ret

sync_current_sector_score:
    push ax
    push bx
    xor ax, ax
    mov al, [sector_num]
    dec al
    xor ah, ah
    shl ax, 1
    mov bx, ax
    mov ax, [sector_score]
    mov [sector_score_table + bx], ax
    pop bx
    pop ax
    ret

get_sector_score_ax:
    xor ah, ah
    dec al
    shl ax, 1
    mov bx, ax
    mov ax, [sector_score_table + bx]
    ret

get_score_rank_index:
    mov ax, [score_total]
    cmp ax, SCORE_RANK_S_THRESHOLD
    jae score_rank_index_s
    cmp ax, SCORE_RANK_A_THRESHOLD
    jae score_rank_index_a
    cmp ax, SCORE_RANK_B_THRESHOLD
    jae score_rank_index_b
    cmp ax, SCORE_RANK_C_THRESHOLD
    jae score_rank_index_c
    mov al, 4
    ret

score_rank_index_s:
    mov al, 0
    ret

score_rank_index_a:
    mov al, 1
    ret

score_rank_index_b:
    mov al, 2
    ret

score_rank_index_c:
    mov al, 3
    ret

get_score_rank_ptr:
    call get_score_rank_index
    cmp al, 0
    je score_rank_ptr_s
    cmp al, 1
    je score_rank_ptr_a
    cmp al, 2
    je score_rank_ptr_b
    cmp al, 3
    je score_rank_ptr_c
    mov si, offset rank_d_text
    ret

score_rank_ptr_s:
    mov si, offset rank_s_text
    ret

score_rank_ptr_a:
    mov si, offset rank_a_text
    ret

score_rank_ptr_b:
    mov si, offset rank_b_text
    ret

score_rank_ptr_c:
    mov si, offset rank_c_text
    ret

get_score_rank_color:
    call get_score_rank_index
    cmp al, 0
    je score_rank_color_s
    cmp al, 1
    je score_rank_color_a
    cmp al, 2
    je score_rank_color_b
    cmp al, 3
    je score_rank_color_c
    mov al, PAL_RED2
    ret

score_rank_color_s:
    mov al, PAL_WHITE
    ret

score_rank_color_a:
    mov al, PAL_CYAN2
    ret

score_rank_color_b:
    mov al, PAL_GATE
    ret

score_rank_color_c:
    mov al, PAL_AMBER
    ret

award_kill:
    cmp byte ptr [kill_count], 99
    jae award_kill_score
    inc byte ptr [kill_count]

award_kill_score:
    mov ax, SCORE_KILL_POINTS
    call award_score_ax
award_done:
    ret

find_enemy_at:
    push ax
    push cx
    mov si, offset enemies
    mov cx, MAX_ENEMIES

find_enemy_loop:
    cmp byte ptr [si + ENEMY_ALIVE], 0
    je find_enemy_next
    cmp si, di
    je find_enemy_next
    mov al, [si + ENEMY_X]
    cmp al, bl
    jne find_enemy_next
    mov al, [si + ENEMY_Y]
    cmp al, bh
    jne find_enemy_next
    pop cx
    pop ax
    stc
    ret

find_enemy_next:
    add si, ENEMY_SIZE
    loop find_enemy_loop
    pop cx
    pop ax
    clc
    ret

get_tile:
    push bx
    call map_index
    mov al, [map_tiles + si]
    pop bx
    ret

set_tile:
    push bx
    call map_index
    mov [map_tiles + si], dl
    pop bx
    call game3d_mark_room_dirty
    ret

map_index:
    xor ax, ax
    mov al, bh
    shl ax, 1
    mov si, ax
    mov si, [map_row_offsets + si]
    xor ax, ax
    mov al, bl
    add si, ax
    ret
