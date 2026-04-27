# Content Pipeline

CyberStorm now has two layers of authored content tooling:

- [assets/visuals.psd1](../assets/visuals.psd1) for sprites and tiles
- [assets/machine_code.psd1](../assets/machine_code.psd1), [assets/presentation.psd1](../assets/presentation.psd1), [assets/sectors.psd1](../assets/sectors.psd1), [assets/geometry.psd1](../assets/geometry.psd1), and [assets/music.psd1](../assets/music.psd1) for gameplay-facing and presentation-facing authored content

The build keeps those source files as the truth, then generates compact MASM includes into `build\` before stage two is assembled.

## Generated Outputs

- `build\generated_art.inc`
- `build\generated_machine_code.inc`
- `build\generated_presentation_content.inc`
- `build\generated_geometry.inc`
- `build\generated_sector_content.inc`
- `build\generated_maps.inc`
- `build\generated_music.inc`
- `build\generated_bank_layout.inc`
- `build\cyberstorm-code-bank.bin`
- `build\cyberstorm-texture-bank.bin`
- `build\cyberstorm-texture-bank-b.bin`
- `build\cyberstorm-map-bank.bin`
- `build\cyberstorm-presentation-bank.bin`
- `build\cyberstorm-geometry-bank.bin`

The include files are intended to stay readable. If a build or runtime behavior looks wrong, open the generated include first to see the exact assembly data that MASM consumed.

The asset-bank system now emits the full runtime bank set:

- `build\generated_machine_code.inc` remains the human-reviewable rendering of the code-bank helper/table offsets
- `build\cyberstorm-code-bank.bin` is the runtime payload for real machine-code helpers and lookup tables
- `build\cyberstorm-texture-bank.bin` and `build\cyberstorm-texture-bank-b.bin` are the two runtime texture pages
- `build\generated_maps.inc` remains the human-reviewable rendering of the authored map pool
- `build\cyberstorm-map-bank.bin` is the runtime payload copied into later BIOS HDD sectors
- `build\generated_presentation_content.inc` remains the human-reviewable rendering of the banked scene-banner offsets
- `build\cyberstorm-presentation-bank.bin` is the runtime payload for the banked presentation scene kit used by splash/title/demo/sector-entry/end scenes
- `build\generated_geometry.inc` remains the human-reviewable rendering of banked scene/gameplay geometry and texture metadata
- `build\cyberstorm-geometry-bank.bin` is the runtime geometry payload
- `build\generated_bank_layout.inc` tells the bootstrap where every bank lives on disk, how large it is, and which segment to load it into

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
- per-map `Scenario` blocks for breach names, entry copy, and shard candidate pools
- optional per-map `Anchors` blocks for terminals, surges, and explicit enemy seeds

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

Every map now provides a `Scenario` table:

- `Name = '...'`
- `Entry = '...'`
- `ShardPool = @('x,y', ...)`

Current shard-pool rules:

- every map must provide exactly `SHARD_POOL_COUNT` coordinates
- shard-pool coordinates must be unique
- shard-pool coordinates must sit on authored floor tiles
- shard-pool coordinates cannot overlap start, exit, or authored anchors
- the runtime still only places `SHARD_COUNT` shards, chosen deterministically from that authored pool

Maps can also provide an optional `Anchors` table. Phase-1 anchor types are:

- `Terminals = @('x,y', ...)`
- `Surges = @('x,y', ...)`
- `Enemies = @(@{ X = ..; Y = ..; Kind = 'RUSHER|FLANKER|WARDEN' }, ...)`

Anchors are hybrid content, not extra budget. They consume the same sector counts that the random placement path would otherwise use, so the runtime flow is:

1. copy the authored ASCII layout
2. place anchored terminals, surges, and enemies
3. place `SHARD_COUNT` shards from the authored scenario pool
4. random-fill any remaining terminal, surge, and enemy budget

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
- anchor coordinates outside the playable bounds
- anchors placed on walls, start, or exit
- duplicate anchor occupancy across anchor types
- enemy anchors that violate the safe-zone contract
- anchor counts that exceed sector budgets
- shard-pool coordinates outside the playable bounds
- shard-pool coordinates placed on walls, start, or exit
- duplicate shard-pool coordinates
- shard-pool coordinates overlapping authored anchors
- unsupported enemy kind tokens
- malformed music events
- sector count drifting away from the runtime contract
- bank payloads drifting beyond the current per-bank 64 KiB runtime window

## Why This Exists

The goal is not to hide the assembly. The goal is to make authored content easier to scale while keeping the assembled output inspectable.

That makes the repo feel more like a tiny engine with content tooling:

- assembly modules hold runtime logic
- content files hold bulky authored data
- generated includes are the reviewable bridge between them
