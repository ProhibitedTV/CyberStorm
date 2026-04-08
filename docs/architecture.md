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
| `7000:0000` | Map bank | Read-only authored map payload loaded by stage two after boot. |
| `7800:0000` | Presentation bank | Read-only scene-kit payload for splash, title, attract/demo, sector-entry, and end screens. |
| `8000:0000` | Geometry bank | Read-only low-poly scene, prop, actor, and gameplay-kit payload for the 3D renderer. |
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
- `generated_presentation_content.inc` is build output, not source. It gives scenes the offsets of the banked presentation scene kit.
- `generated_geometry.inc` is build output, not source. It gives the 3D renderer scene/camera tables, scene-group timelines, material FX tables, gameplay-kit tables, and geometry-bank offsets/counts.
- `audio_config.inc` is build output, not source. It makes the release audio contract explicit before [src/game/audio.asm](../src/game/audio.asm) is assembled.
- [src/game/render/3d_math.asm](../src/game/render/3d_math.asm), [src/game/render/3d_raster.asm](../src/game/render/3d_raster.asm), [src/game/render/3d_scene.asm](../src/game/render/3d_scene.asm), and [src/game/render/3d_gameplay.asm](../src/game/render/3d_gameplay.asm) are the current software-3D render path. Scenes now support authored camera timelines, scene-group visibility windows, group transforms, and face-level pulse/glint tracks from the geometry bank, while gameplay compiles the live tile map into a transient room mesh, chooses camera-relative wall bands for the active chase view, and renders props/actors in world space.
- [src/game/state.asm](../src/game/state.asm) owns the global state layout.
- [src/game/art.asm](../src/game/art.asm) is the visual-data wrapper and includes the build-generated sprite/tile bitmap include before the hand-authored palette/font data.
- [src/game/state.asm](../src/game/state.asm) now includes generated sector metadata/rule tables from the content pipeline.
- [src/game/state.asm](../src/game/state.asm) also includes generated attract/demo scripts from the content pipeline.
- [src/game/banks.asm](../src/game/banks.asm) owns the minimal BIOS disk-read helper for post-boot asset banks.
- [src/game/maps.asm](../src/game/maps.asm) is now documentation only; the authored map pool lives in a bank payload instead of stage two.
- [src/game/audio.asm](../src/game/audio.asm) keeps the playback logic in-source, but includes generated theme data from the content pipeline.
- `build\audio_config.inc` now compiles the runtime in `MUSIC` mode by default. `-SfxOnly` is the explicit quiet build profile when you want one-shot effects without looping themes.

## 4. Core State Layout

The runtime state in [src/game/state.asm](../src/game/state.asm) is grouped like this:

- Frontend/game mode state: `game_state`, `sector_num`, resources, player position, exit position, RNG, frame timing, attract/demo timers.
- Input state: `pressed_*`, `any_key_pending`, raw BIOS debug fields, and the semantic frontend-action/debug counters.
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
- `frontend_action`, `frontend_last_action`, and `frontend_event_count` are the small semantic bridge between BIOS keys and the splash/title/outro state machine. They are also what the debug overlay uses to diagnose "input vs freeze" reports.
- `verify_mode`, `verify_frontend_scenario`, and `verify_frontend_*` reuse the shared PASS/FAIL verify scenes for both replay verification and debug-only frontend verification.
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
- Each frame drains the BIOS key queue, records the last raw scan/ASCII pair, derives one semantic frontend action, and also latches recognized gameplay controls into `pressed_enter`, `pressed_w`, and so on.
- In supported release builds, `Enter` / `Space` / `WASD` / arrows start from splash/title, `Enter` / `Space` continue from win/lose/verify scenes, `R` is the in-run reset key, and attract-mode takeover accepts the same supported frontend/gameplay controls rather than every raw BIOS key.
- The gameplay loop consumes the `pressed_*` latches directly.
- Attract/demo playback does not bypass gameplay. It injects the same `pressed_*` latches the live game uses, so replayed turns stay deterministic and exercise the normal rules.
- The older raw IRQ1 hook is still present as a legacy path, but it is not the default runtime behavior.

Render flow:

- [src/game/render/scenes.asm](../src/game/render/scenes.asm) selects the scene for the current `game_state`.
- In the default release build, splash/title/sector-entry/end scenes go through the grouped flat-shaded 3D path, and gameplay now uses the room-mesh 3D renderer with a chase-style camera plus sector-specific viewport mood fills. `DEBUG_SCENE_RENDER_MODE = 0` plus `DEBUG_GAMEPLAY_RENDER_MODE = 0` keep the older 2D scene/gameplay implementation available as a compile-time oracle.
- The frame always renders into `BACKBUFFER_SEG`.
- [src/game/render/framebuffer.asm](../src/game/render/framebuffer.asm) waits for vertical blank, then copies the backbuffer to `A000:0000`.
- Primitive draw helpers compute offsets into whatever segment is currently loaded into `ES`.

## 6. Map, Tile, And Entity Conventions

Map/tile rules:

- The logical map is `28 x 15`.
- Playable movement stays inside the interior rectangle `x = 1..26`, `y = 1..13`.
- Tile IDs are semantic: floor, wall, shard, locked exit, open exit, surge, terminal.
- Sector template source maps are ASCII and only `#` is treated as a wall. Every other byte becomes floor before dynamic objects are placed.
- The authored sector source now lives outside assembly in `assets\sectors.psd1`, attract scripts live in `assets\demos.psd1`, music themes live in `assets\music.psd1`, and banked presentation assets live in `assets\presentation.psd1`. These all build into reviewable `generated_*.inc` files before MASM runs.
- Each sector now owns a small authored layout family rather than one fixed map. Sector 1 favors open pursuit lanes, sector 2 favors chambers and hinge corridors, and sector 3 favors tighter braided escape routes.
- Each authored map now also defines a `Scenario` block with a short name, sector-entry copy, and a fixed 6-tile shard candidate pool.
- Each authored map can also define a small optional `Anchors` block for terminals, surges, and explicit enemy kinds. Runtime sector loading copies the ASCII layout first, places those anchors, then chooses `SHARD_COUNT` unique shards from the authored scenario pool, then random-fills any remaining terminal, surge, and enemy budget.
- Spoof terminals are placed dynamically after the authored layout is copied. They are single-use tiles that redirect hunter targeting toward the exit for a short fixed window.

Render conventions:

- The legacy 2D oracle still renders each logical tile as an `8 x 8` bitmap anchored by `MAP_PIXEL_X` / `MAP_PIXEL_Y`.
- The default gameplay path now compiles floor slabs plus camera-relative wall-edge runs into a transient low-poly room mesh, then layers sector-specific gate/terminal/surge/shard meshes plus promoted runner/warden meshes into the gameplay viewport. Gate-lane emphasis is now carried mainly by kit materials, props, and world-space glow rather than extra structural room faces.
- Dynamic tile changes mark the room mesh dirty through `set_tile`, so shard pickups, terminal use, surges, and gate-open transitions rebuild the room view without changing game rules.

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

## 8. Asset Banks

CyberStorm now has three narrow post-boot bank paths:

- The build appends `cyberstorm-map-bank.bin`, `cyberstorm-presentation-bank.bin`, and `cyberstorm-geometry-bank.bin` after stage two on the floppy image.
- `generated_bank_layout.inc` records each bank's starting LBA, size in sectors, and byte count.
- [src/game/banks.asm](../src/game/banks.asm) loads the map bank into `MAP_BANK_SEG`, the presentation bank into `PRESENT_BANK_SEG`, and the geometry bank into `GEOMETRY_BANK_SEG` during `start`, before VGA mode is enabled.
- Gameplay reads map templates through `template_offset_table` offsets into the map bank instead of embedding every map into stage two.
- Splash/title/win/lose scenes, the attract HUD, and sector-entry presentation all read fixed-size 64x24 transparent assets from the presentation bank through generated offset constants.
- The banked 3D scene renderer copies the active scene groups out of the geometry bank into bounded scratch buffers in [src/game/state.asm](../src/game/state.asm), applies group motion/yaw based on the current timeline tick, then projects and painter-sorts them inside stage two.
- The gameplay 3D renderer does not use the geometry bank for room slabs. It compiles the active map into transient floor/wall geometry in stage two, reuses the same projection/raster core, and then pulls kit-selected prop/actor meshes from the geometry bank while keeping the 2D gameplay renderer available behind the debug render switch.
- Room-budget rescue currently comes from compiling only the structural wall bands that matter to the active chase-camera orientation. That keeps the transient room buffer bounded without changing map logic, authored scenarios, or prop placement.

Current scope and limits:

- Banks are read-only.
- Each bank currently loads into one destination segment, so each bank must fit within 64 KiB padded to sectors.
- The bank loader assumes the same `18 sectors/track, 2 heads` floppy geometry as [src/boot.asm](../src/boot.asm).
- The runtime currently loads both banks up front during `start`, but the build/report structure is still set up so later banks can be added without changing the boot sector.

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
- authored anchor bounds, occupancy, floor-tile, and enemy-safe-zone rules
- scenario shard-pool bounds, uniqueness, anchor overlap, and spread
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

## 12. Deterministic Replay Harness

CyberStorm also uses its authored attract demos as deterministic gameplay smoke tests through [scripts/replay-harness.ps1](../scripts/replay-harness.ps1).

The important contract is:

- [assets/demos.psd1](../assets/demos.psd1) is now both presentation content and a replay-test source of truth.
- Each demo still defines `Name`, `StartSector`, `Seed`, and `Steps`.
- Each demo also carries an `Expected` block describing the replay end state that should result from the current rules and content.
- The replay harness simulates the same seeded sector load, map selection, authored-anchor placement, scenario shard-pool selection, movement, EMP use, hunter turns, spoof windows, surge hits, exits, and scoring that the runtime uses.

This is intentionally lightweight rather than emulator-driven. It is meant to catch "we changed a rule and the demos no longer land where we think they do" before someone boots a VM.

The build writes the results to `build\cyberstorm-replay-report.txt`. When gameplay changes are intentional, that report includes suggested replacement `Expected` blocks so the demo source can be updated reviewably.

## 13. Frontend Verification

CyberStorm now has a dedicated debug-only frontend verification lane in [scripts/frontend-verify.ps1](../scripts/frontend-verify.ps1).

Its contract is:

- it never changes the supported release image; verification is debug-only
- it does not depend on VirtualBox keyboard injection
- it boots synthetic frontend scenarios for `splash-to-title`, `title-to-start`, and `title-to-attract`
- the runtime injects semantic frontend events internally and then stops on shared `STATE_VERIFY_PASS` / `STATE_VERIFY_FAIL` scenes
- those scenes keep the same fixed marker geometry and signature-bit strips that the other verification lanes already use

The frontend verification signature is intentionally compact:

- low byte: observed `game_state`
- bit `8`: `demo_active`
- bit `9`: `run_start_enter_guard > 0`

That is enough to prove the terminal frontend state machine outcome without adding a separate result-screen format.

## 14. Headless VM Smoke Harness

CyberStorm also has a lightweight VirtualBox smoke lane in [scripts/vm-smoke.ps1](../scripts/vm-smoke.ps1).

Its contract is intentionally narrow:

- it only targets the workspace VirtualBox VM and current release floppy image
- it uses attract-mode timing instead of flaky key injection
- it proves the VM can boot far enough to reach the startup ident, title window, and later attract wait window
- it captures startup, title, and later smoke-window screenshots plus the active VBox log for post-failure inspection

The build can invoke this path with `-VmSmoke`, but it stays opt-in so normal builds do not require VirtualBox. The smoke artifacts are:

- `build\cyberstorm-vm-smoke-report.txt`
- `build\vm-smoke\cyberstorm-vm-smoke.png`
- `build\vm-smoke\cyberstorm-vm-smoke.log`

## 15. Runtime Replay Verification

CyberStorm now also has a debug-only runtime verification lane in [scripts/runtime-verify.ps1](../scripts/runtime-verify.ps1). This closes the loop between the host-side replay model and the actual booted game.

Its contract is:

- it never changes the supported release image; verification is debug-only
- it reuses the real attract/demo input path instead of faking gameplay in a renderer
- it relies on generated verification tables from `generated_runtime_verify.inc`, which come from the replay harness
- it stops on dedicated `STATE_VERIFY_PASS` / `STATE_VERIFY_FAIL` scenes instead of returning silently to title
- those scenes expose fixed marker geometry and 16-bit signature strips so the host can decode pass/fail without OCR

The runtime verification signature intentionally stays compact but meaningful. It mixes:

- `game_state`
- `sector_num`
- `current_template_index`
- player position
- shields, pulses, shards, kills, score
- sector mastery counters
- `spoof_timer`
- the current RNG word
- every enemy record `[alive, x, y, kind]`

That signature is computed after every consumed demo action and compared against the generated checkpoint table. A mismatch lands on the fail scene with both signatures visible.

## 16. Reproducible Showcase Capture

[scripts/capture-showcase.ps1](../scripts/capture-showcase.ps1) turns the deterministic demo/runtime-verification lanes into a public-facing artifact pipeline.

Its contract is:

- use the release VM smoke lane's startup-frame capture for the BitRiver branding shot
- use authored demo metadata from `assets\demos.psd1` for gameplay/hazard/elite-pressure capture roles
- use runtime verification pass/fail scenes for ending/technical proof shots
- write stable captures under `build\showcase\`
- let `build.ps1` rotate README screenshots from those deterministic captures when they are present

This keeps the README/gallery reproducible instead of depending on hand-captured incidental screenshots.
