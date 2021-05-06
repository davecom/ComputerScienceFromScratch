; explosions.s
; Explosion drawing and explosion-missile collision code for Thwaite

;;; Copyright (C) 2011 Damian Yerrick
;
;   This program is free software; you can redistribute it and/or
;   modify it under the terms of the GNU General Public License
;   as published by the Free Software Foundation; either version 3
;   of the License, or (at your option) any later version.
;
;   This program is distributed in the hope that it will be useful,
;   but WITHOUT ANY WARRANTY; without even the implied warranty of
;   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;   GNU General Public License for more details.
;
;   You should have received a copy of the GNU General Public License
;   along with this program; if not, write to 
;     Free Software Foundation, Inc., 59 Temple Place - Suite 330,
;     Boston, MA  02111-1307, USA.
;
;   Visit http://www.pineight.com/ for more information.

.include "src/nes.h"
.include "src/ram.h"

;
; Because of NES PPU limitations, only half the explosions are
; processed on each frame: even ones in even frames and odd ones in
; odd frames.  This adds (predictable) flicker.
;
.segment "BSS"
explodeX: .res NUM_EXPLOSIONS
explodeY: .res NUM_EXPLOSIONS
explodeTime: .res NUM_EXPLOSIONS

; If zero, tiles for a 3x3 tile explosion are in x, x+$01, and x+$02.
; If nonzero, they're in x, x^$01, and x, with the right column
; horizontally flipped.
EXPLOSION_XMIRROR = 1

; If zero, tile rows for a 3x3 tile explosion are at x, x+$10, and
; x+$20, with x an element in explodeFrameStartTile.  If nonzero,
; they're in x, x^$10, and x, with the bottom row vertically flipped.
EXPLOSION_YMIRROR = 1

.segment "CODE"

;;
; Sets all explosions inactive.
; Does not modify memory.
.proc clearExplosions
  lda #$FF
  ldx #NUM_EXPLOSIONS-1
loop:
  sta explodeTime,x
  dex
  bpl loop
  rts
.endproc

;;
; Makes an explosion at (x, y).
; LOCAL-8 compliant
.proc makeExplosion
xpos = 0
ypos = 1
  stx xpos
  sty ypos

  ; Look for the best slot for this explosion.
  ; The "best" slot is the one whose explosion has been on screen
  ; the longest.
  ; y holds the index of the best slot so far
  ; x holds the index of the slot currently being considered
  ldx #NUM_EXPLOSIONS - 2
  ldy #NUM_EXPLOSIONS - 1
  
findFreeSlot:
  ; if the time in x is less than the time in y, y is a better slot
  lda explodeTime,x
  cmp explodeTime,y
  bcc notBetterSlot
  ; otherwise x is a better slot, so set y to x
  txa
  tay
notBetterSlot:
  dex
  bpl findFreeSlot
  lda tvSystem
  beq isNTSC
  lda #explodeTimeToFramePAL-explodeTimeToFrame
isNTSC:
  sta explodeTime,y
  lda xpos
  sta explodeX,y
  lda ypos
  sta explodeY,y

  lda #SFX_BOOM_NOISE
  jsr start_sound
  lda #SFX_BOOM_SQUARE
  jmp start_sound
.endproc


;;
; Draws explosion number X and checks for collision with missiles.
; Does not modify X.
; Not LOCAL-8 compliant, but it is called only by updateAllExplosions
; which should handle the saving and restoring.
.proc updateExplosionX
; these are used during collision
exploRadius = 12
exploX = 13
exploY = 14
exploNumber = 15

; these are used only during drawing
rowNum = 0
curTile = 1
attr2 = 2
exploXHi = 3
startTile = 4
tileSize = exploRadius

  stx exploNumber
  ; Make sure this explosion is active (time < 128)
  lda explodeTime,x
  bmi isDone
  tay
  lda explodeTimeToFrame,y
  bpl runExplosionFrame
  sta explodeTime,x
isDone:
  jmp bail
runExplosionFrame:
  tay
  lda explodeFrameStartTile,y
  sta startTile
  lda explodeFrameTileSize,y
  sta tileSize
  asl a
  asl a
  eor #$FF
  pha
  sec
  adc explodeX,x
  sta exploX
  lda #$FF
  adc #$00
  sta exploXHi
  pla
  clc
  adc explodeY,x
  sta exploY
  ldx oamIndex
  lda #0
  sta rowNum
  lda #$01
  sta attr2
rowloop:
.if ::EXPLOSION_XMIRROR
  lda attr2
  and #<~$40
  sta attr2
.endif
  lda startTile
  sta curTile
  ldy #0    ; y = x position within sprite
tileloop:
  lda curTile
  sta OAM+1,x
.if ::EXPLOSION_XMIRROR
  eor #%0001
  sta curTile
.else
  inc curTile
.endif
  tya
  asl a
  asl a
  asl a
  adc exploX
  sta OAM+3,x
  lda #0
  adc exploXHi
  bne skipOneTile
  lda attr2
  sta OAM+2,x
  lda rowNum
  asl a
  asl a
  asl a
  adc exploY
  cmp #224
  bcs skipOneTile
  sta OAM,x
  inx
  inx
  inx
  inx
skipOneTile:
  iny
.if ::EXPLOSION_XMIRROR
  cpy #2
  bcc nosetxflip
  lda attr2
  ora #$40
  sta attr2
nosetxflip:
.endif
  cpy tileSize
  bcc tileloop

  lda startTile
.if ::EXPLOSION_YMIRROR
  eor #$10
.else
  adc #$0F  ; row width: 10; minus 1 because carry is set
.endif
  sta startTile
  inc rowNum
  lda rowNum
.if ::EXPLOSION_YMIRROR
  cmp #2
  bcc nosetyflip
  lda attr2
  ora #$80
  sta attr2
  lda rowNum
nosetyflip:
.endif
  cmp tileSize
  bcc rowloop

  ; now we're done drawing, so let's load the variables
  ; used for collision
distSquared = rowNum
  stx oamIndex
  ldx exploNumber
  cpx #NUM_EXPLOSIONS
  bcc notOverflow
  lda #$0F
  sta debugHex1
  stx debugHex2
  jmp collision_continue
notOverflow:
  lda explodeX,x
  sta exploX
  lda explodeY,x
  sta exploY
  ldy explodeTime,x
  lda explodeTimeToFrame,y
  tay
  lda explodeFrameRadiusSquared,y
  sta exploRadius
  
  ldx #4
collision_loop:
  lda missileYHi,x
  beq collision_continue
  lda exploY
  beq collision_continue
  sec
  sbc missileYHi,x
  bcs yNotNeg
  eor #$FF
  adc #1
  bne yMadePos
yNotNeg:
  sec
  ldy missileType,x
  sbc missileCollisionHt,y
  bcs yMadePos
  lda #0
yMadePos:
  cmp #12
  bcs collision_continue
  tay
  lda xSquared,y
  sta distSquared

  lda missileXHi,x
  beq collision_continue
  sec
  sbc exploX
  bcs xNotNeg
  eor #$FF
  adc #1
xNotNeg:
  cmp #12
  bcs collision_continue
  tay
  lda xSquared,y
  adc distSquared
  bcs collision_continue
  cmp exploRadius
  bcs collision_continue
  
  jmp found_explosion
collision_continue:
  inx
  cpx #NUM_MISSILES
  bcc collision_loop

  ldx exploNumber
  ; now we're done; go to next frame
  inc explodeTime,x

bail:
  ; epilog: callee-saved variables
  rts

; This part of the code is put down here so that the branch back to
; collision loop will be within +/- 128 bytes.
found_explosion:
  txa
  pha
  ldy missileType,x
  lda missileCollisionHt,y
  lsr a
  adc missileYHi,x
  tay
  lda #0
  sta missileYHi,x
  lda missileXHi,x
  tax
  jsr makeExplosion
  pla
  tax

  ; if a building is threatened, take the building out of threat
  ; (a double-threatened building will get re-threatened next time)
  ldy missileTarget,x
  cpy #12
  bcs badTarget
  lda housesStanding,y
  cmp #2
  bne badTarget
  lda #1
  sta housesStanding,y
.if ::SHOW_THREATENED
  lda #BG_DIRTY_HOUSES
  ora bgDirty
  sta bgDirty
.endif
badTarget:
  jmp collision_continue
.endproc

;;
; Update even or odd explosions: draw them and check for collisions.
;
.proc updateAllExplosions

  ; Save three callee saved regs
  lda 15
  pha
  lda 14
  pha
  lda 13
  pha
  lda 12
  pha

  ; update even explosions in even frames and odd explosions
  ; in odd frames, so that only half the explosions take up
  ; space in OAM
  lda nmis
  ora #$FE
  clc
  adc #NUM_EXPLOSIONS
  tax
exploLoop:
  jsr updateExplosionX
  dex
  dex
  bpl exploLoop
  
  pla
  sta 12
  pla
  sta 13
  pla
  sta 14
  pla
  sta 15
  rts
  rts
.endproc

.segment "RODATA"
explodeTimeToFrame:
  .byt 0,0,0,0,1,1,1,1,2,2,2,2,2,3,3,3,3,3,3,4,4,4,4,5,5,5,5, $FF
explodeTimeToFramePAL:
  .byt 0,0,0,1,1,1,1,2,2,2,2,3,3,3,3,3,4,4,4,4,5,5,5, $FF
explodeFrameStartTile:
  .byt $20,$22,$24,$26,$28,$2A
explodeFrameTileSize:
  .byt 1, 2, 3, 3, 3, 3

; if xSquared[abs(dx)] + ySquared[abs(dy)] < explodeFrameRadiusSquared[frame]
; then there is a hit
explodeFrameRadiusSquared:
  .byt 24, 64, 100, 144, 144, 144
xSquared:
  .byt 0, 1, 4, 9, 16, 25, 36, 49, 64, 81, 100, 121, 144, 169, 196, 225
; in order of MISSILE_TYPE_* at the top of missiles.s
missileCollisionHt:
  .byt 0, 0, 10
