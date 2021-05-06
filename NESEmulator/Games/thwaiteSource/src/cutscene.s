; cutscene.s
; Cut scene code and character data for Thwaite

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
.import cut_scripts

cutStateTimer = tipTimeLeft
.segment "ZEROPAGE"
script_ptr: .res 2
stacked_script_ptr: .res 2
cutscene_vram_dst_lo: .res 1
cutscene_vram_dst_hi: .res 1

CUT_STATE_SCRIPT = 0
CUT_STATE_WAIT_A = 1
CUT_STATE_CLS = 2
CUT_STATE_NEW_GRAPH = 3

.segment "BSS"

cutFadeDir: .res 1
cutFadeAmount: .res 1
variable_actor_ids: .res 3
actor_paranoid = variable_actor_ids
actor_detective = variable_actor_ids + 1
actor_laidback = variable_actor_ids + 2
cutscene_actors: .res 4

.segment "CODE"

.proc load_cutscene
  asl a
  tax
  lda cut_scripts,x
  sta script_ptr
  lda cut_scripts+1,x
  sta script_ptr+1
  
  lda #$3F
  sta cutFadeAmount
  lda #$FD
  sta cutFadeDir
  
  lda nmis
vw1:
  cmp nmis
  beq vw1
  lda #VBLANK_NMI
  sta PPUCTRL
  lda #0
  sta PPUMASK
  jsr update_sound

  lda #$20
  sta PPUADDR
  lda #$00
  sta PPUADDR
  sta stacked_script_ptr+1
  lda #<cutscene_pkb
  sta 0
  lda #>cutscene_pkb
  sta 1
  jsr PKB_unpackblk
  
  ; now hide the houses that have been blown up
  ldy #5
  ; this part uses vertical nametable writes
  lda #VBLANK_NMI|VRAM_DOWN
  sta PPUCTRL
blown_up_mod:
  lda housesStanding+3,y
  bne this_one_not_blown_up
  jsr hideHouseY
this_one_not_blown_up:
  dey
  bpl blown_up_mod
  lda #VBLANK_NMI
  sta PPUCTRL
  
  ldx #cutscene_init_oam_end - cutscene_init_oam - 1
oamcopyloop:
  lda cutscene_init_oam,x
  sta OAM,x
  dex
  bne oamcopyloop
  lda cutscene_init_oam
  sta OAM
  ldx #cutscene_init_oam_end - cutscene_init_oam
  lda #$F0
oamendloop:
  sta OAM,x
  inx
  bne oamendloop
  
; Load the actors
  ldy #0
load_actors_loop:
  lda (script_ptr),y
  sta cutscene_actors,y
  iny
  cpy #4
  bcc load_actors_loop
  clc
  tya
  adc script_ptr
  sta script_ptr
  bcc :+
  inc script_ptr+1
:
  
  lda #$20
  sta PPUADDR
  lda #$8E
  sta PPUADDR
  jsr cut_handle_state_new_graph

  lda #MUSIC_1600
  jsr init_music
main_loop:
  jsr update_sound
  
  lda nmis
vw:
  cmp nmis
  beq vw

  ; copy faded palette
  lda cutFadeAmount
  beq doneFading
  and #$F0
  sta 0
  lda #$3F
  sta PPUADDR
  ldx #$00
  stx PPUADDR
palloop:
  lda cutscene_palette,x
  sec
  sbc 0
  bpl palNotNeg
  cmp #$F0
  bne palNotF0
  lda #$02
  bne palNotNeg
palNotF0:
  lda #$0F
palNotNeg:
  sta PPUDATA
  inx
  cpx #$20
  bcc palloop
  bcs skipHandleScript
doneFading:
  jsr cut_handle_state
skipHandleScript:

  lda #>OAM
  ldx #0
  stx OAMADDR
  sta OAM_DMA
  lda #VBLANK_NMI|BG_1000|OBJ_1000
  ldy #BG_ON|OBJ_ON
  sta PPUCTRL
  stx PPUSCROLL
  stx PPUSCROLL
  sty PPUMASK

  jsr read_pads
  lda mouseEnabled+0
  beq no_read_mouse
  ldx #0
  jsr read_mouse
no_read_mouse:
  lda new_keys
  and #KEY_START
  beq notStart
  lda #4
  sta cutFadeDir
notStart:

s0wait0:
  bit $2002
  bvs s0wait0
s0wait1:
  bit $2002
  bmi s0waitfail
  bvc s0wait1
  lda #VBLANK_NMI|BG_0000|OBJ_1000
  sta PPUCTRL
s0waitfail:

  lda cutFadeDir
  clc
  adc cutFadeAmount
  sta cutFadeAmount
  and cutFadeDir
  bpl notWrappedToNeg
  lda #0
  sta cutFadeAmount
  sta cutFadeDir
notWrappedToNeg:
  
  lda cutFadeDir
  bmi jmp_loop
  lda cutFadeAmount
  cmp #$20
  bcs bail
jmp_loop:
  jmp main_loop
bail:
  jmp stop_music
  
hideHouseY:
  sty 0
  tya
  asl a
  asl a
  ora #$81
  adc 0
  sta 0
  ldx #3
hideloop:
  lda #$21
  sta PPUADDR
  lda 0
  inc 0
  sta PPUADDR
  lda #$00
  sta PPUDATA
  sta PPUDATA
  txa
  eor #$BB
  sta PPUDATA
  eor #$04
  sta PPUDATA
  dex
  bpl hideloop
  rts
.endproc

.proc cut_handle_state
  lda #$FF
  sta OAM+cutscene_init_oam_end-cutscene_init_oam-4
  lda gameState
  asl a
  tax
  lda states+1,x
  pha
  lda states,x
  pha
  rts
.segment "RODATA"
states:
  .addr cut_handle_state_script-1
  .addr cut_handle_state_wait_a-1
  .addr cut_handle_state_cls-1
  .addr cut_handle_state_new_graph-1
.segment "CODE"
.endproc

.proc cut_handle_state_script
  ldy #0
  lda (script_ptr),y
  bne not_nul

  ; The script stack (used for $ commands) is one level deep.  
  lda stacked_script_ptr+1
  beq stack_underflow
  sta script_ptr+1
  lda stacked_script_ptr
  sta script_ptr
  lda #0
  sta stacked_script_ptr+1
  beq cut_handle_state_script
stack_underflow:

  lda #CUT_STATE_WAIT_A
  sta gameState
  rts
  
not_nul:

  inc script_ptr
  bne :+
  inc script_ptr+1
:
  cmp #12
  bne not_formfeed
  lda #CUT_STATE_WAIT_A
  sta gameState
  rts
not_formfeed:

  cmp #10
  bne not_newline
  lda cutscene_vram_dst_lo
  and #%11100000
  clc
  adc #34
  sta cutscene_vram_dst_lo
  bcc :+
  inc cutscene_vram_dst_hi
:
  rts
not_newline:
  cmp #'$'
  beq is_dollar
  ldx cutscene_vram_dst_hi
  stx PPUADDR
  ldx cutscene_vram_dst_lo
  inc cutscene_vram_dst_lo
  stx PPUADDR
  sta PPUDATA
  rts
is_dollar:
  lda (script_ptr),y
  pha
  clc
  lda script_ptr
  adc #1
  sta stacked_script_ptr
  lda script_ptr+1
  adc #0
  sta stacked_script_ptr+1
  pla
  jsr cut_translate_actorid
  clc
  tax
  lda #<character_name0
  adc character_name_offset,x
  sta script_ptr
  lda #>character_name0
  adc #0
  sta script_ptr+1
  jmp cut_handle_state_script
.endproc

.proc cut_handle_state_wait_a
  lda nmis
  and #%00011000
  beq no_show_marker
  lda cutscene_init_oam_end-4
  sta OAM+cutscene_init_oam_end-cutscene_init_oam-4
no_show_marker:
  lda mouseEnabled
  beq not_pressed_lmb
  lda new_mbuttons
  and #MOUSE_L
  bne pressed_lmb

not_pressed_lmb:
  lda #KEY_A
  and new_keys
  beq not_pressed_A

pressed_lmb:
  ; So the player has pressed A.  Now is this the end of this script?
  ; If the next byte of this script or the stacked script is nonzero,
  ; the script is not at its end.
  ldy #0
  lda (script_ptr),y
  bne script_not_done
  lda stacked_script_ptr+1
  beq script_is_done
  lda (stacked_script_ptr),y
  bne script_not_done

script_not_done:
  ; The script is not done; it needs the screen cleared
  ; for the next paragraph.
  lda #CUT_STATE_CLS
  sta gameState
  lda #$81
  sta cutscene_vram_dst_lo
not_pressed_A:
  rts
script_is_done:
  lda #4
  sta cutFadeDir
  rts
.endproc

.proc cut_handle_state_cls
  lda #$22
  sta PPUADDR
  lda cutscene_vram_dst_lo
  sta PPUADDR
  ldy #6
  lda #' '
clrloop:
  .repeat 5
  sta PPUDATA
  .endrepeat
  dey
  bne clrloop
  lda cutscene_vram_dst_lo
  clc
  adc #32
  sta cutscene_vram_dst_lo
  bcc notDoneYet
  lda #CUT_STATE_NEW_GRAPH
  sta gameState
notDoneYet:
  rts
.endproc

.proc cut_handle_state_new_graph
  lda #$22
  sta PPUADDR
  sta cutscene_vram_dst_hi
  lda #$81
  sta PPUADDR
  lda #$A2
  sta cutscene_vram_dst_lo
  lda #'<'
  sta PPUDATA
  ldy #0
  
  ; Fetch the speaker
  lda (script_ptr),y
  inc script_ptr
  bne :+
  inc script_ptr+1
:
  jsr cut_translate_actorid

  ; Fetch the speaker's name
  cmp #15
  bcc :+
  lda #15
  clc
:
  tax
  lda #<character_name0
  adc character_name_offset,x
  sta 0
  lda #>character_name0
  adc #0
  sta 1
  ldy #0
loop:
  lda (0),y
  beq nul
  sta PPUDATA
  iny
  bne loop
nul:
  lda #'>'
  sta PPUDATA
  lda #CUT_STATE_SCRIPT
  sta gameState
  rts
.endproc

;;
; Translates a role letter ('A'-'Z') into a name id (0-22).
; Trashes Y.
; @param A role letter
; @return name id
.proc cut_translate_actorid
  sec
  sbc #'A'
  cmp #'X'-'A'
  bcc not_role
  sbc #'X'-'A'
  tay
  lda variable_actor_ids,y
not_role:
  rts
.endproc

;;
; Chooses three villagers at random to fit the three roles in the
; game's script, according to the villagers' personalities.
; @param X 1 for game start, 0 for already having chosen paranoid
.proc cut_choose_villagers
randacc = 3

  ldy #6
  jsr random
  lda rand3
  sta randacc
  cpx #0
  beq alreadyParanoid

  ; choose the paranoid one
  jsr randpull3
  tax
  lda paranoid_characters,x
  sta actor_paranoid
alreadyParanoid:

  ; choose the laid-back one
  jsr randpull3
  tax
  lda laidback_characters,x
  cmp actor_paranoid
  bne laidback_is_ok
  
  ; if the laid-back is the same person as the paranoid (which
  ; could happen by promotion after the old laid-back's house
  ; was destroyed), get a new laid-back
  ldy #1
  jsr random
  lda rand3
  lsr a  ; carry is randomly 0 or 1
  txa
  adc #1  ; a is randomly x + 1 or x + 2
  cmp #3
  bcc laidback_no_wrap
  sbc #3
laidback_no_wrap:
  tax
  lda laidback_characters,x
laidback_is_ok:
  sta actor_laidback

  ; choose the detective
  ldy #2
  jsr random
  lda #%00000011
  and rand3
  tax
  lda detective_characters,x
  sta actor_detective
  
  ; if the detective is the same person as the paranoid (which
  ; could happen by promotion after the old detective's house
  ; was destroyed), get a new detective
  cmp actor_paranoid
  beq find_another_detective

  ; if all three are the same sex, also get a new detective
  tay
  lda character_sex,y
  ldy actor_laidback
  eor character_sex,y
  bmi opposite_sexes
  ldy actor_laidback
  lda character_sex,y
  ldy actor_paranoid
  eor character_sex,y
  bmi opposite_sexes

  ; then find another detective.  They're arranged in the list
  ; alternating by sex, so xor 
find_another_detective:
  txa
  eor #%00000001
  tax
  lda detective_characters,x
  sta actor_detective
opposite_sexes:

  rts

randpull3:
  lda randacc
  and #%00111111
  sta randacc
  asl randacc
  adc randacc
  sta randacc
  and #%11000000
  asl a
  rol a
  rol a
  rts  
.endproc


.segment "RODATA"
cutscene_palette:
  .byt $22,$18,$2A,$0F  ; grass and text
  .byt $22,$20,$16,$08  ; houseR
  .byt $22,$20,$2A,$08  ; houseG
  .byt $22,$20,$12,$08  ; houseB
  .byt $22,$1A,$2A,$26  ; tree, people (green)
  .byt $22,$17,$27,$26  ; tree trunk
  .byt $22,$16,$12,$26  ; people 1
  .byt $22,$00,$10,$26  ; clouds, people 2

cutscene_pkb:
  .incbin "src/cutscene.pkb"

cutscene_init_oam:
  .byt 126,$01,$21,248  ; sprite 0 for CHR split
  .byt 118,$55,$01,  0
  .byt 110,$54,$01,  0
  .byt 102,$55,$81,  0
  .byt 118,$55,$01,  0
  .byt 110,$54,$01,  0
  .byt 102,$55,$81,  0
  .byt  95,$53,$20,  0
  .byt  95,$52,$60,  8
  .byt  87,$51,$20,  0
  .byt  87,$50,$60,  8
  .byt  79,$50,$60,  4
  .byt  79,$51,$20,  0
  .byt 118,$55,$01,240
  .byt 110,$54,$01,240
  .byt 102,$55,$81,240
  .byt  95,$52,$20,232
  .byt  95,$53,$20,240
  .byt  95,$52,$60,248
  .byt  87,$50,$20,232
  .byt  87,$51,$20,240
  .byt  87,$50,$60,248
  .byt  79,$50,$20,236
  .byt  79,$50,$60,244
  .byt 183,$56,$02,232

cutscene_init_oam_end:

character_name_offset:
  .byt character_name0-character_name0
  .byt character_name1-character_name0
  .byt character_name2-character_name0
  .byt character_name3-character_name0
  .byt character_name4-character_name0
  .byt character_name5-character_name0
  .byt character_name6-character_name0
  .byt character_name7-character_name0
  .byt character_name8-character_name0
  .byt character_name9-character_name0
  .byt character_name10-character_name0
  .byt character_name11-character_name0
  .byt character_name12-character_name0
  .byt character_name13-character_name0
  .byt character_name14-character_name0

character_name0:  .byt "T¯da",0
character_name1:  .byt "Meg",0
character_name2:  .byt "M¯o",0    ; Player 1
character_name3:  .byt "Isca",0
character_name4:  .byt "Gnivad",0
character_name5:  .byt "Justin",0
character_name6:  .byt "Briar",0
character_name7:  .byt "Acha",0
character_name8:  .byt "Torben",0
character_name9:  .byt "Staisy",0  ; Player 2
character_name10: .byt "Thad",0
character_name11: .byt "Oliver",0
character_name12: .byt "L.T.D.",0  ; Traveling musician
character_name13: .byt "Pino",0    ; Hidden TAS character
character_name14: .byt "???",0

; $00 for male, $80 for female
character_sex: .byt $80,$80, $00, $80,$00,$00,$80,$80,$00, $80, $00,$00
paranoid_characters:  .byt 0, 6, 8
laidback_characters:  .byt 1, 5, 10
detective_characters: .byt 3, 4, 7, 11

