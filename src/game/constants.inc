STATE_TITLE    equ 0
STATE_PLAYING  equ 1
STATE_WIN      equ 2
STATE_LOSE     equ 3
STATE_SPLASH   equ 4

SPLASH_DURATION equ 54
TITLE_ATTRACT_DELAY equ 90
TITLE_BADGE_DELAY equ 72
RUN_START_ENTER_GUARD_TICKS equ 6
SPLASH_REVEAL_LOGO equ 4
SPLASH_REVEAL_WORDMARK equ 12
SPLASH_REVEAL_UI equ 18
SECTOR_CARD_STAGE_LIMIT equ 6

SCREEN_W      equ 320
SCREEN_H      equ 200
SCREEN_PIXELS equ SCREEN_W * SCREEN_H
SCREEN_WORDS  equ SCREEN_PIXELS / 2
TEXT_MODE_80X25 equ 0003h

; Stage two mirrors the bootloader's floppy geometry for post-boot bank reads.
FLOPPY_SECTOR_BYTES       equ 0200h
FLOPPY_SECTORS_PER_TRACK  equ 18
FLOPPY_HEADS              equ 2

TILE_SIZE     equ 8
TILE_SHIFT    equ 3

KEY_ENTER      equ 0Dh
SCAN_ENTER     equ 1Ch
SCAN_W         equ 11h
SCAN_A         equ 1Eh
SCAN_S         equ 1Fh
SCAN_D         equ 20h
SCAN_R         equ 13h
SCAN_C         equ 2Eh
SCAN_EXT_FLAG  equ 80h
SCAN_UP_EXT    equ 0C8h
SCAN_LEFT_EXT  equ 0CBh
SCAN_RIGHT_EXT equ 0CDh
SCAN_DOWN_EXT  equ 0D0h
BIOS_SCAN_UP    equ 48h
BIOS_SCAN_LEFT  equ 4Bh
BIOS_SCAN_RIGHT equ 4Dh
BIOS_SCAN_DOWN  equ 50h
KEY_QUEUE_SIZE equ 16
KEY_QUEUE_MASK equ 0Fh
KEY_STATE_TABLE_BYTES  equ 256
KEY_STATE_REGION_BYTES equ KEY_STATE_TABLE_BYTES * 2

MSG_SECTOR     equ 0
MSG_BLOCK      equ 1
MSG_SHARD      equ 2
MSG_GATE       equ 3
MSG_HIT        equ 4
MSG_KILL       equ 5
MSG_PULSE      equ 6
MSG_NOPULSE    equ 7
MSG_SURGE      equ 8
MSG_TRAP       equ 9
MSG_RECHARGE   equ 10
MSG_SPOOF      equ 11

THREAT_NONE    equ 0
THREAT_NEAR    equ 1
THREAT_ELITE   equ 2

FEEDBACK_TICKS_MINOR    equ 5
FEEDBACK_TICKS_STANDARD equ 7
FEEDBACK_TICKS_MAJOR    equ 11

END_REVEAL_HEADLINE equ 2
END_REVEAL_BODY     equ 6
END_REVEAL_STATS    equ 13
END_REVEAL_PROMPT   equ 22

SFX_NONE      equ 0
SFX_SECTOR    equ 1
SFX_BLOCK     equ 2
SFX_SHARD     equ 3
SFX_GATE      equ 4
SFX_HIT       equ 5
SFX_KILL      equ 6
SFX_PULSE     equ 7
SFX_DRY       equ 8
SFX_SURGE     equ 9
SFX_TRAP      equ 10
SFX_RECHARGE  equ 11
SFX_WIN       equ 12
SFX_LOSE      equ 13

; Demo scripts are generated as [action, repeat-count] byte pairs and played
; through the normal pressed_* gameplay latches.
DEMO_ACTION_END   equ 0
DEMO_ACTION_WAIT  equ 1
DEMO_ACTION_LEFT  equ 2
DEMO_ACTION_RIGHT equ 3
DEMO_ACTION_UP    equ 4
DEMO_ACTION_DOWN  equ 5
DEMO_ACTION_PULSE equ 6

TILE_FLOOR        equ 0
TILE_WALL         equ 1
TILE_SHARD        equ 2
TILE_EXIT_LOCKED  equ 3
TILE_EXIT_OPEN    equ 4
TILE_SURGE        equ 5
TILE_TERMINAL     equ 6

MAP_W         equ 28
MAP_H         equ 15
MAP_SIZE      equ 420
MAP_PIXEL_X   equ 20
MAP_PIXEL_Y   equ 44
PLAY_MIN_X    equ 1
PLAY_MIN_Y    equ 1
PLAY_MAX_X    equ MAP_W - 2
PLAY_MAX_Y    equ MAP_H - 2

START_X       equ 2
START_Y       equ 13
EXIT_COL      equ 25
EXIT_ROW      equ 1

TOTAL_SECTORS     equ 3
START_SHIELDS     equ 5
START_PULSES      equ 3
MAX_PULSES        equ 5
SPOOF_TURNS       equ 3
ENEMY_SPAWN_STEP  equ 2
ENEMY_SPAWN_BASE  equ 3
PULSE_RADIUS         equ 1
PULSE_RECHARGE_KILLS equ 2
SURGE_START_SECTOR   equ 2
SURGE_PLAYER_DAMAGE  equ 1
NEAR_THREAT_DISTANCE equ 1
ELITE_THREAT_DISTANCE equ 4

MAX_ENEMIES   equ 10
ENEMY_ALIVE   equ 0
ENEMY_X       equ 1
ENEMY_Y       equ 2
ENEMY_KIND    equ 3
ENEMY_SIZE    equ 4
ENEMY_RUSHER  equ 0
ENEMY_FLANKER equ 1
ENEMY_WARDEN  equ 2
SHARD_COUNT   equ 4
SHARD_POOL_COUNT equ 6

; Mastery scoring stays secondary to survival: most points come from core play,
; while a few sector-end bonuses reward cleaner and more efficient runs.
SCORE_SHARD_POINTS          equ 100
SCORE_KILL_POINTS           equ 30
SCORE_TRAP_BONUS            equ 40
SCORE_CHAIN_STEP            equ 25
SCORE_NO_HIT_BONUS          equ 120
SCORE_EFFICIENT_PULSE_BONUS equ 60
SCORE_EFFICIENT_PULSE_LIMIT equ 1
SCORE_FAST_CLEAR_BASE       equ 120
SCORE_FAST_CLEAR_STEP       equ 4
SCORE_WIN_SHIELD_BONUS      equ 25
SCORE_WIN_PULSE_BONUS       equ 15
SCORE_RANK_S_THRESHOLD      equ 2200
SCORE_RANK_A_THRESHOLD      equ 1800
SCORE_RANK_B_THRESHOLD      equ 1400
SCORE_RANK_C_THRESHOLD      equ 1000

SAFE_X_MAX    equ 6
SAFE_Y_MIN    equ 10

; Phase-1 asset banks load into a separate conventional-memory segment so
; stage two can keep its original 64 KiB boot contract unchanged.
MAP_BANK_SEG   equ 7000h
PRESENT_BANK_SEG equ 7800h
BACKBUFFER_SEG equ 9000h
VGA_SEG        equ 0A000h

; Phase-2 presentation banners are fixed-size banked bitmaps so scenes can
; use richer art without adding more bulky static data to stage two.
; Banked presentation assets are fixed-size 64x24 transparent bitmaps. They
; are currently rendered through a shared 2x scene blitter so the bank can grow
; without changing the in-memory art format or boot/runtime contract.
PRESENT_BANNER_W     equ 64
PRESENT_BANNER_H     equ 24
PRESENT_BANNER_SCALE equ 2

PAL_BLACK      equ 0
PAL_BG0        equ 1
PAL_BG1        equ 2
PAL_PANEL      equ 3
PAL_PANEL2     equ 4
PAL_CYAN       equ 5
PAL_CYAN2      equ 6
PAL_WHITE      equ 7
PAL_AMBER      equ 8
PAL_RED        equ 9
PAL_RED2       equ 10
PAL_WALL       equ 11
PAL_WALL2      equ 12
PAL_FLOOR      equ 13
PAL_FLOOR2     equ 14
PAL_PLAYER     equ 15
PAL_ENEMY      equ 16
PAL_GATE       equ 17
