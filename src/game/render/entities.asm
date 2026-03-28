get_enemy_sprite:
    test byte ptr [anim_phase], 1
    jz get_enemy_sprite_a
    mov si, offset sprite_enemy_b
    ret
get_enemy_sprite_a:
    mov si, offset sprite_enemy_a
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
    cmp byte ptr [si], 0
    je render_enemy_next
    xor bx, bx
    mov bl, [si + 1]
    shl bx, 3
    add bx, MAP_PIXEL_X
    xor dx, dx
    mov dl, [si + 2]
    shl dx, 3
    add dx, MAP_PIXEL_Y
    test byte ptr [anim_phase], 1
    jz enemy_bob_ready
    inc dx
enemy_bob_ready:
    push si
    call get_enemy_sprite
    mov al, PAL_ENEMY
    call draw_sprite8
    pop si

render_enemy_next:
    add si, ENEMY_SIZE
    loop render_enemy_loop
    ret

render_player:
    xor bx, bx
    mov bl, [player_x]
    shl bx, 3
    add bx, MAP_PIXEL_X
    xor dx, dx
    mov dl, [player_y]
    shl dx, 3
    add dx, MAP_PIXEL_Y
    test byte ptr [anim_phase], 1
    jz player_bob_ready
    dec dx
player_bob_ready:
    call get_player_sprite
    mov al, PAL_PLAYER
    call draw_sprite8
    ret
