# CyberStorm

CyberStorm is a bare-metal x86 game that boots directly from a floppy image with no operating system underneath it.

The current target is BIOS-compatible x86 hardware and Oracle VirtualBox. The image is a raw floppy disk (`.img` / `.vfd`) whose first sector is a hand-written bootloader. That loader reads the game into memory and jumps straight into it.

## Architecture

The runtime contracts and memory/layout assumptions are documented in [docs/architecture.md](docs/architecture.md). Read that before changing boot flow, segment setup, input handling, or the state layout.

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

The build script discovers `ml.exe` in this order:

1. `-MasmPath`
2. `ML_EXE`
3. `PATH`
4. `VCToolsInstallDir`
5. `vswhere`

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\build.ps1
```

If MASM is installed somewhere unusual, you can override discovery explicitly:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\build.ps1 -MasmPath 'C:\path\to\ml.exe'
```

The build writes:

- `build\cyberstorm.img`
- `build\cyberstorm.vfd`
- `build\cyberstorm-boot.bin`
- `build\cyberstorm-stage2.bin`
- `build\boot.lst`
- `build\game.lst`
- `build\cyberstorm-build-report.txt`

The console summary now includes:

- MASM discovery path and source
- boot code size and remaining slack before the 510-byte limit
- stage-two size, padded size, sector count, and remaining slack before the 64 KiB load limit
- floppy usage
- key addresses used by the current boot contract
- relocation counts and MASM warning counts

### Build Validation

The build validates the layout assumptions before writing the floppy image:

- boot code must fit within `510` bytes so the `55 AA` signature still occupies bytes `510-511`
- stage two must fit in the current single-segment load window at `1000:0000`
- boot plus stage two must fit in the `1.44MB` floppy image
- the final `.img` / `.vfd` must have the exact expected floppy size

### Inspecting Output

If a build fails or boots unexpectedly, these artifacts are the fastest things to inspect:

- `build\boot.lst`: MASM listing for the bootloader
- `build\game.lst`: MASM listing for stage two
- `build\cyberstorm-build-report.txt`: layout summary, addresses, relocation counts, warnings, and artifact paths
- `build\cyberstorm-stage2.bin`: flattened stage-two payload exactly as written after the boot sector

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
