# Content Pipeline

CyberStorm now has two layers of authored content tooling:

- [assets/visuals.psd1](../assets/visuals.psd1) for sprites and tiles
- [assets/presentation.psd1](../assets/presentation.psd1), [assets/sectors.psd1](../assets/sectors.psd1), and [assets/music.psd1](../assets/music.psd1) for gameplay-facing and presentation-facing authored content

The build keeps those source files as the truth, then generates compact MASM includes into `build\` before stage two is assembled.

## Generated Outputs

- `build\generated_art.inc`
- `build\generated_presentation_content.inc`
- `build\generated_sector_content.inc`
- `build\generated_maps.inc`
- `build\generated_music.inc`
- `build\generated_bank_layout.inc`
- `build\cyberstorm-map-bank.bin`
- `build\cyberstorm-presentation-bank.bin`

The include files are intended to stay readable. If a build or runtime behavior looks wrong, open the generated include first to see the exact assembly data that MASM consumed.

The asset-bank system now emits two raw runtime payloads:

- `build\generated_maps.inc` remains the human-reviewable rendering of the authored map pool
- `build\cyberstorm-map-bank.bin` is the runtime payload copied into later floppy sectors
- `build\generated_presentation_content.inc` remains the human-reviewable rendering of the banked scene-banner offsets
- `build\cyberstorm-presentation-bank.bin` is the runtime payload for splash/title/end presentation art
- `build\generated_bank_layout.inc` tells stage two where that bank lives on disk and how large it is

## Presentation Source

[assets/presentation.psd1](../assets/presentation.psd1) defines the fixed-size banked scene banners used by:

- splash
- title
- win
- lose

The format stays deliberately lightweight:

- `Legend` maps single ASCII tokens to 8-bit palette indices
- `Banners` must stay in the runtime order above
- each banner must provide exactly `PRESENT_BANNER_H` rows
- each row must be exactly `PRESENT_BANNER_W` characters

The generator validates banner order, row width/height, unknown legend tokens, non-ASCII characters, and total payload size before writing the bank binary.

## Sector Content Source

[assets/sectors.psd1](../assets/sectors.psd1) defines:

- sector title and intro copy
- per-sector authored rule values
- the map pool for each sector

Current rule fields:

- `SurgeCount`
- `TerminalCount`
- `EnemyBonus`
- `FlankerThreshold`
- `WardenThreshold`
- `WardenEngageDistance`

Each sector also owns a `Maps` array. Every map must provide:

- a valid assembly label `Name`
- exactly `MAP_H` rows
- exactly `MAP_W` characters per row

The build validates the sector count against `TOTAL_SECTORS` in [src/game/constants.inc](../src/game/constants.inc).

Those same authored maps feed two outputs:

- a readable assembly include for review
- a compact raw bank payload for runtime loading

## Music Source

[assets/music.psd1](../assets/music.psd1) defines the theme event lists for:

- splash
- title
- run
- win
- lose

The event format is intentionally compact:

- `"A3 6"` means note `A3` for `6` BIOS ticks
- `"REST 2"` means a silent duration
- `"LOOP"` means rewind to the start of that theme

The generator validates theme order, supported note names, event durations, and that `LOOP` stays at the end of each theme.

## Validation Goals

The content generators try to fail early with actionable errors:

- missing required keys
- invalid assembly labels
- map geometry mismatches
- non-ASCII content
- duplicate map names
- malformed music events
- sector count drifting away from the runtime contract
- bank payloads drifting beyond the current per-bank 64 KiB runtime window

## Why This Exists

The goal is not to hide the assembly. The goal is to make authored content easier to scale while keeping the assembled output inspectable.

That makes the repo feel more like a tiny engine with content tooling:

- assembly modules hold runtime logic
- content files hold bulky authored data
- generated includes are the reviewable bridge between them
