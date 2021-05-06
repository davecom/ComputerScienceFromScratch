;
; Music sequence data for Thwaite
; Copyright 2010 Damian Yerrick
;
; Copying and distribution of this file, with or without
; modification, are permitted in any medium without royalty provided
; the copyright notice and this notice are preserved in all source
; code copies.  This file is offered as-is, without any warranty.
;
; Translation: Go ahead and make your ReMixes, but credit me.

.include "src/musicseq.h"

.segment "RODATA"

; Sound effect map for Thwaite
;  0 MIRV splitting into three ordinary missiles
;  1 Snare drum (triangle part)
;  2 Kick drum (triangle part)
;  3 Hi-hat
;  4 Alert (pulse 1 part)
;  5 Alert (pulse 2 part)
;  6 Missile launch
;  7 Explosion (pulse part)
;  8 Explosion (noise part)
;  9 Snare drum (noise part)
; 10 Kick drum (noise part)
psg_sound_table:
  .addr mirv_split_snd
  .byt 0, 18
  .addr snare2_snd
  .byt 8, 2
  .addr kick2_snd
  .byt 8, 4
  .addr hihat_snd
  .byt 12, 2
  .addr threat1_snd
  .byt 0, 21

  .addr threat2_snd
  .byt 16+0, 10
  .addr shoot_snd
  .byt 64+12, 7
  .addr boom1_snd
  .byt 16+0, 15
  .addr boom2_snd
  .byt 48+12, 16
  .addr snare_snd
  .byt 12, 7

  .addr kick_snd
  .byt 12, 3

; alternating duty/volume and pitch bytes

mirv_split_snd:
  .byt $4F, $24, $44, $24
  .byt $4F, $29, $44, $29
  .byt $4F, $2E, $44, $2E
  .byt $44, $24, $42, $24
  .byt $44, $29, $42, $29
  .byt $44, $2E, $42, $2E
  .byt $42, $24, $41, $24
  .byt $42, $29, $41, $29
  .byt $42, $2E, $41, $2E
snare2_snd:
  .byt $8F, $26, $8F, $25
kick2_snd:
  .byt $8F, $1F, $8F, $1B, $8F, $18, $82, $15
hihat_snd:
  .byt $06, $03, $04, $83
threat1_snd:
  .byt $46, $1F
  .byt $4C, $1F, $4C, $1F, $4C, $25, $4C, $25
  .byt $4C, $2B, $4C, $2B, $4C, $31, $4C, $31
  .byt $4C, $31, $4C, $31, $4C, $31, $4C, $31, $4C, $31, $4C, $31
  .byt $4C, $31, $4B, $31, $4A, $31, $49, $31, $47, $31, $45, $31
threat2_snd:
  .byt $4C, $1C, $4C, $22
  .byt $4C, $28, $4C, $2E
  .byt $4C, $2E, $4C, $2E, $4C, $2E, $4B, $2E, $49, $2E, $46, $2E
shoot_snd:
  .byt $0A, $03, $08, $04, $07, $04, $06, $05
  .byt $04, $06, $03, $06, $02, $06
boom1_snd:
  .byt $8F, $12, $4F, $0F, $8E, $0C
  .byt $0E, $0E, $8D, $0C, $4C, $0A
  .byt $8B, $0B, $0A, $09, $89, $06
  .byt $48, $08, $87, $07, $06, $05
  .byt $84, $06, $42, $04, $81, $03
boom2_snd:
  .byt $0F, $0E
  .byt $0E, $0D
  .byt $0D, $0E
  .byt $0C, $0E
  .byt $0B, $0E
  .byt $0A, $0F
  .byt $09, $0E
  .byt $08, $0E
  .byt $07, $0F
  .byt $06, $0E
  .byt $05, $0F
  .byt $04, $0E
  .byt $03, $0F
  .byt $02, $0E, $01, $0F, $01, $0F
snare_snd:
  .byt $0A, 085, $08, $84, $06, $04
  .byt $04, $84, $03, $04, $02, $04, $01, $04
kick_snd:
  .byt $08,$04,$08,$0E,$04,$0E
  .byt $05,$0E,$04,$0E,$03,$0E,$02,$0E,$01,$0E
  
; Each drum consists of one or two sound effects.
drumSFX:
  .byt 10, 2
  .byt 1,  9
  .byt 3, -1
KICK  = 0*8
SNARE = 1*8
CLHAT = 2*8

instrumentTable:
  ; first byte: initial duty (0/4/8/c) and volume (1-F)
  ; second byte: volume decrease every 16 frames
  ; third byte:
  ; bit 7: cut note if half a row remains
  .byt $88, 0, $00, 0  ; bass
  .byt $47, 2, $00, 0  ; piano
  .byt $86, 1, $00, 0  ; bell between rounds
  .byt $87, 2, $00, 0  ; xylo long
  .byt $87, 6, $00, 0  ; xylo short
  .byt $05, 0, $00, 0  ; distant horn blat
  .byt $88, 4, $00, 0  ; xylo medium

songTable:
  .addr hr4_conductor, hr2_conductor, hr3_conductor, hr4_conductor, hr5_conductor
  .addr cleared_conductor, hr16_conductor

musicPatternTable:
  ; patterns 0-3: 2 AM
  .addr hr2_sq1, hr2_sq2, hr2_bass, hr2_drums
  ; pattern 4: cleared
  .addr cleared_sq1
  ; patterns 5-10: 3 AM
  .addr hr3_drums, hr3_tri_1, hr3_tri_2, hr3_sq1_1, hr3_sq2_1, hr3_sq2_2
  ; patterns 11-14: 4 AM
  .addr hr4_sq1, hr4_sq2, hr4_drums, hr4_drums_2
  ; patterns 15-18: 4 PM
  .addr hr16_sq1, hr16_sq2, hr16_tri, hr16_drums
  ; patterns 19-xx: 5 AM
  .addr hr5_sqloop, hr5_triloop, hr5_melody

;____________________________________________________________________
; 02:00 theme
; This is the famous first eight bars of the second movement of
; Beethoven's "Pathetique" done in 9/8 like ACWW 2am.

hr2_conductor:
  setTempo 300
  playPatSq1 0, 27, 1
  playPatSq2 1, 27, 1
  playPatTri 2, 27, 0
  waitRows 36
  .byt CON_PLAYPAT+3, 3, 0, 0
  waitRows 144
  dalSegno

hr2_sq1:
  .byt REST|D_D8, N_GS|D_D4, REST|D_D8, N_FS|D_D4
  .byt REST|D_D8, N_GS|D_D4, REST|D_D8, N_FS|D_D4
  .byt REST|D_D8, N_GS|D_D4, REST|D_D8, N_FS|D_D4
  .byt REST|D_D8, N_GS|D_D4, REST|D_D8, N_FS|D_D4
  .byt REST|D_D8, N_A|D_D4, REST|D_D8, N_B|D_D8, N_DSH|D_D8
  .byt REST|D_D8, N_GS|D_D4, REST|D_D8, N_GS|D_D4
  .byt REST|D_D8, N_GS|D_D4, REST|D_D8, N_GS|D_D4
  .byt REST|D_D8, N_A|D_D4, REST|D_D8, N_E|D_D4
  .byt REST|D_D8, N_FS|D_D4, REST|D_D8, N_D|D_D4
  .byt REST|D_D8, N_D|D_D4, REST|D_D8, N_CS|D_D4
  .byt 255

hr2_sq2:
  .byt REST|D_D8, N_CSH|D_D4, REST|D_D8, N_B|D_D4
  .byt REST|D_D8, N_CSH|D_D4, REST|D_D8, N_B|D_D4
  .byt N_CSH|D_2, REST, N_B|D_2, REST
  .byt N_EH|D_2, N_TIE, REST|D_D4, N_DH|D_D8
  .byt N_CSH|D_4, N_TIE, N_EH|D_4, N_AH|D_D8, N_BH|D_D4
  .byt N_EH|D_2, N_TIE, REST|D_D4, N_FH|D_D8
  .byt N_FSH|D_2, REST, N_B|D_D4, N_CSH|D_8, N_DH
  .byt N_EH|D_2, REST, N_AS|D_2, REST
  .byt N_DH|D_2, REST, N_CSH|D_8, N_B|D_D8, N_A|D_D8, N_GS
  .byt N_B|D_2, REST, N_A|D_2, REST
  .byt 255

hr2_bass:
  .byt N_A|D_2, REST, N_G|D_2, REST
  .byt N_A|D_2, REST, N_G|D_2, REST
  .byt N_A|D_2, REST, N_G|D_2, REST
  .byt N_A|D_2, REST, N_G|D_2, REST
  .byt N_FS|D_2, REST, N_B|D_2, REST
  .byt N_E|D_2, REST, N_E|D_2, REST
  .byt N_DH|D_2, REST, N_DH|D_2, REST
  .byt N_CSH|D_2, REST, N_FS|D_2, REST
  .byt N_B|D_2, REST, N_E|D_2, REST
  .byt N_A|D_2, REST, N_A|D_2, REST
  .byt 255

hr2_drums:
  .byt KICK|D_D8, CLHAT|D_8, CLHAT, CLHAT|D_D8, SNARE|D_D8, CLHAT|D_D4
  .byt 255
  
;____________________________________________________________________
; 3am theme

hr3_conductor:
  setTempo 300
  playPatNoise 5, 0, 0
  playPatTri 6, 15, 0
  waitRows 48
  playPatSq1 8, 27, 3
  playPatSq2 9, 27, 3
  waitRows 96
  playPatTri 7, 15, 0
  playPatSq1 10, 22, 3
  playPatSq2 10, 27, 3
  waitRows 96
  stopPatSq1
  stopPatSq2
  dalSegno


hr3_drums:
  .byt KICK|D_D8, CLHAT|D_8, KICK, SNARE|D_8, CLHAT, CLHAT|D_8, CLHAT
  .byt KICK|D_8, CLHAT, CLHAT|D_8, KICK, SNARE|D_D8, CLHAT|D_D8
  .byt 255

hr3_tri_1:
  .byt N_E|D_8, REST, N_EH|D_8, N_E|D_8, REST, N_EH|D_8, REST|D_8
  .byt REST|D_D2
  .byt N_A|D_8, REST, N_AH|D_8, N_A|D_8, REST, N_AH|D_8, REST|D_8
  .byt REST|D_D2
  .byt 255

hr3_tri_2:
  .byt N_B|D_8, REST, N_BH|D_8, N_B|D_8, REST, N_BH|D_8, REST|D_8
  .byt REST|D_D2
  .byt N_A|D_8, REST, N_AH|D_8, N_A|D_8, REST, N_AH|D_8, REST|D_8
  .byt REST|D_D2
  .byt 255

hr3_sq2_1:
  .byt N_EH|D_D2, N_DH|D_D2, N_CSH|D_D2, N_CH|D_D2
  .byt 255

hr3_sq1_1:
  .byt N_CSH|D_D2, N_B|D_D2, N_A|D_D2, N_G|D_D2
  .byt 255

hr3_sq2_2:
  .byt REST|D_D8, N_B|D_4, N_TIE, N_DH|D_4
  .byt N_CSH|D_4, N_TIE, N_A|D_4, N_TIE|D_D8
  .byt REST|D_D8, N_A|D_4, N_TIE, N_CH|D_4
  .byt N_B|D_4, N_TIE, N_G|D_4, N_TIE|D_D8
  .byt 255

;____________________________________________________________________
; 4am theme

hr4_conductor:
  setTempo 300
  playPatSq1 11, 15, 0
  playPatSq2 12, 15, 0
  waitRows 6
  playPatNoise 13, 0, 0
  waitRows 84
  playPatNoise 14, 0, 0
  segno
  waitRows 192
  dalSegno

hr4_sq1:
  .byt INSTRUMENT, 4, N_FH|D_8, N_EH|D_4, N_DH|D_D8
  .byt INSTRUMENT, 5, N_DH, REST|D_2, REST|D_D4
  .byt INSTRUMENT, 4, N_EH|D_8, N_DH|D_4, N_CH|D_D8
  .byt INSTRUMENT, 5, N_CH, REST|D_2, REST|D_D4
  .byt INSTRUMENT, 4, N_DH|D_8, N_CH|D_4, N_BB|D_D8
  .byt INSTRUMENT, 5, N_BB, REST|D_2, REST|D_D4
  .byt INSTRUMENT, 4, N_BB|D_8, N_A|D_4, N_G|D_D8
  .byt INSTRUMENT, 5, N_DH, REST|D_2, REST|D_D4
  .byt $FF
hr4_sq2:
  .byt INSTRUMENT, 4, N_AH|D_D8, N_GH|D_D8, N_FH|D_D8
  .byt INSTRUMENT, 5, N_FH, REST|D_2, REST|D_D4
  .byt INSTRUMENT, 4, N_GH|D_D8, N_FH|D_D8, N_EH|D_D8
  .byt INSTRUMENT, 5, N_EH, REST|D_2, REST|D_D4
  .byt INSTRUMENT, 4, N_FH|D_D8, N_EH|D_D8, N_DH|D_D8
  .byt INSTRUMENT, 5, N_DH, REST|D_2, REST|D_D4
  .byt INSTRUMENT, 4, N_DH|D_D8, N_CH|D_D8, N_B|D_D8
  .byt INSTRUMENT, 5, N_GH, REST|D_2, REST|D_D4
  .byt $FF
hr4_drums_2:
  .byt KICK|D_D8, CLHAT|D_D8, SNARE|D_D8, CLHAT|D_8, KICK
hr4_drums:
  .byt KICK|D_D8, CLHAT|D_D4, CLHAT|D_8, KICK
  .byt $FF

;____________________________________________________________________
; 5am theme
;
; This is melodies from the third movement of Beethoven's
; "Pathetique" combined with rhythms from ACPG 5am.
; At the time I transcribed this, there were about 400 bytes left
; in the RODATA segment of the PRG ROM.

hr5_conductor:
  setTempo 300
  playPatNoise 5, 0, 0  ; shared with hr5
  playPatSq2 19, 27, 1
  playPatSq1 19, 22, 1
  waitRows 96
  playPatSq2 21, 27, 6
  playPatTri 20, 15, 0
  waitRows 192
  stopPatTri
  dalSegno

hr5_sqloop:
  .byt INSTRUMENT, 1
  .byt REST|D_8, N_E, N_A|D_8, N_B, N_CSH|D_8, REST, N_DH|D_8, N_B|D_8
  .byt INSTRUMENT, 5
  .byt REST, N_E, N_A|D_8, N_B, N_CSH|D_8, REST, N_DH|D_8, N_B|D_8
  .byt REST, REST|D_D4, REST|D_1
  .byt INSTRUMENT, 1
  .byt REST|D_8, N_E, N_A|D_8, N_B, N_CSH|D_8, REST, N_B|D_8, N_G|D_8
  .byt INSTRUMENT, 5
  .byt REST, N_E, N_A|D_8, N_B, N_CSH|D_8, REST, N_B|D_8, N_G|D_8
  .byt REST, REST|D_D4, REST|D_1
  .byt 255  
hr5_triloop:
  .byt N_A|D_8, REST, N_G|D_8, N_FS|D_8, REST, N_G|D_8, REST|D_2
  .byt N_FS|D_8, REST, N_F|D_8, N_E|D_8
  .byt REST|D_D8, REST|D_4, REST|D_1
  .byt 255
hr5_melody:
  .byt REST, N_CSH, N_DH, N_CSH, N_B, N_CSH, N_DH, N_EH|D_8, N_EH|D_8, N_EH|D_D8
  .byt REST|D_8, REST|D_1, REST|D_1
  .byt N_EH|D_8, N_CSH, N_DH|D_8, N_EH|D_D8, N_DH, N_CSH|D_8, N_FSH|D_D8
  .byt REST|D_8, REST|D_1, REST|D_1
  .byt N_CSH|D_8, N_A, N_B|D_8, N_CSH|D_D8, N_B, N_A|D_8, N_DH|D_D8
  .byt REST|D_8, REST|D_1, REST|D_1
  .byt N_E|D_D8, N_E|D_D8, N_E|D_D8, N_E|D_8, N_A|D_D8
  .byt REST|D_8, REST|D_1, REST|D_1
  .byt 255

;____________________________________________________________________
; round cleared theme

cleared_conductor:
  setTempo 60
  playPatSq1 4, 15, 2
  playPatSq2 4, 24, 2
  waitRows 5
  fine

cleared_sq1:
  .byt N_F, N_A, N_G, N_C|D_8
  .byt 255

;____________________________________________________________________
; 4pm theme

hr16_conductor:
  setTempo 300
  playPatSq1 15, 15, 4
  playPatSq2 16, 15, 4
  playPatTri 17, 15, 0
  playPatNoise 18, 0, 0
  waitRows 48
  dalSegno

hr16_sq2:
  .byt N_FH|D_D8, N_CH|D_D8, N_FH|D_D8, N_CH|D_8, N_FH
  .byt N_EBH|D_D8, N_BB|D_D8, N_EBH|D_D8, N_BB|D_8, N_EBH
  .byt N_FH|D_D8, N_DH|D_D8, N_FH|D_D8, N_DH|D_8, N_FH
  .byt N_GH|D_D8, N_DH|D_D8, N_GH|D_D8, N_CH|D_8, N_GH
  .byt $FF
hr16_sq1:
  .byt N_AH|D_D4, N_AH|D_D4
  .byt N_AH|D_D4, N_AH|D_D4
  .byt N_AH|D_D4, N_AH|D_4, N_TIE, N_AH
  .byt N_BBH|D_D4, N_BBH|D_4, N_TIE, N_BBH
  .byt $FF
hr16_tri:
  .byt N_FH|D_8, REST|D_D4, N_CH|D_8, REST|D_8
  .byt N_EBH|D_8, REST|D_D4, N_BB|D_8, REST|D_8
  .byt N_DH|D_8, REST|D_D4, N_A|D_8, REST|D_8
  .byt N_GH|D_8, REST|D_D4, N_CH|D_8, REST|D_8
  .byt $FF
hr16_drums:
  .byt KICK|D_D8, SNARE|D_D8, CLHAT|D_8, KICK, SNARE|D_D8
  .byt $FF

