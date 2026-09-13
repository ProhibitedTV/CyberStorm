# x64 Visible Cover

The integrity system originally rewarded constant movement but offered no stationary defensive choice. `LEVEL 01 NEON SPINE` already contains visible blocker geometry, so this pass turns selected **near-side pockets behind those objects** into signal-masking cover instead of inventing invisible safe areas.

Cover does not change hostile HP, exposure timing, integrity damage, cooldown, TRACE progression, or mission rank thresholds.

## Authored cover pockets

`assets/x64_cover.psd1` defines three cover pockets that line up with fallback geometry already present in `bootx64.asm`:

- **front-left pillar** — pocket around `x -132..-84, z 96..128`, immediately in front of the visible blocker at `x -120..-92, z 138..186`;
- **front-right pillar** — mirrored pocket around `x 84..132, z 96..128`, in front of the blocker at `x 92..120, z 138..186`;
- **mid-center column** — pocket around `x -36..36, z 264..300`, in front of the center blocker at `x -18..18, z 310..360`.

All three pockets are reachable on the existing 24-unit movement grid.

The cover harness validates the exact blocker geometry strings so a future level-layout change cannot silently leave a cover zone floating in empty space.

## Runtime behavior

`UpdatePlayerCoverState` runs once per combat tick and resolves the player point into one of the three cover states or `COVER_NONE`.

When the player is in cover:

1. accumulated exposure is cleared;
2. hostile lock cannot build;
3. projected lock beams disappear naturally because `ExposureTicks` remains below the warning threshold;
4. the secondary HUD reads `SIGNAL MASKED` while any hostile remains alive.

When all hostiles are dead, the cover message disappears because there is no signal left to mask.

## Why this is not a magic safe rectangle

Each cover pocket sits on the player-facing side of an already-visible blocker and overlaps that blocker's X footprint. The cover volume ends **before** the blocker begins in Z, so the player is conceptually standing behind the object rather than inside it.

The first two pockets are available almost immediately after the pressure engagement line at world Z 96. That gives the opening fight a readable choice:

**keep moving to break lock, or strafe behind a visible pillar and hold position.**

The center column gives the later room another defensive beat without turning the terminal or exit volume itself into free cover.

## Validation

`scripts/x64-cover-harness.ps1` checks:

- exactly three authored cover pockets;
- each blocker exists in runtime geometry;
- each pocket is on the near side of its blocker;
- each pocket overlaps the blocker's X footprint;
- each pocket is reachable with 24-unit movement steps;
- representative player points resolve to left/right/center cover correctly;
- the open center lane remains exposed;
- stationary cover suppresses exposure beyond the normal 900 ms hit window;
- leaving cover restores the unchanged exposure threshold.

The composed validation lane remains:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\run-x64-combat-validation.ps1 -CheckOnly
powershell -ExecutionPolicy Bypass -File .\scripts\run-x64-combat-validation.ps1
```

Production codemod order is now:

1. TRACE response;
2. integrity / pressure / completion rank;
3. lock / impact presentation;
4. attributed hostile shot events;
5. visible geometry cover.

## VM playtest contract

The first real playtest should verify:

- the front pillars visually read as objects worth hiding behind;
- moving from the open center lane to either front pocket visibly clears lock;
- `SIGNAL MASKED` appears quickly enough to teach that the position is safe;
- standing still behind cover does not drain integrity;
- stepping back into the lane restores threat without delay beyond the existing movement grace;
- the mid-center column provides useful late-room cover without trivializing TRACE;
- cover plus movement feels complementary rather than making one defensive verb obsolete.

If these pockets play well, the next upgrade can make hostile attacks interact with cover more explicitly: actor-specific charge cadence, line-of-fire tests, muzzle flashes, and distinct Warden/sentry attack patterns.
