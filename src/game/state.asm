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
last_tick    dw 0
anim_phase   db 0
splash_ticks db 0

text_cursor_x  dw 0
text_cursor_y  dw 0
glyph_base_x   dw 0
glyph_base_y   dw 0
rect_w         dw 0
rect_h         dw 0
text_color     db 0
glyph_row_bits db 0

enemies db MAX_ENEMIES * ENEMY_SIZE dup (0)
map_tiles db MAP_SIZE dup (0)

map_row_offsets dw 0, 28, 56, 84, 112, 140, 168, 196, 224, 252, 280, 308, 336, 364, 392

message_table dw offset text_msg_sector, offset text_msg_block, offset text_msg_shard, offset text_msg_gate
              dw offset text_msg_hit, offset text_msg_kill, offset text_msg_pulse, offset text_msg_nopulse

template_table dw offset sector1_map, offset sector2_map, offset sector3_map

hud_title     db 'CYBERSTORM', 0
sector_text   db 'SECTOR', 0
data_text     db 'DATA', 0
kills_text    db 'KILLS', 0
shield_text   db 'SHIELD', 0
pulse_text    db 'PULSE', 0
gate_text     db 'GATE', 0
controls_text db 'MOVE WASD OR ARROWS  C EMP  ENTER RESET', 0

text_msg_sector  db 'TAKE ALL 4 SHARDS TO OPEN THE GATE.', 0
text_msg_block   db 'BLACK ICE BLOCKS THAT ROUTE.', 0
text_msg_shard   db 'SHARD SECURED.', 0
text_msg_gate    db 'GATE UNLOCKED. PUSH THROUGH.', 0
text_msg_hit     db 'HUNTER HIT. SHIELD LOST.', 0
text_msg_kill    db 'HUNTER PURGED.', 0
text_msg_pulse   db 'EMP DETONATED.', 0
text_msg_nopulse db 'NO EMP CHARGES LEFT.', 0

splash_brand    db 'BITRIVER', 0
splash_subtitle db 'SOFTWARE', 0
splash_tagline  db 'BOOTSTRAPPING WORLDS FROM BARE METAL.', 0
splash_skip     db 'ENTER TO RUN  ANY KEY TO SKIP', 0

title_logo    db 'CYBERSTORM', 0
title_line_1  db 'NO OS. NO SHELL. JUST THE BREACH.', 0
title_line_2  db 'TURN BASED INFILTRATION IN RAW VGA.', 0
title_line_3  db 'TAKE 4 SHARDS. OPEN THE GATE. REPEAT.', 0
title_line_4  db 'PRESS ENTER TO JACK IN.', 0
title_prompt  db 'BOOTED DIRECT TO THE RUN.', 0

win_line_1    db 'VAULT', 0
win_line_2    db 'ALL THREE SECTORS FELL TO THE RUN.', 0
lose_line_1   db 'SEVERED', 0
lose_line_2   db 'THE STORM CLOSED BEFORE THE BREACH.', 0
replay_prompt db 'PRESS ENTER TO RUN AGAIN.', 0
