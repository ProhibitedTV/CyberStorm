update_machine_kernel_frame_mode:
    mov byte ptr [machine_kernel_active], 0

    cmp byte ptr [game_state], STATE_PLAYING
    je machine_kernel_frame_playing
    cmp byte ptr [game_state], STATE_SPLASH
    je machine_kernel_frame_scene
    cmp byte ptr [game_state], STATE_TITLE
    je machine_kernel_frame_scene
    cmp byte ptr [game_state], STATE_WIN
    je machine_kernel_frame_scene
    cmp byte ptr [game_state], STATE_LOSE
    je machine_kernel_frame_scene
    ret

machine_kernel_frame_playing:
    cmp byte ptr [gameplay_render_mode], GAMEPLAY_RENDER_MODE_3D_MACHINE
    jne machine_kernel_frame_done
    mov byte ptr [machine_kernel_active], 1
    ret

machine_kernel_frame_scene:
    cmp byte ptr [scene_render_mode], SCENE_RENDER_MODE_3D_MACHINE
    jne machine_kernel_frame_done
    mov byte ptr [machine_kernel_active], 1

machine_kernel_frame_done:
    ret

machine_call_far_kernel:
    mov [machine_kernel_far_ptr], ax
    mov word ptr [machine_kernel_far_ptr + 2], CODE_BANK_SEG
    call dword ptr cs:[machine_kernel_far_ptr]
    ret

machine_pose_step_reference:
    mov ax, [si]
    mov dx, [si + 2]
    cmp ax, dx
    je machine_pose_step_store
    jl machine_pose_step_increase
    sub ax, [si + 4]
    cmp ax, dx
    jge machine_pose_step_store
    mov ax, dx
    jmp machine_pose_step_store

machine_pose_step_increase:
    add ax, [si + 4]
    cmp ax, dx
    jle machine_pose_step_store
    mov ax, dx

machine_pose_step_store:
    mov [si + 6], ax
    ret
