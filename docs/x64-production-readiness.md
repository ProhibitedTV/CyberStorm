# CyberStorm x64 Production Readiness

CyberStorm is now staged around the x64 UEFI ISO as the mainline release artifact. The legacy x86 build stays available for archive/reference work, but release energy should go into the blockers below.

## Top Release Blockers

### 1. Issue #22: x64 Mainline Cutover

Production risk: the project still carried legacy x86 wording, defaults, and VM assumptions that made the x64 release feel optional.

Staged improvement:

- `scripts/build.ps1` now defaults to `-Target x64-uefi`.
- The no-argument build emits `build/cyberstorm-x64.iso`.
- The legacy BIOS build remains available through `scripts/build.ps1 -Target x86-expanded`.
- README and architecture docs describe x64 as mainline and x86 as legacy/reference.

Next gate:

- Keep release naming and packaging centered on `cyberstorm-x64.iso`.
- Promote the PR from draft only after x64 VM smoke and the playable vertical slice are both green.

### 2. Issue #21: x64 VM Smoke And Screenshot Verification

Production risk: a demo can boot locally but still fail silently with a black frame, stale ISO, locked VM, or unusable input.

Staged improvement:

- `scripts/deploy-x64-vm.ps1` creates or refreshes a UEFI VirtualBox VM for `cyberstorm-x64.iso`.
- `scripts/build.ps1 -VmSmoke` now runs the x64 UEFI VM smoke lane when the target is x64.
- The smoke path captures title, Down, and Enter screenshots.
- Screenshots are checked for nonblack/accented title pixels before the smoke report can pass.
- `build/cyberstorm-x64-smoke-report.txt` records boot mode, display mode, VM log path, screenshot paths, and input-smoke status.
- Shared VirtualBox helpers retry transient VM lock/unlock states instead of failing the demo path.

Next gate:

- Add marker-level checks for title/menu state once the renderer exposes a compact runtime log or framebuffer marker.
- Extend smoke to the playable mission once issue #18 lands.

### 3. Issue #18: x64 Gameplay Vertical Slice

Production risk: the x64 path has a strong boot/title/runtime scaffold, but production needs an actual playable mission loop.

Staged improvement:

- The x64 pack already reserves map, script, title, campaign, texture, material, mesh, audio, and engine chunks.
- The default release direction now makes this slice the next central engineering target instead of a side migration.
- The current title input path proves selection, confirmation, and back-out behavior without crashing in VirtualBox.
- `NEW GAME` now enters `LEVEL 01 NEON SPINE`, a first playable x64 mission scaffold with a cyber corridor, HUD, objective prompt, Warden target, terminal breach node, reticle, hit counter, extraction gate, and mission-complete state.
- Gameplay basics are wired: WASD moves the player marker, Enter/Space fires, and UEFI SimplePointer left-click fires when firmware exposes mouse/pointer support.
- The first level now has a simple objective chain: eliminate the Warden, breach the terminal by firing at it or standing near the node, then reach the exit gate.
- `scripts/build.ps1 -VmSmoke` is staged to request a gameplay smoke that captures title, first-level entry, movement, and fire screenshots.
- `ENGINE64.BIN` now carries assembly-authored Warden and terminal model records with signed vertices plus triangle face/material tables, and the x64 level runtime draws them from the payload instead of the old target-box placeholders.

Next gate:

- Load one authored district map chunk through the existing x64 pack loader instead of using hardcoded level geometry.
- Promote the current model-edge renderer into filled/depth-tested actor rendering so authored meshes do not read like wireframe/debug art.
- Replace the target-box hit test with weapon ray/collision against map actors.
- Replace the hand-authored terminal/exit zones with map-driven objective volumes.
- Add mouse-look/aim smoothing once the pointer protocol is stable across VM profiles.
- Keep the first shippable slice small: one corridor, one branch, one objective pickup, one exit.

## Fat To Keep Out

- Do not commit VirtualBox machine state, VM logs, local smoke screenshots, object files, listing files, or map files.
- Do not let legacy x86 docs describe the primary release path.
- Do not expand x86 release work unless it preserves the archive path or unblocks the x64 cutover.
