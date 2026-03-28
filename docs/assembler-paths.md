# CyberStorm Assembler Paths

This note answers a simple question: how portable is the current assembly/build story, and what can be changed without endangering the existing boot image contract?

## Short Answer

- `MASM` is the stable, verified path today.
- `UASM` / `JWasm` are plausible low-risk experimental paths because they aim at MASM syntax and similar command-line behavior.
- `NASM` is not a low-risk drop-in for this repository as it exists today.

## What The Current Build Expects

The current build pipeline in [scripts/build.ps1](../scripts/build.ps1) does more than "run an assembler":

1. Assemble `boot.asm` and `game.asm` to COFF objects.
2. Extract the first `.text*` section from each object.
3. Apply 16-bit relocations while flattening to raw binaries.
4. Write the boot sector and stage two into the floppy image.

That means an alternate assembler path must satisfy both of these contracts:

- Source compatibility with the current MASM-style files.
- Object compatibility with the current COFF flattener.

The flattener currently assumes:

- a code section whose name starts with `.text`
- 16-bit relocations compatible with type `0x0001`
- symbol values that line up with the flat `org 0` model

## MASM-Specific Source Features In CyberStorm

The source tree is still clearly MASM-dialect code, not generic x86 assembly text. Examples include:

- `.model tiny` and `.code`
- `end start`
- `include foo.inc`
- `offset symbol`
- `byte ptr` / `word ptr`
- `dup (...)` data declarations
- MASM conditional assembly such as `IF`, `ELSE`, `ENDIF`

The most important recent portability blocker is the debug configuration layer: [src/game/main.asm](../src/game/main.asm) and [src/game/state.asm](../src/game/state.asm) now use MASM conditional assembly driven by generated `debug_config.inc`.

## Feasibility Assessment

### MASM

Status: stable and verified

Why it fits:

- native fit for the current source syntax
- already verified against the current COFF flattener
- current build/debug workflow is built around it

### UASM / JWasm

Status: experimental, low-risk enough to expose as an alternate build path

Why this is the best alternate path:

- the source is already written in a MASM-family dialect
- the command-line model is close enough to reuse the existing build script
- if the emitted COFF is compatible, no source fork is needed

What is still experimental:

- this repository was only locally verified with MASM on this machine
- `UASM` / `JWasm` were not installed here, so the experimental path was validated for discovery/failure behavior, not end-to-end object compatibility

Practical implication:

- if a contributor has `UASM` or `JWasm`, they can now try:
  - `powershell -ExecutionPolicy Bypass -File .\scripts\build.ps1 -Assembler uasm -AssemblerPath 'C:\path\to\uasm.exe'`
  - `powershell -ExecutionPolicy Bypass -File .\scripts\build.ps1 -Assembler jwasm -AssemblerPath 'C:\path\to\jwasm.exe'`
- if the tool emits incompatible COFF, the build should fail in the object/relocation validation step rather than producing a silently broken image

### NASM

Status: feasible in principle, but not low-risk for this repository right now

Why it is meaningfully harder:

- the source would need a real syntax port, not just a flag switch
- MASM conditional assembly would need `%if` / `%endif` conversion or a preprocessing layer
- `.model`, `.code`, `end start`, `offset`, `ptr`, and `dup` forms all need translation
- the current build assumes a MASM-family COFF story; a NASM path would likely want either:
  - a separate direct-`bin` build flow, or
  - a second object-format compatibility path with its own validation work

The real cost is not only syntax churn. A NASM path would also create a second binary-generation contract to maintain and compare.

## Supported Path Matrix

| Path | Status | Source changes required | Build pipeline changes required | Risk |
| --- | --- | --- | --- | --- |
| MASM | Supported | none | none | low |
| UASM / JWasm | Experimental | none expected | small tool-selection changes only | low to medium |
| NASM | Not implemented | substantial | substantial | high |

## Recommendation

If the goal is a cleaner or more portable story without breaking the current binary expectations:

1. Keep `MASM` as the stable default.
2. Treat `UASM` / `JWasm` as the first portability experiment because they preserve the existing source and binary model.
3. Only pursue `NASM` if the project is ready to own either:
   - a parallel source port, or
   - a preprocessing layer plus a second binary-output path.

That makes the portability roadmap incremental instead of turning the build into a second systems project.
