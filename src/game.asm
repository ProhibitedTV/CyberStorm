.model tiny
.code
org 0

; boot.asm far-returns to 1000:0000, so stage two must begin with executable
; code at byte 0 regardless of how the modules below are reorganized.
jmp start

include game\constants.inc
include debug_config.inc
include audio_config.inc
include generated_bank_layout.inc
include generated_presentation_content.inc
include game\audio.asm
include game\feedback.asm
include game\input.asm
include game\banks.asm
include game\main.asm
include game\gameplay.asm
include game\render\framebuffer.asm
include game\render\primitives.asm
include game\render\3d_math.asm
include game\render\3d_raster.asm
include game\render\3d_scene.asm
include game\render\3d_gameplay.asm
include game\render\palette.asm
include game\render\text.asm
include game\render\sprites.asm
include game\render\scenes.asm
include game\render\hud.asm
include game\render\tiles.asm
include game\render\entities.asm
include game\render\effects.asm
include game\state.asm
include game\art.asm
include game\maps.asm

end start
