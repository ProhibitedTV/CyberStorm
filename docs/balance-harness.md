# CyberStorm Balance Harness

CyberStorm now includes a lightweight balance and validation harness for authored gameplay data. The goal is not to replace playtesting. The goal is to catch dumb regressions early, surface difficulty-shaping content knobs clearly, and make deterministic AI-assisted iteration safer.

## What It Does

The harness currently focuses on high-value checks around sector content:

- static map fairness checks
- spawn-capacity sanity checks
- sector rule sanity checks
- deterministic spawn sweeps across a fixed seed set
- compact per-sector summaries for build reviews

It is intentionally build-tool aligned: plain PowerShell, no external test framework, and no emulator dependency.

## Source Of Truth

The harness reads:

- [assets/sectors.psd1](../assets/sectors.psd1) for authored sector rules and map pools
- [src/game/constants.inc](../src/game/constants.inc) for runtime constants that shape placement and pressure

That means it validates the same authored content the build already turns into generated includes and bank payloads.

## How To Run It

Run it directly:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\balance-harness.ps1
```

Or run the full build:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\build.ps1
```

The full build invokes the harness automatically after generated content is written and before the final floppy image is assembled.

## Output

The harness writes:

- [build/cyberstorm-balance-report.txt](../build/cyberstorm-balance-report.txt)

The main build also copies the key summary into the `Balance Harness` section of:

- [build/cyberstorm-build-report.txt](../build/cyberstorm-build-report.txt)

## Current Checks

### Static Map Validation

For every authored map, the harness verifies:

- the start tile is walkable
- the exit tile is walkable
- there is at least one walkable path from start to exit
- there is enough floor capacity for dynamic placements
- there are enough non-safe-zone tiles for terminal placement
- there are enough non-safe-zone tiles for enemy placement

It also records useful metrics for balancing:

- path length
- open tile count
- branch tile count
- placement slack
- terminal-safe tile count
- enemy-safe tile count

### Sector Rule Sanity

For every sector, the harness checks:

- derived enemy count does not exceed `MAX_ENEMIES`
- warden threshold ordering is sane relative to the flanker threshold
- pressure trends do not obviously move backward across sectors without a warning

### Deterministic Spawn Sweeps

The harness runs placement sweeps across a fixed seed set:

- `0x1234`
- `0xACE1`
- `0xBEEF`
- `0x0F0F`

For each map/seed combination, it simulates the current placement rules for:

- terminals
- shards
- surge fields
- enemy positions
- enemy kind mix

This uses the same 16-bit LFSR-style RNG pattern and the same placement constraints the runtime depends on, so the results are useful as a content-regression smoke pass.

The sweep currently reports:

- worst placement retry count seen in that sector
- nearest enemy distance from the start area
- hunter mix percentages for rushers, flankers, and wardens

## Why This Helps AI Iteration

CyberStorm now behaves more like a tiny engine with content tooling:

- authored data is externalized
- generated includes stay reviewable
- balance signals become visible in normal build output
- AI-driven content changes can be checked against deterministic guardrails before someone boots the VM

That makes future tuning loops faster and less fragile.

## Extending It Safely

The current harness is phase 1. Good next checks would be:

- replay-script validation against deterministic debug builds
- tighter spawn-distance heuristics for specific sectors
- warnings for outlier branch density or path length drift
- generated summaries for music/demo/replay content once those banks grow

When extending it, keep the existing style:

- fail fast on malformed content
- prefer clear warnings over noisy pseudo-simulation
- keep outputs readable in source control and build logs
- do not let the harness silently drift away from the runtime rules it is supposed to guard
