# Breach Response — x64 Encounter Design

Breach Response is a **deferred x64-forward design**, not active stage-two runtime code.

During the gameplay pass, objective-triggered hunter waves were prototyped for the four-district adventure campaign. The interaction tested well on paper with the new resource loop, but the current stage-two binary is already within roughly 838 bytes of its 64 KiB load limit. A full spawn/telegraph module is therefore the wrong architectural trade for the legacy single-segment runtime.

The design is retained here because it fits the newer x64 `NEON SPINE` direction extremely well.

## Core Rule

Meaningful objective progress should create an explicit world response:

**breach -> get traced -> fight or route -> recover resources -> breach again**

A response is event-driven, never an arbitrary endless spawn timer. Relay, terminal, key, or equivalent mission events should emit a response event that encounter logic can consume.

The intended player read is simple:

> I breached the grid. The grid noticed.

## Escalation Model

The four-district prototype used this pressure curve as a reference:

- **Subgrid:** one pursuit hunter per objective beat.
- **Switchyard:** singles early, then a two-angle Rusher + Flanker response.
- **Thermal:** Flanker pressure, mixed pursuit, then a late Warden.
- **Apex:** two-hunter lockdown beats culminating in Warden + Flanker pressure.

The x64 implementation should preserve the *shape* of that escalation without copying these exact counts blindly.

## Fairness Contract

Any future response system should guarantee:

- no contact spawns;
- no spawning inside objective or hazard volumes;
- a hard live-hostile cap;
- readable ingress direction;
- no immediate free attack on the frame the response appears;
- a visible/audio trace warning before the response becomes dangerous.

The player should understand why pressure increased.

## Map-Driven Ingress

The x64 version should not search arbitrary nearby floor tiles. `NEON SPINE` already has map-driven actor/objective volumes and a pack architecture; response ingress should become authored map data as well.

Useful future volume/record types include:

- security door;
- lift shaft;
- maintenance hatch;
- side-corridor ingress;
- rooftop/drop ingress;
- reinforcement-disabled safe room.

Each response event can choose from valid ingress points based on distance, visibility, live-enemy cap, and encounter phase.

## Event Vocabulary

The x64 gameplay layer should expose explicit events/state for:

- `OBJECTIVE_COMPLETED`
- `HOSTILE_KILLED`
- `PLAYER_DAMAGED`
- `RESOURCE_SPENT`
- `RESOURCE_RECHARGED`
- `RESPONSE_STARTED`
- `RESPONSE_CLEARED`

That vocabulary gives FLOW/resource systems, HUD feedback, audio, encounter scripting, and future scoring one shared contract instead of hard-wiring every feature into one routine.

## Telegraphing

The prototype used a short `TRACE` cue. The x64 presentation can go further:

- HUD trace-strength flash;
- security-door emissive transition;
- directional warning wedge;
- short audio chirp/siren;
- environment light pulse toward the ingress point;
- hostile silhouette before activation.

The warning should be stylish but mechanically useful.

## Relationship To The Compact Stage-Two Economy

The stage-two pass now uses `pulse_count` itself as the visible resource: flame spends pulses, while kills, shards, and objectives can earn them back.

That is a useful proof of the core rhythm without introducing another meter. If that loop feels good in playtesting, x64 can expand it into an explicit FLOW/response model because it is not trapped inside the legacy 64 KiB segment.

## Implementation Gate

Do not port this design into stage two unless the runtime first gains meaningful code-space headroom through banked gameplay code or another architectural change.

For x64, the next implementation step should be to extend map/actor data with one or more response ingress records and introduce a small gameplay-event dispatcher around the existing Warden/terminal/exit objective chain.
