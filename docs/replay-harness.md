# Replay Harness

CyberStorm now treats its authored attract demos as deterministic gameplay smoke tests.

## Why It Exists

The repo already had:

- deterministic seeds
- authored demo scripts
- generated content files
- build-time balance validation
- boot/image regression checks

What it did not have was a lightweight way to say "this exact sequence of gameplay actions should still land in this exact state."

That is what the replay harness adds.

## Source Of Truth

[assets/demos.psd1](../assets/demos.psd1) now contains, for each demo:

- `Name`
- `StartSector`
- `Seed`
- `Steps`
- `Expected`

`Expected` is the end-state contract for that replay. It is intentionally readable:

- state
- sector
- selected map
- player position
- shields / pulses
- shard count
- kill count
- live enemy count
- score
- sector action counters
- spoof timer
- final RNG state

## What The Harness Simulates

[scripts/replay-harness.ps1](../scripts/replay-harness.ps1) replays the demo against the authored sector/rule data and current gameplay constants. It models:

- seeded sector load and map selection
- shard / terminal / surge / enemy placement
- movement and blocked moves
- EMP pulse kills and recharge
- hunter response turns
- spoof-terminal rerouting
- surge-field player/enemy interactions
- sector transitions and mastery scoring

It is not a full emulator. It is a narrow deterministic gameplay model aimed at regression detection.

## Workflow

Run it directly:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\replay-harness.ps1
```

Or just run the normal build:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\build.ps1
```

The build already runs the replay harness automatically.

## When It Fails

If gameplay changes intentionally alter a replay outcome, the harness writes [build/cyberstorm-replay-report.txt](../build/cyberstorm-replay-report.txt) with:

- the observed replay signature
- the full observed end state
- the exact expectation mismatch
- a suggested replacement `Expected` block

That keeps the update path reviewable instead of forcing people to hand-derive new end states.
