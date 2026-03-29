get_enemy_sprite:
    mov al, [si + ENEMY_KIND]
    cmp al, ENEMY_FLANKER
    je get_enemy_sprite_flanker
    cmp al, ENEMY_WARDEN
    je get_enemy_sprite_warden
    call get_visual_cycle_phase
    cmp al, 0
    je get_enemy_sprite_a
    cmp al, 3
    je get_enemy_sprite_a
    mov si, offset sprite_enemy_b
    ret

get_enemy_sprite_flanker:
    call get_visual_cycle_phase
    cmp al, 0
    je get_enemy_sprite_flanker_a
    cmp al, 3
    je get_enemy_sprite_flanker_a
    mov si, offset sprite_enemy_flanker_b
    ret

get_enemy_sprite_flanker_a:
    mov si, offset sprite_enemy_flanker_a
    ret

get_enemy_sprite_warden:
    call get_visual_cycle_phase
    test al, 2
    jz get_enemy_sprite_warden_a
    mov si, offset sprite_enemy_warden_b
    ret

get_enemy_sprite_a:
    mov si, offset sprite_enemy_a
    ret

get_enemy_sprite_warden_a:
    mov si, offset sprite_enemy_warden_a
    ret

get_player_sprite:
    call get_visual_cycle_phase
    cmp al, 0
    je get_player_sprite_a
    cmp al, 3
    je get_player_sprite_a
    mov si, offset sprite_player_b
    ret
get_player_sprite_a:
    mov si, offset sprite_player_a
    ret

render_enemies:
    mov si, offset enemies
    mov cx, MAX_ENEMIES

render_enemy_loop:
    cmp byte ptr [si + ENEMY_ALIVE], 0
    je render_enemy_next
    xor bx, bx
    mov bl, [si + ENEMY_X]
    shl bx, TILE_SHIFT
    add bx, MAP_PIXEL_X
    xor dx, dx
    mov dl, [si + ENEMY_Y]
    shl dx, TILE_SHIFT
    add dx, MAP_PIXEL_Y
    ; Four-beat motion keeps entities lively, but the 1px offsets are small
    ; enough that tile occupancy and threat positions stay immediately readable.
    call get_visual_cycle_phase
    mov ah, al
    mov al, [si + ENEMY_KIND]
    cmp al, ENEMY_WARDEN
    je enemy_bob_ready
    cmp al, ENEMY_FLANKER
    je enemy_bob_flanker
    cmp ah, 1
    je enemy_bob_rusher_down
    cmp ah, 3
    je enemy_bob_rusher_up
    jmp enemy_bob_ready

enemy_bob_rusher_down:
    inc dx
    jmp enemy_bob_ready

enemy_bob_rusher_up:
    dec dx
    jmp enemy_bob_ready

enemy_bob_flanker:
    cmp ah, 1
    je enemy_bob_flanker_left
    cmp ah, 3
    je enemy_bob_flanker_right
    jmp enemy_bob_ready

enemy_bob_flanker_left:
    dec bx
    jmp enemy_bob_ready

enemy_bob_flanker_right:
    inc bx

enemy_bob_ready:
    cmp al, ENEMY_WARDEN
    jne enemy_draw_ready
    cmp byte ptr [sector_num], 3
    jne enemy_draw_ready
    push ax
    push bx
    push dx
    mov cx, 10
    mov bp, 10
    test byte ptr [anim_phase], 1
    jz elite_warden_aura_base
    mov al, PAL_WHITE
    jmp elite_warden_aura_ready

elite_warden_aura_base:
    mov al, PAL_GATE

elite_warden_aura_ready:
    call draw_rect_outline
    pop dx
    pop bx
    pop ax

enemy_draw_ready:
    push si
    call get_enemy_sprite
    call draw_sprite8
    pop si

render_enemy_next:
    add si, ENEMY_SIZE
    dec cx
    jz render_enemies_done
    jmp render_enemy_loop
render_enemies_done:
    ret

render_player:
    xor bx, bx
    mov bl, [player_x]
    shl bx, TILE_SHIFT
    add bx, MAP_PIXEL_X
    xor dx, dx
    mov dl, [player_y]
    shl dx, TILE_SHIFT
    add dx, MAP_PIXEL_Y
    call get_visual_cycle_phase
    cmp al, 1
    je player_bob_up
    cmp al, 3
    je player_bob_down
    jmp player_bob_ready

player_bob_up:
    dec dx
    jmp player_bob_ready

player_bob_down:
    inc dx
player_bob_ready:
    call get_player_sprite
    call draw_sprite8
    ret
