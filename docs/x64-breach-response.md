# x64 Breach Response Implementation Notes

`NEON SPINE` already has the right bones for a second combat beat: one Warden, two side sentries, a terminal breach, and an extraction gate. The first response implementation should reuse those actors instead of inventing a second spawn framework before the vertical slice has earned it.

## Shipping target

When `ObjectiveState` transitions from `1` (terminal ready) to `2` (terminal breached):

1. Re-arm `SentryLeftAlive` / `SentryRightAlive` and reset each sentry to one hit point.
2. Change the state-2 objective read to `BREAK TRACE / REACH EXIT`.
3. Keep extraction logically **and visually** locked while either response sentry remains alive.
4. Use `TRACE RESPONSE` instead of the old `EXIT ROUTE OPEN` state-2 status read while the response beat is active.
5. When both response sentries are cleared, extraction becomes valid; `ObjectiveState` remains `2` until the player enters the exit volume.
6. Reaching extraction advances to the existing state `3` mission-complete path.

The result is a mission rhythm of:

**initial clear -> breach -> TRACE response -> final clear -> extraction**

That is a larger improvement to encounter shape than simply increasing Warden HP. It asks the player to reposition twice and gives the terminal interaction consequence.

The authored encounter spec retains a `TelegraphTicks = 45` tuning target for the future data-driven version. The first runtime patch deliberately does **not** add a timer/state system just to flash the word TRACE; the state-2 objective text remains the telegraph for the whole response beat. That keeps the first implementation tiny and deterministic.

## Why reuse the sentries

The current x64 slice already owns all of the expensive pieces for these actors: alive/HP state, hit testing, projection, rendering, shadows, HUD pips, and objective-clear bookkeeping. Re-activating them after the terminal breach creates a second authored beat with minimal new runtime surface area.

The first response is intentionally only two one-hit targets. The goal is pacing and phase change, not a difficulty spike. If this lands well, the later data-driven system can add dedicated ingress volumes and additional actor records.

## Data contract

`assets/x64_encounters.psd1` is the authored encounter contract. `scripts/x64-encounter-harness.ps1` validates it against the current runtime symbols and simulates the four-state mission chain.

The response data now owns the first-pass presentation contract as well as the actor contract:

- `RuntimePrompt = 'BREAK TRACE / REACH EXIT'`
- `RuntimeStatus = 'TRACE RESPONSE'`
- `ExitLockedUntilClear = $true`
- `ExitVisualLockedUntilClear = $true`

The harness has one explicit integration gate for the monolithic runtime patch. Before that source patch is applied, the design/state checks can pass while `Runtime response patch landed` reports `PENDING`. After the source patch is present, every check should pass.

## Reproducible runtime patch

Because `src/bootx64.asm` is a large monolithic UEFI translation unit, the response change is encoded as a small idempotent codemod rather than relying on a hand-edited copy of the entire file:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\apply-x64-breach-response.ps1 -CheckOnly
powershell -ExecutionPolicy Bypass -File .\scripts\apply-x64-breach-response.ps1
```

The patcher uses exact anchors and refuses to run if the runtime has drifted or an anchor becomes ambiguous. On success it patches only these seams:

- adds `StartTerminalTraceResponse` / `terminal_trace_response:`;
- calls the helper from both existing terminal-breach paths;
- re-arms the two one-hit sentries;
- locks `objective_exit_complete` until both response sentries are down;
- keeps the rendered exit gate locked while either response sentry remains alive;
- keeps the exit label muted until TRACE is broken;
- changes the state-2 prompt to `BREAK TRACE / REACH EXIT`;
- changes the state-2 status from `EXIT ROUTE OPEN` to `TRACE RESPONSE`;
- updates the short mission-loop tagline;
- runs the x64 encounter harness automatically unless `-SkipHarness` is supplied.

The patcher is idempotent: if `terminal_trace_response:` already exists it does not apply the edits again.

## Reproducible VM smoke extension

The existing x64 gameplay smoke already proves the initial Warden/sentry clear, walks to the terminal, then walks to extraction. `scripts/apply-x64-response-smoke.ps1` extends that proven route instead of creating a second VM driver.

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\apply-x64-response-smoke.ps1 -CheckOnly
powershell -ExecutionPolicy Bypass -File .\scripts\apply-x64-response-smoke.ps1
```

After the terminal breach screenshot, the patched smoke:

1. backtracks from the terminal to the already-proven sentry firing positions;
2. reuses the existing `A4 / fire` and `D10 / fire` targeting sequence to clear the rebooted sentries;
3. captures a new `trace-clear` screenshot;
4. returns through the known terminal route;
5. takes the existing extraction movement and captures mission complete.

This deliberately avoids a debug-only kill command. The smoke test exercises the same hitboxes and firing path as the player-facing runtime.

## Visual state verification

`scripts/x64-response-smoke-verify.ps1` verifies that the capture pipeline did not simply produce three stale gameplay frames. It checks:

- TRACE response, TRACE clear, and mission-complete screenshots have distinct hashes;
- the right-side exit region materially changes when TRACE is broken;
- the upper objective/HUD region materially changes on mission completion;
- broad frame samples change across both transitions.

The visual verifier defaults to the same screenshot base used by `scripts/build.ps1 -VmSmoke`: `build/cyberstorm-x64-vm-smoke-title.png`.

## One-command validation lane

The full x64 TRACE pass can be checked or executed through `scripts/run-x64-trace-validation.ps1`.

Validate patch anchors without modifying source:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\run-x64-trace-validation.ps1 -CheckOnly
```

Apply the two codemods, validate the encounter state machine, build x64, run the standard headless VirtualBox gameplay smoke, and verify the TRACE visual transitions:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\run-x64-trace-validation.ps1
```

The runner also accepts `-X64AssemblerPath` and `-X64LinkerPath` when the Visual Studio tools are not discoverable automatically. `-SkipBuild` is available for a source/state-only validation pass.

## Why this is intentionally not a generic spawn system

Do **not** add an allocator/spawner for this first pass. The current mission has three known actor slots and a known two-actor response. An explicit state transition is easier to verify in UEFI and better aligned with the vertical-slice goal.

A later production pass can move the response contract into map/encounter data with dedicated ingress volumes, spawn records, hard live-hostile caps, and timed TRACE presentation. The current pass proves whether a breach-causes-counterattack structure actually improves the mission first.

## Next combat gap

The x64 audit currently finds hostile HP/alive state but no obvious player-health, shield, incoming-damage, or fail-state loop. That means the current enemies are primarily targets rather than threats to the player. This should be the next gameplay-system investigation **after** TRACE is validated in VM smoke; player pressure deserves its own explicit state model rather than being mixed blindly into this encounter patch.

## Manual playtest contract

After the automated lane is green, manually confirm:

- initial Warden + two-sentry clear still reaches terminal-ready state;
- firing at the terminal and proximity breach each trigger the response exactly once;
- both sentries visibly return after breach;
- the HUD reads `BREAK TRACE / REACH EXIT` during state 2;
- the exit stays visually locked/muted while a response sentry is alive;
- the player cannot finish by simply running through the exit during TRACE;
- killing both response sentries opens the exit presentation and makes extraction valid;
- mission-complete state remains the existing objective state 3 path.
