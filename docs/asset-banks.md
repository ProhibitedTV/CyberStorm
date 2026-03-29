# Asset Banks (Phase 1)

CyberStorm still boots with the same contract:

- boot sector at LBA `0`
- stage two immediately after it
- stage two loaded to `1000:0000`
- far-return into offset `0000`

Phase 1 adds a second content path after that handoff: once stage two starts, it can load additional read-only payloads from later floppy sectors into their own conventional-memory segments.

## Why This Exists

Stage two still has to fit in one 64 KiB load segment because the boot sector never moves `ES` while reading it. That is the hard ceiling for code plus in-segment data.

Asset banks are the path beyond that ceiling:

- keep boot simple
- keep stage two BIOS-friendly
- move bulky read-only content out of the initial stage-two segment
- make later growth possible without redesigning the bootloader first

## Phase-1 Scope

Phase 1 banks the authored sector map pool.

That means:

- `assets/sectors.psd1` still owns the source-of-truth maps
- `build/generated_maps.inc` still exists for review
- `build/cyberstorm-map-bank.bin` now carries the runtime map payload
- `build/generated_bank_layout.inc` tells stage two where that payload lives on disk
- stage two loads the map bank into `MAP_BANK_SEG`

The gameplay benefit is immediate: all authored map templates no longer consume stage-two resident bytes, but the game still picks and copies them the same way at runtime.

## Runtime Contract

The minimal bank loader lives in [src/game/banks.asm](../src/game/banks.asm).

Important assumptions:

- `start` stores BIOS boot drive `DL` into `boot_drive` before any BIOS calls clobber it
- the loader uses BIOS `INT 13h` sector reads after stage two starts
- LBA is converted to CHS using the same `18 sectors/track, 2 heads` geometry the bootloader already assumes
- each bank currently loads into one destination segment, so padded bank size must stay within 64 KiB

If a required bank fails to load, stage two drops back to text mode and prints a fatal bank error instead of continuing with half-initialized content.

## Build Layout

The build now resolves banks in two passes:

1. generate content and a provisional bank layout include
2. assemble stage two to learn its final sector count
3. rewrite bank metadata so banks start immediately after stage two
4. assemble stage two again until the bank metadata is stable

That keeps the existing boot contract while still letting stage two know the real post-boot LBA layout.

## Current Phase-1 Files

- [assets/sectors.psd1](../assets/sectors.psd1)
- [build/generated_maps.inc](../build/generated_maps.inc)
- [build/cyberstorm-map-bank.bin](../build/cyberstorm-map-bank.bin)
- [build/generated_bank_layout.inc](../build/generated_bank_layout.inc)
- [src/game/banks.asm](../src/game/banks.asm)

## VirtualBox Test Steps

1. Build the image:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\build.ps1
```

2. Open `build\cyberstorm-build-report.txt` and confirm:
   - a `Map bank` entry exists
   - the map bank has its own LBA range after stage two
   - the map bank load segment is `7000:0000`

3. Boot `build\cyberstorm.vfd` in VirtualBox.

4. Start several new runs and sectors. The game should behave normally, which now proves:
   - stage two booted correctly
   - the post-boot map bank loaded successfully
   - sector templates are being copied from the banked payload rather than stage-two labels

5. If startup fails with a text-mode `MAP BANK ERROR`, inspect:
   - `build/generated_bank_layout.inc`
   - `build/cyberstorm-map-bank.bin`
   - `build/cyberstorm-build-report.txt`
   - `build/game.lst`

## Next Steps After Phase 1

The same path can later bank:

- larger intro/splash art
- extra sector families
- scripted demo/replay input streams
- bigger music tables

without touching the boot sector again.
