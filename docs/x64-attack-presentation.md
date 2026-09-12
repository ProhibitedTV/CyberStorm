# x64 Hostile Attack Presentation

The integrity-pressure pass makes `LEVEL 01 NEON SPINE` mechanically dangerous, but a HUD-only `HOSTILE LOCK` warning is not enough. The player should be able to read **who is threatening them, where that threat originates, and when the lock becomes urgent** without mentally translating a timer.

This pass adds presentation only. It does **not** change integrity, exposure timing, damage cadence, actor HP, objective progression, or TRACE behavior.

## Readable combat loop

The intended x64 combat read becomes:

**hostile alive -> lock source appears -> beams converge -> center bracket pulses -> move to break lock -> fire/reposition -> impact frame if caught**

That is a much better bridge from the current abstract security-pressure model toward eventual explicit enemy attacks.

## World-space threat sources

`assets/x64_attack_presentation.psd1` authors one lock source for each existing hostile actor:

- Warden: a point inside the current Warden body/weapon volume;
- left sentry: a point inside the left sentry emissive/front-face volume;
- right sentry: the mirrored right-sentry point.

`scripts/x64-attack-presentation-harness.ps1` checks those points against the actual actor boxes already rendered by `bootx64.asm`. If the actor geometry moves later, the harness should force the presentation coordinates to be reviewed rather than silently drawing beams from empty space.

## Lock presentation

Once the existing `ExposureTicks` reaches `PRESSURE_WARN_TICKS`:

1. every **live** hostile projects its authored lock point through the existing `ProjectLevelPoint3D` routine;
2. a magenta beam runs from that projected actor point toward the center of the gameplay view;
3. four lock brackets appear around the center;
4. the existing `LevelPulseTicks` animation counter periodically adds a red inner cross.

No new lock timer exists. The renderer visualizes the same exposure state that already drives integrity damage.

Because the source beam is conditional on each actor's existing alive flag:

- killing the Warden removes the Warden beam;
- killing one sentry removes only that sentry beam;
- clearing the initial encounter removes every lock beam;
- terminal TRACE reactivation naturally brings the two sentry beams back;
- clearing TRACE removes them again.

## Impact presentation

While `DamageFlashTicks` is active, the lock visualization is replaced by a stronger hit read:

- a red frame traces the gameplay viewport;
- a red cross flashes through the player-view center;
- the existing `INTEGRITY HIT` HUD text remains visible.

This is deliberately distinct from the player's offensive hit confirm. Enemy damage should read as **the whole link being struck**, not as another enemy-body flash.

## Completion-state discipline

`ObjectiveState >= 3` suppresses hostile attack presentation entirely. Mission-complete grading therefore remains visually clean:

- no stale lock beams;
- no center bracket;
- no impact frame;
- the secondary HUD line is free to show `RANK S/A/B/C`.

## Reproducible runtime patch

The attack presentation is a dependent codemod because it intentionally visualizes state introduced by the integrity-pressure patch:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\apply-x64-attack-presentation.ps1
```

It requires `UpdateHostilePressure PROC` to already exist and refuses to patch an unmodified base runtime.

`scripts/x64-attack-codemod-harness.ps1` creates a throwaway runtime, applies:

1. TRACE response;
2. integrity / pressure / rank;
3. hostile attack presentation;

then reapplies the presentation codemod and verifies the file hash is unchanged. This keeps the dependency explicit while proving idempotency.

The normal entrypoint remains:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\run-x64-combat-validation.ps1 -CheckOnly
powershell -ExecutionPolicy Bypass -File .\scripts\run-x64-combat-validation.ps1
```

## What to look for in VM playtesting

The first manual pass should answer these questions:

- Can you identify whether the Warden, left sentry, right sentry, or multiple actors currently own the lock?
- Does the magenta-beam phase feel like a warning rather than damage that already happened?
- Does the pulsing red center mark create urgency without obscuring aiming?
- Does a single movement input visibly erase the threat presentation quickly enough to teach `move = break lock`?
- During TRACE, do the two reactivated sentries visually recreate a crossfire threat without the dead Warden contributing a stale beam?
- Is the red impact frame unmistakably incoming damage rather than a player hit-confirm effect?
- Does the presentation remain readable when the player is near either lateral edge of the allowed world-space range?

If those reads are good, the next evolution can replace the abstract beams with actual attack events: charge tells, muzzle flashes, hitscan traces/projectiles, cover tests, and actor-specific cadence. Until then, the beams are intentionally a **visualization of the proven pressure mechanic**, not fake projectile simulation.
