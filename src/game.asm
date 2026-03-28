.model tiny
.code
org 0

jmp start

include game\constants.inc
include game\input.asm
include game\main.asm
include game\gameplay.asm
include game\render\framebuffer.asm
include game\render\primitives.asm
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
