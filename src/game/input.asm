poll_key_event:
    mov ah, 11h
    int 16h
    jz poll_key_none
    mov ah, 10h
    int 16h
    stc
    ret

poll_key_none:
    clc
    ret

flush_key_buffer:
flush_key_loop:
    mov ah, 11h
    int 16h
    jz flush_key_done
    mov ah, 10h
    int 16h
    jmp flush_key_loop

flush_key_done:
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
