# x64 Breach Response Implementation Notes

`NEON SPINE` already has the right bones for a second combat beat: one Warden, two side sentries, a terminal breach, and an extraction gate. The first response implementation should reuse those actors instead of inventing a second spawn framework before the vertical slice has earned it.

## Shipping target

When `ObjectiveState` transitions from `1` (terminal ready) to `2` (terminal breached):

1. Re-arm `SentryLeftAlive` / `SentryRightAlive` and reset each sentry to one hit point.
2. Start a short `TRACE` telegraph, targeted at roughly 45 input ticks.
3. Keep extraction logically locked while either response sentry remains alive.
4. When both response sentries are cleared, extraction becomes valid; `ObjectiveState` remains `2` until the player enters the exit volume.
5. Reaching extraction advances to the existing state `3` mission-complete path.

The result is a mission rhythm of:

**initial clear -> breach -> TRACE response -> final clear -> extraction**

That is a larger improvement to encounter shape than simply increasing Warden HP. It asks the player to reposition twice and gives the terminal interaction consequence.

## Why reuse the sentries

The current x64 slice already owns all of the expensive pieces for these actors: alive/HP state, hit testing, projection, rendering, shadows, HUD pips, and objective-clear bookkeeping. Re-activating them after the terminal breach creates a second authored beat with minimal new runtime surface area.

The first response is intentionally only two one-hit targets. The goal is pacing and phase change, not a difficulty spike. If this lands well, the later data-driven system can add dedicated ingress volumes and additional actor records.

## Data contract

`assets/x64_encounters.psd1` is the authored encounter contract. `scripts/x64-encounter-harness.ps1` validates it against the current runtime symbols and simulates the four-state mission chain. The harness treats the actual `bootx64.asm` response patch as a pending integration gate until `TraceTicks` and `terminal_trace_response:` exist in runtime source.

This separation is deliberate: design data can be tuned without pretending a monolithic UEFI source edit has already shipped.

## Runtime patch seam

The smallest safe source patch should touch only these seams in `src/bootx64.asm`:

- mission reset: clear `TraceTicks` and response state;
- both terminal-breach paths: call one helper after state changes to `2`;
- input tick: decrement `TraceTicks`;
- exit-completion path: refuse completion while a response sentry is alive;
- HUD: show `TRACE` while the response is active;
- data: add `TraceTicks dd 0` and, if needed, a one-bit/one-dword response latch.

Do **not** add a generic allocator/spawner for this first pass. The current mission has three known actor slots and a known two-actor response. A small explicit state transition is easier to verify in UEFI and better aligned with the vertical-slice goal.

## Validation

Run:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\x64-encounter-harness.ps1
```

Before the runtime patch lands, the expected summary is zero hard failures plus one pending runtime-integration gate. After the patch lands, every check should pass.
