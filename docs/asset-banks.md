# Asset Banks

CyberStorm still boots with the same contract:

- boot sector at LBA `0`
- stage two immediately after it
- stage two loaded to `1000:0000`
- far-return into offset `0000`

The bank system adds a second content path after that handoff: once stage two starts, it can load additional read-only payloads from later floppy sectors into their own conventional-memory segments.

## Why This Exists

Stage two still has to fit in one 64 KiB load segment because the boot sector never moves `ES` while reading it. That is the hard ceiling for code plus in-segment data.

Asset banks are the path beyond that ceiling:

- keep boot simple
- keep stage two BIOS-friendly
- move bulky read-only content out of the initial stage-two segment
- make later growth possible without redesigning the bootloader first

## Current Scope

CyberStorm now banks two authored payloads:

- the sector map pool
- fixed-size 64x24 transparent presentation assets for splash, title, attract/demo, sector-entry, and ending scenes

That means:

- `assets/sectors.psd1` still owns the source-of-truth maps
- `assets/presentation.psd1` now owns the source-of-truth scene banners
- `build/generated_maps.inc` still exists for review
- `build/generated_presentation_content.inc` still exists for review
- `build/cyberstorm-map-bank.bin` now carries the runtime map payload
- `build/cyberstorm-presentation-bank.bin` now carries the runtime presentation payload
- `build/generated_bank_layout.inc` tells stage two where that payload lives on disk
- stage two loads the map bank into `MAP_BANK_SEG`
- stage two loads the presentation bank into `PRESENT_BANK_SEG`

The benefits are immediate:

- all authored map templates no longer consume stage-two resident bytes, but gameplay still picks and copies them the same way at runtime
- splash/title/end scenes, attract/demo overlays, and sector-entry cards can use richer art without growing stage two or touching the boot sector

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

## Current Files

- [assets/sectors.psd1](../assets/sectors.psd1)
- [assets/presentation.psd1](../assets/presentation.psd1)
- [build/generated_maps.inc](../build/generated_maps.inc)
- [build/generated_presentation_content.inc](../build/generated_presentation_content.inc)
- [build/cyberstorm-map-bank.bin](../build/cyberstorm-map-bank.bin)
- [build/cyberstorm-presentation-bank.bin](../build/cyberstorm-presentation-bank.bin)
- [build/generated_bank_layout.inc](../build/generated_bank_layout.inc)
- [src/game/banks.asm](../src/game/banks.asm)

## VirtualBox Test Steps

1. Build the image:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\build.ps1
```

2. Open `build\cyberstorm-build-report.txt` and confirm:
   - `Map bank` and `Presentation bank` entries both exist
   - both banks have their own LBA ranges after stage two
   - the load segments are `7000:0000` and `7800:0000`

3. Boot `build\cyberstorm.vfd` in VirtualBox.

4. Start several new runs and sectors. The game should behave normally, which now proves:
   - stage two booted correctly
   - the post-boot banks loaded successfully
   - sector templates are being copied from the banked map payload rather than stage-two labels
   - splash/title/end scenes, attract/demo overlays, and sector-entry cards can read their scene-kit art from the presentation bank

5. If startup fails with a text-mode bank error, inspect:
   - `build/generated_bank_layout.inc`
   - `build/cyberstorm-map-bank.bin`
   - `build/cyberstorm-presentation-bank.bin`
   - `build/cyberstorm-build-report.txt`
   - `build/game.lst`

## Next Steps

The same path can later bank:

- larger intro/splash art beyond the fixed banner format
- extra sector families
- scripted demo/replay input streams
- bigger music tables or alternate theme sets

without touching the boot sector again.
