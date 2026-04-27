# CyberStorm

> No OS. No shell. Just the realm.
>
> CyberStorm is a bootable x86 3D adventure slice and a compact bare-metal engine project. The current mainline build emits a BIOS hard-disk image, enters a hand-written boot sector plus tiny bootstrap, prepares an enhanced VBE present path, and then hands off into the legacy real-mode stage-two runtime without DOS or any host runtime.

![CyberStorm hero](build/readme-shot-1.png)

| Built for | Boots from | Video | Runtime |
| --- | --- | --- | --- |
| BIOS x86 + Oracle VirtualBox | Raw HDD image (`.img`) | VBE `640x480x16` present path over a `320x240` gameplay surface with exact 2x presentation when active, plus legacy VGA fallback | i386-targeted boot chain + legacy 16-bit stage-two runtime |

## Key Features

### For Players

- **A full four-district arcade run.** The mainline route now pushes through `Subgrid Ingress`, `Switchyard Spine`, `Thermal Foundry`, and `Apex Vault` as one authored breach campaign.
- **Continuous bare-metal movement.** The release path now supports real-time run, turn, jump, glide, charge, and flame controls instead of the older move-once tactical loop.
- **Readable objective pressure.** Each district keeps the same simple progression spine: secure relays, take the keycard branch, and force the gate before the storm closes.
- **Readable 3D creature pressure.** Small charge targets, flame-vulnerable foes, and a larger patrol threat all render as low-poly world actors instead of flat tokens.
- **A real finale and replay hook.** `Apex Vault` now plays like a climax, and the clear screen turns into a campaign debrief with rank, district breakdown, and the next score target.

### For Engine People

- **A real boot path.** The build emits a bootable BIOS disk image, not a host app wrapped in a fake shell.
- **A compact but structured runtime.** Stage two stays inside a documented single-segment contract while still using modular render, gameplay, audio, and data layers.
- **Generated content tooling.** Sprites, banked presentation assets, low-poly scene geometry, sectors, rules, demos, and music come from readable source files that generate MASM-friendly data at build time.
- **A real software 3D render path.** Splash, title, sector-entry cards, end screens, and now live gameplay all run through a flat-shaded low-poly renderer, while `-DebugRender2D` still keeps the legacy 2D oracle available for parity work.
- **A PS1-style grouped scene system.** Splash, title, sector-entry, and end scenes now share the same dark-techno scene-group timeline path, so the BitRiver ident flows into the rest of the front end instead of feeling like a one-off effect.
- **Integrated low-poly world kits.** The gameplay view now uses authored adventure props, portal/switch/hazard meshes, world-space gems, and low-poly actor meshes instead of treating 3D as a front-end-only trick.
- **A release-first adventure path.** The default boot now goes straight into the real-time realm slice, while the older tactical path remains available behind debug/verification builds as a compatibility oracle.
- **Disciplined validation.** The build enforces boot/image layout, generated content shape, deterministic debug options, and a lightweight balance harness.

## Visual Gallery

The README gallery is intentionally small. The build maintains three verified public slots so the page stays curated instead of turning into a screenshot dump, and it preserves the last verified set when local capture is unavailable.

| Splash / Identity | Realm Beauty | Gameplay Action |
| --- | --- | --- |
| ![CyberStorm splash shot](build/readme-shot-1.png) | ![CyberStorm gameplay shot](build/readme-shot-2.png) | ![CyberStorm payoff shot](build/readme-shot-3.png) |
| The first shot should be the BitRiver splash lockup so the project's first impression is also the gallery's first impression. | The middle shot should sell a district setpiece, skyline massing, and the route the player is about to commit to. | The last shot should show the runner, warden pressure, and final objective state in one readable action frame. |

The gallery now comes only from the verified showcase manifest under [build/showcase/](build/showcase), not from ad hoc filename heuristics or incidental screenshots.

## How It Works

CyberStorm is small enough to inspect, but it is no longer a single opaque assembly file. The diagrams below show the project as it exists in the current build.

### Boot Path

![CyberStorm boot flow](docs/readme/boot-flow.svg)

The boot sector at `LBA 0` loads a tiny bootstrap, the bootstrap loads stage two plus the bank payloads, probes VBE, and writes a handoff block, and then stage two continues through the gameplay runtime. The exact current LBA ranges live in [build/cyberstorm-build-report.txt](build/cyberstorm-build-report.txt).

### Runtime Layout

![CyberStorm memory map](docs/readme/memory-map.svg)

![CyberStorm runtime modules](docs/readme/runtime-modules.svg)

The runtime keeps BIOS-owned low memory untouched, inherits the boot stack at `0000:7C00`, runs stage two from a single segment at `1000:0000`, stages maps/presentation/geometry in conventional-memory banks, and now presents through an enhanced VBE linear-framebuffer path when the bootstrap handoff succeeds.

### Asset And Content Pipeline

![CyberStorm asset pipeline](docs/readme/asset-pipeline.svg)

[assets/visuals.psd1](assets/visuals.psd1), [assets/presentation.psd1](assets/presentation.psd1), [assets/geometry.psd1](assets/geometry.psd1), [assets/sectors.psd1](assets/sectors.psd1), [assets/demos.psd1](assets/demos.psd1), and [assets/music.psd1](assets/music.psd1) are the readable source of truth. [scripts/build.ps1](scripts/build.ps1) turns them into generated includes plus banked map, presentation, and geometry payloads, and the sector source now includes hybrid authored encounter anchors, named breach scenarios, and 6-point shard candidate pools on top of map/rule data.

## Quickstart

### Build The Release Image

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\build.ps1
```

### Boot It In VirtualBox

The supported path is the included deployment script, which refreshes a VirtualBox-ready disk from [build/cyberstorm.img](build/cyberstorm.img):

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\deploy-vm.ps1
```

If you wire a VM manually, use a BIOS VM and attach a hard disk derived from [build/cyberstorm.img](build/cyberstorm.img), not the retired floppy artifact path.

### Use The Included Workspace VM

Register the reusable VM:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\deploy-vm.ps1
```

Launch it:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\start-vm.ps1
```

If you leave the title screen alone for a few seconds, CyberStorm now auto-starts an authored attract/demo run. Press `Enter`, `Space`, `WASD`, arrows, `C`, or `R` during the demo to jump into a fresh live run.

### Release Controls

- `Enter`, `Space`, `WASD`, or arrow keys: start from splash/title
- `Enter` or `Space`: replay from win/lose or return from verify screens
- `W` / `S`: move forward and back
- `A` / `D`: turn left and right
- Arrow keys: movement/turn mirror
- `Space`: jump, then glide while held during descent
- `Left Shift`: charge
- `C`: flame
- `R`: restart the current run

## Technical Facts

This section is intentionally stable. Exact byte counts, LBA ranges, and generated-content totals now live in the current [build/cyberstorm-build-report.txt](build/cyberstorm-build-report.txt) instead of being hardcoded here.

| Fact | Project contract |
| --- | --- |
| Boot path | Boot sector at `LBA 0`, tiny bootstrap immediately after it, then stage two and the asset packs follow on the BIOS HDD image. |
| Stage-two contract | Stage two still fits a single `64 KiB` real-mode load segment, with exact current headroom reported by the build. |
| Banked payloads | Code, map, presentation, geometry, and texture payloads load into `2000:0000`, `2800:0000`, `3000:0000`, `3800:0000`, `4000:0000`, and `5000:0000`. |
| Public gallery | `title`, `beauty`, and `action` README slots are sourced from the verified showcase manifest under [build/showcase/](build/showcase). |
| Validation stack | Build, balance, replay, regression, frontend verify, VM smoke, runtime verify, and showcase capture all write reviewable reports. |
| Release defaults | `MUSIC` audio policy, grouped low-poly frontend scenes, the stable reference gameplay 3D path by default, the experimental machine path only when explicitly requested, and an enhanced VBE present path that displays the `320x240` gameplay surface at exact `2x` when the handoff marks it safe. |

## Why This Is A Strong AI-Assisted Development Example

CyberStorm is a good AI-assisted project for a specific reason: the repository gives automated iteration clear boundaries. The interesting part is not "AI wrote some assembly." The interesting part is that the repo makes it practical to use AI on a bare-metal codebase without letting that become reckless.

- **The source of truth is readable.** Visuals, presentation art, sector layouts, sector rules, demos, and music live in compact authored files instead of sprawling raw assembly data.
- **The runtime contracts are explicit.** [docs/architecture.md](docs/architecture.md) spells out the boot handoff, segment assumptions, memory map, state layout, and bank-loading rules.
- **The build enforces the dangerous constraints.** [scripts/build.ps1](scripts/build.ps1) validates boot-sector size, bootstrap size, the single-segment stage-two limit, bank layout, disk-image footprint, and generated content shape before writing the image.
- **Debugging can be reproduced.** Deterministic debug flags can force a known RNG seed, start in a chosen sector, and enable a compact overlay.
- **Balance changes get guardrails.** [scripts/balance-harness.ps1](scripts/balance-harness.ps1) runs static fairness checks and fixed-seed spawn sweeps before someone boots VirtualBox.
- **Design intent is written down.** [docs/sector-identity.md](docs/sector-identity.md) and [docs/enemy-drama.md](docs/enemy-drama.md) explain what sectors and enemies are supposed to feel like, not just how they are coded.

Repo artifacts that support that claim:

- [assets/visuals.psd1](assets/visuals.psd1), [assets/presentation.psd1](assets/presentation.psd1), [assets/sectors.psd1](assets/sectors.psd1), [assets/demos.psd1](assets/demos.psd1), and [assets/music.psd1](assets/music.psd1)
- [build/generated_art.inc](build/generated_art.inc), [build/generated_presentation_content.inc](build/generated_presentation_content.inc), [build/generated_sector_content.inc](build/generated_sector_content.inc), [build/generated_maps.inc](build/generated_maps.inc), [build/generated_demos.inc](build/generated_demos.inc), and [build/generated_music.inc](build/generated_music.inc)
- [docs/architecture.md](docs/architecture.md), [docs/sector-identity.md](docs/sector-identity.md), and [docs/enemy-drama.md](docs/enemy-drama.md)
- [scripts/build.ps1](scripts/build.ps1) and [scripts/balance-harness.ps1](scripts/balance-harness.ps1)
- [build/cyberstorm-build-report.txt](build/cyberstorm-build-report.txt) and [build/cyberstorm-balance-report.txt](build/cyberstorm-balance-report.txt)

## Build, Debug, And Validation

### Prerequisites

- Windows PowerShell
- MASM `ml.exe` from Visual Studio or Visual Studio Build Tools with the MSVC x86/x64 toolset

If MASM is installed somewhere unusual:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\build.ps1 -MasmPath 'C:\path\to\ml.exe'
```

There is also an experimental MASM-compatible path for tools like `UASM` or `JWasm`:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\build.ps1 -Assembler uasm -AssemblerPath 'C:\path\to\uasm.exe'
```

That path is not the default and is only expected to work with assemblers that accept MASM-style source and emit compatible `16-bit` COFF output.

### Deterministic Debug Build

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\build.ps1 `
  -DebugBuild `
  -DebugSeed 4660 `
  -DebugOverlay `
  -DebugStartInGame `
  -DebugStartSector 2
```

Useful switches:

- `-DebugSeed <0..65535>` forces the same `16-bit` RNG seed on every new run
- `-DebugOverlay` shows compact live state in-game, including `GS/DM/GD/KS/KA/FA/FE/AB/AM/FX/FT` for state, demo, guard, raw scan, ASCII, last semantic frontend action, frontend event count, audio backend, audio mode, active SFX, and SFX timer
- `-DebugStartInGame` skips splash/title and boots directly into a run
- `-DebugStartSector <n>` starts every new run from a chosen sector
- `-DebugRender2D` keeps the legacy 2D scene/gameplay oracle available while the 3D room path evolves
- `-DebugRender3D` forces the low-poly scene plus gameplay-room renderer explicitly in debug builds

### Audio Modes

Release builds now ship with looping themes enabled by default:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\build.ps1
```

If you want a quiet `SFX_ONLY` build instead:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\build.ps1 -SfxOnly
```

Looping themes are now the supported release baseline. One-shot SFX still preempt the channel and the music transport resumes underneath them.

### Balance Harness

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\balance-harness.ps1
```

The harness checks:

- walkable start-to-exit paths for every authored map
- authored encounter-anchor bounds, occupancy, floor-tile, and enemy-safe-zone rules
- scenario shard-pool shape, overlap, and spread rules
- placement slack for shards, surges, terminals, and enemies
- safe-zone pressure constraints
- sector rule sanity
- deterministic spawn mixes and nearest-enemy pressure across fixed seeds

### Replay Harness

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\replay-harness.ps1
```

The replay harness turns the authored attract demos into deterministic gameplay smoke tests:

- replays the same seeded sector loads the title demos use
- simulates authored anchor placement, scenario shard-pool selection, movement, EMP use, hunter turns, spoof routing, surge hits, sector exits, and scoring
- compares the observed end state against the `Expected` block stored beside each demo in [assets/demos.psd1](assets/demos.psd1)
- writes a report with suggested replacement expectation blocks if an intentional gameplay change shifted the result
- keeps the runtime-verify lane focused on stable opening-run checkpoints instead of carrying stale key/portal scripts that no longer match the shipped movement path

The normal build runs this automatically and writes [build/cyberstorm-replay-report.txt](build/cyberstorm-replay-report.txt).

### Regression Harness

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\regression-harness.ps1
```

The regression harness checks the binary/runtime contract that is easiest to accidentally break in assembly work:

- boot sector size and `0x55AA` signature
- `GAME_SECTORS` vs the actual stage-two sector count
- stage-two entry byte `0` still contains an intentional executable handoff
- `.img` and `.vfd` byte-for-byte equality
- stage-two and bank payload placement at the correct LBA ranges
- zero-filled sector padding and unused floppy tail
- presence of `boot.lst` and `game.lst` for post-failure inspection

The normal build runs this automatically and writes [build/cyberstorm-regression-report.txt](build/cyberstorm-regression-report.txt).

### Frontend Verification

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\frontend-verify.ps1
```

Or from the full build:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\build.ps1 -FrontendVerify
```

This debug-only lane proves the first-run state machine without VirtualBox key injection. It:

- boots dedicated splash/title/attract verification scenarios
- injects synthetic semantic frontend events inside the runtime
- waits for a shared `FRONTEND PASS` or `FRONTEND FAIL` scene
- samples fixed verification markers from the screenshot instead of relying on OCR
- records expected and observed terminal states beside the VBox log

Artifacts:

- [build/cyberstorm-frontend-verify-report.txt](build/cyberstorm-frontend-verify-report.txt)
- [build/frontend-verify/](build/frontend-verify)

### VM Smoke

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\vm-smoke.ps1
```

Or from the full build:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\build.ps1 -VmSmoke
```

The smoke path is deliberately attract-mode driven instead of key-injection driven. It:

- redeploys the workspace VM against the current release image
- boots headless
- waits long enough for splash -> title -> attract timing
- captures a startup-frame screenshot, a title-window screenshot, a later smoke-window screenshot, and the active VBox log
- fails if the log never reaches floppy boot or shows obvious guest failure markers

Artifacts:

- [build/cyberstorm-vm-smoke-report.txt](build/cyberstorm-vm-smoke-report.txt)
- [build/vm-smoke/cyberstorm-vm-smoke-title.png](build/vm-smoke/cyberstorm-vm-smoke-title.png)
- [build/vm-smoke/cyberstorm-vm-smoke.png](build/vm-smoke/cyberstorm-vm-smoke.png)
- [build/vm-smoke/cyberstorm-vm-smoke.log](build/vm-smoke/cyberstorm-vm-smoke.log)

### Runtime Replay Verification

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\runtime-verify.ps1
```

Or from the full build:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\build.ps1 -RuntimeVerify
```

This is the new closed-loop proof lane. It does not trust only the PowerShell replay model. Instead it:

- builds debug-only demo boots that reuse the real attract/demo input path
- boots them headless in VirtualBox
- waits for a dedicated `REPLAY PASS` or `REPLAY FAIL` scene
- samples fixed verification markers from the screenshot instead of relying on OCR
- records the expected and observed runtime signatures beside the VBox log
- only gates the stable opening Subgrid checkpoints right now; longer late-route demos were removed from this lane once they stopped representing truthful shipped behavior

Artifacts:

- [build/cyberstorm-runtime-verify-report.txt](build/cyberstorm-runtime-verify-report.txt)
- [build/runtime-verify/](build/runtime-verify)

### Showcase Capture

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\capture-showcase.ps1
```

Or from the full build:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\build.ps1 -CaptureShowcase
```

This turns deterministic demos into reproducible public-facing captures:

- a verified `title` shot from the VM smoke title frame
- a verified `beauty` shot from `Campaign.Showcase.Beauty` in `assets/sectors.psd1` (currently `thermal-attract-a`)
- a verified `action` shot from `Campaign.Showcase.Action` in `assets/sectors.psd1` (currently `vault-attract-b`)
- a machine-readable gallery manifest under `build/showcase/` so the README can publish fresh captures or preserve the last verified set without rotating manual screenshots

Artifacts:

- [build/cyberstorm-showcase-report.txt](build/cyberstorm-showcase-report.txt)
- [build/showcase/](build/showcase)

### Confidence Stack

CyberStorm now has a layered confidence model:

1. content validation during generation
2. replay-model validation in [scripts/replay-harness.ps1](scripts/replay-harness.ps1)
3. frontend verification in [scripts/frontend-verify.ps1](scripts/frontend-verify.ps1)
4. runtime replay verification in [scripts/runtime-verify.ps1](scripts/runtime-verify.ps1)
5. release boot smoke in [scripts/vm-smoke.ps1](scripts/vm-smoke.ps1)
6. reproducible public showcase capture in [scripts/capture-showcase.ps1](scripts/capture-showcase.ps1)

### Key Build Outputs

- [build/cyberstorm.img](build/cyberstorm.img)
- [build/cyberstorm.vfd](build/cyberstorm.vfd)
- [build/cyberstorm-boot.bin](build/cyberstorm-boot.bin)
- [build/cyberstorm-stage2.bin](build/cyberstorm-stage2.bin)
- [build/generated_art.inc](build/generated_art.inc)
- [build/generated_presentation_content.inc](build/generated_presentation_content.inc)
- [build/generated_geometry.inc](build/generated_geometry.inc)
- [build/generated_machine_code.inc](build/generated_machine_code.inc)
- [build/generated_sector_content.inc](build/generated_sector_content.inc)
- [build/generated_maps.inc](build/generated_maps.inc)
- [build/generated_demos.inc](build/generated_demos.inc)
- [build/generated_music.inc](build/generated_music.inc)
- [build/generated_bank_layout.inc](build/generated_bank_layout.inc)
- [build/cyberstorm-code-bank.bin](build/cyberstorm-code-bank.bin)
- [build/cyberstorm-texture-bank.bin](build/cyberstorm-texture-bank.bin)
- [build/cyberstorm-texture-bank-b.bin](build/cyberstorm-texture-bank-b.bin)
- [build/cyberstorm-map-bank.bin](build/cyberstorm-map-bank.bin)
- [build/cyberstorm-presentation-bank.bin](build/cyberstorm-presentation-bank.bin)
- [build/cyberstorm-geometry-bank.bin](build/cyberstorm-geometry-bank.bin)
- [build/cyberstorm-replay-report.txt](build/cyberstorm-replay-report.txt)
- [build/cyberstorm-balance-report.txt](build/cyberstorm-balance-report.txt)
- [build/cyberstorm-regression-report.txt](build/cyberstorm-regression-report.txt)
- [build/cyberstorm-vm-smoke-report.txt](build/cyberstorm-vm-smoke-report.txt)
- [build/cyberstorm-runtime-verify-report.txt](build/cyberstorm-runtime-verify-report.txt)
- [build/cyberstorm-showcase-report.txt](build/cyberstorm-showcase-report.txt)
- [build/showcase/verified-gallery.json](build/showcase/verified-gallery.json)
- [build/boot.lst](build/boot.lst)
- [build/game.lst](build/game.lst)
- [build/debug_config.inc](build/debug_config.inc)
- [build/audio_config.inc](build/audio_config.inc)
- [build/cyberstorm-build-report.txt](build/cyberstorm-build-report.txt)

### Best Files To Inspect When Something Breaks

- [build/boot.lst](build/boot.lst): bootloader assembly listing
- [build/game.lst](build/game.lst): stage-two assembly listing
- [build/generated_art.inc](build/generated_art.inc): generated sprite/tile data as MASM sees it
- [build/generated_presentation_content.inc](build/generated_presentation_content.inc): generated scene-kit asset offsets and sizes as MASM sees them
- [build/generated_geometry.inc](build/generated_geometry.inc): generated scene/camera tables, gameplay-kit tables, and mesh offsets as MASM sees them
- [build/generated_machine_code.inc](build/generated_machine_code.inc): generated code-bank helper/table offsets as MASM sees them
- [build/generated_demos.inc](build/generated_demos.inc): generated attract-mode scripts as MASM sees them
- [build/generated_bank_layout.inc](build/generated_bank_layout.inc): bootstrap bank layout metadata
- [build/cyberstorm-machine-code-report.txt](build/cyberstorm-machine-code-report.txt): generated helper/table inventory for the code bank
- [build/cyberstorm-code-bank.bin](build/cyberstorm-code-bank.bin): raw machine-code helper and table payload
- [build/cyberstorm-texture-bank.bin](build/cyberstorm-texture-bank.bin): raw texture page A payload
- [build/cyberstorm-texture-bank-b.bin](build/cyberstorm-texture-bank-b.bin): raw texture page B payload
- [build/cyberstorm-map-bank.bin](build/cyberstorm-map-bank.bin): raw post-boot map payload
- [build/cyberstorm-presentation-bank.bin](build/cyberstorm-presentation-bank.bin): raw post-boot presentation payload
- [build/cyberstorm-geometry-bank.bin](build/cyberstorm-geometry-bank.bin): raw post-boot low-poly scene and mesh payload
- [build/cyberstorm-replay-report.txt](build/cyberstorm-replay-report.txt): deterministic replay smoke summary and suggested expectation updates
- [build/cyberstorm-balance-report.txt](build/cyberstorm-balance-report.txt): fairness and deterministic sweep summary
- [build/cyberstorm-regression-report.txt](build/cyberstorm-regression-report.txt): boot/image contract summary for the shipped floppy artifacts
- [build/cyberstorm-vm-smoke-report.txt](build/cyberstorm-vm-smoke-report.txt): headless VirtualBox smoke summary and capture paths
- [build/cyberstorm-runtime-verify-report.txt](build/cyberstorm-runtime-verify-report.txt): screenshot-decoded runtime replay verification summary
- [build/cyberstorm-showcase-report.txt](build/cyberstorm-showcase-report.txt): deterministic gallery/capture assignment summary
- [build/audio_config.inc](build/audio_config.inc): generated release audio-mode contract
- [build/cyberstorm-build-report.txt](build/cyberstorm-build-report.txt): layout, addresses, warnings, and artifact paths
- [build/cyberstorm-stage2.bin](build/cyberstorm-stage2.bin): flattened stage-two payload exactly as written after the boot sector

## Project Guide

- Runtime and memory-layout contracts: [docs/architecture.md](docs/architecture.md)
- Sector identity: [docs/sector-identity.md](docs/sector-identity.md)
- Hunter behavior and telegraphing: [docs/enemy-drama.md](docs/enemy-drama.md)
- Tactical spoof terminals: [docs/spoof-terminals.md](docs/spoof-terminals.md)
- Mastery score and rank rules: [docs/mastery-score.md](docs/mastery-score.md)
- Content-generation pipeline: [docs/content-pipeline.md](docs/content-pipeline.md)
- Asset-bank design: [docs/asset-banks.md](docs/asset-banks.md)
- Balance harness: [docs/balance-harness.md](docs/balance-harness.md)
- Replay harness: [docs/replay-harness.md](docs/replay-harness.md)
- Assembler-path notes: [docs/assembler-paths.md](docs/assembler-paths.md)

## Scope And Truth-In-Advertising

- CyberStorm is OS-independent in the sense that it boots directly on the target machine or VM and does not rely on a host kernel, filesystem, or runtime.
- It is not firmware- or architecture-universal. The current image targets BIOS-style x86 booting, which is the right fit for VirtualBox.
- The build intentionally preserves the current boot contract: boot sector at `LBA 0`, stage two immediately after it at `LBA 1`, loaded by the bootloader to `1000:0000`.
