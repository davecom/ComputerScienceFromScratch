;
; Target selection for Thwaite
; Copyright (C) 2011 Damian Yerrick
;
; This program is free software: you can redistribute it and/or modify
; it under the terms of the GNU General Public License as published by
; the Free Software Foundation, either version 3 of the License, or
; (at your option) any later version.
;
; This program is distributed in the hope that it will be useful,
; but WITHOUT ANY WARRANTY; without even the implied warranty of
; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
; GNU General Public License for more details.
;
; You should have received a copy of the GNU General Public License
; along with this program.  If not, see <http://www.gnu.org/licenses/>.
;
.include "src/ram.h"
;.include "src/nes.h"  ; for debugging high level shit
.segment "ZEROPAGE"
rand0: .res 1
rand1: .res 1
rand2: .res 1
rand3: .res 1
lastTarget: .res 1
lruTargets: .res NUM_BUILDINGS

.segment "CODE"
;; random
; Uses the crc32 polynomial to generate Y
; pseudorandom bits as the low_order bits of rand3.
; Average 48 cycles per bit.
;
.proc random
  asl rand3
  rol rand2
  rol rand1
  rol rand0
  bcc @no_xor
  lda rand0
  eor #$04
  sta rand0
  lda rand1
  eor #$c1
  sta rand1
  lda rand2
  eor #$1d
  sta rand2
  lda rand3
  eor #$b7
  sta rand3
@no_xor:
  dey
  bne random
  rts
.endproc

.proc chooseRandomTarget
  ldy #3
  jsr random
  lda #$07
  and rand3
  clc
  adc #NUM_BUILDINGS - 8
  tay
  lda lruTargets,y
  pha
loop:
  lda lruTargets-1,y
  sta lruTargets,y
  dey
  bne loop
  pla
  sta lruTargets
  rts
.endproc

.proc initRandomTarget
  ldy #NUM_BUILDINGS - 1
:
  lda initLRUData,y
  sta lruTargets,y
  dey
  bpl :-
  rts
.endproc

.proc findRandomDestroyedHouse
  ldx #NUM_BUILDINGS - 2
  stx 0
  ldy #3
  jsr random
  lda #$07
  and rand3
  clc
  adc #2
  tax
searchloop:
  lda initLRUData,x
  tay
  lda housesStanding,y
  beq found
  inx
  cpx #NUM_BUILDINGS
  bcc :+
  ldx #2
:
  dec 0
  bne searchloop
  ldy #$FF
found:
  rts
.endproc

.segment "RODATA"
; Initial LRU data for chooseRandomTarget.  Putting 2, 9 at the
; front helps new players by not immediately blowing up the silos. 
initLRUData:
  .byt 2, 9, 11, 0, 1, 10, 8, 3, 4, 7, 6, 5
