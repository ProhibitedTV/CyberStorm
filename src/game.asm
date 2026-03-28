.model tiny
.code
org 0

STATE_TITLE    equ 0
STATE_PLAYING  equ 1
STATE_WIN      equ 2
STATE_LOSE     equ 3

MSG_SECTOR     equ 0
MSG_BLOCK      equ 1
MSG_SHARD      equ 2
MSG_GATE       equ 3
MSG_HIT        equ 4
MSG_KILL       equ 5
MSG_PULSE      equ 6
MSG_NOPULSE    equ 7

TILE_FLOOR        equ 0
TILE_WALL         equ 1
TILE_SHARD        equ 2
TILE_EXIT_LOCKED  equ 3
TILE_EXIT_OPEN    equ 4

MAP_W         equ 28
MAP_H         equ 15
MAP_SIZE      equ 420

MAP_SCREEN_X  equ 2
MAP_SCREEN_Y  equ 4

START_X       equ 2
START_Y       equ 13
EXIT_COL      equ 25
EXIT_ROW      equ 1

MAX_ENEMIES   equ 10
ENEMY_SIZE    equ 3
SHARD_COUNT   equ 4

SAFE_X_MAX    equ 6
SAFE_Y_MIN    equ 10

start:
    push cs
    pop ds

    mov ax, 0003h
    int 10h
    mov ah, 01h
    mov ch, 20h
    mov cl, 00h
    int 10h

    mov ax, 0B800h
    mov es, ax

    xor ah, ah
    int 1Ah
    mov [rng_state], dx
    cmp dx, 0
    jne seed_ready
    mov word ptr [rng_state], 0ACE1h

seed_ready:
    mov byte ptr [game_state], STATE_TITLE
    mov byte ptr [message_id], MSG_SECTOR

main_loop:
    call render_screen
    xor ax, ax
    int 16h

    cmp byte ptr [game_state], STATE_PLAYING
    je handle_play_input

    cmp al, 0Dh
    jne main_loop
    call start_new_run
    jmp main_loop

handle_play_input:
    call process_play_input
    jmp main_loop

start_new_run:
    mov byte ptr [game_state], STATE_PLAYING
    mov byte ptr [sector_num], 1
    mov byte ptr [shield_count], 5
    mov byte ptr [pulse_count], 3
    mov byte ptr [data_count], 0
    mov byte ptr [kill_count], 0
    call load_sector
    mov byte ptr [message_id], MSG_SECTOR
    ret

process_play_input:
    mov byte ptr [action_taken], 0

    cmp al, 0Dh
    jne check_pulse_lower
    call start_new_run
    ret

check_pulse_lower:
    cmp al, 'c'
    je do_pulse
    cmp al, 'C'
    je do_pulse

    cmp al, 'a'
    je move_left
    cmp al, 'A'
    je move_left
    cmp ah, 4Bh
    je move_left

    cmp al, 'd'
    je move_right
    cmp al, 'D'
    je move_right
    cmp ah, 4Dh
    je move_right

    cmp al, 'w'
    je move_up
    cmp al, 'W'
    je move_up
    cmp ah, 48h
    je move_up

    cmp al, 's'
    je move_down
    cmp al, 'S'
    je move_down
    cmp ah, 50h
    je move_down

    ret

move_left:
    mov bl, [player_x]
    cmp bl, 1
    jbe blocked_move
    dec bl
    mov bh, [player_y]
    call attempt_move_to
    jmp maybe_enemy_turn

move_right:
    mov bl, [player_x]
    cmp bl, 26
    jae blocked_move
    inc bl
    mov bh, [player_y]
    call attempt_move_to
    jmp maybe_enemy_turn

move_up:
    mov bl, [player_x]
    mov bh, [player_y]
    cmp bh, 1
    jbe blocked_move
    dec bh
    call attempt_move_to
    jmp maybe_enemy_turn

move_down:
    mov bl, [player_x]
    mov bh, [player_y]
    cmp bh, 13
    jae blocked_move
    inc bh
    call attempt_move_to
    jmp maybe_enemy_turn

blocked_move:
    mov byte ptr [message_id], MSG_BLOCK
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

move_floor:
    mov [player_x], bl
    mov [player_y], bh
    mov byte ptr [action_taken], 1
    ret

move_blocked:
    mov byte ptr [message_id], MSG_BLOCK
    ret

stepped_into_enemy:
    pop bx
    mov byte ptr [si], 0
    call award_kill
    mov [player_x], bl
    mov [player_y], bh
    mov byte ptr [message_id], MSG_KILL
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
    mov byte ptr [message_id], MSG_GATE
    ret

shard_message:
    mov byte ptr [message_id], MSG_SHARD
    ret

move_use_exit:
    inc byte ptr [sector_num]
    mov al, [sector_num]
    cmp al, 4
    jb advance_sector
    mov byte ptr [game_state], STATE_WIN
    ret

advance_sector:
    call load_sector
    mov byte ptr [message_id], MSG_SECTOR
    ret

use_pulse:
    cmp byte ptr [pulse_count], 0
    jne pulse_live
    mov byte ptr [message_id], MSG_NOPULSE
    ret

pulse_live:
    dec byte ptr [pulse_count]
    mov byte ptr [message_id], MSG_PULSE
    mov byte ptr [action_taken], 1
    mov si, offset enemies
    mov cx, MAX_ENEMIES

pulse_loop:
    cmp byte ptr [si], 0
    je pulse_next

    mov al, [si + 1]
    mov bl, [player_x]
    cmp al, bl
    je pulse_x_ok
    jb pulse_x_left
    sub al, bl
    cmp al, 1
    ja pulse_next
    jmp pulse_x_ok

pulse_x_left:
    mov dl, bl
    sub dl, al
    cmp dl, 1
    ja pulse_next

pulse_x_ok:
    mov al, [si + 2]
    mov bl, [player_y]
    cmp al, bl
    je pulse_hit
    jb pulse_y_up
    sub al, bl
    cmp al, 1
    ja pulse_next
    jmp pulse_hit

pulse_y_up:
    mov dl, bl
    sub dl, al
    cmp dl, 1
    ja pulse_next

pulse_hit:
    mov byte ptr [si], 0
    call award_kill

pulse_next:
    add si, ENEMY_SIZE
    loop pulse_loop
    ret

enemy_turn:
    mov si, offset enemies
    mov cx, MAX_ENEMIES

enemy_turn_loop:
    cmp byte ptr [si], 0
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
    mov al, [si + 1]
    mov ah, [si + 2]

    mov bl, [player_x]
    cmp al, bl
    je enemy_try_vertical
    jb enemy_try_right

enemy_try_left:
    mov dl, al
    dec dl
    mov dh, ah
    call try_enemy_step
    jc enemy_done
    jmp enemy_try_vertical

enemy_try_right:
    mov dl, al
    inc dl
    mov dh, ah
    call try_enemy_step
    jc enemy_done

enemy_try_vertical:
    mov bl, [player_y]
    cmp ah, bl
    je enemy_done
    jb enemy_try_down

enemy_try_up:
    mov dl, [si + 1]
    mov dh, [si + 2]
    dec dh
    call try_enemy_step
    jmp enemy_done

enemy_try_down:
    mov dl, [si + 1]
    mov dh, [si + 2]
    inc dh
    call try_enemy_step

enemy_done:
    ret

try_enemy_step:
    mov bl, [player_x]
    cmp dl, bl
    jne step_not_player
    mov bl, [player_y]
    cmp dh, bl
    jne step_not_player
    dec byte ptr [shield_count]
    mov byte ptr [si], 0
    mov byte ptr [message_id], MSG_HIT
    cmp byte ptr [shield_count], 0
    jne step_success
    mov byte ptr [game_state], STATE_LOSE
step_success:
    stc
    ret

step_not_player:
    mov bl, dl
    mov bh, dh
    call get_tile
    cmp al, TILE_WALL
    je step_fail
    cmp al, TILE_EXIT_LOCKED
    je step_fail
    cmp al, TILE_EXIT_OPEN
    je step_fail

    mov bl, dl
    mov bh, dh
    mov di, si
    call find_enemy_at
    jc step_fail

    mov [si + 1], dl
    mov [si + 2], dh
    stc
    ret

step_fail:
    clc
    ret

load_sector:
    cmp byte ptr [sector_num], 1
    je keep_pulse_count
    cmp byte ptr [pulse_count], 5
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
    mov al, [sector_num]
    dec al
    xor ah, ah
    shl ax, 1
    mov bx, ax
    mov si, word ptr [template_table + bx]
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

place_enemies:
    mov al, [sector_num]
    add al, al
    add al, 3
    mov cl, al
    mov si, offset enemies

place_enemy_find_slot:
    cmp byte ptr [si], 0
    je place_enemy_here
    add si, ENEMY_SIZE
    jmp place_enemy_find_slot

place_enemy_here:
    call random_enemy_position
    mov byte ptr [si], 1
    mov [si + 1], bl
    mov [si + 2], bh
    add si, ENEMY_SIZE
    dec cl
    jnz place_enemy_find_slot
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
    ret

random_x:
    call random_word
    mov bl, 26
    div bl
    mov al, ah
    inc al
    ret

random_y:
    call random_word
    mov bl, 13
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
    cmp byte ptr [si], 0
    je find_enemy_next
    cmp si, di
    je find_enemy_next
    mov al, [si + 1]
    cmp al, bl
    jne find_enemy_next
    mov al, [si + 2]
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

render_screen:
    cmp byte ptr [game_state], STATE_TITLE
    je render_title_screen
    cmp byte ptr [game_state], STATE_WIN
    je render_win_screen
    cmp byte ptr [game_state], STATE_LOSE
    je render_lose_screen
    jmp render_game_screen

render_game_screen:
    call clear_screen
    call render_game_ui
    call render_map
    call render_enemies
    call render_player
    ret

render_title_screen:
    call clear_screen

    mov ah, 0Bh
    mov dl, 30
    mov dh, 5
    mov si, offset title_line_1
    call draw_string_xy

    mov ah, 0Fh
    mov dl, 12
    mov dh, 8
    mov si, offset title_line_2
    call draw_string_xy

    mov ah, 07h
    mov dl, 12
    mov dh, 10
    mov si, offset title_line_3
    call draw_string_xy

    mov ah, 07h
    mov dl, 12
    mov dh, 12
    mov si, offset title_line_4
    call draw_string_xy

    mov ah, 0Eh
    mov dl, 19
    mov dh, 15
    mov si, offset title_line_5
    call draw_string_xy

    mov ah, 07h
    mov dl, 18
    mov dh, 18
    mov si, offset title_prompt
    call draw_string_xy
    ret

render_win_screen:
    call clear_screen

    mov ah, 0Ah
    mov dl, 30
    mov dh, 8
    mov si, offset win_line_1
    call draw_string_xy

    mov ah, 0Fh
    mov dl, 12
    mov dh, 11
    mov si, offset win_line_2
    call draw_string_xy

    mov ah, 0Eh
    mov dl, 18
    mov dh, 15
    mov si, offset replay_prompt
    call draw_string_xy
    ret

render_lose_screen:
    call clear_screen

    mov ah, 0Ch
    mov dl, 30
    mov dh, 8
    mov si, offset lose_line_1
    call draw_string_xy

    mov ah, 0Fh
    mov dl, 12
    mov dh, 11
    mov si, offset lose_line_2
    call draw_string_xy

    mov ah, 0Eh
    mov dl, 18
    mov dh, 15
    mov si, offset replay_prompt
    call draw_string_xy
    ret

render_game_ui:
    mov ah, 0Bh
    mov dl, 2
    mov dh, 0
    mov si, offset hud_title
    call draw_string_xy

    mov ah, 0Fh
    mov dl, 18
    mov dh, 0
    mov si, offset sector_text
    call draw_string_xy
    mov al, [sector_num]
    mov ah, 0Fh
    mov dl, 25
    mov dh, 0
    call draw_digit_xy
    mov ah, 0Fh
    mov dl, 26
    mov dh, 0
    mov si, offset of_three_text
    call draw_string_xy

    mov ah, 0Fh
    mov dl, 31
    mov dh, 0
    mov si, offset data_text
    call draw_string_xy
    mov al, [data_count]
    mov ah, 0Fh
    mov dl, 36
    mov dh, 0
    call draw_digit_xy
    mov ah, 0Fh
    mov dl, 37
    mov dh, 0
    mov si, offset of_four_text
    call draw_string_xy

    mov ah, 0Fh
    mov dl, 41
    mov dh, 0
    mov si, offset kills_text
    call draw_string_xy
    mov al, [kill_count]
    mov ah, 0Fh
    mov dl, 47
    mov dh, 0
    call draw_two_digits_xy

    mov ah, 0Fh
    mov dl, 2
    mov dh, 1
    mov si, offset shield_text
    call draw_string_xy
    mov al, '*'
    mov ah, 0Ah
    mov dl, 10
    mov dh, 1
    mov cl, [shield_count]
    call draw_repeat_xy

    mov ah, 0Fh
    mov dl, 19
    mov dh, 1
    mov si, offset pulse_text
    call draw_string_xy
    mov al, '#'
    mov ah, 0Eh
    mov dl, 26
    mov dh, 1
    mov cl, [pulse_count]
    call draw_repeat_xy

    xor ax, ax
    mov al, [message_id]
    shl ax, 1
    mov bx, ax
    mov si, word ptr [message_table + bx]
    mov ah, 0Eh
    mov dl, 2
    mov dh, 2
    call draw_string_xy

    mov al, '='
    mov ah, 09h
    mov dl, 1
    mov dh, 3
    mov cl, 30
    call draw_repeat_xy
    mov al, '='
    mov ah, 09h
    mov dl, 1
    mov dh, 19
    mov cl, 30
    call draw_repeat_xy

    mov bx, 4

render_border_sides:
    mov al, '|'
    mov ah, 09h
    mov dl, 1
    mov dh, bl
    call draw_char_xy
    mov al, '|'
    mov ah, 09h
    mov dl, 30
    mov dh, bl
    call draw_char_xy
    inc bl
    cmp bl, 19
    jb render_border_sides

    mov ah, 0Ah
    mov dl, 36
    mov dh, 4
    mov si, offset legend_runner
    call draw_string_xy
    mov ah, 0Ch
    mov dl, 36
    mov dh, 5
    mov si, offset legend_hunter
    call draw_string_xy
    mov ah, 0Bh
    mov dl, 36
    mov dh, 6
    mov si, offset legend_shard
    call draw_string_xy
    mov ah, 0Ch
    mov dl, 36
    mov dh, 7
    mov si, offset legend_locked
    call draw_string_xy
    mov ah, 0Ah
    mov dl, 36
    mov dh, 8
    mov si, offset legend_exit
    call draw_string_xy
    mov ah, 07h
    mov dl, 36
    mov dh, 10
    mov si, offset control_line_1
    call draw_string_xy
    mov ah, 07h
    mov dl, 36
    mov dh, 11
    mov si, offset control_line_2
    call draw_string_xy
    mov ah, 07h
    mov dl, 36
    mov dh, 12
    mov si, offset control_line_3
    call draw_string_xy
    ret

render_map:
    mov si, offset map_tiles
    xor bh, bh
    mov cx, MAP_H

render_map_row:
    push cx
    xor bl, bl
    mov cx, MAP_W

render_map_col:
    mov al, [si]
    cmp al, TILE_WALL
    je render_tile_wall
    cmp al, TILE_SHARD
    je render_tile_shard
    cmp al, TILE_EXIT_LOCKED
    je render_tile_locked
    cmp al, TILE_EXIT_OPEN
    je render_tile_open
    mov al, '.'
    mov ah, 08h
    jmp render_tile_draw

render_tile_wall:
    mov al, '#'
    mov ah, 08h
    jmp render_tile_draw

render_tile_shard:
    mov al, '*'
    mov ah, 0Bh
    jmp render_tile_draw

render_tile_locked:
    mov al, 'X'
    mov ah, 0Ch
    jmp render_tile_draw

render_tile_open:
    mov al, '>'
    mov ah, 0Ah

render_tile_draw:
    push bx
    push cx
    push si
    mov dl, bl
    add dl, MAP_SCREEN_X
    mov dh, bh
    add dh, MAP_SCREEN_Y
    call draw_char_xy
    pop si
    pop cx
    pop bx
    inc si
    inc bl
    loop render_map_col
    inc bh
    pop cx
    loop render_map_row
    ret

render_enemies:
    mov si, offset enemies
    mov cx, MAX_ENEMIES

render_enemy_loop:
    cmp byte ptr [si], 0
    je render_enemy_next
    mov al, 'H'
    mov ah, 0Ch
    mov dl, [si + 1]
    add dl, MAP_SCREEN_X
    mov dh, [si + 2]
    add dh, MAP_SCREEN_Y
    call draw_char_xy

render_enemy_next:
    add si, ENEMY_SIZE
    loop render_enemy_loop
    ret

render_player:
    mov al, '@'
    mov ah, 0Ah
    mov dl, [player_x]
    add dl, MAP_SCREEN_X
    mov dh, [player_y]
    add dh, MAP_SCREEN_Y
    call draw_char_xy
    ret

clear_screen:
    push ax
    push cx
    push di
    xor di, di
    mov ax, 0720h
    mov cx, 2000
    rep stosw
    pop di
    pop cx
    pop ax
    ret

draw_digit_xy:
    add al, '0'
    call draw_char_xy
    ret

draw_two_digits_xy:
    push bx
    push dx
    mov bl, ah
    aam
    add ax, 3030h
    mov bh, al
    mov al, ah
    mov ah, bl
    call draw_char_xy
    inc dl
    mov al, bh
    mov ah, bl
    call draw_char_xy
    pop dx
    pop bx
    ret

draw_repeat_xy:
    push ax
    push cx
    push dx
    push di
    call compute_screen_offset

draw_repeat_loop:
    cmp cl, 0
    je draw_repeat_done
    stosw
    dec cl
    jmp draw_repeat_loop

draw_repeat_done:
    pop di
    pop dx
    pop cx
    pop ax
    ret

draw_string_xy:
    push ax
    push bx
    push dx
    push di
    push si
    mov bl, ah
    call compute_screen_offset

draw_string_loop:
    lodsb
    or al, al
    jz draw_string_done
    mov ah, bl
    stosw
    jmp draw_string_loop

draw_string_done:
    pop si
    pop di
    pop dx
    pop bx
    pop ax
    ret

draw_char_xy:
    push dx
    push di
    call compute_screen_offset
    stosw
    pop di
    pop dx
    ret

compute_screen_offset:
    push ax
    push bx
    xor bx, bx
    mov bl, dh
    shl bx, 1
    mov di, [screen_row_offsets + bx]
    xor bx, bx
    mov bl, dl
    shl bx, 1
    add di, bx
    pop bx
    pop ax
    ret

game_state   db STATE_TITLE
sector_num   db 1
shield_count db 5
pulse_count  db 3
data_count   db 0
kill_count   db 0
message_id   db MSG_SECTOR
action_taken db 0
player_x     db START_X
player_y     db START_Y
exit_x       db EXIT_COL
exit_y       db EXIT_ROW
rng_state    dw 0ACE1h

enemies db MAX_ENEMIES * ENEMY_SIZE dup (0)
map_tiles db MAP_SIZE dup (0)

map_row_offsets dw 0, 28, 56, 84, 112, 140, 168, 196, 224, 252, 280, 308, 336, 364, 392

screen_row_offsets dw 0, 160, 320, 480, 640, 800, 960, 1120, 1280, 1440
                  dw 1600, 1760, 1920, 2080, 2240, 2400, 2560, 2720, 2880, 3040
                  dw 3200, 3360, 3520, 3680, 3840

message_table dw offset text_msg_sector, offset text_msg_block, offset text_msg_shard, offset text_msg_gate
              dw offset text_msg_hit, offset text_msg_kill, offset text_msg_pulse, offset text_msg_nopulse

template_table dw offset sector1_map, offset sector2_map, offset sector3_map

hud_title      db 'CYBERSTORM', 0
sector_text    db 'SECTOR', 0
of_three_text  db '/3', 0
data_text      db 'DATA', 0
of_four_text   db '/4', 0
kills_text     db 'KILLS', 0
shield_text    db 'SHIELD', 0
pulse_text     db 'PULSE', 0

legend_runner  db '@ RUNNER', 0
legend_hunter  db 'H HUNTER', 0
legend_shard   db '* SHARD', 0
legend_locked  db 'X LOCKED GATE', 0
legend_exit    db '> OPEN EXIT', 0
control_line_1 db 'WASD / ARROWS  MOVE', 0
control_line_2 db 'C              EMP', 0
control_line_3 db 'ENTER          RESTART', 0

text_msg_sector  db 'Harvest four shards, unlock the gate, and push forward.', 0
text_msg_block   db 'Black ice blocks that route.', 0
text_msg_shard   db 'Shard secured.', 0
text_msg_gate    db 'Gate unlocked. Breach the exit.', 0
text_msg_hit     db 'A hunter ripped through your shields.', 0
text_msg_kill    db 'Hunter neutralized.', 0
text_msg_pulse   db 'EMP pulse detonated.', 0
text_msg_nopulse db 'No pulse charges left.', 0

title_line_1 db 'CYBERSTORM', 0
title_line_2 db 'A no-OS infiltration run that boots straight from the machine.', 0
title_line_3 db 'Breach three sectors and harvest four shards in each.', 0
title_line_4 db 'Hunters move after every action. EMP only buys space.', 0
title_line_5 db 'No shell. No desktop. Just the breach.', 0
title_prompt db 'PRESS ENTER TO JACK IN', 0

win_line_1   db 'VAULT BREACHED', 0
win_line_2   db 'You crossed all three sectors and escaped with the core.', 0
lose_line_1  db 'LINK SEVERED', 0
lose_line_2  db 'The hunters collapsed the run before the vault broke open.', 0
replay_prompt db 'PRESS ENTER TO RUN AGAIN', 0

sector1_map db '############################'
            db '#..........#...............#'
            db '#..####....#..#####..####..#'
            db '#......#...#......#.....#..#'
            db '#.####.#...####...#.###.#..#'
            db '#.#....#..........#.#...#..#'
            db '#.#.########..#####.#.###..#'
            db '#.#..................#.....#'
            db '#.#.######.######.####.##..#'
            db '#...#....#......#......##..#'
            db '###.#.##.####.#.######.##..#'
            db '#...#.##......#.#......##..#'
            db '#.###.#########.#.########.#'
            db '#..........................#'
            db '############################'

sector2_map db '############################'
            db '#......#....#.........#....#'
            db '#.####.#.##.#.######..#....#'
            db '#.#....#....#......#..#....#'
            db '#.#.####.########..#.##.##.#'
            db '#.#....#...........#....##.#'
            db '#.####.#.###########.####..#'
            db '#......#.....#.............#'
            db '#.##########.#.###########.#'
            db '#.#..........#.#...........#'
            db '#.#.##########.#.#########.#'
            db '#.#.............#.......#..#'
            db '#.###############.#####.#..#'
            db '#..........................#'
            db '############################'

sector3_map db '############################'
            db '#....#...........#.........#'
            db '#.##.#.#########.#.#######.#'
            db '#....#.....#.....#.....#...#'
            db '####.#####.#.#########.#.###'
            db '#....#.....#.....#.....#...#'
            db '#.####.#########.#.#######.#'
            db '#.#....#.........#.........#'
            db '#.#.####.###############.###'
            db '#.#......#.......#.......#.#'
            db '#.######.#.#####.#.#####.#.#'
            db '#......#.#.....#.#.....#...#'
            db '#.####.#.#####.#.#####.###.#'
            db '#..........................#'
            db '############################'

end start
