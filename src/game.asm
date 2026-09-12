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
include game\main.asm

; Keep the established gameplay implementation intact, but give the campaign
; extension layer one narrow interception point. main.asm has already emitted
; calls to process_play_input, so only the implementation below is renamed.
process_play_input TEXTEQU <process_play_input_core>
include game\gameplay.asm
PURGE process_play_input

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
include game\render\scenes.asm

; scenes.asm has already emitted its call to render_game_screen. Rename the
; stock renderer while it is included so flow.asm can decorate the completed
; gameplay frame before render_screen presents it.
render_game_screen TEXTEQU <render_game_screen_core>
include game\render\hud.asm
PURGE render_game_screen

include game\render\tiles.asm
include game\render\entities.asm
include game\render\effects.asm
include game\flow.asm
include game\state.asm
include game\art.asm
include game\render\enhanced_present.asm

end start