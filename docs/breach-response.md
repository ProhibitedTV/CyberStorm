# Breach Response Encounter Pass

Breach Response is the encounter-design companion to Breach Flow. FLOW gives the player a reason to keep momentum; Response gives the world a reason to push back when the player makes meaningful progress.

## Problem

The four-district adventure campaign already has authored routes, enemy roles, relays, keys, hazards, and a strong district progression. But completing a relay or picking up the key mostly changed counters and gate state. The world did not visibly react to the breach.

That creates a pacing problem: objectives can feel like errands placed inside combat rather than the events that *cause* combat to change.

## New Rule

Every completed relay/key objective can trigger a short hunter response beat.

The system does **not** run on an arbitrary timer and does not continuously spawn enemies. It listens to the same `adventure_objectives_done` delta that feeds FLOW. If the objective count did not advance, no response wave is created.

The intended read is simple:

> I breached the grid. The grid noticed.

## District Escalation

Response composition uses the existing three hunter roles rather than inventing new controls or enemy state.

### Subgrid Ingress

- Objective 1: one Rusher.
- Objective 2: one Flanker.

This teaches the response rule without turning the first district into an attrition fight.

### Switchyard Spine

- Objective 1: one Rusher.
- Objective 2: one Flanker.
- Objective 3: one Flanker plus one Rusher.

The final beat creates the first deliberate two-angle pursuit, matching Switchyard's safe-loop versus hot-hinge identity.

### Thermal Foundry

- Objective 1: one Flanker.
- Objective 2: one Flanker plus one Rusher.
- Objective 3: one Warden.

Foundry uses response composition to escalate from route pressure into an elite late-run threat without changing the district's normal opening population.

### Apex Vault

- Objective 1: one Flanker plus one Rusher.
- Objective 2: two Flankers.
- Objective 3: one Warden plus one Flanker.

Apex is the lockdown district. Its response beats are deliberately the strongest, but the global live-enemy cap prevents an objective rush from producing an unreadable pile-up.

## Fairness Contract

Response spawning is intentionally conservative.

A candidate spawn must:

- remain inside playable map bounds;
- be plain floor;
- not already contain an enemy;
- fit inside the normal enemy table;
- keep the live population below six hunters.

Candidates are searched in a ring around the current player, starting roughly four to five tiles away and falling back to three tiles only in tight corridors. This avoids contact spawns while keeping the existing simple hunter steering close enough to create actual pressure.

Because only `TILE_FLOOR` is accepted, response hunters cannot replace a shard, relay, key, hazard, locked/open gate, or other dynamic tile.

## Telegraphing

A successful response wave produces a short `TRACE` HUD flash showing how many hunters actually entered the encounter. The pressure system is immediately recalculated and the existing enemy-reveal camera logic is allowed to react when the new threat qualifies.

New hunters do **not** receive an immediate free enemy turn. The objective action completes, the response appears, and normal action-driven enemy cadence resumes afterward.

That is important: the response is a consequence the player can read, not hidden damage attached to touching an objective.

## Interaction With Breach Flow

The two systems are intentionally coupled but not hard-coded into one another.

- Objective completion adds FLOW and may summon response pressure.
- Response hunters become opportunities to extend FLOW through kills.
- Spending flame to solve a response costs pulse reserve.
- Sustained aggressive play can recharge that reserve.
- Taking damage from the response breaks FLOW.

The resulting rhythm is:

**breach -> get traced -> fight or route -> build FLOW -> recover resources -> breach again**.

## Playtest Questions

The first manual pass should answer these before any further difficulty increase:

- Does the `TRACE` cue give enough warning before the new hunters matter?
- Do response hunters appear close enough to matter without feeling like teleporting contact damage?
- Is the six-hunter live cap sufficient in Apex when the player leaves opening enemies alive?
- Does the Foundry Warden feel like escalation, or does it slow the run too much?
- Does killing the response naturally feed FLOW strongly enough that aggressive players perceive the intended risk/reward loop?
- Are there map locations where every candidate ring tile is blocked, causing an objective to receive no response? A few intentional safe moments are acceptable; systematic dead zones should be fixed with map-specific ingress candidates later.

## Future Direction

If the system survives playtesting, the next refinement should move response ingress points into authored campaign data instead of increasing raw spawn counts. That would let each route beat define named security doors, lift shafts, or breach apertures while keeping the runtime rules unchanged.

The x64 `NEON SPINE` runtime should eventually implement the same event vocabulary—objective event, response event, kill event, damage event—through its map/actor volume architecture rather than copying this stage-two assembly module literally.
