process_play_input:
    ; Only consumed actions set action_taken; that flag is what grants hunters
    ; exactly one responding turn.
    mov byte ptr [action_taken], 0

    cmp byte ptr [pressed_enter], 0
    je check_pulse_lower
    mov byte ptr [pressed_enter], 0
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
    jmp do_pulse

consume_left:
    mov byte ptr [pressed_a], 0
    mov byte ptr [pressed_left], 0
    mov byte ptr [any_key_pending], 0
    jmp move_left

consume_right:
    mov byte ptr [pressed_d], 0
    mov byte ptr [pressed_right], 0
    mov byte ptr [any_key_pending], 0
    jmp move_right

consume_up:
    mov byte ptr [pressed_w], 0
    mov byte ptr [pressed_up], 0
    mov byte ptr [any_key_pending], 0
    jmp move_up

consume_down:
    mov byte ptr [pressed_s], 0
    mov byte ptr [pressed_down], 0
    mov byte ptr [any_key_pending], 0
    jmp move_down

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
    call enemy_turn

input_done:
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
    cmp al, TILE_EXIT_OPEN
    je move_use_exit
    cmp al, TILE_SURGE
    je move_trigger_surge

move_floor:
    mov [player_x], bl
    mov [player_y], bh
    mov byte ptr [action_taken], 1
    ret

move_blocked:
    mov al, MSG_BLOCK
    call set_message_event
    ret

stepped_into_enemy:
    pop bx
    mov byte ptr [si + ENEMY_ALIVE], 0
    call award_kill
    mov [player_x], bl
    mov [player_y], bh
    mov al, MSG_KILL
    call set_message_event
    mov byte ptr [action_taken], 1
    ret

move_collect_shard:
    mov dl, TILE_FLOOR
    call set_tile
    mov [player_x], bl
    mov [player_y], bh
    inc byte ptr [data_count]
    mov byte ptr [action_taken], 1
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

move_use_exit:
    inc byte ptr [sector_num]
    mov al, [sector_num]
    cmp al, TOTAL_SECTORS
    jbe advance_sector
    mov byte ptr [game_state], STATE_WIN
    ret

move_trigger_surge:
    mov dl, TILE_FLOOR
    call set_tile
    mov [player_x], bl
    mov [player_y], bh
    mov byte ptr [action_taken], 1
    sub byte ptr [shield_count], SURGE_PLAYER_DAMAGE
    mov al, MSG_SURGE
    call set_message_event
    cmp byte ptr [shield_count], 0
    jne surge_done
    mov byte ptr [game_state], STATE_LOSE

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
    mov byte ptr [si + ENEMY_ALIVE], 0
    call award_kill
    inc di

pulse_next:
    add si, ENEMY_SIZE
    loop pulse_loop
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
    ret

move_enemy:
    mov al, [si + ENEMY_KIND]
    cmp al, ENEMY_FLANKER
    je move_enemy_flanker
    cmp al, ENEMY_WARDEN
    je move_enemy_warden
    jmp enemy_player_horizontal_first

move_enemy_flanker:
    call get_enemy_player_delta
move_enemy_flanker_ready:
    cmp ch, cl
    jae enemy_player_vertical_first
    jmp enemy_player_horizontal_first

move_enemy_warden:
    call get_enemy_player_delta
    mov al, cl
    add al, ch
    cmp al, WARDEN_ENGAGE_DISTANCE
    jbe move_enemy_flanker_ready
    call get_enemy_exit_delta
    cmp ch, cl
    jae enemy_exit_vertical_first
    jmp enemy_exit_horizontal_first

enemy_player_horizontal_first:
    mov bl, [player_x]
    call enemy_try_horizontal_to_target
    jc enemy_done
    mov bh, [player_y]
    call enemy_try_vertical_to_target
    jmp enemy_done

enemy_player_vertical_first:
    mov bh, [player_y]
    call enemy_try_vertical_to_target
    jc enemy_done
    mov bl, [player_x]
    call enemy_try_horizontal_to_target
    jmp enemy_done

enemy_exit_horizontal_first:
    mov bl, [exit_x]
    call enemy_try_horizontal_to_target
    jc enemy_done
    mov bh, [exit_y]
    call enemy_try_vertical_to_target
    jmp enemy_done

enemy_exit_vertical_first:
    mov bh, [exit_y]
    call enemy_try_vertical_to_target
    jc enemy_done
    mov bl, [exit_x]
    call enemy_try_horizontal_to_target

enemy_done:
    ret

get_enemy_player_delta:
    mov al, [player_x]
    sub al, [si + ENEMY_X]
    jns enemy_player_dx_ready
    neg al

enemy_player_dx_ready:
    mov cl, al
    mov al, [player_y]
    sub al, [si + ENEMY_Y]
    jns enemy_player_dy_ready
    neg al

enemy_player_dy_ready:
    mov ch, al
    ret

get_enemy_exit_delta:
    mov al, [exit_x]
    sub al, [si + ENEMY_X]
    jns enemy_exit_dx_ready
    neg al

enemy_exit_dx_ready:
    mov cl, al
    mov al, [exit_y]
    sub al, [si + ENEMY_Y]
    jns enemy_exit_dy_ready
    neg al

enemy_exit_dy_ready:
    mov ch, al
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
    dec byte ptr [shield_count]
    mov byte ptr [si + ENEMY_ALIVE], 0
    mov al, MSG_HIT
    call set_message_event
    cmp byte ptr [shield_count], 0
    jne step_success
    mov byte ptr [game_state], STATE_LOSE
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
    mov byte ptr [si + ENEMY_ALIVE], 0
    call award_kill
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
    call clear_enemy_table
    call copy_sector_layout
    mov byte ptr [player_x], START_X
    mov byte ptr [player_y], START_Y
    mov byte ptr [exit_x], EXIT_COL
    mov byte ptr [exit_y], EXIT_ROW
    call set_exit_locked
    call place_shards
    call place_surge_fields
    call place_enemies
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
    ; Sector templates are MAP_H rows of MAP_W ASCII bytes. Only '#'
    ; survives as a wall; everything else is normalized to floor here.
    call select_sector_template
    mov di, offset map_tiles
    mov cx, MAP_SIZE

copy_layout_loop:
    lodsb
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
    ret

select_sector_template:
    mov al, [sector_num]
    dec al
    xor ah, ah
    mov bx, ax
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
    xor ah, ah
    shl ax, 1
    mov bx, ax
    mov si, word ptr [template_table + bx]
    ret

set_exit_locked:
    mov bl, EXIT_COL
    mov bh, EXIT_ROW
    mov dl, TILE_EXIT_LOCKED
    call set_tile
    ret

open_exit:
    mov bl, [exit_x]
    mov bh, [exit_y]
    mov dl, TILE_EXIT_OPEN
    call set_tile
    ret

place_shards:
    mov cx, SHARD_COUNT

place_shard_loop:
    call random_floor_position
    mov dl, TILE_SHARD
    call set_tile
    loop place_shard_loop
    ret

place_surge_fields:
    mov al, [sector_num]
    cmp al, SURGE_START_SECTOR
    jb place_surge_done
    sub al, SURGE_START_SECTOR - 1
    xor cx, cx
    mov cl, al

place_surge_loop:
    call random_floor_position
    mov dl, TILE_SURGE
    call set_tile
    loop place_surge_loop

place_surge_done:
    ret

place_enemies:
    mov al, [sector_num]
    mov bl, ENEMY_SPAWN_STEP
    mul bl
    add al, ENEMY_SPAWN_BASE
    xor cx, cx
    mov cl, al
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
    ret

roll_enemy_kind:
    mov al, [sector_num]
    cmp al, 1
    je roll_enemy_kind_sector1
    cmp al, 2
    je roll_enemy_kind_sector2
    call random_word
    cmp al, SECTOR3_WARDEN_THRESHOLD
    jb roll_enemy_kind_warden
    cmp al, SECTOR3_FLANKER_THRESHOLD
    jb roll_enemy_kind_flanker
    jmp roll_enemy_kind_rusher

roll_enemy_kind_sector1:
    call random_word
    cmp al, SECTOR1_FLANKER_THRESHOLD
    jb roll_enemy_kind_flanker
    jmp roll_enemy_kind_rusher

roll_enemy_kind_sector2:
    call random_word
    cmp al, SECTOR2_FLANKER_THRESHOLD
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

award_kill:
    cmp byte ptr [kill_count], 99
    jae award_done
    inc byte ptr [kill_count]
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
