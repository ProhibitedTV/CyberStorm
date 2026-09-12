.model tiny
.code
org 0

; boot.asm far-returns to 1000:0000, so stage two must begin with executable
; code at byte 0 regardless of how the modules below are reorganized.
jmp start

include game\constants.inc
include debug_config.inc
include audio_config.inc
include generated_machine_code.inc
include generated_presentation_content.inc
include game\audio.asm
include game\feedback.asm
include game\input.asm

; Redirect the caller while main.asm is assembled, then restore the stock
; gameplay symbol before its implementation is included. This keeps the large
; gameplay module untouched and gives flow.asm a narrow interception point.
process_play_input TEXTEQU <breach_flow_process_play_input>
include game\main.asm
PURGE process_play_input
include game\gameplay.asm

include game\render\framebuffer.asm
include game\render\machine_kernels.asm
include game\render\primitives.asm
include game\render\3d_math.asm
include game\render\3d_raster.asm
include game\render\3d_scene.asm
include game\render\3d_gameplay.asm
include game\render\palette.asm
include game\render\text.asm
include game\render\sprites.asm

; Apply the same caller-only redirect to the gameplay renderer. scenes.asm emits
; the render call, hud.asm still owns the original render_game_screen body.
render_game_screen TEXTEQU <breach_flow_render_game_screen>
include game\render\scenes.asm
PURGE render_game_screen
include game\render\hud.asm

include game\render\tiles.asm
include game\render\entities.asm
include game\render\effects.asm
include game\flow.asm
include game\state.asm
include game\art.asm
include game\render\enhanced_present.asm

end start