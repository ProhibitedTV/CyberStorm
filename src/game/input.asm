install_keyboard_handler:
    ; Legacy raw IRQ1 hook retained for experiments. The default runtime now
    ; leaves the BIOS handler installed and polls INT 16h for compatibility.
    push ax
    push es
    cli
    xor ax, ax
    mov es, ax
    mov word ptr es:[9 * 4], offset keyboard_irq_handler
    mov word ptr es:[9 * 4 + 2], cs
    sti
    pop es
    pop ax
    ret

reset_keyboard_state:
    push ax
    push cx
    push di
    push es
    mov byte ptr [key_extended], 0
    mov byte ptr [input_event_count], 0
    mov byte ptr [input_last_code], 0
    mov byte ptr [input_last_ascii], 0
    mov byte ptr [input_check_count], 0
    mov byte ptr [input_poll_count], 0
    mov byte ptr [input_last_polled], 0
    mov byte ptr [frontend_action], FRONTEND_ACTION_NONE
    mov byte ptr [frontend_last_action], FRONTEND_ACTION_NONE
    mov byte ptr [frontend_event_count], 0
    call clear_pressed_latches
    push ds
    pop es
    mov di, offset key_down
    ; key_down and key_pressed are cleared together and must remain adjacent.
    mov cx, KEY_STATE_REGION_BYTES
    xor al, al
    rep stosb
    call drain_bios_keyboard_buffer
    pop es
    pop di
    pop cx
    pop ax
    ret

clear_pressed_latches:
    push ax
    mov byte ptr [any_key_pending], 0
    mov byte ptr [pressed_enter], 0
    mov byte ptr [pressed_w], 0
    mov byte ptr [pressed_a], 0
    mov byte ptr [pressed_s], 0
    mov byte ptr [pressed_d], 0
    mov byte ptr [pressed_r], 0
    mov byte ptr [pressed_c], 0
    mov byte ptr [pressed_space], 0
    mov byte ptr [pressed_shift], 0
    mov byte ptr [pressed_up], 0
    mov byte ptr [pressed_left], 0
    mov byte ptr [pressed_right], 0
    mov byte ptr [pressed_down], 0
    mov byte ptr [frontend_action], FRONTEND_ACTION_NONE
    pop ax
    ret

drain_bios_keyboard_buffer:
    push ax

drain_bios_keyboard_loop:
    mov ah, 01h
    int 16h
    jz drain_bios_keyboard_done
    xor ah, ah
    int 16h
    jmp drain_bios_keyboard_loop

drain_bios_keyboard_done:
    pop ax
    ret

poll_bios_keyboard:
    push ax
    cmp byte ptr [input_check_count], 99
    jae poll_bios_keyboard_loop
    inc byte ptr [input_check_count]

poll_bios_keyboard_loop:
    mov ah, 01h
    int 16h
    jz poll_bios_keyboard_done
    xor ah, ah
    int 16h
    mov [input_last_polled], ah
    mov [input_last_code], ah
    mov [input_last_ascii], al
    mov byte ptr [any_key_pending], 1
    cmp byte ptr [input_event_count], 99
    jae bios_event_count_ready
    inc byte ptr [input_event_count]

bios_event_count_ready:
    cmp byte ptr [input_poll_count], 99
    jae bios_poll_count_ready
    inc byte ptr [input_poll_count]

bios_poll_count_ready:
    call record_frontend_semantic_action
    call latch_bios_key
    jmp poll_bios_keyboard_loop

poll_bios_keyboard_done:
    pop ax
    ret

record_frontend_semantic_action:
    push bx
    call classify_semantic_action_from_bios_key
    cmp al, FRONTEND_ACTION_NONE
    je semantic_action_done
    mov bl, [frontend_action]
    cmp bl, FRONTEND_ACTION_NONE
    je semantic_action_store
    cmp al, FRONTEND_ACTION_ACTIVITY
    je semantic_action_last
    cmp bl, FRONTEND_ACTION_ACTIVITY
    jne semantic_action_last

semantic_action_store:
    mov [frontend_action], al

semantic_action_last:
    mov [frontend_last_action], al
    cmp byte ptr [frontend_event_count], 99
    jae semantic_action_done
    inc byte ptr [frontend_event_count]

semantic_action_done:
    pop bx
    ret

classify_semantic_action_from_bios_key:
    cmp byte ptr [game_state], STATE_SPLASH
    je classify_semantic_frontend
    cmp byte ptr [game_state], STATE_TITLE
    je classify_semantic_frontend
    cmp byte ptr [game_state], STATE_WIN
    je classify_semantic_continue
    cmp byte ptr [game_state], STATE_LOSE
    je classify_semantic_continue
    cmp byte ptr [game_state], STATE_VERIFY_PASS
    je classify_semantic_continue
    cmp byte ptr [game_state], STATE_VERIFY_FAIL
    je classify_semantic_continue
    cmp byte ptr [demo_active], 0
    jne classify_semantic_demo_takeover
    jmp classify_semantic_gameplay

classify_semantic_frontend:
    cmp byte ptr [game_state], STATE_SPLASH
    jne classify_semantic_title
    call is_bios_continue_key
    jc classify_semantic_confirm_ready
    mov al, FRONTEND_ACTION_ACTIVITY
    ret

classify_semantic_title:
    call is_bios_continue_key
    jc classify_semantic_confirm_ready
    call is_bios_nav_up_key
    jc classify_semantic_nav_up_ready
    call is_bios_nav_down_key
    jc classify_semantic_nav_down_ready
    call is_bios_nav_left_key
    jc classify_semantic_nav_left_ready
    call is_bios_nav_right_key
    jc classify_semantic_nav_right_ready
    mov al, FRONTEND_ACTION_ACTIVITY
    ret

classify_semantic_confirm_ready:
    mov al, FRONTEND_ACTION_CONFIRM
    ret

classify_semantic_continue:
    call is_bios_continue_key
    jc classify_semantic_continue_ready
    mov al, FRONTEND_ACTION_ACTIVITY
    ret

classify_semantic_continue_ready:
    mov al, FRONTEND_ACTION_CONTINUE
    ret

classify_semantic_demo_takeover:
    call is_bios_continue_key
    jc classify_semantic_continue_ready
    call is_bios_move_key
    jc classify_semantic_move_ready
    call is_bios_pulse_key
    jc classify_semantic_pulse_ready
    call is_bios_reset_key
    jc classify_semantic_reset_ready
    mov al, FRONTEND_ACTION_ACTIVITY
    ret

classify_semantic_gameplay:
    call is_bios_move_key
    jc classify_semantic_move_ready
    call is_bios_pulse_key
    jc classify_semantic_pulse_ready
    call is_bios_reset_key
    jc classify_semantic_reset_ready
    mov al, FRONTEND_ACTION_ACTIVITY
    ret

classify_semantic_move_ready:
    mov al, FRONTEND_ACTION_MOVE
    ret

classify_semantic_pulse_ready:
    mov al, FRONTEND_ACTION_PULSE
    ret

classify_semantic_reset_ready:
    mov al, FRONTEND_ACTION_RESET
    ret

classify_semantic_nav_up_ready:
    mov al, FRONTEND_ACTION_NAV_UP
    ret

classify_semantic_nav_down_ready:
    mov al, FRONTEND_ACTION_NAV_DOWN
    ret

classify_semantic_nav_left_ready:
    mov al, FRONTEND_ACTION_NAV_LEFT
    ret

classify_semantic_nav_right_ready:
    mov al, FRONTEND_ACTION_NAV_RIGHT
    ret

is_bios_continue_key:
    cmp ah, SCAN_ENTER
    je bios_continue_true
    cmp al, KEY_ENTER
    je bios_continue_true
    cmp ah, SCAN_SPACE
    je bios_continue_true
    cmp al, ' '
    je bios_continue_true
    clc
    ret

bios_continue_true:
    stc
    ret

is_bios_nav_up_key:
    cmp ah, SCAN_W
    je bios_nav_true
    cmp al, 'w'
    je bios_nav_true
    cmp al, 'W'
    je bios_nav_true
    cmp ah, BIOS_SCAN_UP
    je bios_nav_true
    clc
    ret

is_bios_nav_down_key:
    cmp ah, SCAN_S
    je bios_nav_true
    cmp al, 's'
    je bios_nav_true
    cmp al, 'S'
    je bios_nav_true
    cmp ah, BIOS_SCAN_DOWN
    je bios_nav_true
    clc
    ret

is_bios_nav_left_key:
    cmp ah, SCAN_A
    je bios_nav_true
    cmp al, 'a'
    je bios_nav_true
    cmp al, 'A'
    je bios_nav_true
    cmp ah, BIOS_SCAN_LEFT
    je bios_nav_true
    clc
    ret

is_bios_nav_right_key:
    cmp ah, SCAN_D
    je bios_nav_true
    cmp al, 'd'
    je bios_nav_true
    cmp al, 'D'
    je bios_nav_true
    cmp ah, BIOS_SCAN_RIGHT
    je bios_nav_true
    clc
    ret

bios_nav_true:
    stc
    ret

is_bios_move_key:
    cmp ah, SCAN_W
    je bios_move_true
    cmp al, 'w'
    je bios_move_true
    cmp al, 'W'
    je bios_move_true
    cmp ah, SCAN_A
    je bios_move_true
    cmp al, 'a'
    je bios_move_true
    cmp al, 'A'
    je bios_move_true
    cmp ah, SCAN_S
    je bios_move_true
    cmp al, 's'
    je bios_move_true
    cmp al, 'S'
    je bios_move_true
    cmp ah, SCAN_D
    je bios_move_true
    cmp al, 'd'
    je bios_move_true
    cmp al, 'D'
    je bios_move_true
    cmp ah, BIOS_SCAN_UP
    je bios_move_true
    cmp ah, BIOS_SCAN_LEFT
    je bios_move_true
    cmp ah, BIOS_SCAN_RIGHT
    je bios_move_true
    cmp ah, BIOS_SCAN_DOWN
    je bios_move_true
    clc
    ret

bios_move_true:
    stc
    ret

is_bios_pulse_key:
    cmp ah, SCAN_C
    je bios_pulse_true
    cmp al, 'c'
    je bios_pulse_true
    cmp al, 'C'
    je bios_pulse_true
    clc
    ret

bios_pulse_true:
    stc
    ret

is_bios_reset_key:
    cmp ah, SCAN_R
    je bios_reset_true
    cmp al, 'r'
    je bios_reset_true
    cmp al, 'R'
    je bios_reset_true
    clc
    ret

bios_reset_true:
    stc
    ret

latch_bios_key:
    cmp ah, SCAN_ENTER
    je bios_key_enter
    cmp al, 0Dh
    je bios_key_enter
    cmp ah, SCAN_W
    je bios_key_w
    cmp al, 'w'
    je bios_key_w
    cmp al, 'W'
    je bios_key_w
    cmp ah, SCAN_A
    je bios_key_a
    cmp al, 'a'
    je bios_key_a
    cmp al, 'A'
    je bios_key_a
    cmp ah, SCAN_S
    je bios_key_s
    cmp al, 's'
    je bios_key_s
    cmp al, 'S'
    je bios_key_s
    cmp ah, SCAN_D
    je bios_key_d
    cmp al, 'd'
    je bios_key_d
    cmp al, 'D'
    je bios_key_d
    cmp ah, SCAN_R
    je bios_key_r
    cmp al, 'r'
    je bios_key_r
    cmp al, 'R'
    je bios_key_r
    cmp ah, SCAN_C
    je bios_key_c
    cmp al, 'c'
    je bios_key_c
    cmp al, 'C'
    je bios_key_c
    cmp ah, SCAN_SPACE
    je bios_key_space
    cmp al, ' '
    je bios_key_space
    cmp ah, SCAN_LSHIFT
    je bios_key_shift
    cmp ah, BIOS_SCAN_UP
    je bios_key_up
    cmp ah, BIOS_SCAN_LEFT
    je bios_key_left
    cmp ah, BIOS_SCAN_RIGHT
    je bios_key_right
    cmp ah, BIOS_SCAN_DOWN
    je bios_key_down
    ret

bios_key_enter:
    mov byte ptr [pressed_enter], 1
    ret

bios_key_w:
    mov byte ptr [pressed_w], 1
    ret

bios_key_a:
    mov byte ptr [pressed_a], 1
    ret

bios_key_s:
    mov byte ptr [pressed_s], 1
    ret

bios_key_d:
    mov byte ptr [pressed_d], 1
    ret

bios_key_r:
    mov byte ptr [pressed_r], 1
    ret

bios_key_c:
    mov byte ptr [pressed_c], 1
    ret

bios_key_space:
    mov byte ptr [pressed_space], 1
    ret

bios_key_shift:
    mov byte ptr [pressed_shift], 1
    ret

bios_key_up:
    mov byte ptr [pressed_up], 1
    ret

bios_key_left:
    mov byte ptr [pressed_left], 1
    ret

bios_key_right:
    mov byte ptr [pressed_right], 1
    ret

bios_key_down:
    mov byte ptr [pressed_down], 1
    ret

poll_key_event:
    ; The main loop consumes pressed_* latches directly. This translator remains
    ; available for diagnostics and any future BIOS-style callers.
    cmp byte ptr [input_check_count], 99
    jae poll_check_ready
    inc byte ptr [input_check_count]
poll_check_ready:
    cmp byte ptr [pressed_enter], 0
    jne poll_key_enter
    cmp byte ptr [pressed_w], 0
    jne poll_key_w
    cmp byte ptr [pressed_a], 0
    jne poll_key_a
    cmp byte ptr [pressed_s], 0
    jne poll_key_s
    cmp byte ptr [pressed_d], 0
    jne poll_key_d
    cmp byte ptr [pressed_r], 0
    jne poll_key_r
    cmp byte ptr [pressed_c], 0
    jne poll_key_c
    cmp byte ptr [pressed_space], 0
    jne poll_key_space
    cmp byte ptr [pressed_shift], 0
    jne poll_key_shift
    cmp byte ptr [pressed_up], 0
    jne poll_key_up
    cmp byte ptr [pressed_left], 0
    jne poll_key_left
    cmp byte ptr [pressed_right], 0
    jne poll_key_right
    cmp byte ptr [pressed_down], 0
    jne poll_key_down
    cmp byte ptr [any_key_pending], 0
    jne poll_key_unknown
    clc
    ret

poll_key_enter:
    mov byte ptr [pressed_enter], 0
    mov byte ptr [any_key_pending], 0
    mov al, SCAN_ENTER
    jmp poll_key_ready

poll_key_w:
    mov byte ptr [pressed_w], 0
    mov byte ptr [any_key_pending], 0
    mov al, SCAN_W
    jmp poll_key_ready

poll_key_a:
    mov byte ptr [pressed_a], 0
    mov byte ptr [any_key_pending], 0
    mov al, SCAN_A
    jmp poll_key_ready

poll_key_s:
    mov byte ptr [pressed_s], 0
    mov byte ptr [any_key_pending], 0
    mov al, SCAN_S
    jmp poll_key_ready

poll_key_d:
    mov byte ptr [pressed_d], 0
    mov byte ptr [any_key_pending], 0
    mov al, SCAN_D
    jmp poll_key_ready

poll_key_r:
    mov byte ptr [pressed_r], 0
    mov byte ptr [any_key_pending], 0
    mov al, SCAN_R
    jmp poll_key_ready

poll_key_c:
    mov byte ptr [pressed_c], 0
    mov byte ptr [any_key_pending], 0
    mov al, SCAN_C
    jmp poll_key_ready

poll_key_space:
    mov byte ptr [pressed_space], 0
    mov byte ptr [any_key_pending], 0
    mov al, SCAN_SPACE
    jmp poll_key_ready

poll_key_shift:
    mov byte ptr [pressed_shift], 0
    mov byte ptr [any_key_pending], 0
    mov al, SCAN_LSHIFT
    jmp poll_key_ready

poll_key_up:
    mov byte ptr [pressed_up], 0
    mov byte ptr [any_key_pending], 0
    mov al, SCAN_UP_EXT
    jmp poll_key_ready

poll_key_left:
    mov byte ptr [pressed_left], 0
    mov byte ptr [any_key_pending], 0
    mov al, SCAN_LEFT_EXT
    jmp poll_key_ready

poll_key_right:
    mov byte ptr [pressed_right], 0
    mov byte ptr [any_key_pending], 0
    mov al, SCAN_RIGHT_EXT
    jmp poll_key_ready

poll_key_down:
    mov byte ptr [pressed_down], 0
    mov byte ptr [any_key_pending], 0
    mov al, SCAN_DOWN_EXT
    jmp poll_key_ready

poll_key_unknown:
    mov byte ptr [any_key_pending], 0
    xor al, al

poll_key_ready:
    mov [input_last_polled], al
    cmp byte ptr [input_poll_count], 99
    jae poll_count_ready
    inc byte ptr [input_poll_count]
poll_count_ready:
    call translate_key_event
    stc
    ret

translate_key_event:
    mov ah, al
    cmp al, SCAN_W
    jne key_check_a
    mov al, 'w'
    ret

key_check_a:
    cmp al, SCAN_A
    jne key_check_s
    mov al, 'a'
    ret

key_check_s:
    cmp al, SCAN_S
    jne key_check_d
    mov al, 's'
    ret

key_check_d:
    cmp al, SCAN_D
    jne key_check_r
    mov al, 'd'
    ret

key_check_r:
    cmp al, SCAN_R
    jne key_check_c
    mov al, 'r'
    ret

key_check_c:
    cmp al, SCAN_C
    jne key_check_enter
    mov al, 'c'
    ret

key_check_enter:
    cmp al, SCAN_SPACE
    jne key_check_shift
    mov al, ' '
    mov ah, SCAN_SPACE
    ret

key_check_shift:
    cmp al, SCAN_LSHIFT
    jne key_check_enter_scan
    xor al, al
    mov ah, SCAN_LSHIFT
    ret

key_check_enter_scan:
    cmp al, SCAN_ENTER
    je key_enter_match
    cmp al, (SCAN_ENTER or SCAN_EXT_FLAG)
    jne key_check_up

key_enter_match:
    mov al, KEY_ENTER
    mov ah, SCAN_ENTER
    ret

key_check_up:
    cmp al, SCAN_UP_EXT
    jne key_check_left
    xor al, al
    mov ah, 48h
    ret

key_check_left:
    cmp al, SCAN_LEFT_EXT
    jne key_check_right
    xor al, al
    mov ah, 4Bh
    ret

key_check_right:
    cmp al, SCAN_RIGHT_EXT
    jne key_check_down
    xor al, al
    mov ah, 4Dh
    ret

key_check_down:
    cmp al, SCAN_DOWN_EXT
    jne key_unknown
    xor al, al
    mov ah, 50h
    ret

key_unknown:
    xor al, al
    ret

is_enter_key:
    cmp al, KEY_ENTER
    je enter_key_true
    cmp ah, SCAN_ENTER
    je enter_key_true
    clc
    ret

enter_key_true:
    stc
    ret

keyboard_irq_handler:
    ; Latch one-shot press events on make codes and ignore typematic repeats
    ; until the corresponding break code arrives.
    push ax
    push bx
    push cx
    push dx
    push ds
    push cs
    pop ds

    in al, 60h
    cmp al, 0E0h
    je keyboard_mark_extended
    cmp al, 0E1h
    je keyboard_ignore

    mov dl, al
    and dl, 80h
    and al, 7Fh
    mov bl, [key_extended]
    mov byte ptr [key_extended], 0
    or al, bl
    xor bx, bx
    mov bl, al
    test dl, 80h
    jnz keyboard_release

    cmp byte ptr [key_down + bx], 0
    jne keyboard_done
    mov byte ptr [key_down + bx], 1
    mov byte ptr [any_key_pending], 1
    mov [input_last_code], al
    cmp al, SCAN_ENTER
    je keyboard_press_enter
    cmp al, SCAN_W
    je keyboard_press_w
    cmp al, SCAN_A
    je keyboard_press_a
    cmp al, SCAN_S
    je keyboard_press_s
    cmp al, SCAN_D
    je keyboard_press_d
    cmp al, SCAN_R
    je keyboard_press_r
    cmp al, SCAN_C
    je keyboard_press_c
    cmp al, SCAN_SPACE
    je keyboard_press_space
    cmp al, SCAN_LSHIFT
    je keyboard_press_shift
    cmp al, SCAN_UP_EXT
    je keyboard_press_up
    cmp al, SCAN_LEFT_EXT
    je keyboard_press_left
    cmp al, SCAN_RIGHT_EXT
    je keyboard_press_right
    cmp al, SCAN_DOWN_EXT
    je keyboard_press_down
    jmp keyboard_count_event

keyboard_press_enter:
    mov byte ptr [pressed_enter], 1
    jmp keyboard_count_event

keyboard_press_w:
    mov byte ptr [pressed_w], 1
    jmp keyboard_count_event

keyboard_press_a:
    mov byte ptr [pressed_a], 1
    jmp keyboard_count_event

keyboard_press_s:
    mov byte ptr [pressed_s], 1
    jmp keyboard_count_event

keyboard_press_d:
    mov byte ptr [pressed_d], 1
    jmp keyboard_count_event

keyboard_press_r:
    mov byte ptr [pressed_r], 1
    jmp keyboard_count_event

keyboard_press_c:
    mov byte ptr [pressed_c], 1
    jmp keyboard_count_event

keyboard_press_space:
    mov byte ptr [pressed_space], 1
    jmp keyboard_count_event

keyboard_press_shift:
    mov byte ptr [pressed_shift], 1
    jmp keyboard_count_event

keyboard_press_up:
    mov byte ptr [pressed_up], 1
    jmp keyboard_count_event

keyboard_press_left:
    mov byte ptr [pressed_left], 1
    jmp keyboard_count_event

keyboard_press_right:
    mov byte ptr [pressed_right], 1
    jmp keyboard_count_event

keyboard_press_down:
    mov byte ptr [pressed_down], 1

keyboard_count_event:
    cmp byte ptr [input_event_count], 99
    jae keyboard_done
    inc byte ptr [input_event_count]
    jmp keyboard_done

keyboard_release:
    mov byte ptr [key_down + bx], 0
    jmp keyboard_done

keyboard_mark_extended:
    mov byte ptr [key_extended], SCAN_EXT_FLAG
    jmp keyboard_done

keyboard_ignore:
    mov byte ptr [key_extended], 0

keyboard_done:
    in al, 61h
    mov ah, al
    or al, 80h
    out 61h, al
    mov al, ah
    out 61h, al
    mov al, 20h
    out 20h, al
    pop ds
    pop dx
    pop cx
    pop bx
    pop ax
    iret

record_runtime_frontend_action:
    push bx
    cmp al, FRONTEND_ACTION_NONE
    je runtime_frontend_action_done
    mov bl, [frontend_action]
    cmp bl, FRONTEND_ACTION_NONE
    je runtime_frontend_action_store
    cmp al, FRONTEND_ACTION_ACTIVITY
    je runtime_frontend_action_last
    cmp bl, FRONTEND_ACTION_ACTIVITY
    jne runtime_frontend_action_last

runtime_frontend_action_store:
    mov [frontend_action], al

runtime_frontend_action_last:
    mov [frontend_last_action], al
    cmp byte ptr [frontend_event_count], 99
    jae runtime_frontend_action_done
    inc byte ptr [frontend_event_count]

runtime_frontend_action_done:
    pop bx
    ret

poll_runtime_keyboard:
    mov byte ptr [frontend_action], FRONTEND_ACTION_NONE
    cmp byte ptr [game_state], STATE_SPLASH
    je runtime_keyboard_splash
    cmp byte ptr [game_state], STATE_TITLE
    je runtime_keyboard_title
    cmp byte ptr [game_state], STATE_WIN
    je runtime_keyboard_continue
    cmp byte ptr [game_state], STATE_LOSE
    je runtime_keyboard_continue
    cmp byte ptr [game_state], STATE_VERIFY_PASS
    je runtime_keyboard_continue
    cmp byte ptr [game_state], STATE_VERIFY_FAIL
    je runtime_keyboard_continue
    cmp byte ptr [demo_active], 0
    jne runtime_keyboard_takeover
    jmp runtime_keyboard_gameplay

runtime_keyboard_splash:
    cmp byte ptr [pressed_enter], 0
    jne runtime_keyboard_confirm
    cmp byte ptr [pressed_space], 0
    jne runtime_keyboard_confirm
    cmp byte ptr [any_key_pending], 0
    je runtime_keyboard_done
    mov al, FRONTEND_ACTION_ACTIVITY
    call record_runtime_frontend_action
    jmp runtime_keyboard_done

runtime_keyboard_title:
    cmp byte ptr [pressed_enter], 0
    jne runtime_keyboard_confirm
    cmp byte ptr [pressed_space], 0
    jne runtime_keyboard_confirm
    cmp byte ptr [pressed_w], 0
    jne runtime_keyboard_nav_up
    cmp byte ptr [pressed_up], 0
    jne runtime_keyboard_nav_up
    cmp byte ptr [pressed_a], 0
    jne runtime_keyboard_nav_left
    cmp byte ptr [pressed_left], 0
    jne runtime_keyboard_nav_left
    cmp byte ptr [pressed_s], 0
    jne runtime_keyboard_nav_down
    cmp byte ptr [pressed_down], 0
    jne runtime_keyboard_nav_down
    cmp byte ptr [pressed_d], 0
    jne runtime_keyboard_nav_right
    cmp byte ptr [pressed_right], 0
    jne runtime_keyboard_nav_right
    cmp byte ptr [any_key_pending], 0
    je runtime_keyboard_done
    mov al, FRONTEND_ACTION_ACTIVITY
    call record_runtime_frontend_action
    jmp runtime_keyboard_done

runtime_keyboard_confirm:
    mov al, FRONTEND_ACTION_CONFIRM
    call record_runtime_frontend_action
    jmp runtime_keyboard_done

runtime_keyboard_nav_up:
    mov al, FRONTEND_ACTION_NAV_UP
    call record_runtime_frontend_action
    jmp runtime_keyboard_done

runtime_keyboard_nav_down:
    mov al, FRONTEND_ACTION_NAV_DOWN
    call record_runtime_frontend_action
    jmp runtime_keyboard_done

runtime_keyboard_nav_left:
    mov al, FRONTEND_ACTION_NAV_LEFT
    call record_runtime_frontend_action
    jmp runtime_keyboard_done

runtime_keyboard_nav_right:
    mov al, FRONTEND_ACTION_NAV_RIGHT
    call record_runtime_frontend_action
    jmp runtime_keyboard_done

runtime_keyboard_continue:
    cmp byte ptr [pressed_enter], 0
    jne runtime_keyboard_continue_yes
    cmp byte ptr [pressed_space], 0
    jne runtime_keyboard_continue_yes
    cmp byte ptr [any_key_pending], 0
    je runtime_keyboard_done
    mov al, FRONTEND_ACTION_ACTIVITY
    call record_runtime_frontend_action
    jmp runtime_keyboard_done

runtime_keyboard_continue_yes:
    mov al, FRONTEND_ACTION_CONTINUE
    call record_runtime_frontend_action
    jmp runtime_keyboard_done

runtime_keyboard_takeover:
    cmp byte ptr [pressed_enter], 0
    jne runtime_keyboard_continue_yes
    cmp byte ptr [pressed_space], 0
    jne runtime_keyboard_move
    cmp byte ptr [pressed_w], 0
    jne runtime_keyboard_move
    cmp byte ptr [pressed_a], 0
    jne runtime_keyboard_move
    cmp byte ptr [pressed_s], 0
    jne runtime_keyboard_move
    cmp byte ptr [pressed_d], 0
    jne runtime_keyboard_move
    cmp byte ptr [pressed_up], 0
    jne runtime_keyboard_move
    cmp byte ptr [pressed_left], 0
    jne runtime_keyboard_move
    cmp byte ptr [pressed_right], 0
    jne runtime_keyboard_move
    cmp byte ptr [pressed_down], 0
    jne runtime_keyboard_move
    cmp byte ptr [pressed_c], 0
    jne runtime_keyboard_pulse
    cmp byte ptr [pressed_shift], 0
    jne runtime_keyboard_pulse
    cmp byte ptr [pressed_r], 0
    jne runtime_keyboard_reset
    cmp byte ptr [any_key_pending], 0
    je runtime_keyboard_done
    mov al, FRONTEND_ACTION_ACTIVITY
    call record_runtime_frontend_action
    jmp runtime_keyboard_done

runtime_keyboard_gameplay:
    cmp byte ptr [pressed_w], 0
    jne runtime_keyboard_move
    cmp byte ptr [pressed_a], 0
    jne runtime_keyboard_move
    cmp byte ptr [pressed_s], 0
    jne runtime_keyboard_move
    cmp byte ptr [pressed_d], 0
    jne runtime_keyboard_move
    cmp byte ptr [pressed_up], 0
    jne runtime_keyboard_move
    cmp byte ptr [pressed_left], 0
    jne runtime_keyboard_move
    cmp byte ptr [pressed_right], 0
    jne runtime_keyboard_move
    cmp byte ptr [pressed_down], 0
    jne runtime_keyboard_move
    cmp byte ptr [pressed_space], 0
    jne runtime_keyboard_move
    cmp byte ptr [pressed_c], 0
    jne runtime_keyboard_pulse
    cmp byte ptr [pressed_shift], 0
    jne runtime_keyboard_pulse
    cmp byte ptr [pressed_r], 0
    jne runtime_keyboard_reset
    cmp byte ptr [any_key_pending], 0
    je runtime_keyboard_done
    mov al, FRONTEND_ACTION_ACTIVITY
    call record_runtime_frontend_action
    jmp runtime_keyboard_done

runtime_keyboard_move:
    mov al, FRONTEND_ACTION_MOVE
    call record_runtime_frontend_action
    jmp runtime_keyboard_done

runtime_keyboard_pulse:
    mov al, FRONTEND_ACTION_PULSE
    call record_runtime_frontend_action
    jmp runtime_keyboard_done

runtime_keyboard_reset:
    mov al, FRONTEND_ACTION_RESET
    call record_runtime_frontend_action

runtime_keyboard_done:
    ret
