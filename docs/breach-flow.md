# Breach Economy Gameplay Pass

This pass strengthens CyberStorm's four-district stage-two adventure loop while respecting the runtime's most important engineering constraint: stage two is already within roughly one kilobyte of its 64 KiB load ceiling.

The first design iteration used a separate FLOW meter plus a dynamic response-wave system. The mechanics were promising, but the implementation was too large for the legacy single-segment runtime. The shippable stage-two version therefore compresses the same risk/reward idea into the resource already visible in the HUD: **PULSES**.

## Problem

Adventure mode already has strong verbs—continuous movement, jump/glide, charge, flame, gems, relays, keys, hazards, and distinct hunter roles—but its flame attack was effectively free whenever the short cooldown expired. The HUD displayed `pulse_count`, districts reset it, and the older tactical path treated pulses as a real resource, but adventure flame did not consume it.

That made one of the HUD's most prominent resources decorative and weakened the relationship between combat, routing, and objectives.

## Compact Resource Loop

The new live-player economy is deliberately simple:

1. A district begins with the existing pulse reserve.
2. Starting a flame consumes one pulse.
3. At zero pulses, `C` is blocked and the existing `NO PULSE` feedback is used.
4. Every two kills recover one pulse, up to the existing cap.
5. Every four collected data shards recover one pulse.
6. Completing any relay/key objective recovers one pulse if there is room in the reserve.
7. Taking shield damage clears partial kill/shard recharge progress.

The loop becomes:

**spend -> attack or route -> recover -> keep moving**.

There is no second meter to learn and no new control. The existing pulse digit is the authoritative resource display.

## Why This Fits The Game

### Flame now has opportunity cost

The player can still solve a dangerous Flanker immediately with flame, but repeated panic shots eventually run dry. That turns the weapon into a decision instead of a cooldown button.

### Aggression pays for aggression

Two kills return one pulse. Charge, hazards, and flame therefore feed the same combat economy rather than behaving like unrelated answers.

### Routing matters to combat readiness

Four shards return a pulse, so taking a richer line through the district can restore offensive capacity. Shards are no longer only a gate tax.

### Objectives create recovery beats

Relays and keys restore one pulse without replacing their existing objective message. Finishing progression under pressure therefore gives the player a small second wind.

### Damage breaks momentum without adding damage

A hit clears unfinished kill/shard recharge progress. Expert play gets an additional consequence for mistakes without increasing enemy damage or adding hidden punishment.

## Compatibility Strategy

`src/game.asm` redirects only the live `process_play_input` caller through a compact wrapper in `src/game/flow.asm`. The original gameplay implementation remains intact under a private MASM `TEXTEQU` name.

Attract/demo and deterministic replay input bypass the wrapper and continue through the historical core.

The implementation intentionally does **not** add a new render pass or dynamic stage-two response-wave runtime. The existing build report leaves only about 838 bytes before the 64 KiB stage-two limit, so byte cost is treated as a gameplay-design constraint, not an afterthought.

## Campaign Pacing Correction

During this pass a separate source/runtime drift was found: authored Subgrid data specifies `RequiredDataShards = 12`, while the checked-in generated runtime table still required 20 of its 24 shards.

The generated table is synchronized to the authored district targets:

- Subgrid: 12
- Switchyard: 12
- Thermal: 14
- Apex: 14

That restores route choice in the opening district instead of asking the player to vacuum up 83% of all available shards.

## Validation

Run:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\breach-flow-harness.ps1
```

The harness checks the compact hook order, flame cooldown rollover case, pulse-spend behavior, recharge thresholds, damage-chain reset, demo bypass, 16-bit register safety, and authored/generated shard-target parity.

The normal stage-two build remains the decisive byte-budget gate. Because the pre-pass build report was already close to the segment limit, this PR should remain draft until a fresh Windows/MASM build confirms the final assembled size.

## Playtest Questions

- Are three starting flame shots enough to create tension without feeling stingy?
- Is two kills per pulse fast enough that aggressive play feels self-sustaining?
- Does four shards per pulse make optional routing attractive without encouraging tedious collection?
- Do objective pulse restores feel like a useful second wind?
- Does losing partial recharge progress on damage feel legible rather than arbitrary?
- With Subgrid restored to 12 required shards, does the player naturally choose routes instead of clearing the map mechanically?

## Deferred: Breach Response

Objective-triggered hunter response waves are still a strong direction, but they are not appropriate to bolt into the nearly-full 16-bit segment. The design is retained in `docs/breach-response.md` as an x64-forward encounter system.

The x64 `NEON SPINE` runtime has the address space and map-volume architecture to implement explicit objective, response, kill, and damage events cleanly. That is where the fuller FLOW/Response design should graduate once the compact stage-two economy proves the underlying rhythm.
