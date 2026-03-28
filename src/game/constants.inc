STATE_TITLE    equ 0
STATE_PLAYING  equ 1
STATE_WIN      equ 2
STATE_LOSE     equ 3
STATE_SPLASH   equ 4

SPLASH_DURATION equ 54

SCREEN_W      equ 320
SCREEN_H      equ 200
SCREEN_PIXELS equ SCREEN_W * SCREEN_H
SCREEN_WORDS  equ SCREEN_PIXELS / 2

TILE_SIZE     equ 8
TILE_SHIFT    equ 3

KEY_ENTER      equ 0Dh
SCAN_ENTER     equ 1Ch
SCAN_W         equ 11h
SCAN_A         equ 1Eh
SCAN_S         equ 1Fh
SCAN_D         equ 20h
SCAN_C         equ 2Eh
SCAN_EXT_FLAG  equ 80h
SCAN_UP_EXT    equ 0C8h
SCAN_LEFT_EXT  equ 0CBh
SCAN_RIGHT_EXT equ 0CDh
SCAN_DOWN_EXT  equ 0D0h
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

TILE_FLOOR        equ 0
TILE_WALL         equ 1
TILE_SHARD        equ 2
TILE_EXIT_LOCKED  equ 3
TILE_EXIT_OPEN    equ 4
TILE_SURGE        equ 5

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
ENEMY_SPAWN_STEP  equ 2
ENEMY_SPAWN_BASE  equ 3
PULSE_RADIUS         equ 1
PULSE_RECHARGE_KILLS equ 2
SURGE_START_SECTOR   equ 2
SURGE_PLAYER_DAMAGE  equ 1

MAX_ENEMIES   equ 10
ENEMY_ALIVE   equ 0
ENEMY_X       equ 1
ENEMY_Y       equ 2
ENEMY_SIZE    equ 3
SHARD_COUNT   equ 4

SAFE_X_MAX    equ 6
SAFE_Y_MIN    equ 10

BACKBUFFER_SEG equ 9000h
VGA_SEG        equ 0A000h

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
