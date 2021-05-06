; smoke.s
; Dissipating smoke drawing functions for Thwaite

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

NUM_SMOKE = 48
FIRST_SMOKE_TILE = $10
SMOKE_PALETTE = $23
.segment "BSS"
smokeX: .res NUM_SMOKE
smokeY: .res NUM_SMOKE
smokeSpeed: .res NUM_SMOKE
smokeTime: .res NUM_SMOKE

.segment "CODE"
;;
; Makes a smoke particle at (x, y) with dissipation speed a.
.proc makeSmoke
xpos = 0
ypos = 1
dissipSpeed = 2
  sta dissipSpeed
  txa
  clc
  adc #252
  bcc cancelSmoke
  sta xpos
  tya
  adc #250
  sta ypos
  bcc cancelSmoke

  ; Look for the best slot for this explosion.
  ; The "best" slot is the one whose explosion has been on screen
  ; the longest.
  ; y holds the index of the best slot so far
  ; x holds the index of the slot currently being considered
  ldx #NUM_SMOKE - 2
  ldy #NUM_SMOKE - 1
  
findFreeSlot:
  ; if the time in x is less than the time in y, y is a better slot
  lda smokeTime,x
  cmp smokeTime,y
  bcc notBetterSlot
  ; otherwise x is a better slot, so set y to x
  txa
  tay
notBetterSlot:
  dex
  bpl findFreeSlot
  lda dissipSpeed
  sta smokeSpeed,y
  lda #0
  sta smokeTime,y
  lda xpos
  sta smokeX,y
  lda ypos
  sta smokeY,y
cancelSmoke:
  rts
.endproc

.proc updateSmoke
  lda nmis
  and #$01
  clc
  adc #NUM_SMOKE - 2
  tax
  ldy oamIndex
smokeloop:
  ; set tile number if the particle is still active
  lda smokeTime,x
  cmp #5*32
  bcs smokecontinue
  lsr a
  lsr a
  lsr a
  lsr a
  lsr a
  clc
  adc #FIRST_SMOKE_TILE
  sta OAM+1,y

  ; set (pretransformed) coordinates
  lda smokeY,x
  sta OAM,y
  lda smokeX,x
  sta OAM+3,y
  
  ; put bits 2-1 of vblank count into smoke's flip bits
  lda nmis
  ror a
  ror a
  ror a
  ror a
  and #$C0
  ora #SMOKE_PALETTE
  sta OAM+2,y
  lda smokeTime,x
  clc
  adc smokeSpeed,x
  sta smokeTime,x
  iny
  iny
  iny
  iny
  beq bail
smokecontinue:
  dex
  dex
  bpl smokeloop
bail:
  sty oamIndex
  rts
.endproc

.proc clearAllSmoke
  ldy #NUM_SMOKE - 1
  lda #$FF
loop:
  sta smokeTime,y
  dey
  bpl loop
  rts
.endproc
