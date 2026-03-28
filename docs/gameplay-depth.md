# CyberStorm Gameplay Depth Note

This pass focused on additions that create more decisions inside the existing one-action, one-response turn loop without changing the game's identity.

## Top Three Candidate Additions

1. Sector-specific surge hazards
2. EMP chain rewards
3. Lightweight hunter variants

## What Was Chosen

### 1. Surge Nodes

Surge nodes were chosen because they fit the current architecture almost perfectly:

- they live in the existing tilemap
- they need no new controls
- they make sectors `2` and `3` feel different immediately
- they create tactical routing instead of passive difficulty inflation

The final rule is intentionally compact: later sectors spawn one-use surge tiles that burn the runner for one shield if stepped on, but they also fry hunters that path into them. That turns them into readable risk/reward spaces instead of just punishment.

### 2. EMP Chain Recharge

EMP already exists as the game's one special resource, so deepening it was higher value than adding a second active system.

The final rule is also small: if one EMP blast purges at least two hunters, one pulse charge is restored up to the normal cap.

This improves replayability because it rewards timing and positioning:

- panic pulses still work
- disciplined pulses now have upside
- the player has a reason to bait clusters before firing

## Why Hunter Variants Were Deferred

Hunter variants were the best third option, but they were not included in this pass because they would either:

- add per-enemy type state to the current compact enemy record, or
- rely on more implicit slot-based behavior than is healthy for maintenance

That is a good next step, but surge nodes plus EMP recharge deliver more tactical depth per line of assembly right now.
