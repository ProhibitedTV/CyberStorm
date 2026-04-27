# Asset Banks

CyberStorm now boots through a tiny bootstrap, not a stage-two self-loader:

- boot sector at `LBA 0`
- bootstrap immediately after it
- stage two after the bootstrap
- bootstrap loads every post-boot bank before far-returning into stage two at `1000:0000`

## Why This Exists

Stage two still has to fit in one `64 KiB` load segment. That is the hard ceiling for live code plus in-segment data.

Asset banks are the release path beyond that ceiling:

- keep the boot sector simple
- keep stage two BIOS-friendly
- move bulky read-only payloads out of the resident stage-two segment
- make later growth possible without redesigning the runtime model first

## Current Scope

CyberStorm currently banks six payloads:

- the machine-code helper bank
- texture bank A
- texture bank B
- the sector map pool
- the fixed-size presentation scene kit
- low-poly gameplay and frontend geometry

That means:

- `assets/machine_code.psd1` is the source of truth for code-bank helpers and lookup tables
- `assets/sectors.psd1` is still the source of truth for authored maps and campaign metadata
- `assets/presentation.psd1` owns the banked scene banners
- `assets/geometry.psd1` owns low-poly scene, prop, actor, gameplay-kit, and texture-bank content
- `build/generated_machine_code.inc`, `build/generated_maps.inc`, `build/generated_presentation_content.inc`, and `build/generated_geometry.inc` stay readable for review
- `build/generated_bank_layout.inc` tells the bootstrap where every bank lives on disk and where it should be loaded in memory

## Runtime Contract

The bootstrap path lives in [src/bootstrap.asm](../src/bootstrap.asm).

Important assumptions:

- the bootstrap preserves the BIOS boot drive and performs all post-boot `INT 13h` reads
- `generated_bank_layout.inc` must agree with the actual image layout
- each bank currently loads into one destination segment, so padded bank size must stay within `64 KiB`
- texture bank A and texture bank B are already close to that per-segment ceiling

Current load segments:

- code bank -> `2000:0000`
- map bank -> `2800:0000`
- presentation bank -> `3000:0000`
- geometry bank -> `3800:0000`
- texture bank A -> `4000:0000`
- texture bank B -> `5000:0000`

If a required bank fails to load, the bootstrap prints a fatal error instead of handing stage two a half-initialized runtime.

## Build Layout

The build resolves bank layout in two passes:

1. generate content and a provisional bank-layout include
2. assemble stage two to learn its final sector count
3. rewrite bank metadata so the banks start immediately after stage two
4. rebuild until the bootstrap and bank layout agree

That keeps the boot contract stable while still letting the repo grow beyond the stage-two segment.

## Current Files

- [assets/machine_code.psd1](../assets/machine_code.psd1)
- [assets/sectors.psd1](../assets/sectors.psd1)
- [assets/presentation.psd1](../assets/presentation.psd1)
- [assets/geometry.psd1](../assets/geometry.psd1)
- [build/generated_machine_code.inc](../build/generated_machine_code.inc)
- [build/generated_maps.inc](../build/generated_maps.inc)
- [build/generated_presentation_content.inc](../build/generated_presentation_content.inc)
- [build/generated_geometry.inc](../build/generated_geometry.inc)
- [build/generated_bank_layout.inc](../build/generated_bank_layout.inc)
- [build/cyberstorm-code-bank.bin](../build/cyberstorm-code-bank.bin)
- [build/cyberstorm-texture-bank.bin](../build/cyberstorm-texture-bank.bin)
- [build/cyberstorm-texture-bank-b.bin](../build/cyberstorm-texture-bank-b.bin)
- [build/cyberstorm-map-bank.bin](../build/cyberstorm-map-bank.bin)
- [build/cyberstorm-presentation-bank.bin](../build/cyberstorm-presentation-bank.bin)
- [build/cyberstorm-geometry-bank.bin](../build/cyberstorm-geometry-bank.bin)
- [src/bootstrap.asm](../src/bootstrap.asm)

## VirtualBox Test Steps

1. Build the image:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\build.ps1
```

2. Open `build\cyberstorm-build-report.txt` and confirm:
   - code, texture, map, presentation, and geometry bank entries all exist
   - all banks have their own LBA ranges after stage two
   - the load segments match the addresses above

3. Boot `build\cyberstorm.vfd` in VirtualBox.

4. Verify that splash/title, gameplay, and sector-entry scenes behave normally. That proves:
   - the bootstrap loaded every bank
   - stage two is reading authored maps from the map bank
   - frontend scenes are reading presentation assets from the presentation bank
   - the renderer is reading geometry, texture, and code-bank assets from the preloaded segments

5. If startup fails, inspect:
   - `build/generated_bank_layout.inc`
   - `build/cyberstorm-build-report.txt`
   - `build/cyberstorm-code-bank.bin`
   - `build/cyberstorm-texture-bank.bin`
   - `build/cyberstorm-texture-bank-b.bin`
   - `build/cyberstorm-map-bank.bin`
   - `build/cyberstorm-presentation-bank.bin`
   - `build/cyberstorm-geometry-bank.bin`
   - `build/bootstrap.lst`

## Next Steps

This path still leaves room for later bank growth, but the immediate rule is simple: prefer deleting stale payloads and fake helpers before inventing new bank consumers.
