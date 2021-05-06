; levels.s
; Level loading code and level definitions for Thwaite

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

.include "src/ram.h"

.import levelTips

.segment "RODATA"
; Seven parameters vary per round:  the speed of the missiles, the
; number of missiles before the round ends, the time between salvos
; (groups of missiles spawned together), and the four kinds of salvos
; that appear in the round.  There is an unused flags byte, which was
; originally going to store salvo types until I decided on the
; current system.
;
; Salvo types 1-5 are just that many missiles.
; 8 is a balloon (costs 2 missiles)
; 9 is a MIRV (costs 2 missiles)

; Number of days in levels.s::levelTable and tips.s::levelTips
NUM_MADE_DAYS = 7

; Debug build to test balance starting at a specific day
; (0: sun; 7: sat)
; Always set to 0 for release builds.
SKIP_TO_DAY = 0

levelTable:
  ;     +----------------------- missile speed (unit: px/85 frames)
  ;     |   +------------------- number of missiles
  ;     |   |   +--------------- time between salvos (unit: 100 ms)
  ;     |   |   |   +----------- flags (unused)
  ;     |   |   |   |         +- salvo types (1, 2, 3, 4, 5, 8, 9)
  ;     |   |   |   |         |
  ;SUN spd num tim unused     salvo types
  ; The first level is almost painfully slow.  It's for nooblets
  ; and grandmas.
  .byt  16, 10, 50,%00000000, 1, 1, 2, 2
  .byt  17, 15, 45,%00000000, 2, 2, 3, 3
  .byt  18, 20, 40,%00000000, 2, 3, 4, 8
  .byt  19, 25, 37,%00000000, 3, 4, 4, 9
  .byt  20, 30, 35,%00000000, 3, 4, 5, 9

  ;MON spd num tim            types
  .byt  20, 20, 30,%00000000, 8, 3, 4, 8
  .byt  21, 25, 25,%00000000, 9, 3, 4, 8
  .byt  22, 30, 20,%00000000, 9, 4, 4, 8
  ; Occasionally, we surprise the player with levels where the
  ; progression in difficulty is irregular, in order to teach the
  ; player to adapt to different play styles.
  ; Mon 04 has unusually fast missiles, but not as many of them.
  .byt  64, 15, 30,%00000000, 1, 1, 2, 2
  .byt  24, 30, 25,%00000000, 4, 4, 9, 9

  ;TUE
  ; Tue 01 is a preview of Balloon Fever.
  .byt  25, 30, 20,%00000000, 4, 8, 8, 8
  .byt  26, 30, 25,%00000000, 3, 3, 4, 8
  .byt  28, 30, 25,%00000000, 3, 4, 4, 8
  .byt  29, 32, 25,%00000000, 3, 4, 5, 8
  .byt  30, 32, 25,%00000000, 9, 4, 5, 8

  ;WED
  ; Wed 01 is the first of the "Balloon Fever" levels.  All missiles
  ; are either balloons or MIRVs, and the number of missiles is
  ; cranked up to reflect that each balloon or MIRV uses up two
  ; missiles.  If the aim is off or slow, watch split then boom.
  ; Fortunately, the player always has both silos at the beginning
  ; of a day, but it's easy to lose them if the player runs out of
  ; ammo.  And it's really easy to run out of ammo when cleaning up
  ; after a couple splits.  So for this reason don't crank up the
  ; ammo more than 40.
  .byt  44, 34, 20,%00000000, 8, 8, 8, 9
  .byt  32, 30, 24,%00000000, 9, 3, 4, 9
  ; Wed 03 is another fast level
  .byt  64, 20, 30,%00000000, 1, 1, 2, 2
  .byt  33, 28, 23,%00000000, 8, 3, 5, 8
  .byt  34, 35, 22,%00000000, 9, 4, 5, 8

  ;THU
  .byt  52, 36, 18,%00000000, 8, 8, 8, 9
  .byt  34, 25, 22,%00000000, 9, 4, 5, 9
  .byt  35, 25, 21,%00000000, 8, 4, 5, 8
  .byt  36, 30, 21,%00000000, 9, 4, 5, 9
  .byt  37, 35, 20,%00000000, 9, 4, 5, 8  ; yup, a wakeup call level
  ;FRI
  .byt  58, 38, 16,%00000000, 8, 8, 8, 9
  .byt  35, 30, 20,%00000000, 9, 4, 5, 9
  .byt  36, 30, 20,%00000000, 8, 4, 5, 8
  .byt  72, 20, 30,%00000000, 1, 2, 2, 9
  .byt  38, 35, 20,%00000000, 9, 4, 5, 8
  ;SAT
  .byt  64, 40, 15,%00000000, 8, 8, 8, 9
  .byt  37, 30, 20,%00000000, 9, 4, 5, 9
  .byt  38, 30, 20,%00000000, 8, 4, 5, 8
  .byt  39, 30, 20,%00000000, 9, 4, 5, 9
  .byt  40, 35, 20,%00000000, 9, 4, 5, 8


.segment "BSS"
; Do not shuffle these; they must remain in the same order as in
; levelTable or level loading will fail.
levelMissileSpeed:  .res 1
enemyMissilesLeft:  .res 1
levelReleasePeriod: .res 1
levelMissileFlags:  .res 1
levelSalvoSizes:    .res 4

.segment "CODE"

;;
; Loads the data for a level
; @param A level number (0-63)
.proc loadLevel
  tax
  lda isPractice
  bne noLoadTip
  lda levelTips,x
  sta curTip
  cpx #1
  bne notTwoPlayerReplace
  lda numPlayers
  cmp #2
  bne notTwoPlayerReplace
  lda #11  ; two player tip
  sta curTip
notTwoPlayerReplace:
  lda #BG_DIRTY_TIP
  ora bgDirty
  sta bgDirty
  lda #50
  sta tipTimeLeft
noLoadTip:
  txa
  asl a
  asl a
  asl a
  sta 0
  lda #0
  rol a
  sta 1
  lda #<levelTable
  adc 0
  sta 0
  lda #>levelTable
  adc 1
  sta 1
  ldy #7
copyloop:
  lda (0),y
  sta levelMissileSpeed,y
  dey
  bpl copyloop

  ; Make missiles 18.75% faster on PAL (should be 20% but
  ; who'll notice?)
  ldx tvSystem
  beq noPALCorrection
  lsr a
  adc levelMissileSpeed
  lsr a
  lsr a
  lsr a
  adc levelMissileSpeed
  sta levelMissileSpeed
noPALCorrection:

  rts
.endproc

