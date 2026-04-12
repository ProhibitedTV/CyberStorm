; Core run state. Most symbols are referenced directly, so only the documented
; adjacency assumptions below matter to the runtime.
game_state   db STATE_TITLE
sector_num   db 1
; current_template_index keeps the selected authored map slot so hybrid anchor
; placement can read the right generated tables after copy_sector_layout.
current_template_index db 0
; shard_pool_pick_mask is a sector-load scratch bitmask used while selecting
; 4 unique live shard positions from the authored 6-tile scenario pool.
shard_pool_pick_mask db 0
shield_count db START_SHIELDS
pulse_count  db START_PULSES
data_count   db 0
kill_count   db 0
score_total  dw 0
sector_score dw 0
; Sector mastery stays small and explainable: turn count feeds fast-clear bonus,
; hits gate the clean-sector bonus, and pulse usage gates the efficiency bonus.
sector_actions     db 0
sector_hits        db 0
sector_pulses_used db 0
message_id   db MSG_SECTOR
action_taken db 0
player_x     db START_X
player_y     db START_Y
exit_x       db EXIT_COL
exit_y       db EXIT_ROW
adventure_player_world_x dw 0
adventure_player_world_y dw GAME3D_FLOOR_Y
adventure_player_world_z dw 0
adventure_player_vel_y   dw 0
adventure_player_yaw     db GAME3D_YAW_NORTH
adventure_player_grounded db 1
adventure_charge_timer   db 0
adventure_flame_timer    db 0
adventure_enemy_tick     db 0
adventure_hazard_timer   db 0
adventure_objectives_done db 0
adventure_objectives_total db 0
adventure_intro_timer    db 0
adventure_key_collected  db 0
adventure_chunk_x        db 0FFh
adventure_chunk_y        db 0FFh
adventure_chunk_min_x    db 0
adventure_chunk_max_x    db MAP_W - 1
adventure_chunk_min_y    db 0
adventure_chunk_max_y    db MAP_H - 1
; Boot drive is captured from DL on stage-two entry so post-boot bank reads do
; not depend on the boot sector staying resident.
boot_drive   db 0
rng_state    dw 0ACE1h
last_tick    dw 0
pit_frame_due_low dw 0
pit_frame_due_high dw 0
frame_skip_render db 0
render_skip_streak db 0
anim_phase   db 0
splash_ticks db 0
state_ticks  db 0
title_idle_ticks db 0
; A short post-start guard keeps freshly entered runs from immediately honoring
; reset input on the next gameplay tick while frontend keys are settling.
run_start_enter_guard db 0
; Demo playback is opt-in attract mode driven by generated [action, ticks]
; pairs. next_demo_index rotates the title idle cycle through the authored set.
demo_active  db 0
demo_index   db 0
next_demo_index db 0
demo_action_code db DEMO_ACTION_END
demo_action_ticks db 0
demo_script_ptr dw 0
; Debug-only replay verification tracks consumed demo actions separately from
; action_taken so blocked moves and other no-turn inputs can still be checked.
verify_action_pending db 0
verify_action_index db 0
verify_result_demo_index db 0
verify_expected_signature dw 0
verify_observed_signature dw 0
verify_snapshot_heading db 0
verify_snapshot_variant db 0
verify_snapshot_cue_flags db 0
verify_snapshot_intro_timer db 0
verify_snapshot_enemy_tick db 0
verify_snapshot_threat_level db THREAT_NONE
verify_snapshot_threat_x db START_X
verify_snapshot_threat_y db START_Y
verify_snapshot_enemy0 dw 0
verify_snapshot_enemy1 dw 0
verify_snapshot_enemy2 dw 0
; verify_mode reuses the shared PASS/FAIL scenes for both replay verification
; and the debug-only frontend trust scenarios.
verify_mode db VERIFY_MODE_REPLAY
verify_frontend_scenario db FRONTEND_VERIFY_NONE
verify_frontend_ticks db 0
verify_frontend_event_fired db 0
last_game_state db 0FFh
feedback_timer db 0
; The runner's last committed step lets flanking hunters aim one tile ahead
; without any hidden extra turns or non-deterministic guesses.
last_player_dx db 0
last_player_dy db 0
; Spoof terminals briefly reroute hunters toward the gate. The timer is counted
; in enemy response phases, and spoof_x/y anchor the active route effect.
spoof_timer  db 0
spoof_x      db START_X
spoof_y      db START_Y
; threat_level and threat/effect tiles are render hints only; they telegraph
; danger and localize flashes without changing the rules.
threat_level db THREAT_NONE
threat_x     db START_X
threat_y     db START_Y
effect_x     db START_X
effect_y     db START_Y
; One-shot SFX owns the speaker; music state tracks the looping theme beneath it.
sound_id     db SFX_NONE
sound_timer  db 0
sound_phase  db 0
music_theme  db MUSIC_THEME_NONE
music_ticks  db 0
music_note   db MUSIC_NOTE_REST
music_ptr    dw 0
scene_render_mode db SCENE_RENDER_MODE_3D
gameplay_render_mode db GAMEPLAY_RENDER_MODE_3D
machine_kernel_active db 0
machine_kernel_far_ptr dw 0, 0
machine_kernel_param_block db 16 dup (0)
scene3d_active db 0
scene3d_index  db 0
scene3d_face_count db 0
scene3d_vertex_count dw 0
scene3d_vertex_source dw offset scene3d_vertex_raw
scene3d_face_source dw offset scene3d_face_raw
game3d_rendering_active db 0
game3d_room_dirty db 1
game3d_room_overflow db 0
game3d_room_face_count db 0
game3d_room_vertex_count dw 0
game3d_emit_flags db 0
game3d_optional_faces_remaining db GAME3D_OPTIONAL_FACE_BUDGET
game3d_wall_emit_mode db 0
game3d_camera_heading db GAME3D_HEADING_EAST
game3d_camera_yaw_current db GAME3D_YAW_DEFAULT
game3d_camera_yaw_target  db GAME3D_YAW_DEFAULT
game3d_room_variant db GAME3D_ROOM_VARIANT_NORTHWEST
game3d_shot_mode db GAME3D_SHOT_BASE_CHASE
game3d_shot_reason db GAME3D_SHOT_REASON_NONE
game3d_shot_tick db 0
game3d_shot_duration db 0
game3d_shot_frame_variant db GAME3D_FRAME_VARIANT_NONE
game3d_shot_subject_x db START_X
game3d_shot_subject_y db START_Y
game3d_end_state_pending db 0
game3d_last_threat_level db THREAT_NONE
game3d_mesh_index db 0
game3d_mesh_yaw db 0
game3d_mesh_face_flags db 0
game3d_mesh_vertex_base dw 0
game3d_mesh_world_x dw 0
game3d_mesh_world_y dw 0
game3d_mesh_world_z dw 0
key_extended db 0
any_key_pending db 0
input_event_count db 0
input_last_code db 0
input_last_ascii db 0
input_check_count db 0
input_poll_count db 0
input_last_polled db 0
; frontend_action is the current semantic action for splash/title/outro flow.
; frontend_last_action preserves the most recent semantic event for debugging.
frontend_action db FRONTEND_ACTION_NONE
frontend_last_action db FRONTEND_ACTION_NONE
frontend_event_count db 0
pressed_enter db 0
pressed_w db 0
pressed_a db 0
pressed_s db 0
pressed_d db 0
pressed_r db 0
pressed_c db 0
pressed_space db 0
pressed_shift db 0
pressed_up db 0
pressed_left db 0
pressed_right db 0
pressed_down db 0
; key_down and key_pressed must stay adjacent because reset_keyboard_state
; clears one contiguous KEY_STATE_REGION_BYTES block starting here.
key_down db KEY_STATE_TABLE_BYTES dup (0)
; Reserved for future/diagnostic per-scan bookkeeping.
key_pressed db KEY_STATE_TABLE_BYTES dup (0)

text_cursor_x  dw 0
text_cursor_y  dw 0
glyph_base_x   dw 0
glyph_base_y   dw 0
rect_w         dw 0
rect_h         dw 0
text_color     db 0
glyph_row_bits db 0

scene3d_clip_left   dw 0
scene3d_clip_top    dw 0
scene3d_clip_right  dw SCREEN_W - 1
scene3d_clip_bottom dw SCREEN_H - 1
scene3d_center_x    dw SCREEN_W / 2
scene3d_center_y    dw SCREEN_H / 2
scene3d_project_scale dw 112
scene3d_cam_x       dw 0
scene3d_cam_y       dw 0
scene3d_cam_z       dw 0
scene3d_yaw_angle   db 0
scene3d_pitch_angle db 0
scene3d_tick        db 0
scene3d_timeline_tick db 0
scene3d_temp_x      dw 0
scene3d_temp_y      dw 0
scene3d_temp_z      dw 0
scene3d_temp_u      dw 0
scene3d_temp_v      dw 0
scene3d_temp_w      dw 0
scene3d_temp_l      dw 0
scene3d_temp_r      dw 0
scene3d_temp_s      dw 0
scene3d_temp_depth  dw 0
scene3d_tri_x0      dw 0
scene3d_tri_y0      dw 0
scene3d_tri_u0      dw 0
scene3d_tri_v0      dw 0
scene3d_tri_x1      dw 0
scene3d_tri_y1      dw 0
scene3d_tri_u1      dw 0
scene3d_tri_v1      dw 0
scene3d_tri_x2      dw 0
scene3d_tri_y2      dw 0
scene3d_tri_u2      dw 0
scene3d_tri_v2      dw 0
scene3d_text_left_x dw 0
scene3d_text_left_u dw 0
scene3d_text_left_v dw 0
scene3d_text_right_x dw 0
scene3d_text_right_u dw 0
scene3d_text_right_v dw 0
scene3d_text_step_long_x dw 0
scene3d_text_step_long_u dw 0
scene3d_text_step_long_v dw 0
scene3d_text_step_short_x dw 0
scene3d_text_step_short_u dw 0
scene3d_text_step_short_v dw 0
scene3d_temp_color  db 0
scene3d_temp_dither db 0
scene3d_temp_face   db 0
scene3d_temp_texture db SCENE3D_TEXTURE_NONE
scene3d_vertex_x    dw SCENE3D_MAX_VERTICES dup (0)
scene3d_vertex_y    dw SCENE3D_MAX_VERTICES dup (0)
scene3d_vertex_z    dw SCENE3D_MAX_VERTICES dup (0)
scene3d_vertex_raw  db SCENE3D_MAX_VERTICES * SCENE3D_VERTEX_BYTES dup (0)
scene3d_face_depth  dw SCENE3D_MAX_FACES dup (0)
scene3d_face_order  db SCENE3D_MAX_FACES dup (0)
scene3d_face_raw    db SCENE3D_MAX_FACES * SCENE3D_FACE_BYTES dup (0)
game3d_room_vertex_raw db SCENE3D_MAX_VERTICES * SCENE3D_VERTEX_BYTES dup (0)
game3d_room_face_raw   db SCENE3D_MAX_FACES * SCENE3D_FACE_BYTES dup (0)
game3d_floor_marks db MAP_SIZE dup (0)

; Enemy slot layout: [alive, x, y, kind].
enemies db MAX_ENEMIES * ENEMY_SIZE dup (0)
map_tiles db MAP_SIZE dup (0)

; map_index depends on these row bases matching MAP_W exactly.
map_row_offsets dw 0, 28, 56, 84, 112, 140, 168, 196, 224, 252, 280, 308, 336, 364, 392
sector_score_table dw TOTAL_SECTORS dup (0)

message_table dw offset text_msg_sector, offset text_msg_block, offset text_msg_shard, offset text_msg_gate
              dw offset text_msg_hit, offset text_msg_kill, offset text_msg_pulse, offset text_msg_nopulse
              dw offset text_msg_surge, offset text_msg_trap, offset text_msg_recharge, offset text_msg_spoof
              dw offset text_msg_key

hud_title     db 'CYBERSTORM', 0
score_text    db 'SCORE', 0
sector_text   db 'SECTOR', 0
data_text     db 'DATA', 0
kills_text    db 'KILLS', 0
demo_text     db 'DEMO', 0
spoof_text    db 'SPOOF', 0
shield_text   db 'SHIELD', 0
pulse_text    db 'PULSE', 0
gate_text     db 'GATE', 0
controls_text db 'MOVE WASD OR ARROWS  C EMP  R RESET', 0
adventure_controls_text db 'WS RUN  AD TURN  SPC GLIDE  SHF CHARGE  C FLAME  ENT PORTAL', 0
realm_text db 'REALM', 0
gems_text db 'GEMS', 0
goals_text db 'GOALS', 0
portal_text db 'PORTAL', 0
slash_text db '/', 0
portal_open_text db 'OPEN', 0
portal_locked_text db 'LOCK', 0
sector1_short_text db 'S1', 0
sector2_short_text db 'S2', 0
sector3_short_text db 'S3', 0
rank_s_text db 'RANK S', 0
rank_a_text db 'RANK A', 0
rank_b_text db 'RANK B', 0
rank_c_text db 'RANK C', 0
rank_d_text db 'RANK D', 0

; Sector template pools, authored encounter anchors, scenario text, shard
; candidate pools, rule tables, and sector-facing copy are generated from
; assets\sectors.psd1 at build time.
include generated_sector_content.inc
; Demo scripts are generated from assets\demos.psd1 as compact action/tick
; pairs so attract-mode content can scale without hand-editing ASM tables.
include generated_demos.inc
; Replay verification tables are generated from scripts\replay-harness.ps1 so
; the live runtime can prove it still matches the deterministic host model.
include generated_runtime_verify.inc
; Low-poly scene geometry is generated from assets\geometry.psd1 into a banked
; payload plus scene/camera metadata tables for the phase-1 3D renderer.
include generated_geometry.inc

text_msg_sector   db 'THE REALM IS LIVE. GATHER GEMS, CLAIM THE KEY, AND LIGHT THE PEDESTAL.', 0
text_msg_block    db 'A CLIFF OR STONE WALL BLOCKS THE WAY.', 0
text_msg_shard    db 'GEM COLLECTED. THE PORTAL BRIGHTENS.', 0
text_msg_gate     db 'PORTAL OPEN. STEP THROUGH WHEN YOU ARE READY.', 0
text_msg_hit      db 'OUCH. THAT ONE COST A HEART.', 0
text_msg_kill     db 'FOE TOPPLED. THE PATH BREATHES.', 0
text_msg_pulse    db 'EMP WAVE CUT LOOSE.', 0
text_msg_nopulse  db 'EMP DRY. NO CHARGES IN THE BANK.', 0
text_msg_surge    db 'LAVA OR BAD AIR BIT BACK.', 0
text_msg_trap     db 'THE HAZARD CAUGHT A FOE.', 0
text_msg_recharge db 'CHAIN BREAK. EMP CHARGE RESTORED.', 0
text_msg_spoof    db 'PEDESTAL LIT. ANOTHER PORTAL SEAL IS GONE.', 0
text_msg_key      db 'SUN KEY CLAIMED. THE PORTAL CAN NOW UNSEAL.', 0

splash_brand    db 'BITRIVER', 0
splash_subtitle db 'SOFTWARE', 0
splash_tagline  db 'BOOTSTRAPPING WORLDS FROM BARE METAL.', 0
splash_run_prompt  db 'ENTER SPACE OR MOVE TO RUN', 0
splash_skip_prompt db 'OTHER KEYS SKIP TO TITLE', 0

title_logo    db 'CYBERSTORM', 0
title_line_1  db 'NO OS. NO SHELL. JUST THE BREACH.', 0
title_line_2  db 'BARE METAL 3D ADVENTURE IN RAW VGA.', 0
title_line_3  db 'GATHER GEMS. LIGHT THE REALM. OPEN THE PORTAL.', 0
title_line_4  db 'PRESS ENTER SPACE OR MOVE TO JACK IN.', 0
title_prompt  db 'IDLE STARTS AN ATTRACT RUN.', 0
demo_takeover_text db 'ENTER SPACE OR LIVE KEYS TAKE OVER.', 0
IF DEBUG_BUILD
; Temporary title-scene diagnostics used while hardening keyboard support.
debug_keys_text db 'KEYS', 0
debug_enter_text db 'ENTR', 0
debug_check_text db 'CHCK', 0
debug_poll_text db 'POLL', 0
ENDIF

IF DEBUG_OVERLAY
debug_tag_text   db 'DBG', 0
debug_state_tag  db 'GS', 0
debug_demo_tag   db 'DM', 0
debug_guard_tag  db 'GD', 0
debug_scan_tag   db 'KS', 0
debug_ascii_tag  db 'KA', 0
debug_frontend_action_tag db 'FA', 0
debug_frontend_events_tag db 'FE', 0
debug_backend_tag db 'AB', 0
debug_audio_mode_tag db 'AM', 0
debug_sfx_tag    db 'FX', 0
debug_sfx_timer_tag db 'FT', 0
debug_sector_tag db 'S', 0
debug_x_tag      db 'X', 0
debug_y_tag      db 'Y', 0
debug_shield_tag db 'H', 0
debug_pulse_tag  db 'P', 0
debug_data_tag   db 'D', 0
debug_enemy_tag  db 'E', 0
debug_overflow_tag db 'GO', 0
debug_camera_tag db 'CQ', 0
debug_shot_tag db 'SM', 0
debug_shot_subject_x_tag db 'SX', 0
debug_shot_subject_y_tag db 'SY', 0
debug_frame_tag db 'FV', 0
debug_demo_code_tag db 'DC', 0
debug_demo_ticks_tag db 'DT', 0
debug_verify_action_tag db 'VA', 0
ENDIF

win_line_1    db 'VAULT', 0
win_line_2    db 'ALL THREE SECTORS FELL TO THE RUN.', 0
win_line_3    db 'THE STORM BENT. THE BREACH HELD.', 0
lose_line_1   db 'SEVERED', 0
lose_line_2   db 'THE STORM CLOSED BEFORE THE BREACH.', 0
lose_line_3   db 'REBUILD THE LINE. RUN IT AGAIN.', 0
replay_prompt db 'PRESS ENTER OR SPACE TO RUN AGAIN.', 0
verify_pass_headline db 'REPLAY PASS', 0
verify_fail_headline db 'REPLAY FAIL', 0
verify_line_1 db 'LIVE RUNTIME MATCHED THE AUTHORED DEMO CONTRACT.', 0
verify_line_2 db 'THE BOOTED GAME DIVERGED FROM THE EXPECTED CHECKPOINT.', 0
verify_demo_label db 'DEMO', 0
verify_scenario_label db 'SCN', 0
verify_step_label db 'ACT', 0
verify_event_label db 'EVT', 0
verify_expect_label db 'EXP', 0
verify_observe_label db 'OBS', 0
verify_state_px_label db 'PX', 0
verify_state_py_label db 'PY', 0
verify_state_action_label db 'AC', 0
verify_state_heading_label db 'HD', 0
verify_state_variant_label db 'RV', 0
verify_state_shot_label db 'SM', 0
verify_state_reason_label db 'SR', 0
verify_state_subject_x_label db 'SX', 0
verify_state_subject_y_label db 'SY', 0
verify_state_frame_label db 'FV', 0
verify_state_shield_label db 'SH', 0
verify_state_pulse_label db 'PU', 0
verify_state_data_label db 'DT', 0
verify_state_kill_label db 'KG', 0
verify_state_game_label db 'GS', 0
verify_state_map_label db 'MP', 0
verify_state_score_label db 'SC', 0
verify_state_rng_label db 'RG', 0
verify_state_cue_label db 'CF', 0
verify_state_tick_label db 'TK', 0
verify_state_hits_label db 'HI', 0
verify_state_pulses_used_label db 'PS', 0
verify_state_spoof_label db 'SP', 0
verify_state_intro_label db 'IT', 0
verify_state_enemy_tick_label db 'ET', 0
verify_state_threat_label db 'TH', 0
verify_state_threat_x_label db 'TX', 0
verify_state_threat_y_label db 'TY', 0
verify_state_enemy0_label db 'E0', 0
verify_state_enemy1_label db 'E1', 0
verify_state_enemy2_label db 'E2', 0
verify_prompt db 'ENTER OR SPACE RETURNS TO TITLE.', 0
frontend_verify_pass_headline db 'FRONTEND PASS', 0
frontend_verify_fail_headline db 'FRONTEND FAIL', 0
frontend_verify_line_1 db 'SYNTHETIC FRONTEND INPUT REACHED THE EXPECTED STATE.', 0
frontend_verify_line_2 db 'THE FRONTEND STATE MACHINE DIVERGED FROM EXPECTATION.', 0
frontend_verify_splash_name db 'SPLASH TO TITLE', 0
frontend_verify_title_start_name db 'TITLE TO START', 0
frontend_verify_title_attract_name db 'TITLE TO ATTRACT', 0
frontend_verify_splash_detail db 'EXPECT TITLE ENTRY AFTER NON START INPUT.', 0
frontend_verify_title_start_detail db 'EXPECT LIVE RUN ENTRY FROM A START ACTION.', 0
frontend_verify_title_attract_detail db 'EXPECT ATTRACT HANDOFF AFTER IDLE TIMEOUT.', 0
