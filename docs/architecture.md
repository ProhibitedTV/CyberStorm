# CyberStorm Architecture

CyberStorm is a single-segment 16-bit real-mode game that boots directly from a floppy image. There is no DOS, filesystem, or kernel underneath it. The sections below call out the contracts that make the current boot flow and runtime work.

## 1. Boot And Load Contract

1. The BIOS loads the first floppy sector to `0000:7C00` and enters [src/boot.asm](../src/boot.asm).
2. The boot sector reads `GAME_SECTORS` sectors starting at floppy sector `2` into physical address `0x10000` (`1000:0000`).
3. The boot sector far-returns to `1000:0000`.
4. [src/game.asm](../src/game.asm) therefore must keep executable code at offset `0`, which is why the file begins with `jmp start`.

Practical consequences:

- Stage two must remain a flat binary that starts immediately after the boot sector in the image.
- Stage two must fit inside one 64 KiB segment. The build validates this because the bootloader never updates `ES` while reading.
- The bootloader clears the direction flag and stage two relies on that for `lodsb`, `stosb`, and `movsb`-based code.
- Stage two inherits the boot stack set by the bootloader. Today that means `SS:SP = 0000:7C00` remains live after the far jump.

## 2. Memory And Segment Layout

| Region | Purpose | Notes |
| --- | --- | --- |
| `0000:0000-0000:03FF` | Interrupt vector table | Left under BIOS ownership in the default runtime. |
| `0000:0400-0000:04FF` | BIOS data area | Must remain untouched. |
| `0000:7C00` downward | Active stack | Created by the boot sector and still used by stage two and the keyboard ISR. |
| `1000:0000` upward | Stage two code + data | `DS` is set to `CS` on entry and the whole game assumes one shared segment. |
| `9000:0000` | Backbuffer | 64,000-byte linear framebuffer used before presenting to VGA. |
| `A000:0000` | VGA mode `13h` framebuffer | Final 320x200x8 output. |

Register assumptions that matter:

- `DS = CS` before any stage-two code touches globals.
- `ES = BACKBUFFER_SEG` for most rendering helpers.
- String operations assume `DF = 0`.
- The default runtime leaves BIOS keyboard services installed and polls `INT 16h` once per frame.

## 3. Stage-Two Composition

[src/game.asm](../src/game.asm) is the composition root. It is not a normal linker entrypoint; it is the literal byte sequence loaded by the boot sector. Module ordering only matters at a few boundaries:

- The first byte must remain executable because boot jumps to offset `0`.
- [src/game/state.asm](../src/game/state.asm) owns the global state layout.
- [src/game/art.asm](../src/game/art.asm) and [src/game/maps.asm](../src/game/maps.asm) are data-only tails of the flat image.

## 4. Core State Layout

The runtime state in [src/game/state.asm](../src/game/state.asm) is grouped like this:

- Frontend/game mode state: `game_state`, `sector_num`, resources, player position, exit position, RNG, frame timing.
- Input latches: `pressed_*`, `any_key_pending`, and keyboard debug counters.
- Rendering scratch: text and rectangle temporaries reused by draw routines.
- World data: `enemies` and `map_tiles`.
- Lookup tables and strings: row offsets, message/template tables, UI text.

Important layout contracts:

- `enemies` is a packed table of `MAX_ENEMIES` records, each `[alive, x, y]`.
- `map_tiles` is a linear `MAP_W * MAP_H` tile buffer.
- `key_down` and `key_pressed` must stay adjacent because reset code clears them as one contiguous region.
- `map_row_offsets` must stay synchronized with `MAP_W`, because `map_index` trusts the table instead of multiplying at runtime.
- `template_table` is indexed with `sector_num - 1`, so its entry count must match `TOTAL_SECTORS`.

## 5. Update, Input, And Render Flow

The main loop lives in [src/game/main.asm](../src/game/main.asm):

1. Wait for the BIOS tick count to advance.
2. Update frontend-only timers such as the splash timeout.
3. Render the current frame.
4. Consume input for the current `game_state`.

That ordering is intentional: non-playing screens are drawn first, then keypresses move the runtime into the next state for the following frame.

Input flow:

- [src/game/input.asm](../src/game/input.asm) polls BIOS keyboard services through `INT 16h`.
- Each frame drains the BIOS key queue and latches recognized controls into `pressed_enter`, `pressed_w`, and so on.
- The gameplay loop consumes the `pressed_*` latches directly.
- The older raw IRQ1 hook is still present as a legacy path, but it is not the default runtime behavior.

Render flow:

- [src/game/render/scenes.asm](../src/game/render/scenes.asm) selects the scene for the current `game_state`.
- The frame always renders into `BACKBUFFER_SEG`.
- [src/game/render/framebuffer.asm](../src/game/render/framebuffer.asm) waits for vertical blank, then copies the backbuffer to `A000:0000`.
- Primitive draw helpers compute offsets into whatever segment is currently loaded into `ES`.

## 6. Map, Tile, And Entity Conventions

Map/tile rules:

- The logical map is `28 x 15`.
- Playable movement stays inside the interior rectangle `x = 1..26`, `y = 1..13`.
- Tile IDs are semantic: floor, wall, shard, locked exit, open exit.
- Sector template source maps are ASCII and only `#` is treated as a wall. Every other byte becomes floor before dynamic objects are placed.

Render conventions:

- Each logical tile is currently rendered as an `8 x 8` bitmap.
- `MAP_PIXEL_X` / `MAP_PIXEL_Y` anchor the tilemap inside the VGA frame.
- Player and enemy sprites are drawn after tiles, so they visually sit on top of the map.

Entity rules:

- Enemy records use `[alive, x, y]`.
- Player movement or EMP usage sets `action_taken`; only then do hunters get a responding turn.
- Hunters move greedily toward the player, trying horizontal progress before vertical progress.

## 7. Sector Progression And Gameplay Rules

The gameplay runtime in [src/game/gameplay.asm](../src/game/gameplay.asm) is intentionally small and deterministic:

- A new run starts in sector `1` with `START_SHIELDS` shield pips and `START_PULSES` EMP charges.
- Every sector contains `SHARD_COUNT` shards. Collecting the last one opens the exit.
- Entering an open exit advances to the next sector; clearing the final sector switches to `STATE_WIN`.
- Sector transitions refill one EMP charge up to `MAX_PULSES`.
- Enemy count is `sector_num * ENEMY_SPAWN_STEP + ENEMY_SPAWN_BASE`.
- The lower-left safe zone (`SAFE_X_MAX`, `SAFE_Y_MIN`) is excluded from random enemy placement.

## 8. Extension Checklist

Before changing the runtime, keep these contracts intact:

- Do not remove the executable jump at byte `0` of stage two.
- Do not move stage two out of the single load segment unless the bootloader changes too.
- Do not change `SS:SP`, `DS`, or `DF` assumptions without auditing every string op and interrupt path.
- Do not reorder `key_down` / `key_pressed` without updating the reset routine.
- Do not change enemy record width or field order without updating gameplay and render code together.
- Do not change map dimensions, row offsets, or tile size in only one module.
- Do not add OS-style dependencies; the current runtime assumes BIOS + raw hardware only.
