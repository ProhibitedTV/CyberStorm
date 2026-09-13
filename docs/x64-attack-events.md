# x64 Hostile Attack Events

The hostile-lock presentation makes incoming pressure readable, but until this pass every integrity hit is still anonymous: the screen flashes red, yet the player cannot tell which live hostile actually fired the shot.

This pass attributes every **existing pressure hit** to one currently-live hostile and renders a brief shot event from that source. It does **not** change the 450 ms warning window, 900 ms hit threshold, one-second cooldown, three-integrity budget, actor HP, TRACE state machine, or mission grading.

## Event model

Attack attribution is authored in `assets/x64_attack_events.psd1`.

The current source ids are:

- `1` — Warden;
- `2` — left sentry;
- `3` — right sentry;
- `0` — no valid source.

When the existing pressure system reaches its damage threshold, `SelectHostileAttackSource` chooses one live actor using a round-robin cursor. Dead actors are skipped.

With all three actors alive, consecutive hits resolve:

**Warden -> left sentry -> right sentry -> Warden ...**

During TRACE the Warden is already dead, so the same selector naturally becomes:

**left sentry -> right sentry -> left sentry -> right sentry ...**

There is no special TRACE attack code.

## Why round-robin

A fixed priority would make the Warden appear responsible for every early hit and one sentry dominate every later hit. Random selection would make deterministic VM validation harder for almost no gameplay benefit in a three-actor vertical slice.

Round-robin gives each surviving threat visual ownership while remaining deterministic and cheap.

## Visible shot event

The selected actor id is stored in `LastAttackSource` when an integrity hit occurs. `AttackEventTicks` keeps the shot trace alive for a very short window while the existing, longer `DamageFlashTicks` still drives the red impact frame.

During that brief event:

1. the selected actor's already-authored weapon point is projected using `ProjectLevelPoint3D`;
2. a bright yellow-white trace runs from that source to the player-view center;
3. a compact muzzle cross marks the firing point;
4. the existing red viewport frame and center impact cross remain the primary damage read.

The event renderer preserves projected coordinates in nonvolatile registers and uses a Windows-x64-aligned call frame before invoking line drawing routines.

## Relationship to lock beams

The two layers have intentionally different jobs:

- **magenta lock beams** = all current actors that can threaten the player;
- **yellow-white shot trace** = the one actor that actually owned this integrity hit;
- **red viewport impact** = the player link took damage.

That creates a readable sequence:

**multiple threats acquiring -> one hostile fires -> player is hit**.

## Failure and restart

Zero integrity still reuses `StartFirstLevel`.

The attack-event state is reset on a normal level start so a stale source cannot leak into a new run. A fatal hit may transition immediately into `LINK RESET` before a full source trace is visually useful; that is acceptable because the reboot feedback is the dominant event at failure.

## Reproducible codemod

The attack-event layer is downstream of both integrity and attack presentation:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\apply-x64-attack-events.ps1 -CheckOnly
powershell -ExecutionPolicy Bypass -File .\scripts\apply-x64-attack-events.ps1
```

Normally, use the composed lane instead:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\run-x64-combat-validation.ps1 -CheckOnly
powershell -ExecutionPolicy Bypass -File .\scripts\run-x64-combat-validation.ps1
```

The production codemod order is:

1. TRACE response;
2. integrity / pressure / completion rank;
3. lock / impact presentation;
4. attributed hostile shot events.

`scripts/x64-attack-codemod-harness.ps1` builds that chain on a throwaway `bootx64.asm`, verifies all expected hooks/state, then reapplies both downstream attack codemods and requires the runtime hash to remain unchanged.

## Deterministic validation

`scripts/x64-attack-events-harness.ps1` verifies:

- three unique, nonzero source ids;
- short trace lifetime and compact muzzle marker;
- the pressure timing remains exactly 90 exposure ticks / 100 cooldown ticks;
- all-live selection rotates Warden -> left -> right;
- TRACE selection alternates left -> right;
- no live actor returns source `0`;
- runtime source selection and draw hooks exist after patching;
- projected coordinates are preserved across drawing calls;
- the event renderer maintains Windows x64 stack alignment.

## VM playtest contract

The first real playtest should answer:

- Is the firing actor obvious during the short shot trace?
- Is yellow-white distinct enough from the magenta acquisition beams and red damage frame?
- Does early combat visually rotate responsibility across Warden and sentries instead of feeling arbitrary?
- During TRACE, do hits alternate cleanly between the two rebooted sentries?
- Is the muzzle marker useful at the side edges of the arena without becoming visual noise?
- Does the trace feel like an actual shot event rather than another persistent targeting line?

If this reads well, the next combat step can start changing **when** actors attack instead of only **who owns** the existing hit: actor-specific charge cadence, cover interruption, explicit hitscan/projectile travel, and distinct Warden versus sentry attack patterns.
