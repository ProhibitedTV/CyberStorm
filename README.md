# CyberStorm

CyberStorm is a bare-metal x86 game that boots directly from a floppy image with no operating system underneath it.

The current target is BIOS-compatible x86 hardware and Oracle VirtualBox. The image is a raw floppy disk (`.img` / `.vfd`) whose first sector is a hand-written bootloader. That loader reads the game into memory and jumps straight into it.

## What The Game Is

CyberStorm is a turn-based terminal-styled infiltration run:

- You control a runner diving through three hostile sectors.
- Each sector contains four data shards that must be harvested before the gate unlocks.
- Hunter programs move after every action.
- EMP pulses can clear nearby threats, but charges are limited.
- The run ends in victory only if you breach all three sectors.

## Build

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\build.ps1
```

The build writes:

- `build\cyberstorm.img`
- `build\cyberstorm.vfd`

## Run In VirtualBox

1. Create a new BIOS-based VM such as `Other/Unknown (32-bit)`.
2. Add or keep a floppy controller.
3. Attach `build\cyberstorm.vfd` as the floppy disk.
4. Boot the VM.

## Notes

- This is OS-independent in the sense that it boots directly on the machine or VM and does not rely on a host kernel, filesystem, or runtime.
- It is not firmware- or architecture-universal. The current image targets BIOS-style x86 booting, which is the right fit for VirtualBox.
