# CyberStorm

CyberStorm is a bare-metal x86 game that boots directly from a floppy image with no operating system underneath it.

The current target is BIOS-compatible x86 hardware and Oracle VirtualBox. The image is a raw floppy disk (`.img` / `.vfd`) whose first sector is a hand-written bootloader. That loader reads the game into memory and jumps straight into it.

## Architecture

The runtime contracts and memory/layout assumptions are documented in [docs/architecture.md](docs/architecture.md). Read that before changing boot flow, segment setup, input handling, or the state layout.

Assembler/build portability notes live in [docs/assembler-paths.md](docs/assembler-paths.md).

Sector design goals and the current three-zone identity pass live in [docs/sector-identity.md](docs/sector-identity.md).

Hunter behavior and balance notes for the latest drama/telegraph pass live in [docs/enemy-drama.md](docs/enemy-drama.md).

The new spoof-terminal tactical system is explained in [docs/spoof-terminals.md](docs/spoof-terminals.md).

The score and rank rules for the mastery layer live in [docs/mastery-score.md](docs/mastery-score.md).

The broader authored data workflow is documented in [docs/content-pipeline.md](docs/content-pipeline.md).

The phase-1 banked-content design and runtime contract are documented in [docs/asset-banks.md](docs/asset-banks.md).

The new deterministic balance/validation workflow is documented in [docs/balance-harness.md](docs/balance-harness.md).

## What The Game Is

CyberStorm is a turn-based terminal-styled infiltration run:

- You control a runner diving through three hostile sectors.
- Each sector contains four data shards that must be harvested before the gate unlocks.
- Hunter programs move after every action.
- EMP pulses can clear nearby threats, but charges are limited.
- The run ends in victory only if you breach all three sectors.

## Screenshots

The build keeps a small rolling screenshot pool in `build\` and rewrites these stable README slots on each build so the gallery stays fresh without accumulating every debug capture forever.

![CyberStorm Screenshot 1](build/readme-shot-1.png)
![CyberStorm Screenshot 2](build/readme-shot-2.png)
![CyberStorm Screenshot 3](build/readme-shot-3.png)

## Build

### Prerequisites

- Windows PowerShell
- MASM `ml.exe` from Visual Studio or Visual Studio Build Tools with the MSVC x86/x64 toolset

The stable default is the MASM path:

1. `-MasmPath`
2. `-AssemblerPath`
3. `ML_EXE`
4. `PATH`
5. `VCToolsInstallDir`
6. `vswhere`

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\build.ps1
```

If MASM is installed somewhere unusual, you can override discovery explicitly:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\build.ps1 -MasmPath 'C:\path\to\ml.exe'
```

There is also an experimental MASM-compatible assembler path for tools like `UASM` or `JWasm`:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\build.ps1 -Assembler uasm -AssemblerPath 'C:\path\to\uasm.exe'
```

That path is intentionally not the default. It reuses the same source and COFF-flattening pipeline, so it is only expected to work with assemblers that accept MASM-style source and emit compatible 16-bit COFF output.

The build writes:

- `build\cyberstorm.img`
- `build\cyberstorm.vfd`
- `build\cyberstorm-boot.bin`
- `build\cyberstorm-stage2.bin`
- `build\generated_art.inc`
- `build\generated_sector_content.inc`
- `build\generated_maps.inc`
- `build\generated_music.inc`
- `build\generated_bank_layout.inc`
- `build\cyberstorm-map-bank.bin`
- `build\cyberstorm-balance-report.txt`
- `build\readme-shot-1.png`
- `build\readme-shot-2.png`
- `build\readme-shot-3.png`
- `build\boot.lst`
- `build\game.lst`
- `build\debug_config.inc`
- `build\cyberstorm-build-report.txt`

The console summary now includes:

- assembler discovery path and source
- active assembler path
- balance harness seed set, scenario count, and per-sector pressure summary
- boot code size and remaining slack before the 510-byte limit
- stage-two size, padded size, sector count, and remaining slack before the 64 KiB load limit
- asset-bank LBA ranges, payload sizes, and runtime load segments
- floppy usage
- key addresses used by the current boot contract
- relocation counts and assembler warning counts

### Editing Sprites And Tiles

Sprite and tile bitmaps now come from [assets\visuals.psd1](assets/visuals.psd1). The build generates `build\generated_art.inc`, and [src\game\art.asm](src/game/art.asm) includes that file at assembly time.

That means future visual edits usually happen in the asset source instead of raw `db` rows. The format is intentionally small:

- `Legend` maps one-character pixels to assembly palette symbols such as `PAL_CYAN2` or `0`
- each asset keeps its runtime label name, plus an explicit `Width`, `Height`, and `Rows`
- the build validates unknown legend keys, row width mismatches, and declared size mismatches before MASM runs

Example row source:

```powershell
Rows = @(
    '..pppp..'
    '.pCCCCp.'
)
```

The generated-art console/report section shows the source file, generated include path, asset count, byte footprint, and size buckets so visual-data changes are easy to sanity-check.

### Editing Sector Content And Music

Authored gameplay content now has the same source-of-truth workflow:

- [assets\sectors.psd1](assets/sectors.psd1) owns sector titles, intro copy, rule tables, and the authored map pools
- [assets\music.psd1](assets/music.psd1) owns the looping theme note sequences

The build generates:

- `build\generated_sector_content.inc`
- `build\generated_maps.inc`
- `build\generated_music.inc`
- `build\generated_bank_layout.inc`
- `build\cyberstorm-map-bank.bin`

`build\generated_maps.inc` stays in the repo as a readable review artifact, but phase 1 of the asset-bank system now emits the same map pool as `build\cyberstorm-map-bank.bin` and places it after stage two on disk. The runtime reads that bank into `MAP_BANK_SEG` after stage two starts, using metadata from `build\generated_bank_layout.inc`.

Validation now catches:

- sector count drifting away from `TOTAL_SECTORS`
- malformed or duplicate map labels
- wrong map geometry
- malformed music events or unsupported note names
- non-ASCII content that would be awkward to emit into MASM includes

The generated-content console/report section summarizes sector count, map count, rule summaries, theme count, and event count so authored data changes are easy to review.

### Deterministic Debug Builds

The default build is a release image. Debug/testability features are only enabled when you pass explicit debug flags:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\build.ps1 `
  -DebugBuild `
  -DebugSeed 4660 `
  -DebugOverlay `
  -DebugStartInGame `
  -DebugStartSector 2
```

What those flags do:

- `-DebugSeed <0..65535>` forces the same 16-bit RNG seed on every new run, including `Enter` resets. This is the key switch for reproducible gameplay bugs.
- `-DebugOverlay` adds a compact in-game state strip showing sector, player `X/Y`, shield, pulse, shard count, and live enemy count.
- `-DebugStartInGame` skips the splash/title flow and boots directly into a run.
- `-DebugStartSector <n>` makes every new run start from that sector instead of sector `1`.
- `-DebugBuild` enables the debug profile and keeps title-screen diagnostics available when you need them.

The generated `build\debug_config.inc` and `build\cyberstorm-build-report.txt` record which debug options were compiled into the current image.

To return to the normal release image, run the build script again without any debug flags.

### Balance Harness

The build now runs a lightweight deterministic balance harness after content generation and before the final image is written:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\balance-harness.ps1
```

That harness is intentionally simple and Windows-friendly. It does not require an external test framework or emulator plugin. Instead, it validates the authored sector data and runs deterministic spawn sweeps against a fixed seed set so content regressions are easier to catch in normal development.

The main outputs are:

- `build\cyberstorm-balance-report.txt`: static fairness checks, deterministic spawn-sweep summaries, and warnings
- the `Balance Harness` section in the console/build report: seed set, scenario count, and per-sector summaries

The current harness checks:

- walkable start-to-exit paths for every authored map
- placement slack for shards, surges, terminals, and enemies
- safe-zone pressure constraints for terminals and enemy spawns
- sector rule sanity such as `MAX_ENEMIES` and hunter-threshold ordering
- deterministic spawn mixes and nearest-enemy pressure across a fixed seed sweep

For interpretation details and extension guidance, see [docs/balance-harness.md](docs/balance-harness.md).

### Build Validation

The build validates the layout assumptions before writing the floppy image:

- boot code must fit within `510` bytes so the `55 AA` signature still occupies bytes `510-511`
- stage two must fit in the current single-segment load window at `1000:0000`
- post-boot asset banks must fit in their current single-segment runtime load windows
- boot, stage two, and asset banks must fit in the `1.44MB` floppy image
- the final `.img` / `.vfd` must have the exact expected floppy size

### Inspecting Output

If a build fails or boots unexpectedly, these artifacts are the fastest things to inspect:

- `build\boot.lst`: assembler listing for the bootloader
- `build\game.lst`: assembler listing for stage two
- `build\generated_art.inc`: generated sprite/tile `db` rows exactly as seen by MASM
- `build\generated_bank_layout.inc`: generated LBA/size metadata for post-boot asset banks
- `build\cyberstorm-map-bank.bin`: the raw bank payload currently loaded by stage two
- `build\cyberstorm-balance-report.txt`: map fairness checks, deterministic spawn sweeps, and balance warnings
- `build\readme-shot-*.png`: stable README gallery images rotated from the newest kept screenshot captures
- `build\debug_config.inc`: generated compile-time debug flags for the current image
- `build\cyberstorm-build-report.txt`: layout summary, addresses, relocation counts, warnings, and artifact paths
- `build\cyberstorm-stage2.bin`: flattened stage-two payload exactly as written after the boot sector

For a comparison of MASM, MASM-compatible experimental paths, and why NASM is not currently a low-risk drop-in, see [docs/assembler-paths.md](docs/assembler-paths.md).

## Run In VirtualBox

1. Create a new BIOS-based VM such as `Other/Unknown (32-bit)`.
2. Add or keep a floppy controller.
3. Attach `build\cyberstorm.vfd` as the floppy disk.
4. Boot the VM.

## Deploy A Reusable VM

To register a ready-to-boot VirtualBox VM named `CyberStorm` in this workspace:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\deploy-vm.ps1
```

To launch it:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\start-vm.ps1
```

## Notes

- This is OS-independent in the sense that it boots directly on the machine or VM and does not rely on a host kernel, filesystem, or runtime.
- It is not firmware- or architecture-universal. The current image targets BIOS-style x86 booting, which is the right fit for VirtualBox.
- The build intentionally preserves the current boot contract: boot sector at LBA `0`, stage two immediately after it at LBA `1`, loaded by the bootloader to `1000:0000`.
