# CyberStorm

CyberStorm is a bare-metal x86 game that boots directly from a floppy image with no operating system underneath it.

The current target is BIOS-compatible x86 hardware and Oracle VirtualBox. The image is a raw floppy disk (`.img` / `.vfd`) whose first sector is a hand-written bootloader. That loader reads the game into memory and jumps straight into it.

## Architecture

The runtime contracts and memory/layout assumptions are documented in [docs/architecture.md](docs/architecture.md). Read that before changing boot flow, segment setup, input handling, or the state layout.

Assembler/build portability notes live in [docs/assembler-paths.md](docs/assembler-paths.md).

## What The Game Is

CyberStorm is a turn-based terminal-styled infiltration run:

- You control a runner diving through three hostile sectors.
- Each sector contains four data shards that must be harvested before the gate unlocks.
- Hunter programs move after every action.
- EMP pulses can clear nearby threats, but charges are limited.
- The run ends in victory only if you breach all three sectors.

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
- `build\boot.lst`
- `build\game.lst`
- `build\debug_config.inc`
- `build\cyberstorm-build-report.txt`

The console summary now includes:

- assembler discovery path and source
- active assembler path
- boot code size and remaining slack before the 510-byte limit
- stage-two size, padded size, sector count, and remaining slack before the 64 KiB load limit
- floppy usage
- key addresses used by the current boot contract
- relocation counts and assembler warning counts

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

### Build Validation

The build validates the layout assumptions before writing the floppy image:

- boot code must fit within `510` bytes so the `55 AA` signature still occupies bytes `510-511`
- stage two must fit in the current single-segment load window at `1000:0000`
- boot plus stage two must fit in the `1.44MB` floppy image
- the final `.img` / `.vfd` must have the exact expected floppy size

### Inspecting Output

If a build fails or boots unexpectedly, these artifacts are the fastest things to inspect:

- `build\boot.lst`: assembler listing for the bootloader
- `build\game.lst`: assembler listing for stage two
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
