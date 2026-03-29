; Core run state. Most symbols are referenced directly, so only the documented
; adjacency assumptions below matter to the runtime.
game_state   db STATE_TITLE
sector_num   db 1
shield_count db START_SHIELDS
pulse_count  db START_PULSES
data_count   db 0
kill_count   db 0
message_id   db MSG_SECTOR
action_taken db 0
player_x     db START_X
player_y     db START_Y
exit_x       db EXIT_COL
exit_y       db EXIT_ROW
rng_state    dw 0ACE1h
last_tick    dw 0
anim_phase   db 0
splash_ticks db 0
state_ticks  db 0
last_game_state db 0FFh
feedback_timer db 0
; The runner's last committed step lets flanking hunters aim one tile ahead
; without any hidden extra turns or non-deterministic guesses.
last_player_dx db 0
last_player_dy db 0
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

message_table dw offset text_msg_sector, offset text_msg_block, offset text_msg_shard, offset text_msg_gate
              dw offset text_msg_hit, offset text_msg_kill, offset text_msg_pulse, offset text_msg_nopulse
              dw offset text_msg_surge, offset text_msg_trap, offset text_msg_recharge

; sector_num is 1-based; load_sector uses these base/count tables to choose one
; authored layout from each sector's template pool.
sector_template_start db SECTOR1_TEMPLATE_BASE, SECTOR2_TEMPLATE_BASE, SECTOR3_TEMPLATE_BASE
sector_template_count db SECTOR1_TEMPLATE_COUNT, SECTOR2_TEMPLATE_COUNT, SECTOR3_TEMPLATE_COUNT
template_table dw offset sector1_map_a, offset sector1_map_b, offset sector1_map_c
              dw offset sector2_map_a, offset sector2_map_b, offset sector2_map_c
              dw offset sector3_map_a, offset sector3_map_b, offset sector3_map_c
; HUD and sector-entry feedback share these tables so each run can name the
; current breach zone without adding new state or bespoke scene code.
sector_name_table dw offset sector1_name, offset sector2_name, offset sector3_name
sector_intro_table dw offset sector1_intro, offset sector2_intro, offset sector3_intro

hud_title     db 'CYBERSTORM', 0
sector_text   db 'SECTOR', 0
data_text     db 'DATA', 0
kills_text    db 'KILLS', 0
shield_text   db 'SHIELD', 0
pulse_text    db 'PULSE', 0
gate_text     db 'GATE', 0
controls_text db 'MOVE WASD OR ARROWS  C EMP  ENTER RESET', 0
sector1_name  db 'SCOUT', 0
sector2_name  db 'SURGE', 0
sector3_name  db 'WARDEN', 0

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
sector1_intro     db 'SCOUT GRID LIVE. OPEN LANES FAVOR CLEAN CHASES.', 0
sector2_intro     db 'SURGE FURNACE LIVE. ARC NODES BITE BOTH SIDES.', 0
sector3_intro     db 'WARDEN LOCK LIVE. EXTRA HUNTERS CROWD THE EXIT.', 0

splash_brand    db 'BITRIVER', 0
splash_subtitle db 'SOFTWARE', 0
splash_tagline  db 'BOOTSTRAPPING WORLDS FROM BARE METAL.', 0
splash_skip     db 'ENTER TO RUN  ANY KEY TO SKIP', 0

title_logo    db 'CYBERSTORM', 0
title_line_1  db 'NO OS. NO SHELL. JUST THE BREACH.', 0
title_line_2  db 'TURN BASED INFILTRATION IN RAW VGA.', 0
title_line_3  db 'TAKE 4 SHARDS. OPEN THE GATE. REPEAT.', 0
title_line_4  db 'PRESS ANY KEY TO JACK IN.', 0
title_prompt  db 'BOOTED DIRECT TO THE RUN.', 0
IF DEBUG_BUILD
; Temporary title-scene diagnostics used while hardening keyboard support.
debug_keys_text db 'KEYS', 0
debug_enter_text db 'ENTR', 0
debug_check_text db 'CHCK', 0
debug_poll_text db 'POLL', 0
ENDIF

IF DEBUG_OVERLAY
debug_tag_text   db 'DBG', 0
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
replay_prompt db 'PRESS ANY KEY TO RUN AGAIN.', 0
