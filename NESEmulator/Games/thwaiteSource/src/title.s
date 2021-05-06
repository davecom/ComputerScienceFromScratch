;
; title.s
; title screen code for Thwaite

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

B_TO_RESET = 0

.segment "CODE"
;;
; Displays the text file pointed to at (0)
; starting at (2, 3) on nametable $2000.
.proc display_textfile
src = 0
dstLo = 2
dstHi = 3
  lda #$20
  sta dstHi
  lda #$62
  sta dstLo
txt_rowloop:
  ldy dstHi
  sty PPUADDR
  ldy dstLo
  sty PPUADDR
  ldy #0
txt_charloop:
  lda (src),y
  beq txt_done
  cmp #$0A
  beq is_newline
  sta PPUDATA
  iny
  bne txt_charloop
is_newline:

  sec
  tya
  adc src+0
  sta src+0
  lda src+1
  adc #0
  sta src+1
  lda dstLo
  adc #32
  sta dstLo
  lda dstHi
  adc #0
  sta dstHi
  cmp #$23
  bcc txt_rowloop
  lda dstLo
  cmp #$C0
  bcc txt_rowloop

txt_done:
  rts
.endproc

.proc display_todo
  lda #VBLANK_NMI
  ldx #$00
  ldy #$3F
  sta PPUCTRL
  stx PPUMASK
  sty PPUADDR
  stx PPUADDR
copypal:
  lda title_palette,x
  sta PPUDATA
  inx
  cpx #32
  bcc copypal

  ; clear nt
  ldy #$20
  sty PPUADDR
  ldy #$00
  sty PPUADDR
  tya
:
  sta PPUDATA
  sta PPUDATA
  sta PPUDATA
  sta PPUDATA
  dey
  bne :-

  lda #>todo_txt
  sta 1
  lda #<todo_txt
  sta 0
  jsr display_textfile

  ;use this when testing a new song
;  lda #4
;  jsr init_music

loop:
  lda nmis
:
  cmp nmis
  beq :-
  lda #0
  ldx #VBLANK_NMI|BG_0000
  ldy #BG_ON
  sta PPUSCROLL
  sta PPUSCROLL
  stx PPUCTRL
  sty PPUMASK
  jsr update_sound
  jsr read_pads
  jsr title_detect_mice

.if ::B_TO_RESET
  lda new_keys
  and #KEY_B
  beq notB
  jmp ($FFFC)
notB:
.endif

  lda mouseEnabled+0
  beq no_mouse
  lda new_mbuttons+0
  and #MOUSE_L
  bne done
no_mouse:
  lda new_keys
  and #KEY_A|KEY_START
  beq loop
done:
  rts
.endproc

.proc titleScreen
  jsr display_todo
  lda #VBLANK_NMI
  ldx #$00
  ldy #$3F
  sta PPUCTRL
  stx PPUMASK
  sty PPUADDR
  stx PPUADDR
  lda #1
  sta numPlayers
  lda #128
  sta crosshairYHi+0
  sta crosshairXHi+0
copypal:
  lda title_palette,x
  sta PPUDATA
  inx
  cpx #32
  bcc copypal
  
  lda #<title_pkb
  sta 0
  lda #>title_pkb
  sta 1
  ldx #$20
  stx PPUADDR
  ldy #$00
  sty PPUADDR
  jsr PKB_unpackblk
  
  lda #$F0
  ldx #$04
:
  sta OAM,x
  inx
  bne :-
  
loop:
  jsr title_draw_sprites
  lda nmis
:
  cmp nmis
  beq :-
  bit PPUSTATUS
  
  ldy #0
  lda #VBLANK_NMI|BG_0000|OBJ_1000
  ldx #>OAM
  sty OAMADDR
  sty PPUSCROLL
  sty PPUSCROLL
  sta PPUCTRL
  stx OAM_DMA

  ldx #BG_ON|OBJ_ON
  stx PPUMASK

  jsr update_sound
  jsr read_pads
  jsr title_detect_mice

s0wait0:
  bit $2002
  bvs s0wait0
s0wait1:
  bit $2002
  bmi s0waitfail
  bvc s0wait1
  lda #VBLANK_NMI|BG_1000|OBJ_1000
  sta PPUCTRL
s0waitfail:

  jsr title_move_numPlayers
  
.if ::B_TO_RESET
  lda new_keys
  and #KEY_B
  beq notB
  jmp ($FFFC)
notB:
.endif

  ; Let the buttons of the first mouse
  ldx #0
  lda mouseEnabled,x
  bne handleClick
  inx
  lda mouseEnabled,x
  bne handleClick
doneClick:
  lda new_keys+0
  and #(KEY_START | KEY_A)
  beq loop
done:

  ; mix the current time into the rng
  lda nmis
  eor rand3
  clc
  adc rand1
  sta rand1
  ldy #8
  jmp random  ; and off we go, done with the title screen

  ; Appendix: How to handle mouse clicks
handleClick:
  lda new_mbuttons,x
  and #MOUSE_L
  beq doneClick
  lda crosshairYHi+0
  sec
  sbc #128
  lsr a
  lsr a
  lsr a
  lsr a
  
  ; Row 0: Change speed
  ; Row 1: 1 player; 2: 2 player; 3: Practice
  beq changeSpd
  cmp #4
  bcs doneClick
  sta numPlayers
  jmp done
changeSpd:
  ldx #0
  lda crosshairXHi+0
  bpl :+
  inx
:
  jsr mouse_change_sensitivity
  jmp doneClick
.endproc

;;
; Checks for the signature of a Super NES Mouse, which is $x1
; on the second read report.
; Stores 0 for no mouse or 1-3 for mouse sensitivity 1/4, 1/2, 1
.proc title_detect_mice
  lda #0
  sta 4
  sta 5
  ldx #1
loop:
  jsr read_mouse
  lda 1
  and #$0F
  cmp #1
  bne notMouse
  lda 2
  sta 4
  lda 3
  sta 5
  lda 1
  and #$30
  lsr a
  lsr a
  lsr a
  lsr a
  clc
  adc #1
  bne isMouse
notMouse:
  lda #0
isMouse:
  sta mouseEnabled,x
  dex
  bpl loop

  ; If a mouse is connected, 4 will have Y motion and 5 will have
  ; X motion
  
  lda 4
  bpl mouseNotDown
  eor #$7F
  clc
  adc #$01
mouseNotDown:
  clc
  adc crosshairYHi+0
  cmp #128
  bcs noClipTop
  lda #128
noClipTop:
  cmp #191
  bcc noClipBottom
  lda #191
noClipBottom:
  sta crosshairYHi+0

  lda 5
  bpl mouseNotLeft
  eor #$7F
  clc
  adc #$01
mouseNotLeft:
  clc
  adc crosshairXHi+0
  cmp #48
  bcs noClipLeft
  lda #48
noClipLeft:
  cmp #207
  bcc noClipRight
  lda #207
noClipRight:
  sta crosshairXHi+0
  rts
.endproc

.proc title_move_numPlayers
  ldx numPlayers
  lda new_keys
  and #KEY_SELECT
  beq notSelect
  inx
  cpx #4
  bcc notSelect
  ldx #1
notSelect:

  lda new_keys
  and #KEY_DOWN
  beq notDown
  inx
  cpx #4
  bcc notDown
  dex
notDown:

  lda new_keys
  and #KEY_UP
  beq notUp
  dex
  bne notUp
  inx
notUp:

  stx numPlayers
  rts
.endproc

.proc title_draw_sprites
  ldx oamIndex

  lda mouseEnabled
  ora mouseEnabled+1
  beq noMouseCrosshair
  lda crosshairYHi+0
  sec
  sbc #5
  sta OAM,x
  lda crosshairXHi+0
  sec
  sbc #4
  sta OAM+3,x
  lda #4
  sta OAM+1,x
  lda #0
  sta OAM+2,x

  inx
  inx
  inx
  inx
noMouseCrosshair:

  ; Draw arrow for number of players
  lda numPlayers
  asl a
  asl a
  asl a
  asl a
  pha
  lda nmis
  lsr a
  pla
  adc #130
  sta OAM+0,x
  lda #SELECTED_ARROW_TILE
  sta OAM+1,x
  lda #1
  sta OAM+2,x
  lda #76
  sta OAM+3,x
  txa
  clc
  adc #4
  tax
  
  ldy #1
miceloop:
  lda mouseEnabled,y
  beq not_mouse
  jsr draw_mouse_player_y

not_mouse:
  dey
  bpl miceloop

  stx oamIndex
  jsr clearRestOfOAM

  ; draw sprite 0, used to switch in CHR for "1 Player" text
  ; (which is written in FH, 15px autohinted)
  lda #102
  sta OAM+0
  lda #$01
  sta OAM+1
  lda #$23  ; black sprite on black bg, behind
  sta OAM+2
  lda #172
  sta OAM+3
  rts

draw_mouse_player_y:
  ; Y coordinate
  lda #127
  sta OAM+0,x
  sta OAM+4,x
  sta OAM+8,x
  sta OAM+12,x
  lda #135
  sta OAM+16,x
  sta OAM+20,x
  sta OAM+24,x
  sta OAM+28,x
  
  ; Tile numbers
  tya
  ora #$60
  sta OAM+1,x
  ora #$10
  sta OAM+17,x
  lda mouseEnabled,y
  clc
  adc #$56
  sta OAM+13,X
  sta OAM+29,x
  lda #$68
  sta OAM+5,x
  lda #$69
  sta OAM+9,x
  lda #$78
  sta OAM+21,x
  lda #$79
  sta OAM+25,x

  ; Colors
  lda #$00
  sta OAM+2,x
  sta OAM+14,x
  sta OAM+18,x
  sta OAM+30,x
  lda #$02
  sta OAM+6,x
  sta OAM+10,x
  sta OAM+22,x
  sta OAM+26,x

  ; X coordinate
  lda mouse_icon_x,y
  sta OAM+3,x
  sta OAM+19,x
  adc #8
  sta OAM+7,x
  sta OAM+23,x
  adc #8
  sta OAM+11,x
  sta OAM+27,x
  ; and the speed lines
  adc #6
  sta OAM+15,x
  adc #1
  sta OAM+31,x

  txa
  clc
  adc #32
  tax
  rts
.endproc

.segment "RODATA"
; backdrop: black
; bg0: dark gray, light gray, white
; bg1: brown, red, white
; bg2: brown, green, white
; bg3: brown, blue, white
; obj0: blue, light blue, ? (player 1 crosshair and presents)
; obj1: red, orange, pale yellow (player 2 crosshair, missiles, balloons, and explosions)
; obj2: red, green, peach (villagers)
; obj3: gray, orange, peach (villagers, smoke)

title_pkb:
  .incbin "src/title.pkb"
todo_txt:
  .incbin "todo.txt"
  .byt 0
title_palette:
  .byt $0F,$00,$10,$20,$0F,$17,$16,$20,$0F,$17,$2A,$20,$0F,$17,$12,$20
  ;    grayscale        arrow            mouse            sprite 0
  .byt $0F,$00,$10,$30, $0F,$16,$27,$38, $0F,$00,$10,$13, $0F,$0F,$0F,$0F
mouse_icon_x:
  .byt 92, 140
