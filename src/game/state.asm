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
; Boot drive is captured from DL on stage-two entry so post-boot bank reads do
; not depend on the boot sector staying resident.
boot_drive   db 0
rng_state    dw 0ACE1h
last_tick    dw 0
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
key_extended db 0
any_key_pending db 0
input_event_count db 0
input_last_code db 0
input_check_count db 0
input_poll_count db 0
input_last_polled db 0
pressed_enter db 0
pressed_w db 0
pressed_a db 0
pressed_s db 0
pressed_d db 0
pressed_r db 0
pressed_c db 0
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

; Enemy slot layout: [alive, x, y, kind].
enemies db MAX_ENEMIES * ENEMY_SIZE dup (0)
map_tiles db MAP_SIZE dup (0)

; map_index depends on these row bases matching MAP_W exactly.
map_row_offsets dw 0, 28, 56, 84, 112, 140, 168, 196, 224, 252, 280, 308, 336, 364, 392
sector_score_table dw TOTAL_SECTORS dup (0)

message_table dw offset text_msg_sector, offset text_msg_block, offset text_msg_shard, offset text_msg_gate
              dw offset text_msg_hit, offset text_msg_kill, offset text_msg_pulse, offset text_msg_nopulse
              dw offset text_msg_surge, offset text_msg_trap, offset text_msg_recharge, offset text_msg_spoof

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

text_msg_sector   db 'SECTOR LIVE. LIFT 4 SHARDS TO CRACK THE GATE.', 0
text_msg_block    db 'BLACK ICE HOLDS. CUT A DIFFERENT LINE.', 0
text_msg_shard    db 'SHARD SPIKED. THE BREACH IS OPENING.', 0
text_msg_gate     db 'GATE SHATTERED. RUN THE EXIT.', 0
text_msg_hit      db 'RUNNER HIT. SHIELD SHEARED AWAY.', 0
text_msg_kill     db 'HUNTER PURGED. THE LANE BREATHES.', 0
text_msg_pulse    db 'EMP WAVE CUT LOOSE.', 0
text_msg_nopulse  db 'EMP DRY. NO CHARGES IN THE BANK.', 0
text_msg_surge    db 'SURGE ARC BURNED A SHIELD.', 0
text_msg_trap     db 'SURGE TRAP LANDED. HUNTER BURNT OUT.', 0
text_msg_recharge db 'CHAIN BREAK. EMP CHARGE RESTORED.', 0
text_msg_spoof    db 'TERMINAL SPOOF LIVE. HUNTERS PULL TO THE GATE.', 0

splash_brand    db 'BITRIVER', 0
splash_subtitle db 'SOFTWARE', 0
splash_tagline  db 'BOOTSTRAPPING WORLDS FROM BARE METAL.', 0
splash_skip     db 'ENTER TO RUN  ANY KEY TO SKIP', 0

title_logo    db 'CYBERSTORM', 0
title_line_1  db 'NO OS. NO SHELL. JUST THE BREACH.', 0
title_line_2  db 'TURN BASED INFILTRATION IN RAW VGA.', 0
title_line_3  db 'TAKE 4 SHARDS. OPEN THE GATE. REPEAT.', 0
title_line_4  db 'PRESS ENTER TO JACK IN.', 0
title_prompt  db 'IDLE STARTS AN ATTRACT RUN.', 0
demo_takeover_text db 'ANY KEY TAKES OVER.', 0
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
debug_key_tag    db 'LK', 0
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
ENDIF

win_line_1    db 'VAULT', 0
win_line_2    db 'ALL THREE SECTORS FELL TO THE RUN.', 0
win_line_3    db 'THE STORM BENT. THE BREACH HELD.', 0
lose_line_1   db 'SEVERED', 0
lose_line_2   db 'THE STORM CLOSED BEFORE THE BREACH.', 0
lose_line_3   db 'REBUILD THE LINE. RUN IT AGAIN.', 0
replay_prompt db 'PRESS ENTER TO RUN AGAIN.', 0
verify_pass_headline db 'REPLAY PASS', 0
verify_fail_headline db 'REPLAY FAIL', 0
verify_line_1 db 'LIVE RUNTIME MATCHED THE AUTHORED DEMO CONTRACT.', 0
verify_line_2 db 'THE BOOTED GAME DIVERGED FROM THE EXPECTED CHECKPOINT.', 0
verify_demo_label db 'DEMO', 0
verify_step_label db 'ACT', 0
verify_expect_label db 'EXP', 0
verify_observe_label db 'OBS', 0
verify_prompt db 'ENTER RETURNS TO TITLE.', 0
