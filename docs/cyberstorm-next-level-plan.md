# CyberStorm Next-Level Plan

CyberStorm has already crossed the hardest threshold: it is no longer just a clever boot experiment. The current repository is a playable x64 UEFI ISO with a real GOP title/runtime path, deterministic pack loading, an assembly-authored ENGINE64 payload, a CPU filled-triangle/depth renderer, and a first playable NEON SPINE mission loop.

This document captures the current repo state and turns it into a sharper production direction: make the first x64 level feel like a small, shippable cyberpunk corridor breach instead of a renderer demo.

## Current State

### Mainline release path

- `scripts/build.ps1` defaults to the x64 UEFI target.
- The primary artifact is `build/cyberstorm-x64.iso`.
- The boot path uses `EFI/BOOT/BOOTX64.EFI` and UEFI GOP.
- `X64PACK.BIN`, `X64MAN.TXT`, and `ENGINE64.BIN` define the current x64 payload surface.
- The legacy x86 BIOS image is now an explicit archive/reference target, not the center of release energy.

### Gameplay state

The x64 path currently has a real first loop:

1. Start from the title/menu path.
2. Enter `LEVEL 01 NEON SPINE`.
3. Move through the corridor.
4. Fight the Warden.
5. Breach the terminal.
6. Reach the extraction gate.
7. Trigger mission complete.

That means the game has a vertical slice worth polishing. The next win is not “add ten systems.” The next win is making this one slice look intentional.

### Rendering and asset state

- The renderer has an internal `640x480` xRGB8888 frame arena and 32-bit depth arena.
- Filled projected triangles are already running in the x64 gameplay backend.
- `ENGINE64.BIN` carries assembly-authored model records for Warden, terminal, pylon, and gate assets.
- The pack loader already reserves space for engine, texture, mesh, scene, script, audio, title, map, material, and campaign chunks.

The strongest opportunity is to move the remaining hardcoded-feeling level work into richer, validated map/scene/material chunks while keeping the existing objective loop intact.

## What Should Get Better First

### 1. Make NEON SPINE visually readable

The first playable level should have clear silhouette layers:

- floor path
- side wall massing
- ceiling depth
- terminal alcove
- Warden combat lane
- extraction gate chamber
- signage and hazard strips
- objective-state lighting

The goal is not more polygons everywhere. The goal is readable shape language in screenshots and in motion.

### 2. Make combat feedback obvious

Combat should show four things without needing explanation:

- where the hostile is
- whether the player fired
- whether the shot connected
- whether the objective state changed

Good first effects:

- Warden hit flash
- short muzzle/beam streak
- impact spark on hit
- terminal pulse after breach
- gate glow after terminal breach
- red/yellow danger accent while Warden is alive
- cool cyan/green extraction accent after objective completion

### 3. Make asset validation stricter

The pack report should reject bad visual data before the VM boots:

- invalid material references
- invalid texture references
- mesh bounds outside the expected level volume
- degenerate triangles
- bad face indices
- UVs outside accepted range unless explicitly marked tiled
- chunk size over budget
- checksum mismatch

The project already has the discipline for this. The next improvement is pushing that discipline into the x64 visual content lane.

### 4. Keep the slice small

Do not expand scope before NEON SPINE looks good. The shippable slice should remain:

- one corridor
- one branch or alcove
- one hostile class
- one terminal objective
- one extraction gate

A small, polished mission beats a big unstable map.

## Recommended Implementation Order

### Phase A: Screenshot-driven art pass

Create richer authored geometry for the existing level without changing the mission rules.

Target additions:

- raised side walls with layered inset panels
- overhead cable trays or ceiling ribs
- terminal alcove frame
- gate chamber frame
- low floor barriers or curb rails
- emissive-looking signage planes
- a few silhouette props that do not block the route

Acceptance:

- title still boots
- gameplay still enters
- Warden can still be hit
- terminal can still be breached
- gate can still complete the mission
- smoke screenshots show floor, wall, terminal, hostile, and exit as distinct shapes

### Phase B: Feedback pass

Add bounded, simple feedback effects. Keep them cheap and deterministic.

Target additions:

- beam or projectile line for a few frames after fire
- hit flash timer on Warden
- terminal breach pulse timer
- gate active pulse timer
- compact HUD state change text

Acceptance:

- firing is visible in screenshots
- hit confirmation is visible
- mission state is visible
- effects do not corrupt the frame/depth buffers

### Phase C: Map-driven objective volumes

Replace hand-authored terminal and exit zones with data-driven objective volumes.

Minimum schema:

```text
volume_id
kind
min_x
min_y
min_z
max_x
max_y
max_z
linked_objective
active_state
```

Acceptance:

- the current terminal and gate behavior can be represented by data
- old hardcoded coordinates are removed or quarantined behind debug fallback
- pack validation rejects inverted or out-of-bounds volumes

### Phase D: Renderer hardening lane

After the level has more geometry, harden the renderer against the exact bugs richer scenes expose.

Targets:

- near-plane rejection/clipping guardrails
- triangle bounds checks
- depth write stats
- rejected triangle counts
- ray hit counts
- smoke-report renderer counters

Acceptance:

- no black frames
- no giant spikes
- no stale overlays
- no broken HUD after mission complete or Esc return

## Things Not To Do Yet

- Do not add multiple districts to the x64 path before NEON SPINE is polished.
- Do not revive x86 as the main release path.
- Do not chase a general-purpose engine rewrite yet.
- Do not add complex AI before basic combat readability is excellent.
- Do not add more content if the pack report cannot validate it.
- Do not add renderer features that cannot be screenshot-smoked.

## Definition Of Better

CyberStorm becomes “better” when a new person can boot the x64 ISO, see the title, enter NEON SPINE, understand the objective, recognize the hostile, fire and see feedback, breach the terminal, reach the gate, and complete the mission without needing the README open.

The repo already has the bones. The next version should make the first playable minute feel authored, dangerous, and legible.
