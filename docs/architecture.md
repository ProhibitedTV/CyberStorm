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
- Stage two now captures the BIOS boot drive from `DL` on entry so it can read later asset-bank sectors without changing the bootloader handoff.

## 2. Memory And Segment Layout

| Region | Purpose | Notes |
| --- | --- | --- |
| `0000:0000-0000:03FF` | Interrupt vector table | Left under BIOS ownership in the default runtime. |
| `0000:0400-0000:04FF` | BIOS data area | Must remain untouched. |
| `0000:7C00` downward | Active stack | Created by the boot sector and still used by stage two and the keyboard ISR. |
| `1000:0000` upward | Stage two code + data | `DS` is set to `CS` on entry and the whole game assumes one shared segment. |
| `7000:0000` | Map bank | Phase-1 read-only payload loaded by stage two after boot. |
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
- `generated_bank_layout.inc` is build output, not source. It gives stage two the on-disk LBA/size contract for post-boot banks.
- [src/game/state.asm](../src/game/state.asm) owns the global state layout.
- [src/game/art.asm](../src/game/art.asm) is the visual-data wrapper and includes the build-generated sprite/tile bitmap include before the hand-authored palette/font data.
- [src/game/state.asm](../src/game/state.asm) now includes generated sector metadata/rule tables from the content pipeline.
- [src/game/state.asm](../src/game/state.asm) also includes generated attract/demo scripts from the content pipeline.
- [src/game/banks.asm](../src/game/banks.asm) owns the minimal BIOS disk-read helper for post-boot asset banks.
- [src/game/maps.asm](../src/game/maps.asm) is now documentation only; the authored map pool lives in a bank payload instead of stage two.
- [src/game/audio.asm](../src/game/audio.asm) keeps the playback logic in-source, but includes generated theme data from the content pipeline.

## 4. Core State Layout

The runtime state in [src/game/state.asm](../src/game/state.asm) is grouped like this:

- Frontend/game mode state: `game_state`, `sector_num`, resources, player position, exit position, RNG, frame timing, attract/demo timers.
- Input latches: `pressed_*`, `any_key_pending`, and keyboard debug counters.
- Rendering scratch: text and rectangle temporaries reused by draw routines.
- World data: `enemies` and `map_tiles`.
- Lookup tables and strings: row offsets, message/template tables, UI text.

Important layout contracts:

- `enemies` is a packed table of `MAX_ENEMIES` records, each `[alive, x, y, kind]`.
- `map_tiles` is a linear `MAP_W * MAP_H` tile buffer.
- `boot_drive` is initialized from `DL` at stage-two entry and must remain valid for any later `INT 13h` bank reads.
- `score_total`, `sector_score`, and `sector_score_table` back the mastery layer. The sector counters are reset per zone and the score table is meant to stay comparable on end screens.
- `spoof_timer` / `spoof_x` / `spoof_y` are gameplay state, not render scratch. Hunter AI reads them during enemy turns and effects/HUD read them during rendering.
- `title_idle_ticks` is frontend-only state for the attract timer. `demo_active`, `demo_action_*`, and `demo_script_ptr` drive scripted playback through the normal gameplay input path.
- `key_down` and `key_pressed` must stay adjacent because reset code clears them as one contiguous region.
- `map_row_offsets` must stay synchronized with `MAP_W`, because `map_index` trusts the table instead of multiplying at runtime.
- `template_offset_table` is a flat pool of byte offsets into the banked ASCII layout payload at `MAP_BANK_SEG`. `sector_template_start` and `sector_template_count` define which slice belongs to each 1-based sector.
- The generated sector-rule tables are the source for surge density, terminal density, enemy bonus, flanker threshold, warden threshold, and warden engage distance.

## 5. Update, Input, And Render Flow

The main loop lives in [src/game/main.asm](../src/game/main.asm):

1. Wait for the BIOS tick count to advance.
2. Poll BIOS keyboard input into `pressed_*` latches.
3. Update frontend-only timers such as the splash timeout and title attract timer.
4. Advance timed feedback and audio state.
5. Render the current frame.
6. Consume input for the current `game_state`.

That ordering is intentional: the frame reflects the freshly updated frontend/audio state, and then input moves the runtime into the next state for the following frame.

Input flow:

- [src/game/input.asm](../src/game/input.asm) polls BIOS keyboard services through `INT 16h`.
- Each frame drains the BIOS key queue and latches recognized controls into `pressed_enter`, `pressed_w`, and so on.
- The gameplay loop consumes the `pressed_*` latches directly.
- Attract/demo playback does not bypass gameplay. It injects the same `pressed_*` latches the live game uses, so replayed turns stay deterministic and exercise the normal rules.
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
- Tile IDs are semantic: floor, wall, shard, locked exit, open exit, surge, terminal.
- Sector template source maps are ASCII and only `#` is treated as a wall. Every other byte becomes floor before dynamic objects are placed.
- The authored sector source now lives outside assembly in `assets\sectors.psd1`, and attract scripts live in `assets\demos.psd1`. Both build into reviewable `generated_*.inc` files before MASM runs.
- Each sector now owns a small authored layout family rather than one fixed map. Sector 1 favors open pursuit lanes, sector 2 favors chambers and hinge corridors, and sector 3 favors tighter braided escape routes.
- Spoof terminals are placed dynamically after the authored layout is copied. They are single-use tiles that redirect hunter targeting toward the exit for a short fixed window.

Render conventions:

- Each logical tile is currently rendered as an `8 x 8` bitmap.
- `MAP_PIXEL_X` / `MAP_PIXEL_Y` anchor the tilemap inside the VGA frame.
- Player and enemy sprites are drawn after tiles, so they visually sit on top of the map.

Entity rules:

- Enemy records use `[alive, x, y, kind]`.
- Player movement or EMP usage sets `action_taken`; only then do hunters get a responding turn.
- Rusher hunters move greedily toward the player, flankers prioritize the larger gap axis, and wardens bias toward the exit until the player gets close.

## 7. Sector Progression And Gameplay Rules

The gameplay runtime in [src/game/gameplay.asm](../src/game/gameplay.asm) is intentionally small and deterministic:

- A new run starts in sector `1` with `START_SHIELDS` shield pips and `START_PULSES` EMP charges.
- Every sector contains `SHARD_COUNT` shards. Collecting the last one opens the exit.
- Some sectors also spawn spoof terminals. Stepping onto one spends the tile, starts a short spoof window, and reroutes hunters toward the exit instead of the player.
- Entering an open exit advances to the next sector; clearing the final sector switches to `STATE_WIN`.
- Sector transitions refill one EMP charge up to `MAX_PULSES`.
- Enemy count is `sector_num * ENEMY_SPAWN_STEP + ENEMY_SPAWN_BASE`.
- The lower-left safe zone (`SAFE_X_MAX`, `SAFE_Y_MIN`) is excluded from random enemy placement.

## 8. Asset Banks (Phase 1)

CyberStorm now has one narrow post-boot bank path:

- The build appends `cyberstorm-map-bank.bin` after stage two on the floppy image.
- `generated_bank_layout.inc` records that bank's starting LBA, size in sectors, and byte count.
- [src/game/banks.asm](../src/game/banks.asm) loads the bank into `MAP_BANK_SEG` during `start`, before VGA mode is enabled.
- Gameplay reads map templates through `template_offset_table` offsets into that bank instead of embedding every map into stage two.

Current scope and limits:

- Banks are read-only.
- Each bank currently loads into one destination segment, so each bank must fit within 64 KiB padded to sectors.
- The bank loader assumes the same `18 sectors/track, 2 heads` floppy geometry as [src/boot.asm](../src/boot.asm).
- Phase 1 only loads the map bank, but the build/report structure is now set up so later banks can be added without changing the boot sector.

## 9. Extension Checklist

Before changing the runtime, keep these contracts intact:

- Do not remove the executable jump at byte `0` of stage two.
- Do not move stage two out of the single load segment unless the bootloader changes too.
- Do not change the stage-two bank helper's floppy geometry unless [src/boot.asm](../src/boot.asm) and the build layout logic change with it.
- Do not change `SS:SP`, `DS`, or `DF` assumptions without auditing every string op and interrupt path.
- Do not reorder `key_down` / `key_pressed` without updating the reset routine.
- Do not change enemy record width or field order without updating gameplay and render code together.
- Do not change map dimensions, row offsets, or tile size in only one module.
- Do not add OS-style dependencies; the current runtime assumes BIOS + raw hardware only.

## 10. Build-Time Balance Harness

CyberStorm now has a build-time balance harness in [scripts/balance-harness.ps1](../scripts/balance-harness.ps1). This is not part of the runtime contract, but it is part of the content-authoring contract.

The harness reads the authored sector source plus gameplay constants, then validates:

- map reachability from start to exit
- dynamic placement slack for shards, surges, terminals, and enemies
- safe-zone spawn constraints
- sector enemy/rule sanity
- deterministic spawn behavior across a fixed seed sweep

The build surfaces the results in `build\cyberstorm-balance-report.txt` and echoes a summary into the main build report. When gameplay constants or authored sector content change, this harness is the fastest way to catch balance regressions before a full VM boot.

## 11. Artifact Regression Harness

CyberStorm also has a binary-level regression harness in [scripts/regression-harness.ps1](../scripts/regression-harness.ps1). This one is aimed at the fragile assembly/runtime edges rather than game balance.

It validates the shipped artifacts after the image is built:

- `cyberstorm-boot.bin` is exactly one sector and still ends in `0x55AA`
- `boot_config.inc` still agrees with the actual stage-two sector count
- stage two still fits the single-segment load contract and begins with an intentional offset-0 handoff
- `cyberstorm.img` and `cyberstorm.vfd` are byte-identical
- stage two and the map bank occupy the expected LBA ranges inside the image
- sector padding and the unused floppy tail are zero-filled
- `boot.lst` and `game.lst` are present for follow-up inspection

The build runs this automatically and writes the results to `build\cyberstorm-regression-report.txt`. When low-level assembly changes land, this harness is the quickest way to prove the floppy contract still matches the documentation.
