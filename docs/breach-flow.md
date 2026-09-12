# Breach Flow Gameplay Pass

Breach Flow is a gameplay-design pass for CyberStorm's four-district stage-two adventure campaign. It does **not** change the separate x64 `LEVEL 01 NEON SPINE` runtime; the goal is to prove a stronger moment-to-moment resource and mastery loop in the mature campaign before deciding which pieces belong in the x64 path.

## Problem

The adventure campaign already has good verbs: continuous movement, jump/glide, charge, flame, gems, relay breaches, hazards, enemy roles, score, shields, and a visible pulse reserve. The systems are individually useful, but the live loop did not strongly connect them.

The largest disconnect was flame. The adventure HUD exposed `pulse_count`, districts reset that reserve, and the older tactical path had explicit pulse spending/recharge logic, but adventure flame could start whenever its short timer was idle. That made the pulse display functionally irrelevant during the four-district run.

The result was broad feature count without enough resource tension: charge and flame were answers, objectives were progression, score was mastery, and shields were punishment, but there was no shared rhythm that asked the player to move from one system into the next.

## New Loop

Breach Flow connects those systems with one small meter and one real resource economy.

1. A new run starts with the existing three pulses.
2. Starting a flame consumes one pulse. At zero pulses, flame is dry and the existing `NO PULSE` feedback is used.
3. Kills add `3 FLOW`; gems, relays, and key progress add `1 FLOW`.
4. At `4 FLOW`, kills begin earning a small `+20` mastery bonus.
5. At `8 FLOW`, if the player is below the normal five-pulse cap, one pulse is restored and FLOW drops by `4` instead of resetting to zero.
6. Shield damage breaks FLOW completely.
7. Inactivity drains FLOW after a grace window. The grace tightens across districts: `120 / 90 / 75 / 60` simulation ticks from Subgrid through Apex, then FLOW drains one pip every 30 ticks.

This creates a repeatable rhythm: **spend -> attack -> route through progress -> recover -> keep moving**.

## Why This Fits CyberStorm

### It deepens existing verbs instead of adding controls

No new action key is required. The mechanic gives the existing `C` flame, charge kills, pickups, relay breaches, shield damage, score, and pulse HUD more meaning.

### Aggression creates resources, not just score

The player can spend flame to solve an immediate flanker problem, but strong follow-through can earn the pulse back. The system therefore rewards competence without making the weapon free.

### Damage has a mastery consequence without increasing raw damage

Losing a shield already matters for survival. Breaking FLOW makes getting hit costly to an expert player too, while keeping enemy damage values and fairness rules unchanged.

### District escalation comes from tempo

Subgrid provides a forgiving two-second-plus FLOW grace at the 30 Hz simulation cadence. Apex cuts that window in half. The rules do not change, but the campaign increasingly asks the player to commit to a route and keep pressure on.

### The reward does not snowball without bound

FLOW caps at eight, pulse inventory retains the existing five-pulse cap, and a recharge costs four FLOW. A successful recharge therefore returns the player to the bonus tier rather than leaving the meter permanently full.

## UI

The live adventure view gets a compact `FLOW` strip in the upper-left gameplay viewport with eight pips.

- Cyan: building momentum.
- Amber: mastery bonus tier.
- White flash: pulse recharge.
- Red flash: chain broken or dry flame attempt.

The existing pulse digit remains the authoritative resource count.

## Compatibility Strategy

The implementation deliberately avoids invasive edits to the large gameplay and renderer translation units. `src/game.asm` redirects only the two call sites while their caller modules are assembled, then restores the original names before the stock implementations are included. `src/game/flow.asm` wraps those existing functions.

Attract/demo and deterministic replay input bypass Breach Flow and continue through the historical gameplay core. This preserves the current replay oracle while the new live-player loop is playtested.

## Validation

Run:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\breach-flow-harness.ps1
```

The harness checks integration order, 16-bit register safety, threshold relationships, district tempo ordering, the three-shot starting flame economy, and the expected two-kills-plus-two-progress recharge sequence. It writes `build/cyberstorm-breach-flow-report.txt`.

The normal project build and VM smoke remain the final assembly/runtime gates.

## Playtest Questions

The first playtest should focus on feel rather than raw difficulty:

- Do three starting flames create useful tension without making the opening stingy?
- Does `2 kills + 2 progress` happen often enough to teach recharge organically?
- Is the four-pip bonus tier readable as an invitation to stay aggressive?
- Does a FLOW break after damage feel fair because the hit itself was well telegraphed?
- Does Apex's shorter grace create urgency without forcing reckless play?
- Are there encounter layouts where the player cannot reasonably rebuild resources after spending them? Those should be fixed in encounter placement before increasing gains or caps.

## x64 Follow-Through

The newer x64 `NEON SPINE` slice remains a separate runtime. If this loop survives playtesting, the best migration is not to copy the assembly wrapper literally. The x64 version should expose weapon charges, combat events, objective events, damage events, and FLOW as explicit gameplay state alongside map-driven actor/objective volumes. That will let the newer runtime keep the same risk/reward rhythm while using its own renderer, collision, and pack architecture.
