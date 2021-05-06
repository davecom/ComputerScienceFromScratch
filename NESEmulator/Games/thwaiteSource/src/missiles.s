; missiles.s
; missile movement and displaying functions for Thwaite

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

MISSILE_SMOKE_RATE = 20

MISSILE_TYPE_NORMAL = 0
MISSILE_TYPE_MIRV = 1
MISSILE_TYPE_BALLOON = 2

SALVO_TYPE_BALLOON = 8
SALVO_TYPE_MIRV = 9
BALLOON_START_X = 4

COST_BALLOON = 2
COST_MIRV = 2

CROSSHAIR_TILE = $04
PLAYER_MISSILEDST_TILE = $03
BALLOON_TILE = $06
BALLOON_PALETTE_NO = $01
BALLOON_CRATE_TILE = $16
CRATE_PALETTE_NO = $00
MIRV_TILE_OR_MASK = $10
MISSILE_PALETTE_NO = $01  ; shared with explosions

.segment "BSS"
; NUM_MISSILES * 12 bytes

; A missile slot is considered allocated if YHi > 0.
; Ordinarily, enemy missiles spawn at YHi = 8.
missilesOverlay:
missileXHi:    .res NUM_MISSILES
missileXLo:    .res NUM_MISSILES
missileYHi:    .res NUM_MISSILES
missileYLo:    .res NUM_MISSILES
missileDXHi:   .res NUM_MISSILES
missileDXLo:   .res NUM_MISSILES
missileDYHi:   .res NUM_MISSILES
missileDYLo:   .res NUM_MISSILES
missileAngle:  .res NUM_MISSILES
missileType:   .res NUM_MISSILES
missileTarget: .res NUM_MISSILES

; for player missiles, time until explosion
; for enemy missiles, time until smoke
missileTime:  .res NUM_MISSILES

missileDstX = missileTarget
missileDstY: .res 4

crosshairXLo:  .res 2
crosshairXHi:  .res 2
crosshairYLo:  .res 2
crosshairYHi:  .res 2
crosshairDXLo: .res 2
crosshairDXHi: .res 2
crosshairDYLo: .res 2
crosshairDYHi: .res 2

timeTillSalvo: .res 1
salvoLeft: .res 1

.segment "CODE"
.proc clearAllMissiles
  ldx #NUM_MISSILES-1
  lda #0
  stx timeTillSalvo
  sta salvoLeft
:
  sta missileYHi,x
  dex
  bpl :-
  ldx #1
:
  lda #128
  sta crosshairYHi,x
  lda #0
  sta crosshairYLo,x
  sta crosshairDYHi,x
  sta crosshairDYLo,x
  sta crosshairXLo,x
  sta crosshairDXHi,x
  sta crosshairDXLo,x
  dex
  bpl :-
  lda #64
  sta crosshairXHi
  lda #192
  sta crosshairXHi+1
  rts
.endproc

; To draw a missile:
; 1. Look up its angle. (Straight left and right are not defined.)
; 2. Look up the tile number, flip, hotspot coords corresponding
;    to this angle.
; 3. Subtract the hotspot coords from the tile number to make
;    hardware Y and X.
; 4. Write the missile's Y, tile number, flip, and X to OAM.
.proc drawMissileNumberX
  lda missileType,x
  cmp #MISSILE_TYPE_BALLOON
  bne notBalloon
  jmp drawBalloonNumberX
notBalloon:
  lda missileAngle,x
  and #$1F
  lsr a
  lsr a
  lsr a
  tay
  lda missileTileHotspotY,y
  sta 0
  lda missileTileFlip,y
  sta 2
  lda missileTileHotspotX,y
  sta 3
  lda missileAngle,x
  and #$0F
  tay
  lda missileTileNumber,y
  ldy oamIndex
  sta OAM+1,y
  lda missileType,x
  cmp #MISSILE_TYPE_MIRV
  bne notMIRV
  lda #MIRV_TILE_OR_MASK
  ora OAM+1,y
  sta OAM+1,y
notMIRV:
  clc               ; NES renders sprites a line below their actual
  lda missileYHi,x  ; Y coord, so use 'clc' to bump it up 1 line
  sbc 0
  sta OAM,y
  lda 2
  ora #MISSILE_PALETTE_NO
  sta OAM+2,y
  lda missileXHi,x
  sec
  sbc 3
  sta OAM+3,y
  tya
  clc
  adc #4
  sta oamIndex
  rts  
.endproc

.proc drawBalloonNumberX
  lda nmis
  asl a
  asl a
  asl a
  lda #0
  adc #4
  sta 0
  lda #0
  sta 2

  ldy oamIndex
  cpy #$F8
  bcs overLeftEdge
  lda missileXHi,x
  sec
  sbc #4
  bcc overLeftEdge
  sta OAM+3,y
  sta OAM+7,y
  lda #BALLOON_TILE
  sta OAM+1,y
  lda #BALLOON_CRATE_TILE
  sta OAM+5,y
  clc               ; NES renders sprites a line below their actual
  lda missileYHi,x  ; Y coord, so use 'clc' to bump it up 1 line
  sbc 0
  sta OAM,y
  adc #7
  sta OAM+4,y
  lda #BALLOON_PALETTE_NO
  sta OAM+2,y
  lda #CRATE_PALETTE_NO
  sta OAM+6,y
  tya
  clc
  adc #8
  sta oamIndex
overLeftEdge:
  rts  
.endproc

.proc updateMissiles

  ; If it's time to launch more missiles, do so.  There have to be
  ; enemy missiles left, and it has to be the first frame of this
  ; tenth of second.
  lda enemyMissilesLeft
  beq noNewMissile1
  lda gameSubTenth
  beq yesNewMissile1
noNewMissile1:
  jmp noNewMissile
yesNewMissile1:
  dec timeTillSalvo
  lda timeTillSalvo
  bne noNewSalvo
  lda levelReleasePeriod
  sta timeTillSalvo
  ldy #2
  jsr random
  lda #$03
  and rand3
  tay
  lda levelSalvoSizes,y
  sta salvoLeft
noNewSalvo:

  ; Missiles may be launched only every other tenth of a second, and
  ; only if there are missiles left in this salvo.
  lda gameTenthSecond
  and #1
  bne noNewMissile1
  lda salvoLeft
  beq noNewMissile1
  
  ; Now that we know we're launching *something*, let's see what
  ; we're launching.

  ; 8: balloon
  cmp #SALVO_TYPE_BALLOON
  bne notBalloon

  ; if there aren't enough missiles left to launch a balloon,
  ; launch a salvo of all remaining missiles as regular missiles
  lda enemyMissilesLeft
  cmp #COST_BALLOON
  bcs okBalloon
  sta salvoLeft
  jmp notSpecialMissile
okBalloon:
  jsr makeBalloon
  bcs noNewMissile
  lda enemyMissilesLeft
  sbc #COST_BALLOON - 1  ; because carry is clear
  sta enemyMissilesLeft
  lda #0
  sta salvoLeft
  beq noNewMissile
notBalloon:

  ; 9: MIRV
  cmp #SALVO_TYPE_MIRV
  bne notMIRV
  
  ; if not enough missiles left, launch regular missiles
  lda enemyMissilesLeft
  cmp #COST_BALLOON
  bcs okMIRV
  sta salvoLeft
  jmp notSpecialMissile
okMIRV:
  ; make a missile and upgrade it to a MIRV
  jsr makeMissile
  bcs noNewMissile
  lda #MISSILE_TYPE_MIRV
  sta missileType,x
  lda enemyMissilesLeft
  sbc #COST_MIRV - 1  ; because carry is clear
  sta enemyMissilesLeft
  lda #0
  sta salvoLeft
  beq noNewMissile

notMIRV:
notSpecialMissile:
  jsr makeMissile
  bcs noNewMissile
  dec salvoLeft
  dec enemyMissilesLeft
noNewMissile:

  ldx #0
missileLoop:
  jsr moveMissileNumberX
  lda missileYHi,x
  beq notDrawUnallocated
  jsr drawMissileNumberX
notDrawUnallocated:
  inx
  cpx #NUM_MISSILES
  bcc missileLoop

; draw missileDst
  lda nmis
  and #$01
  ora #$02
  tax
  ldy oamIndex
drawMissileDstLoop:
  lda missileYHi,x
  beq skipDrawMissileDst
  lda missileDstY,x
  sec
  sbc #5
  sta OAM,y
  lda #PLAYER_MISSILEDST_TILE
  sta OAM+1,y
  lda #%00000011
  sta OAM+2,y
  lda missileDstX,x
  sec
  sbc #4
  sta OAM+3,y
  iny
  iny
  iny
  iny
skipDrawMissileDst:

  dex
  dex
  bpl drawMissileDstLoop
  sty oamIndex
  rts
.endproc

;;
; Finds a slot
; @return C: true if all missile slots are in use
;         X: the missile slot that was used
.proc findMissileSlot
  ldx #4
findSlot:
  lda missileYHi,x
  beq foundAtX
  inx
  cpx #NUM_MISSILES
  bcc findSlot
  rts
foundAtX:
  clc
  rts
.endproc

;;
; Fires a missile from a random location toward a random target.
; @return C: true if a missile was NOT fired
;         X: the missile slot that was used
.proc makeMissile
  jsr findMissileSlot
  bcc foundAtX
  rts
foundAtX:
chosenTarget = 6
chosenHouseX = 7
chosenStartX = 8
chosenStartY = 9
chosenSpeed = 10

  ; Find the starting and ending points
  jsr chooseRandomTarget
  sta chosenTarget
  tay
  lda houseX,y
  asl a
  asl a
  asl a
  adc #8
  sta chosenHouseX
  ldy #6
  jsr random
  lda rand3
  asl a
  asl a
  sta chosenStartX
  lda levelMissileSpeed
  sta chosenSpeed
  lda #MISSILE_SPAWN_Y
  sta chosenStartY

  ; Scale missile velocity by the chosen factor
  lda chosenTarget
  sta missileTarget,x
  lda chosenStartX
  sta missileXHi,x
  sec
  lda chosenHouseX
  sta 2  ; getAngle stuff
  sbc missileXHi,x

  ; getSlope and mul8 need the absolute value
  bcs :+
  eor #$FF
  adc #1
:
  ldy chosenSpeed
  jsr mul8
  asl 0
  rol a
  rol 0
  rol a
  rol 0
  sta 1
  lda 0
  and #$03
  sta 0

  ; put the sign back in
  lda chosenHouseX
  cmp missileXHi,x
  bcs notDXNeg
  lda 1
  eor #$FF
  adc #1
  sta 1
  lda 0
  eor #$FF
  adc #0
  sta 0
notDXNeg:
  lda 1
  sta missileDXLo,x
  lda 0
  sta missileDXHi,x
  lda #BUILDING_HIT_Y
  sec
  sbc chosenStartY
  sta 3
  ; scale missile speed
  ldy levelMissileSpeed
  jsr mul8
  asl 0
  rol a
  rol 0
  rol a
  rol 0
  sta missileDYLo,x
  lda #3
  and 0
  sta missileDYHi,x
  lda #0
  sta missileYLo,x
  sta 1
  lda missileXHi,x
  sta 0
  lda chosenStartY
  sta missileYHi,x
  jsr getAngle
  sta missileAngle,x
  lda #MISSILE_SMOKE_RATE
  sta missileTime,x
  lda #MISSILE_TYPE_NORMAL
  sta missileType,x
  clc
  rts
.endproc

.proc makeBalloon
  jsr findMissileSlot
  bcc foundAtX
  rts
foundAtX:
  
  jsr chooseRandomTarget
  cmp #3
  bcs notBefore3
  adc #1
notBefore3:
  cmp #9
  bcc notAfter9
  sbc #1
notAfter9:
  sta missileTarget,x

  ldy #5
  jsr random
  lda rand3
  and #%00011111
  asl a
  adc #BALLOON_SPAWN_Y
  sta missileYHi,x
  lda #0
  sta missileYLo,x
  sta missileDYHi,x
  sta missileDYLo,x
  sta missileXLo,x
  lda #BALLOON_START_X
  sta missileXHi,x
  lda levelMissileSpeed
  asl a
  sta missileDXLo,x
  lda #0
  rol a
  sta missileDXHi,x
  lda #MISSILE_TYPE_BALLOON
  sta missileType,x
  clc
  rts
.endproc

.proc moveMissileNumberX
  lda missileYHi,x
  bne missileExists
  rts
missileExists:
  clc
  lda missileXLo,x
  adc missileDXLo,x
  sta missileXLo,x
  lda missileXHi,x
  adc missileDXHi,x
  sta missileXHi,x
  clc
  lda missileYLo,x
  adc missileDYLo,x
  sta missileYLo,x
  lda missileYHi,x
  adc missileDYHi,x
  sta missileYHi,x

; Missiles 0-3 are player missiles.  They make smoke every 2 frames,
; they aren't tested for collision with houses,
; and they explode at the crosshair position once their time is up.
  cpx #4
  bcs isEnemyMissile
  stx 3
  tay
  lda missileTime,x
  lsr a
  bcc noPlayerSmoke
  lda missileXHi,x
  tax
  lda #4  ; player smoke dissipates faster
  jsr makeSmoke
  ldx 3
noPlayerSmoke:
  dec missileTime,x
  bne playerMissileNotSplodeTime

  ; save X on stack because making an explosion causes a sound
  ; which trashes a few locals
  txa
  pha
  lda #0
  sta missileYHi,x
  ldy missileDstY,x
  lda missileDstX,x
  tax
  jsr makeExplosion
  pla
  tax
playerMissileNotSplodeTime:
  rts
isEnemyMissile:
  cmp #BUILDING_HIT_Y
  bcc noBoom

; put an explosion at the hit point
  tay
  txa
  pha
  lda missileXHi,x
  tax
  jsr makeExplosion
  pla
  tax

; turn off the destroyed building
  lda missileXHi,x
  lsr a
  lsr a
  lsr a
  ldy #NUM_BUILDINGS - 1
findHitBuilding:
  cmp houseX,y
  bcs gotHitBuilding
  dey
  bne findHitBuilding
gotHitBuilding:
  lda housesStanding,y
  beq wasAlreadyDestroyed
  inc buildingsDestroyedThisLevel
  lda #BUILDING_DESTROYED  ; equals 0
  sta housesStanding,y

  ; If it's a silo, set the number of missiles to 0.
  cpy #2
  bne notSilo0
  sta siloMissilesLeft
  beq wasAlreadyDestroyed
notSilo0:
  cpy #9
  bne notSilo1
  sta siloMissilesLeft+1
  beq wasAlreadyDestroyed
notSilo1:

  ; Otherwise, if it's the first house to be destroyed,
  ; record that fact.
  bit firstDestroyedHouse
  bpl wasAlreadyDestroyed
  sty firstDestroyedHouse
;  sty debugHex1
wasAlreadyDestroyed:

; destroy the missile
  lda #0
  sta missileYHi,x
; and set things up for a redraw
  lda #BG_DIRTY_STATUS|BG_DIRTY_HOUSES
  ora bgDirty
  sta bgDirty
  rts
noBoom:
  ; no smoke for balloons
  lda missileType,x
  cmp #MISSILE_TYPE_BALLOON
  beq isBalloon
  dec missileTime,x
  bne noSmoke
  ldy missileAngle,x
  lda missileSine,y
  eor #$7F
  lsr a
  lsr a
  lsr a
  lsr a
  adc #$F8
  adc missileYHi,x
  sta 3
  lda missileCosine,y
  eor #$7F
  lsr a
  lsr a
  lsr a
  lsr a
  adc #$F8
  adc missileXHi,x
  ldy 3
  stx 3
  tax
  lda #2  ; enemy missile smoke currently dissipates in 80 frames
  jsr makeSmoke
  ldx 3
  lda #MISSILE_SMOKE_RATE
  sta missileTime,x
noSmoke:

  lda missileType,x
  cmp #MISSILE_TYPE_MIRV
  bne notMIRV
  jmp handleMIRV
notMIRV:
  rts

isBalloon:
  lda missileXHi,x
  and #$F8
  beq noSmoke
  lsr a
  lsr a
  lsr a
  sbc #0
  ldy missileTarget,x
  cmp houseX,y
  bcc noSmoke
  jmp splitBalloon
.endproc
.proc splitBalloon
  stx 2
  jsr findMissileSlot
  bcc available2
  ldx 2
  rts
available2:
  
  ; drop at LEAST two missiles, one to left and one to right
  stx 3
  ldy 2
  ; copy Y (balloon) position to X (new missile)
  lda missileYHi,y
  sta missileYHi,x
  lda missileXHi,y
  sta missileXHi,x
  lda #0
  sta missileYLo,x
  sta missileDXHi,y
  sta missileDXHi,x
  sta missileDYHi,x
  sta missileType,x
  sta missileType,y
  ; X to left, Y to right
  lda #9
  sta missileAngle,x
  lda #7
  sta missileTime,x
  sta missileTime,y
  sta missileAngle,y
  lda missileTarget,y
  sec
  sbc #1
  sta missileTarget,x
  clc
  adc #2
  sta missileTarget,y
  lda levelMissileSpeed
  asl a
  rol missileDYHi,x
  asl a
  rol missileDYHi,x
  sta missileDYLo,x
  sta missileDYLo,y
  lda missileDYHi,x
  sta missileDYHi,y
  
  ; calculate horizontal missile speed
  lda #BUILDING_HIT_Y
  sec
  sbc missileYHi,x
  tay
  lda #20
  jsr getSlope1
  ldy levelMissileSpeed
  jsr mul8
  asl 0
  rol a
  asl 0
  rol a
  ldy 2
  sta missileDXLo,y
  lda #$FF
  sta missileDXHi,x
  eor missileDXLo,y
  clc
  adc #1
  sta missileDXLo,x
  
  jsr findMissileSlot
  bcs noMiddle
  lda missileYHi,y
  sta missileYHi,x
  lda missileXHi,y
  sta missileXHi,x
  lda missileDYHi,y
  sta missileDYHi,x
  lda missileDYLo,y
  sta missileDYLo,x
  lda #0
  sta missileYLo,x
  sta missileXLo,x
  sta missileDXLo,x
  sta missileDXHi,x
  sta missileType,x
  lda #8
  sta missileAngle,x
  sta missileTime,x
  lda missileTarget,y
  sec
  sbc #1
  sta missileTarget,x
noMiddle:
  lda #SFX_SPLIT
  jsr start_sound
  ldx 2
  rts
.endproc

.proc handleMIRV
  lda missileYHi,x
  cmp #BUILDING_HIT_Y-128
  bcs notTooHigh
  rts
notTooHigh:

mirvTargets = 6
mirvsLeft = 8
parentSlot = 10
newSlot = 11
mirvDX = 12
mirvDXSign = 13

  ; Place one missile either one to the left or
  ; two to the right of this one.
  lda missileTarget,x
  cmp #9
  bcc notAfter9
  sbc #3
notAfter9:
  clc
  adc #2
  sta mirvTargets+0

  ; Place the other missile either two to the left or
  ; one to the right of this one.
  lda missileTarget,x
  cmp #3
  bcs notBefore3
  adc #3
notBefore3:
  sec
  sbc #2
  sta mirvTargets+1
  
  stx parentSlot
  ldy #1
  sty mirvsLeft
mirvsLoop:
  jsr findMissileSlot
  bcc notFull
  jmp bail
notFull:
  stx newSlot
  ldy mirvsLeft

  ; calculate X distance to target
  lda mirvTargets,y
  tay
  lda houseX,y
  asl a
  asl a
  asl a
  adc #8
  sta 2              ; x2 in math.s/getAngle
  ldx parentSlot
  sec
  sbc missileXHi,x
  sta mirvDX
  lda missileDYLo,x  ; the A register will be occupied for a while
  tay                ; so get the parent missile speed into Y now
  lda #0
  adc #$FF
  sta mirvDXSign

  ; Transform dx into sign-and-magnitude
  cmp #$80
  eor mirvDX
  adc #0
  sta mirvDX
  
  ; Calculate xspeed = yspeed * dx / dy (where dy is always 128)
  jsr mul8
  asl 0
  rol a
  asl 0
  adc #0
  ldx newSlot
  sta missileDXLo,x
  lda mirvDXSign
  sta missileDXHi,x
  cmp #$80
  eor missileDXLo,x
  adc #0
  sta missileDXLo,x
  
  ; copy most from the parent slot
  ldy parentSlot
  lda missileYHi,y
  sta missileYHi,x
  sta 1
  lda missileXHi,y
  sta missileXHi,x
  sta 0
  lda missileDYHi,y
  sta missileDYHi,x
  lda missileDYLo,y
  sta missileDYLo,x
  lda missileTime,y
  sta missileTime,x
  lda #0
  sta missileYLo,x
  sta missileXLo,x
  sta missileType,x
  ldy mirvsLeft
  lda mirvTargets,y
  sta missileTarget,x

  lda #BUILDING_HIT_Y
  sta 3

  lda 2
  ldy mirvsLeft

  jsr getAngle
  ldx newSlot
  sta missileAngle,x

  dec mirvsLeft
  bmi bail
  jmp mirvsLoop
bail:

  ; If at least one split, change the missile into normal
  ldx parentSlot
  lda mirvsLeft
  cmp #1
  beq didNotSplit
  lda #MISSILE_TYPE_NORMAL
  sta missileType,x
  lda #SFX_SPLIT
  jsr start_sound
  ldx parentSlot
didNotSplit:
  rts
.endproc

.proc drawCrosshairPlayerX
  ldy oamIndex
  lda crosshairXHi,x
  sec
  sbc #4
  sta OAM+3,y
  sta OAM+3
  lda crosshairYHi,x
  sec
  sbc #5
  sta OAM,y
  lda #CROSSHAIR_TILE
  sta OAM+1,y
  txa
  sta OAM+2,y

  tya
  clc
  adc #4
  sta oamIndex
  rts
.endproc

;;
; Translates mouse movements to velocities and to 
; To do: translate 2P mouse in 1P game to 1P mouse
.proc mouse_to_vel
  ldx #1
loop:
  lda mouseEnabled,x
  beq no_mouse
  lda #0
  sta crosshairDYLo,x
  sta crosshairDXLo,x
  jsr read_mouse

  lda 3
  bpl xNotNeg
  eor #$7F
  clc
  adc #1
xNotNeg:
  sta crosshairDXHi,x

  lda 2
  bpl yNotNeg
  eor #$7F
  clc
  adc #1
yNotNeg:
  sta crosshairDYHi,x
  
  lda new_mbuttons,x
  and #MOUSE_L|MOUSE_R
  ora new_keys,x
  sta new_keys,x

no_mouse:
  dex
  bpl loop
  
  ; if in 1 player, and port 1 has controller, and port 2 has mouse
  lda numPlayers
  cmp #1
  bne no_copy2pto1p
  lda mouseEnabled+0
  bne no_copy2pto1p
  lda mouseEnabled+1
  beq no_copy2pto1p
  
  ; then copy 2P vel and keys to 1P
  lda new_mbuttons+1
  and #MOUSE_L|MOUSE_R
  ora new_keys
  sta new_keys
  lda #0
  sta crosshairDXLo+0
  sta crosshairDYLo+0
  lda crosshairDXHi+1
  sta crosshairDXHi+0
  lda crosshairDYHi+1
  sta crosshairDYHi+0
no_copy2pto1p:
  rts
.endproc

CROSSHAIR_ACCEL_NTSC = 40
CROSSHAIR_MAX_VEL_NTSC = 4*256

crosshairAccels:
  .byt CROSSHAIR_ACCEL_NTSC, CROSSHAIR_ACCEL_NTSC * 36 / 25
crosshairMaxVelLo:
  .byt <CROSSHAIR_MAX_VEL_NTSC, <(CROSSHAIR_MAX_VEL_NTSC * 6 / 5)
crosshairMaxVelHi:
  .byt >CROSSHAIR_MAX_VEL_NTSC, >(CROSSHAIR_MAX_VEL_NTSC * 6 / 5)

.proc moveCrosshairPlayerX
  lda mouseEnabled,x
  bne noAdjustSpeed

  ldy tvSystem
  beq :+
  ldy #1
:
  lda crosshairMaxVelLo,y
  sta abl_maxVel
  lda crosshairMaxVelHi,y
  sta abl_maxVel+1
  lda crosshairAccels,y
  sta abl_accelRate
  asl a
  asl a
  sta abl_brakeRate

  lda crosshairDXLo,x
  sta abl_vel
  lda crosshairDXHi,x
  sta abl_vel+1
  lda cur_keys,x
  sta abl_keys
  jsr accelBrakeLimit
  lda abl_vel
  sta crosshairDXLo,x
  lda abl_vel+1
  sta crosshairDXHi,x

  lda crosshairDYLo,x
  sta abl_vel
  lda crosshairDYHi,x
  sta abl_vel+1
  lda cur_keys,x
  lsr a
  lsr a
  sta abl_keys
  jsr accelBrakeLimit
  lda abl_vel
  sta crosshairDYLo,x
  lda abl_vel+1
  sta crosshairDYHi,x
noAdjustSpeed:
  
  clc
  lda crosshairDXLo,x
  adc crosshairXLo,x
  sta crosshairXLo,x
  lda crosshairDXHi,x
  adc crosshairXHi,x
  sta crosshairXHi,x
  ; the carry should match the sign of the velocity
  ; if it doesn't, there was a wrap
  ror a
  eor crosshairDXHi,x
  bpl notWrappedX
  eor crosshairDXHi,x
  asl a
  jmp limitX
notWrappedX:
  lda crosshairXHi,x
  cmp #$F8
  bcs limitX
  cmp #$08
  bcs noLimitX
limitX:
  lda #0
  sta crosshairDXLo,x
  sta crosshairDXHi,x
  sta crosshairXLo,x
  lda #$08
  bcc noLimitX
  lda #$F8
noLimitX:
  sta crosshairXHi,x

  clc
  lda crosshairDYLo,x
  adc crosshairYLo,x
  sta crosshairYLo,x
  lda crosshairDYHi,x
  adc crosshairYHi,x
  sta crosshairYHi,x
  ; the carry should match the sign of the velocity
  ; if it doesn't, there was a wrap
  ror a
  eor crosshairDYHi,x
  bpl notWrappedY
  eor crosshairDYHi,x
  asl a
  jmp limitY
notWrappedY:
  lda crosshairYHi,x
  cmp #$B0
  bcs limitY
  cmp #$10
  bcs noLimitY
limitY:
  lda #0
  sta crosshairDYLo,x
  sta crosshairDYHi,x
  sta crosshairYLo,x
  lda #$10
  bcc noLimitY
  lda #$B0
noLimitY:
  sta crosshairYHi,x
  
  rts
.endproc

;;
; Fires a player missile.
; Steps:
; 1. Make sure the silo is not out of missiles.
; 2. Search for an empty player missile slot.
; 3. Set up all the missile parameters.
; x: silo number (0 or 1)
; 2: dst X
; 3: dst Y
.proc firePlayerMissile
mslot = 7
mdist = 6
  lda siloMissilesLeft,x
  beq outOfMissiles
.if ::CHECK_ILLEGAL_MISSILES
  cmp #21
  bcc :+
  lda #ILLEGAL_MISSILES_TIP
  sta curTip
  lda #50
  sta tipTimeLeft
  lda #BG_DIRTY_TIP
  ora bgDirty
  sta bgDirty
:
.endif
  txa
  tay
  lda missileYHi,y
  beq foundEmptySlot
  iny
  iny
  lda missileYHi,y
  beq foundEmptySlot
outOfMissiles:
  rts
foundEmptySlot:

  ; at this point, X is the silo number and Y is the slot number
  dec siloMissilesLeft,x
  sty mslot
  lda #BG_DIRTY_STATUS
  ora bgDirty
  sta bgDirty
  lda #0
  sta missileYLo,y
  lda #SILO_Y
  sta missileYHi,y
  lda 2
  sta missileDstX,y
  lda 3
  sta missileDstY,y
  txa
  lsr a
  lda #128
  ror a
  sta missileXHi,y
  jsr measureFromSilo
  ldx mslot
  ; at this point, A = distance, X = slot number, and 3 = angle
  ; set time till explosion
  sta mdist
  
  ; if in PAL, scale travel time by 81.25% (should be 83.33% but
  ; nobody will notice the difference)
  ldy tvSystem
  beq noPALCorrection
  lsr a
  lsr a
  adc mdist
  ror a
  adc mdist
  ror a
noPALCorrection:

  lsr a
  lsr a
  adc #0
  
  ; Occasionally in NTSC, when a player missile is fired toward the
  ; top corner of the screen opposite the silo, player missile travel
  ; time may hit 64 or 65 frames.  This causes trouble farther down
  ; because we have to divide displacements by (time * 4) to get
  ; velocity.  So clamp this time to 63.
  cmp #63
  bcc :+
  lda #63
:
  sta missileTime,x
  ; set velocity
  lda 3
  sta missileAngle,x
  
  ; get the Y component of velocity = y displacement / time
  lda missileTime,x
  asl a
  asl a
  tay
  sec
  lda #SILO_Y
  sbc missileDstY,x
  lsr a
  jsr getSlope1
  eor #$FF
  sta 0
  lda #$FF
  sec
  rol 0
  rol a
  rol 0
  rol a
  rol 0
  rol a
  sta missileDYHi,x
  lda 0
  sta missileDYLo,x

  ; likewise, get the X component of velocity
  ; = abs(x displacement) / time
  lda missileTime,x
  asl a
  asl a
  tay
  sec
  lda missileDstX,x
  sbc missileXHi,x
  bcs xNotNeg1
  eor #$FF
  adc #1
xNotNeg1:
  lsr a
  jsr getSlope1
  sta 0
  lda #0
  asl 0
  rol a
  asl 0
  rol a
  asl 0
  rol a
  sta missileDXHi,x
  lda missileDstX,x
  cmp missileXHi,x
  lda missileDXHi,x
  bcs xNotNeg2
  eor #$FF
  sta missileDXHi,x
xNotNeg2:
  lda 0
  bcs xNotNeg3
  eor #$FF
xNotNeg3:
  sta missileDXLo,x

  lda #SFX_LAUNCH
  jsr start_sound
  rts
.endproc
  

.segment "RODATA"
; These are indexed by angle & $0F
; Tile numbers for fat missiles (MIRVs) are ORed with $08
missileTileNumber:
  .byt $07,$0F,$0E,$0D,$0C,$0B,$0A,$09,$08,$09,$0A,$0B,$0C,$0D,$0E,$0F

; These are indexed by angle >> 3
missileTileFlip:
  .byt $00,$40,$C0,$80
missileTileHotspotY:
  .byt 6
missileTileHotspotX:  
  .byt 6, 1, 1, 6
