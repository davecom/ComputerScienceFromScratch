; Double Action Blaster Guys
;
; Copyright (C) 2012-2013 Princess Nova Storm the Squirrel
;
; This program is free software: you can redistribute it and/or
; modify it under the terms of the GNU General Public License as
; published by the Free Software Foundation; either version 3 of the
; License, or (at your option) any later version.
;
; This program is distributed in the hope that it will be useful, but
; WITHOUT ANY WARRANTY; without even the implied warranty of
; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
; General Public License for more details.
;
; You should have received a copy of the GNU General Public License
; along with this program.  If not, see <http://www.gnu.org/licenses/>.

;.setcpu "6502X"
.include "ns_nes.s" ; handy macros and defines
.include "common.s" ; handy routines
.include "memory.s"
.include "main.s"
.include "player.s"
.include "newgame.s"
.include "meta.s"
.include "bullets.s"
.include "object.s"
.include "screens.s"
.include "levels.s"
.include "misc.s"
.include "unpkb.s"
.include "edit.s"
.include "explosion.s"
.include "powerups.s"
.include "math.s"
.include "unpb53.s"

.include "musicseq.h"
.include "sound.s"
.include "music.s"
.include "musicseq.s"

.segment "INESHDR"
  .byt "NES", $1A
  .byt 2     ; PRG in 16kb units
  .byt 0     ; CHR in 8kb units
  .byt 0     ; horizontal mirroring
  .byt %1000 ; NES 2.0
  .byt 0     ; extra mapper bits
  .byt 0     ; extra PRG/CHR bits
  .byt $00   ; no PRG RAM
  .byt $07   ; 8 kb of CHR RAM
  .byt 0     ; NTSC (PAL works but no speed adjustments are made)
  .byt 0     ; regular PPU

.segment "VECTORS"
VectorAddrs:
  .addr nmi, reset, irq
.segment "CODE"

.proc reset
  lda #0		; Turn off PPU
  sta PPUCTRL
  sta PPUMASK
  sei
  ldx #$FF	; Set up stack pointer
  txs		; Wait for PPU to stabilize

: lda PPUSTATUS
  bpl :-
: lda PPUSTATUS
  bpl :-

  lda #0
  sta SND_CHN

; write a palette
  lda #$3F
  sta PPUADDR
  lda #$00
  sta PPUADDR

  ldx #0
: lda #$31
  sta PPUDATA
  lda #$0f
  sta PPUDATA
  lda MainColors,x
  sta PPUDATA
  lda #$30
  sta PPUDATA
  inx
  cpx #8
  bne :-
  ; put brown in the green palette
  lda #$3f
  sta PPUADDR
  lda #$07
  sta PPUADDR
  lda #$17
  sta PPUDATA

  jsr DecompressCHR

  ldx #0
  txa
: sta $000,x
  sta $100,x
  sta $300,x
  sta $400,x
  sta $500,x
  sta $600,x
  sta $700,x
  inx
  bne :-

  lda #$21
  sta FlashColor

  ; init randomizer
  lda #$69
  sta r_seed
  lda #$5a
  sta random1+0
  lda #$a5
  sta random1+1
  lda #$53
  sta random2+0
  lda #$76
  sta random2+1

  lda #0
  sta HasExtraRAM

  lda #VBLANK_NMI | NT_2000 | OBJ_8X8 | BG_0000 | OBJ_1000
  sta PPUCTRL

  jmp StartMainMenu
.endproc


.proc DecompressCHR
  DecCount = 15
  Ignore = 14
; write graphics
  lda #64 ;8192/128
  sta DecCount
  lda #16*5
  sta Ignore

  lda #0
  sta PPUADDR
  sta PPUADDR
  lda #<CHR
  sta ciSrc+0
  lda #>CHR
  sta ciSrc+1
  lda #0
  sta ciBufStart
  lda #128
  sta ciBufEnd
DecLoop:
  jsr unpb53_some
  ldx #0
: lda Ignore
  beq DontIgnore
    dec Ignore
    jmp Ignored
DontIgnore:
  lda PB53_outbuf,x
  sta PPUDATA
Ignored:
  inx
  cpx #128
  bne :-
  dec DecCount
  bne DecLoop
  rts
.endproc

.proc nmi
  pha
  inc retraces
  lda #0
  sta OAMADDR
  sta OamPtr
  lda #2
  sta OAM_DMA

  lda EnableNMIDraw
  bne :+
    pla
    rti
: dec EnableNMIDraw

  lda #$3f
  sta PPUADDR
  lda #$1e
  sta PPUADDR
  lda FlashColor
  sta PPUDATA
  lda retraces
  and #1
  beq :+
  lda FlashColor
  add #1
  sta FlashColor
  cmp #$2c
  bne :+
    lda #$21
    sta FlashColor
  :

 .repeat 7, I ; change if the max number of tile changes per frame is changed
    lda TileUpdateA1+I
    beq :+
      sta PPUADDR
      lda TileUpdateA2+I
      sta PPUADDR
      lda TileUpdateT+I
      sta PPUDATA
      lda #0
      sta TileUpdateA1+I
    :
 .endrep
 .repeat 3, I ; change if the max number of metatile changes per frame is changed
    lda BlockUpdateA1+I
    beq :+
      sta PPUADDR
      lda BlockUpdateA2+I
      sta PPUADDR
      lda BlockUpdateT1+I
      sta PPUDATA
      lda BlockUpdateT2+I
      sta PPUDATA

      lda BlockUpdateB1+I
      sta PPUADDR
      lda BlockUpdateB2+I
      sta PPUADDR
      lda BlockUpdateT3+I
      sta PPUDATA
      lda BlockUpdateT4+I
      sta PPUDATA
      lda #0
      sta BlockUpdateA1+I
    :
  .endrep

  lda ScrollMode
  jne NoDraw
.if 0
  beq :+
;    lda ScrollGameMode
;    jeq NoDraw
    lda #VBLANK_NMI | NT_2000 | OBJ_8X8 | BG_0000 | OBJ_1000 | VRAM_DOWN
    sta PPUCTRL
    lda Update28Address+0
    sta PPUADDR
    lda Update28Address+1
    sta PPUADDR
    jsr Draw28
    jmp NoDraw
  :
.endif
  PositionXY 0, 2,2
  jsr Draw28

  PositionXY 0, 2,3
  .repeat 11, I
    lda StatusRow2 + I
    sta PPUDATA
  .endrep

NoDraw:
  bit PPUSTATUS
  lda ScrollX+1
  sta PPUSCROLL
  lda #0
  sta PPUSCROLL

  lda #VBLANK_NMI | NT_2000 | OBJ_8X8 | BG_0000 | OBJ_1000
  sta PPUCTRL
  pla
  rti

Draw28:
  .repeat 28, I
    lda StatusRow1 + I
    sta PPUDATA
  .endrep
  rts
.endproc

.proc ClearStatusRows
  lda #' '
  ldx #0
: sta StatusRow1,x
  inx
  cpx #28
  bne :-
  ldx #0
: sta StatusRow2,x
  inx
  cpx #12
  bne :-
  rts
.endproc

.proc MainColors
  .byt $16, $29, $03, $28
  .byt $01, $16, $21, $21
.endproc
.proc BackgroundColors
  .byt $31, $36, $38, $23
.endproc

CHR:
.incbin "ascii.pb53"

.proc irq
	rti
.endproc
