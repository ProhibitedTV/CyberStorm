# x64 Integrity + Exposure Pressure

`LEVEL 01 NEON SPINE` already has movement, hostile HP/alive state, hit testing, objective state, and a 10 ms runtime input tick. What it does not yet have is a reason for the player to fear leaving hostiles alive. The first integrity pass turns those existing actors into pressure without pretending the vertical slice already owns projectile simulation or full enemy AI.

## Core loop

The combat rhythm becomes:

**move -> break lock -> take a shot -> reposition -> clear pressure -> breach -> survive TRACE -> extract -> improve the run**

The model is deliberately legible:

- The opening spawn pocket (`PlayerWorldZ < 96`) is pressure-safe.
- LEVEL 01 starts with a 2.5 second grace period.
- Any world-space movement clears accumulated exposure and grants 450 ms of movement grace.
- If the player stands exposed beyond the engagement line while any Warden/sentry actor remains alive, hostile lock begins accumulating.
- At 450 ms of stationary exposure the HUD warns `HOSTILE LOCK`.
- At 900 ms of exposure, the player loses one of three integrity points.
- A one-second damage cooldown prevents burst deletion.
- A short `INTEGRITY HIT` message confirms damage.
- Zero integrity reuses `StartFirstLevel` and shows `LINK RESET` rather than introducing a separate death-screen state before the combat loop has earned one.

Tuning lives in `assets/x64_combat.psd1`.

## Why pressure instead of fake bullets

The current x64 enemies are authored targets with known world-space presentation and hit volumes. Adding invisible hitscan/projectile behavior before there is enemy facing, attack animation, cover semantics, or projectile rendering would make combat feel arbitrary.

Exposure pressure is honest about the current abstraction. It represents the security network acquiring a firing solution. The player defeats that solution through the verb the level already supports well: movement.

This makes strafing defensively meaningful immediately while leaving a clean upgrade path to explicit attacks later.

## TRACE interaction

The pressure loop intentionally reads the existing `EnemyAlive`, `SentryLeftAlive`, and `SentryRightAlive` flags. Therefore the TRACE response from `docs/x64-breach-response.md` needs no special-case damage logic:

1. Initial Warden/sentries create pressure.
2. Clearing all three removes pressure.
3. Terminal breach re-arms the two sentries.
4. Pressure automatically returns during TRACE.
5. Clearing the response sentries removes pressure again and opens extraction.

That is the desired authored phase change: the terminal does not merely advance a counter; it makes the room dangerous again.

## HUD contract

The existing mission status string grows from:

`SHOTS 0000 HITS 0000`

into:

`SHOTS 0000 HITS 0000 INT 3`

A second compact line at the same HUD cluster is conditional:

- `HOSTILE LOCK` when exposure crosses the warning threshold;
- `INTEGRITY HIT` during damage feedback;
- `LINK RESET` after integrity failure/restart;
- `RANK S/A/B/C` after mission completion.

There is deliberately no separate health bar or large overlay in this pass. Three integrity points are few enough that a single digit remains readable.

## Completion rank

The x64 slice already tracks `MissionShots` and `MissionHits`, so mission completion now turns those decorative counters plus remaining integrity into a replay target without adding another score subsystem.

The authored rank contract is intentionally division-free:

- **S** — full integrity and perfect accuracy (`shots == hits`).
- **A** — full integrity and at least 50% accuracy (`hits * 2 >= shots`).
- **B** — at least two integrity and at least 33% accuracy (`hits * 3 >= shots`).
- **C** — everything else.

The point is not a deep scoring economy yet. It is to make a five-minute vertical slice immediately ask, “can I clear that cleaner?” The thresholds live with the rest of combat tuning in `assets/x64_combat.psd1`.

## Reproducible runtime patch

The monolithic x64 UEFI source is patched through an exact-anchor codemod:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\apply-x64-integrity-pressure.ps1 -CheckOnly
powershell -ExecutionPolicy Bypass -File .\scripts\apply-x64-integrity-pressure.ps1
```

The codemod is idempotent and refuses missing/ambiguous anchors. It patches only:

- x64 combat and rank tuning constants;
- the central 10 ms gameplay tick;
- LEVEL 01 reset state;
- the mission HUD formatter and status/rank lines;
- the two existing HUD draw paths;
- compact pressure/integrity state;
- `UpdateHostilePressure` and `DrawIntegrityThreat` helpers.

It does **not** modify the renderer geometry, actor hit boxes, objective-state machine, or map pack.

## Validation

Before runtime integration:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\x64-integrity-harness.ps1
```

Expected: all design/runtime-seam checks pass with one pending integration gate.

The deterministic harness verifies:

- the spawn pocket cannot damage the player;
- movement clears exposure and refreshes grace;
- standing exposed costs exactly one integrity after the authored window;
- damage cooldown prevents immediate follow-up loss;
- clearing all hostiles clears pressure;
- three deliberate hits reuse the existing level restart path exactly once;
- the current TRACE smoke pause remains shorter than the first damage window;
- representative clean/damaged/sloppy runs resolve to S/A/B/C as authored.

The composed runtime lane also proves that TRACE and integrity/rank codemods apply in either order and remain idempotent:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\run-x64-combat-validation.ps1 -CheckOnly
powershell -ExecutionPolicy Bypass -File .\scripts\run-x64-combat-validation.ps1
```

After applying the patch, the integration gate should also pass.

## Playtest questions

- Does 900 ms stationary exposure feel readable, or too forgiving?
- Does 450 ms movement grace reward active strafing without letting tiny movement taps trivialize pressure?
- Does three integrity create useful tension during the TRACE response without making the first Warden clear frustrating?
- Is `HOSTILE LOCK` enough warning before the first integrity hit?
- Does immediate level reboot at zero integrity feel clean enough for the vertical slice, or is the next pass worth spending on a dedicated fail/retry screen?
- Do S/A/B/C thresholds motivate a cleaner rerun without encouraging tedious accuracy farming?

The next evolution should only add explicit projectile/attack behavior after this simpler positioning loop proves that incoming threat improves the mission.
