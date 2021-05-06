; bg.s
; In-game background display functions for Thwaite

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

BG_GRASSNUM = $10
TILE_BETWEEN_HOUSES = $8F
BUILDING_WRECKAGE_TILE = $9E
BG_USE_DEBUGHEX = 0

BG_GRASSO = BG_GRASSNUM+0
BG_GRASSA = BG_GRASSNUM+10
BG_GRASSB = BG_GRASSNUM+11
BG_GRASSC = BG_GRASSNUM+12
BG_GRASSD = BG_GRASSNUM+13
BG_GRASSE = BG_GRASSNUM+14
BG_GRASSF = BG_GRASSNUM+15
BG_GRASSH = $A0
BG_GRASSM = $A1
BG_GRASSN = $A2
BG_GRASSR = $A3
BG_GRASSS = $A4
BG_GRASST = $A5
BG_GRASSU = $A6
BG_GRASSW = $A7
BG_GRASSCOLON = $A8
; $A9 is the copyright symbol, for latin-1 consistency
BG_GRASSI = $AA


houseXferBuf = $0100
houseXferDstHi = $0140
houseXferDstLo = $0141

.segment "BSS"

; housesStanding is 0 for destroyed, 1 for OK, 2 for threatened
housesStanding:  .res NUM_BUILDINGS

buildingsDestroyedThisLevel: .res 1
score100s: .res 1
score1s: .res 1
gameDay: .res 1
gameHour: .res 1
gameMinute: .res 1
gameSecond: .res 1
gameTenthSecond: .res 1
gameSubTenth: .res 1
bgDirty: .res 1
curTip: .res 1
tipTimeLeft: .res 1
siloMissilesLeft: .res 2
firstDestroyedHouse: .res 1

.segment "CODE"
.proc setupGameBG
  lda #VBLANK_NMI
  ldx #$00
  ldy #$3F
  sta PPUCTRL
  stx PPUMASK
  sty PPUADDR
  stx PPUADDR
  stx bgDirty
copypal:
  lda main_palette,x
  sta PPUDATA
  inx
  cpx #32
  bcc copypal

; fill first 24 rows of nametable with stars
  ldy #$20
  ldx #0
  stx tipTimeLeft
  sty PPUADDR
  stx PPUADDR
skyloop:
  txa
  and #$0F
  ora #$08
  sta 0
  lda starRowX,x
  sta 1
  ldy #32
skycloop:
  lda #0
  dec 1
  bne :+
  lda 0
:
  sta PPUDATA
  dey
  bne skycloop
  inx
  cpx #24
  bcc skyloop

  ; draw the ground starting at row 26
  lda #$23
  sta PPUADDR
  lda #$40
  sta PPUADDR
  ldy #4
groundloop:
  tya
  asl a
  and #$06
  ora #$04
  ldx #16
groundcloop:
  sta PPUDATA
  eor #$01
  sta PPUDATA
  eor #$03
  dex
  bne groundcloop
  dey
  bne groundloop

  ldx #48
attrtop:
  sty PPUDATA
  dex
  bne attrtop

  ldy #0
  ldx #8
attrhouses:
  lda houseAttr,y
  sta PPUDATA
  iny
  dex
  bne attrhouses

  ldy #%10101010
  ldx #8
attrground:
  sty PPUDATA
  dex
  bne attrground

  jsr buildHouseTiles
  jsr blitBGUpdate
  jsr buildStatusBar
  jsr blitBGUpdate
  rts
.endproc

.proc buildBGUpdate

  ; is it time to take the tip off the screen?
  lda gameSubTenth
  cmp #2
  bne notTipUpdateTime
  lda tipTimeLeft
  beq notTipUpdateTime
  dec tipTimeLeft
  bne notTipUpdateTime
  lda bgDirty
  ora #BG_DIRTY_TIP
  sta bgDirty
notTipUpdateTime:

  ; if someone manually calls an updater such as buildLevelRewardBar,
  ; the transfer buffer will be full.  Ignore dirty status
  ; in this case.
  lda houseXferDstHi
  bne xferBufferIsFull

  lda bgDirty
  lsr a
  bcc houseNotDirty
  jmp buildHouseTiles
houseNotDirty:
  lsr a
  bcc statusNotDirty
  jmp buildStatusBar
statusNotDirty:
  lsr a
  bcc eraseTipNotDirty
  jmp buildTipBar
eraseTipNotDirty:
  lsr a
  bcc practiceMeterNotDirty
  jmp buildPracticeMeterBar
practiceMeterNotDirty:

xferBufferIsFull:
  rts
.endproc

.proc buildHouseTiles
  lda bgDirty
  and #~BG_DIRTY_HOUSES
  sta bgDirty
  lda #$23
  sta houseXferDstHi
  lda #$00
  sta houseXferDstLo
  ldx #31
clearBuf:
  lda #0
  sta houseXferBuf,x
  lda #TILE_BETWEEN_HOUSES
  sta houseXferBuf+32,x
  dex
  bpl clearBuf

  ldy #11
houseloop:
  lda houseX,y
  tax
  lda housesStanding,y
  bne isStanding
  lda #BUILDING_WRECKAGE_TILE
  bne bottomHalfOnly
isStanding:
  lda houseShape,y
  sta houseXferBuf,x
  eor #$01
  sta houseXferBuf+1,x
  eor #$11
bottomHalfOnly:
  sta houseXferBuf+32,x
  eor #$01
  sta houseXferBuf+33,x
.if ::SHOW_THREATENED
  lda housesStanding,y
  cmp #BUILDING_THREATENED
  bne :+
  lda #'!'
  sta houseXferBuf,x
:
.endif
  dey
  bpl houseloop
  rts
.endproc

.proc buildStatusBar
  lda bgDirty
  and #~BG_DIRTY_STATUS
  sta bgDirty
  lda #$23
  sta houseXferDstHi
  lda #$40
  sta houseXferDstLo
  lda #$04
  ldx #0
loop:
  sta houseXferBuf,x
  eor #$01
  sta houseXferBuf+1,x
  eor #$02
  sta houseXferBuf+33,x
  eor #$01
  sta houseXferBuf+32,x
  inx
  inx
  cpx #32
  bcc loop
  
  lda siloMissilesLeft
  jsr bcd8bit
  ora #BG_GRASSNUM
  sta houseXferBuf+8
  lda 0
  beq noLeftTens
  ora #BG_GRASSNUM
  sta houseXferBuf+7
noLeftTens:
  lda siloMissilesLeft+1
  jsr bcd8bit
  ora #BG_GRASSNUM
  sta houseXferBuf+24
  lda 0
  beq noRightTens
  ora #BG_GRASSNUM
  sta houseXferBuf+23
noRightTens:

  lda gameDay
  asl a
  adc gameDay
  cmp #7*3
  bcc notNextWeek
  sbc #7*3
notNextWeek:
  tax
  ldy #0
copyDay:
  lda gameDayNames,x
  sta houseXferBuf+53,y
  inx
  iny
  cpy #3
  bcc copyDay
  
  lda gameHour
  sec
  adc #BG_GRASSNUM
  sta houseXferBuf+58
  lda gameTenthSecond
  cmp #5
  bcs noColon
  lda #BG_GRASSCOLON  ; colon
  sta houseXferBuf+59
noColon:
  lda gameMinute
  jsr bcd8bit
  ora #BG_GRASSNUM
  sta houseXferBuf+61
  lda #BG_GRASSNUM
  sta houseXferBuf+57
  ora 0
  sta houseXferBuf+60
  
  ; draw score
  lda #BG_GRASSNUM
  sta houseXferBuf+38
  sta houseXferBuf+39
  lda score100s
  beq noScore100s
  jsr bcd8bit
  ora #BG_GRASSNUM
  sta houseXferBuf+35
  lda 0
  beq noScore100s
  ora #BG_GRASSNUM
  sta houseXferBuf+34
noScore100s:
  lda score1s
  jsr bcd8bit
  ora #BG_GRASSNUM
  sta houseXferBuf+37
  lda 0
  ora score100s
  beq noScore10s
  lda 0
  ora #BG_GRASSNUM
  sta houseXferBuf+36
noScore10s:

  rts
.endproc

.proc clearTipBar
  ldy #31
  lda #0
:
  sta houseXferBuf+32,y
  sta houseXferBuf,y
  dey
  bpl :-
  ldy starRowX+8
  lda #8
  sta houseXferBuf,y
  ldy starRowX+9
  lda #9
  sta houseXferBuf+32,y

  lda bgDirty
  and #~BG_DIRTY_TIP
  sta bgDirty
  ldy #$21
  lda #$00
  sty houseXferDstHi
  sta houseXferDstLo
  rts
.endproc

;;
; Builds the practice mode ammo/speed/delay meters
.proc buildPracticeMeterBar
  jsr clearTipBar
  lda #$40  ; row 10-11 instead of 8-9
  sta houseXferDstLo
  lda bgDirty
  and #~BG_DIRTY_PRACTICE_METER
  sta bgDirty
  
  ; Ammo
  lda enemyMissilesLeft
  jsr bcd8bit
  ora #'0'
  sta houseXferBuf+6
  lda 0
  beq noAmmoTens
  ora #'0'
  sta houseXferBuf+5
noAmmoTens:

  ; Delay
  lda levelReleasePeriod
  jsr bcd8bit
  ora #'0'
  sta houseXferBuf+19
  lda 0
  ora #'0'
  sta houseXferBuf+17
  
  ; Delay units
  lda #'s'
  sta houseXferBuf+21
  lda #'.'
  sta houseXferBuf+18

  ; Speed 
  lda levelMissileSpeed
  jsr bcd8bit
  ora #'0'
  sta houseXferBuf+13
  lda 0
  beq noSpeedTens
  ora #'0'
  sta houseXferBuf+12
  lda 0
  cmp #16
  bcc noSpeedTens
  lsr a
  lsr a
  lsr a
  lsr a
  ora #'0'
  sta houseXferBuf+11
  
noSpeedTens:

  rts
.endproc

.import tipTexts
;;
; If tipTimeLeft is nonzero, draws tip number curTip. Otherwise,
; erases the tip.
.proc buildTipBar
tipSrc = 14

  jsr clearTipBar
  ldx #2
  ; If we're suffixing a tip onto a name, we enter here.
suffix:

  lda curTip
  asl a
  tay
  lda tipTexts,y
  sta tipSrc
  lda tipTexts+1,y
  sta tipSrc+1

  ; load the current gameplay tip
  lda tipTimeLeft
  beq doneLoadingTip
  ldy #0
loadTipLoop:
  lda (tipSrc),y
  beq doneLoadingTip
  cmp #10
  bne notNewline
  ldx #34
  bne tipContinue
notNewline:
  sta houseXferBuf,x
  inx
tipContinue:
  iny
  bne loadTipLoop
doneLoadingTip:
  rts
.endproc

;;
; Builds the "Nice Job!" message after a level
; @param 0 Displayed number of houses
; @param 1 Displayed points added
; @param siloMissilesLeft Number of missiles left
.proc buildLevelRewardBar
  ; First load the tip
  lda #2
  sta curTip
  lda #50
  sta tipTimeLeft
  jsr buildTipBar

  ; Write the number of houses now, because bcd8bit
  ; destroys the value in 0
  lda 0
  jsr bcd8bit
  ora #'0'
  sta houseXferBuf+41
  lda 0
  beq noHouseTens
  ora #'0'
  sta houseXferBuf+40
noHouseTens:

  ; Write the number of unused player missiles
  clc
  lda siloMissilesLeft+1
  adc siloMissilesLeft
  jsr bcd8bit
  ora #'0'
  sta houseXferBuf+45
  lda 0
  beq noMissileTens
  ora #'0'
  sta houseXferBuf+44
noMissileTens:

  ; Write 
  lda 1
  jsr bcd8bit
  ora #'0'
  sta houseXferBuf+59
  lda 0
  beq noBonusTens
  ora #'0'
  sta houseXferBuf+58
  lda 0
  cmp #16
  bcc noBonusTens
  lsr a
  lsr a
  lsr a
  lsr a
  ora #'0'
  sta houseXferBuf+57
noBonusTens:

  rts
.endproc

;;
; Draws a tip with a villager's name prepended.
; @param Y the villager id (0-11)
.proc buildHouseRebuiltBar
tipSrc = 14
  lda character_name_offset,y
  pha
  jsr clearTipBar
  pla
  clc
  adc #<character_name0
  sta tipSrc
  lda #0
  adc #>character_name0
  sta tipSrc+1
  ldx #2
  ldy #0
copynameloop:
  lda (tipSrc),y
  beq copynamedone
  sta houseXferBuf,x
  inx
  iny
  bne copynameloop
copynamedone:
  jmp buildTipBar::suffix
.endproc

.proc blitBGUpdate
  lda houseXferDstHi
  beq noblit
  ldx houseXferDstLo
  clc
  sta PPUADDR
  stx PPUADDR
  ldx #0
  stx houseXferDstHi
loop:
  .repeat 8, I
    lda houseXferBuf+I,x
    sta PPUDATA
  .endrepeat
  txa
  adc #8
  tax
  cpx #64
  bcc loop
noblit:
.if ::BG_USE_DEBUGHEX
  lda #$23
  sta PPUADDR
  lda #$4E
  sta PPUADDR
  lda debugHex1
  jsr puthex
  lda debugHex2
  jsr puthex
.endif
  rts
.endproc

.proc puthex
  pha
  lsr a
  lsr a
  lsr a
  lsr a
  ora #BG_GRASSNUM
  sta PPUDATA
  pla
  and #$0F
  ora #BG_GRASSNUM
  sta PPUDATA
  rts  
.endproc

.proc newGame
  lda #BUILDING_OK
  ldx #11
:
  sta housesStanding,x
  dex
  bpl :-
  stx firstDestroyedHouse  ; bit 7 set: nothing destroyed yet
  lda #SKIP_TO_DAY
  sta gameDay
  lda #0
  sta gameHour
  sta gameMinute
  sta gameSecond
  sta gameTenthSecond
  sta gameSubTenth
  sta score100s
  sta score1s
  rts
.endproc

;;
; Adds between 1 and 255 points to the score.
; X, Y, and memory (apart from score) are unchanged.
.proc addScore
  clc
  adc score1s
  bcc notOver256
  inc score100s
  inc score100s
  adc #55
notOver256:
  cmp #100
  bcc notOver100
  sbc #100
  inc score100s
  bcs notOver256
notOver100:
  sta score1s
  lda bgDirty
  ora #BG_DIRTY_STATUS
  sta bgDirty
  rts
.endproc

.proc incGameClock
  inc gameSubTenth
  lda gameSubTenth
  
  ; if the TV system is not NTSC, end the frame one frame early
  ldy tvSystem
  beq subTenthIsNTSC
  clc
  adc #1
subTenthIsNTSC:
  ldy #0
  cmp #6
  bcc notRollOver
  sty gameSubTenth

  inc gameTenthSecond
  ldx gameTenthSecond
  cpx #5
  bne notHalfSecond
  lda #BG_DIRTY_STATUS  ; for blinking the colons
  ora bgDirty
  sta bgDirty
notHalfSecond:
  cpx #10
  bcc notRollOver
  sty gameTenthSecond
  lda #BG_DIRTY_STATUS
  ora bgDirty
  sta bgDirty

  inc gameSecond
  lda gameSecond
  cmp #60
  bcc notRollOver
  sty gameSecond

  inc gameMinute
  ; random round start time should never place minute in 50-59

notRollOver:
  rts
.endproc


;;
; Count the number of houses (that is, buildings other than silos)
; that are standing.
; @return number of houses in Y
.proc countHousesLeft
  ldx #NUM_BUILDINGS-1
  ldy #0
counthousesleftloop:
  cpx #2
  beq :+
  cpx #9
  beq :+
  lda housesStanding,x
  beq :+
  iny
:
  dex
  bpl counthousesleftloop
  rts
.endproc


.segment "RODATA"
; house colors are    R   G  ===  R   G   B   R   G   B  ===  G   B
houseX:         .byt   2,  4,  7, 10, 12, 14, 16, 18, 20, 23, 26, 28
houseShape:     .byt $80,$82,$88,$84,$86,$80,$82,$84,$86,$8A,$80,$82
houseAttr:      .byt $A6,$AE,$A7,$AE,$A9,$A7,$A9,$AB

gameDayNames:
  .byt BG_GRASSS,BG_GRASSU,BG_GRASSN  ; SUN
  .byt BG_GRASSM,BG_GRASSO,BG_GRASSN  ; MON
  .byt BG_GRASST,BG_GRASSU,BG_GRASSE  ; TUE
  .byt BG_GRASSW,BG_GRASSE,BG_GRASSD  ; WED
  .byt BG_GRASST,BG_GRASSH,BG_GRASSU  ; THU
  .byt BG_GRASSF,BG_GRASSR,BG_GRASSI  ; FRI
  .byt BG_GRASSS,BG_GRASSA,BG_GRASST  ; SAT

starRowX:
  .byt 15, 29, 22,  1
  .byt  5,  4,  9,  8
  .byt 11, 26, 18,  6
  .byt 19, 30, 27, 10
  .byt 25,  0, 31, 23
  .byt  3, 28, 16, 12

main_palette:
  .byt $0F,$00,$10,$20,$0F,$17,$16,$20,$0F,$17,$2A,$20,$0F,$17,$12,$20
  .byt $0F,$12,$22,$00,$0F,$16,$27,$38,$0F,$16,$1A,$26,$0F,$00,$12,$26

