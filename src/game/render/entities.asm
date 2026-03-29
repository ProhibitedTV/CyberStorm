get_enemy_sprite:
    mov al, [si + ENEMY_KIND]
    cmp al, ENEMY_FLANKER
    je get_enemy_sprite_flanker
    cmp al, ENEMY_WARDEN
    je get_enemy_sprite_warden
    test byte ptr [anim_phase], 1
    jz get_enemy_sprite_a
    mov si, offset sprite_enemy_b
    ret

get_enemy_sprite_flanker:
    test byte ptr [anim_phase], 1
    jz get_enemy_sprite_flanker_a
    mov si, offset sprite_enemy_flanker_b
    ret

get_enemy_sprite_flanker_a:
    mov si, offset sprite_enemy_flanker_a
    ret

get_enemy_sprite_warden:
    test byte ptr [anim_phase], 1
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
    test byte ptr [anim_phase], 1
    jz get_player_sprite_a
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
    mov al, [si + ENEMY_KIND]
    cmp al, ENEMY_WARDEN
    je enemy_bob_ready
    test byte ptr [anim_phase], 1
    jz enemy_bob_ready
    cmp al, ENEMY_FLANKER
    je enemy_bob_flanker
    inc dx
    jmp enemy_bob_ready

enemy_bob_flanker:
    dec dx

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
    loop render_enemy_loop
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
    test byte ptr [anim_phase], 1
    jz player_bob_ready
    dec dx
player_bob_ready:
    call get_player_sprite
    call draw_sprite8
    ret
