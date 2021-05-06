; scurry.s
; Animation of villagers fleeing from threatened houses for Thwaite

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

; how many seconds in advance to predict a threat to a building
; can't be greater than FPS/255 (that is, 4 in NTSC)
THREAT_SECONDS = 4

; how many tenths of a second to exit a building
; (determines spacing of evacuees)
DOORWAY_CLOG_TENTHS = 6

NUM_EXCLS = 4
EXCL_TOP_TILE = $05
EXCL_BOTTOM_TILE = $15

VILLAGER_BASE_TILE = $2C
VILLAGER_BASE_PALETTE = 2

.segment "BSS"
; Every tenth of a second, each villager x takes one pixel step
; toward houseX[villagerTarget[x]] * 8 + 8.
villagerX:       .res NUM_VILLAGERS
villagerTarget:  .res NUM_VILLAGERS

; After leaves a building, others can't leave it for
; a few tenths of a second.
doorwayClogTime: .res NUM_BUILDINGS

; Excls are the signs showing up above a building that becomes
; threatened. They look like exclamation points, hence the name.
exclTime: .res NUM_EXCLS
exclX:    .res NUM_EXCLS
lastExclSoundTime: .res 1

.segment "CODE"
.proc initVillagers
  ldx #NUM_VILLAGERS - 1
  stx lastExclSoundTime
eachVillager:
  txa
  sta villagerTarget,x
  lda houseX,x
  asl a
  asl a
  asl a
  sta villagerX,x
  dex
  bpl eachVillager

  ldx #NUM_EXCLS - 1
  lda #0
eachExcl:
  sta exclTime,x
  dex
  bpl eachExcl

  ldx #NUM_BUILDINGS - 1
eachClog:
  sta doorwayClogTime,x
  dex
  bpl eachClog
  rts
.endproc

.proc makeExcl
xpos = 0

  ; Look for the best slot for this exclamation point.
  ; The "best" slot is the one with the least time remaining.
  ; y holds the index of the best slot so far
  ; x holds the index of the slot currently being considered
  ldx #NUM_EXCLS - 2
  ldy #NUM_EXCLS - 1
  sta xpos
  
findFreeSlot:
  ; if the time in x is less than the time in y, y is a better slot
  lda exclTime,x
  cmp exclTime,y
  bcs notBetterSlot
  ; otherwise x is a better slot, so set y to x
  txa
  tay
notBetterSlot:
  dex
  bpl findFreeSlot
  lda #255
  sta exclTime,y
  lda xpos
  sta exclX,y

  pha

  ; If we play sound effects for multiple !s in one frame,
  ; they cover each other up
  lda lastExclSoundTime
  bne noExclSound
  lda #4
  sta lastExclSoundTime
  lda #SFX_ALERT_A
  jsr start_sound
  lda #SFX_ALERT_B
  jsr start_sound
noExclSound:

  pla
  rts
.endproc

;;
; Draws excls and villagers, then moves villagers if subtenth = 2.
.proc updateVillagers
exclSpd = 0

  ; count the time since the last ! sound effect
  lda lastExclSoundTime
  beq :+
  dec lastExclSoundTime
:

  lda #5
  ldx tvSystem
  beq isNTSC
  lda #6
isNTSC:
  sta exclSpd

  ldx #NUM_EXCLS - 1
  ldy oamIndex
eachExcl:
  cpy #$FC
  bcs skipAllExcls
  lda exclTime,x
  sec
  sbc exclSpd
  bcs exclNotUnderflow
  lda #0
exclNotUnderflow:
  sta exclTime,x
  beq skipDrawExcl

  lda exclTime,x
  sec
  sbc #192
  bcs :+
  lda #0
:
  lsr a
  lsr a
  lsr a
  adc #171
  sta OAM,y
  adc #8
  sta OAM+4,y
  lda #EXCL_TOP_TILE
  sta OAM+1,y
  lda #EXCL_BOTTOM_TILE
  sta OAM+5,y

  ; If the ! is still rising, draw it behind the background
  lda exclTime,x
  cmp #192
  lda #%00000001
  bcc :+ 
  lda #%00100001
:
  sta OAM+2,y
  sta OAM+6,y
  lda exclX,x
  sta OAM+3,y
  sta OAM+7,y

  tya
  clc
  adc #8
  tay
  bcc skipDrawExcl
skipAllExcls:
  ldy #0
  ldx #0
skipDrawExcl:
  dex
  bpl eachExcl

  ldx #NUM_VILLAGERS - 1
eachVillager:

attr1 = 1
attr2 = 2

  ; hide the villager if it's at its target
  sty oamIndex
  ldy villagerTarget,x
  lda houseX,y
  ldy oamIndex
  asl a
  asl a
  asl a
  cmp villagerX,x
  beq noDraw
  lda #0
  ror a
  ror a
  eor #VILLAGER_BASE_PALETTE | $40
  sta attr2

  lda #240-32-8-1 ; 4 rows from the bottom, height 8px
  sta OAM,y
  lda villagerX,x
  and #$01
  sta attr1  ; X bit 0: frame of animation
  txa
  and #$02  ; villagerid bit 1: which model to use
  ora attr1
  ora #VILLAGER_BASE_TILE
  sta OAM+1,y
  
  txa
  and #$01  ; villagerid bit 0: which palette to use
  ora attr2
  sta OAM+2,y
  lda villagerX,x
  clc
  adc #5
  sta OAM+3,y
  iny
  iny
  iny
  iny
  beq bail
noDraw:
  dex
  bpl eachVillager
bail:
  sty oamIndex

  lda gameSubTenth
  cmp #3
  beq moveVillagers
  rts
.endproc

.proc moveVillagers

  ; First decrease the time that a doorway is clogged with
  ; another villager
  ldx #NUM_BUILDINGS - 1
eachClog:
  lda doorwayClogTime,x
  beq @notClogged
  dec doorwayClogTime,x
@notClogged:
  dex
  bpl eachClog

  lda gameTenthSecond
  and #%00000001
  clc
  adc #NUM_VILLAGERS - 2
  tax
villagerLoop:
  ldy villagerTarget,x
  lda doorwayClogTime,y
  bne noChooseNewTarget
  lda housesStanding,y
  cmp #BUILDING_OK
  beq noChooseNewTarget
  jsr chooseNewTargetForX
noChooseNewTarget:

  lda houseX,y
  asl a
  asl a
  asl a
  cmp villagerX,x
  beq dontMoveVillager
  
  ; cc: houseX is to left so decrement
  ; cs: houseX is to right so increment
  lda #$FF
  bcc :+
  lda #0
:
  adc villagerX,x
  sta villagerX,x
dontMoveVillager:
  dex
  dex
  bpl villagerLoop

  rts

.endproc

.proc chooseNewTargetForX
bestTarget = 0
bestTargetDist = 1

  ldy #NUM_BUILDINGS/2
  sty bestTarget
  lda #255
  sta bestTargetDist
  ldy #NUM_BUILDINGS-1
targetLoop:
  lda housesStanding,y
  cmp #BUILDING_OK
  bne skipThisTarget
  
  ; abs(houseX-x)
  lda villagerX,x
  lsr a
  lsr a
  lsr a
  adc #1
  sbc houseX,y
  bcs notNeg
  eor #$FF
  adc #1
notNeg:
  cmp bestTargetDist
  bcs skipThisTarget

  ; lower than bestTargetDist
  sta bestTargetDist
  sty bestTarget
skipThisTarget:
  dey
  bpl targetLoop
  lda bestTarget
  ldy villagerTarget,x  ; save the old target
  sta villagerTarget,x

  ; if the OLD target was the building that the villager was inside,
  ; clog that building
  lda houseX,y
  asl a
  asl a
  asl a
  cmp villagerX,x
  bne dontClog
  lda #DOORWAY_CLOG_TENTHS
  sta doorwayClogTime,y
dontClog:
  rts
.endproc

;;
; If any villager is away from home at the end of a round, and his
; house is still OK, move that villager back to his own house.
; TO DO: Make this respect doorwayClogTime.
.proc villagersGoHome
  ldx #NUM_VILLAGERS-1
loop:
  lda housesStanding,x
  cmp #BUILDING_OK
  bne skip
  txa
  sta villagerTarget,x
skip:
  dex
  bpl loop
  rts
.endproc

;;
; Moves all villagers to their target X locations immediately.
; Do this before a timeskip (e.g. at end of round).
.proc warpVillagersToTargets
  ldx #NUM_VILLAGERS-1
loop:
  ldy villagerTarget,x
  lda houseX,y
  asl a
  asl a
  asl a
  sta villagerX,x
  dex
  bpl loop
  rts
.endproc

;;
; @return carry set iff the building targeted by this missile
; is threatened
.proc testMissileXThreat

  ; Is an active missile...
  lda missileYHi,x
  beq notCheck

  ; descending...
  lda missileDYHi,x
  bmi notCheck
  ora missileDYLo,x
  beq notCheck

  ; to attack a building not in check...
  ldy missileTarget,x
  cpy #12
  bcs notCheck  ; don't overflow the buffer
  lda housesStanding,y
  cmp #BUILDING_OK
  bne notCheck
  
  ; and is either moving very swiftly...
  lda missileDYHi,x
  bne isCheck
  
  ; ...or will land both within 256 frames...
  lda missileDYLo,x
  clc
  adc missileYHi,x
  bcs :+
  cmp #BUILDING_HIT_Y
  bcc checkInC
:

  ; ...and within 4 seconds?
  ldy #THREAT_SECONDS * 60
  lda tvSystem
  beq isNTSC_1
  ldy #THREAT_SECONDS * 50
isNTSC_1:
  lda missileDYLo,x
  jsr mul8

  ; At this point, A is the number of YHi units that the missile
  ; moves in three seconds.  Add the missile's current Y position.
  ; If the result is greater than 256 or greater than the blast line,
  ; it's a threat.
  clc
  adc missileYHi,x
  bcs checkInC
  cmp #BUILDING_HIT_Y
checkInC:
  rts

notCheck:
  clc
  rts
isCheck:
  sec
  rts
.endproc

.proc testMissileThreats
  ldx #4  ; skip player missiles
loop:
  jsr testMissileXThreat
  bcc dontMark
  ldy missileTarget,x
  lda #BUILDING_THREATENED
  sta housesStanding,y
.if ::SHOW_THREATENED
  lda #BG_DIRTY_HOUSES
  ora bgDirty
  sta bgDirty
.endif

  txa
  pha
  lda houseX,y
  asl a
  asl a
  asl a
  adc #4
  jsr makeExcl
  pla
  tax

dontMark:
  inx
  cpx #NUM_MISSILES
  bcc loop
  rts
.endproc

