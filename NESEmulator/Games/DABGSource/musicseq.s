.enum
  SOUND_JUMP
  SOUND_SNARE2
  SOUND_KICK2
  SOUND_HIHAT
  SOUND_SHOOT
  SOUND_ENEMYHURT
  SOUND_YOUHURT
  SOUND_COLLECT
  SOUND_SPRING
  SOUND_SNARE
  SOUND_KICK
  SOUND_EXPLODE1
  SOUND_EXPLODE2
  SOUND_ENEMYHURT2
  SOUND_MONEY
  SOUND_YOUDEAD
  SOUND_TELEPORT
.endenum

psg_sound_table: ; address, (channel?), length in words
  .addr playerjump_snd
  .byt 0, 10
  .addr snare2_snd
  .byt 8, 2
  .addr kick2_snd
  .byt 8, 4
  .addr hihat_snd
  .byt 12, 2
  .addr youshoot_snd
  .byt 0, 6
  .addr enemyhurt_snd
  .byt 0, 10
  .addr youhurt_snd
  .byt 0, 10

  .addr collect_snd
  .byt 0, 10
  .addr spring_snd
  .byt 0, 20
  .addr snare_snd
  .byt 12, 7

  .addr kick_snd
  .byt 12, 3

  .addr boom1_snd ; explosion sounds taken from Thwaite
  .byt 16+0, 15
  .addr boom2_snd
  .byt 48+12, 16

  .addr enemyhurt2_snd
  .byt 0, 10
  .addr money_snd
  .byt 0, 10

  .addr youdead_snd
  .byt 0, 20
  .addr teleport_snd
  .byt 0, 10

; alternating duty/volume and pitch bytes
playerjump_snd:
  .byt $4f, $20, $4f, $21
  .byt $4f, $22, $4f, $23
  .byt $4f, $24, $4f, $25
  .byt $4f, $26, $4f, $27
  .byt $4f, $28, $4f, $29

spring_snd:
  .byt $4f, $20, $4f, $21
  .byt $4f, $20, $4f, $21
  .byt $4f, $22, $4f, $23
  .byt $4f, $22, $4f, $23
  .byt $4f, $24, $4f, $25
  .byt $4f, $24, $4f, $25
  .byt $4f, $26, $4f, $27
  .byt $4f, $26, $4f, $27
  .byt $4f, $28, $4f, $29
  .byt $4f, $28, $4f, $29

youshoot_snd:
  .byt $8f, $20, $8f, $21
  .byt $8f, $22, $8f, $23
  .byt $8f, $22, $8f, $21

enemyhurt_snd:
  .byt $4f, $20, $4f, $21
  .byt $40, $22, $40, $23
  .byt $4f, $24, $4f, $2f
  .byt $4f, $26, $4f, $2f
  .byt $4f, $28, $4f, $2f

youhurt_snd:
  .byt $4f, $10, $4f, $11
  .byt $40, $12, $40, $13
  .byt $4f, $14, $4f, $1f
  .byt $4f, $16, $4f, $1f
  .byt $4f, $18, $4f, $1f

youdead_snd:
  .byt $4f, $10, $4f, $11
  .byt $4f, $10, $4f, $11
  .byt $40, $12, $40, $13
  .byt $40, $12, $40, $13
  .byt $4f, $14, $4f, $1f
  .byt $4f, $14, $4f, $24
  .byt $4f, $16, $4f, $1f
  .byt $4f, $16, $4f, $25
  .byt $4f, $18, $4f, $1f
  .byt $4f, $18, $4f, $26

teleport_snd:
  .byt $8f, $20, $80, $20
  .byt $8f, $20, $80, $20
  .byt $8f, $20, $88, $20
  .byt $86, $20, $84, $20
  .byt $82, $20, $81, $20

collect_snd:
  .byt $4f, $20, $4f, $21
  .byt $40, $22, $40, $23
  .byt $4f, $24, $4f, $2f
  .byt $40, $26, $40, $2f
  .byt $4f, $28, $4f, $2f

enemyhurt2_snd:
  .byt $4f, $20, $4f, $18
  .byt $4f, $10, $4f, $16
  .byt $4f, $20, $4f, $14
  .byt $4f, $10, $4f, $12
  .byt $4f, $20, $4f, $10

money_snd:
  .byt $4f, $20, $4f, $20
  .byt $40, $20, $40, $20
  .byt $4f, $23, $4f, $23
  .byt $40, $26, $40, $26
  .byt $4f, $26, $4f, $27

snare2_snd:
  .byt $8F, $26, $8F, $25
kick2_snd:
  .byt $8F, $1F, $8F, $1B, $8F, $18, $82, $15
hihat_snd:
  .byt $06, $03, $04, $83
snare_snd:
  .byt $0A, 085, $08, $84, $06, $04
  .byt $04, $84, $03, $04, $02, $04, $01, $04
kick_snd:
  .byt $08,$04,$08,$0E,$04,$0E
  .byt $05,$0E,$04,$0E,$03,$0E,$02,$0E,$01,$0E

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
  .byt $47, 4, $00, 0  ; piano
  .byt $86, 1, $00, 0  ; bell between rounds
  .byt $87, 2, $00, 0  ; xylo long
  .byt $87, 6, $00, 0  ; xylo short
  .byt $05, 0, $00, 0  ; distant horn blat
  .byt $88, 4, $00, 0  ; xylo medium

songTable:
  .addr morning_mood

.enum
  PATT_MORNING_DRUMS
  PATT_MORNING_SQA1
  PATT_MORNING_SQA2
  PATT_MORNING_SQA3
  PATT_MORNING_SQA4
  PATT_MORNING_SQB
  PATT_NOTHING
.endenum

musicPatternTable:
  .addr morning_drums, morning_sqA1, morning_sqA2, morning_sqA3, morning_sqA4, morning_sqB, morning_nothing

morning_mood:
  setTempo 540
  playPatSq2 PATT_NOTHING, 27, 1
  playPatTri PATT_NOTHING, 27, 0
  playPatNoise PATT_MORNING_DRUMS, 0, 0

  playPatSq1 PATT_MORNING_SQA1, 27, 1
  waitRows 32
  playPatSq1 PATT_MORNING_SQA2, 27, 1
  waitRows 32
  playPatSq1 PATT_MORNING_SQA3, 27, 1
  waitRows 32
  playPatSq1 PATT_MORNING_SQA4, 27, 1
  waitRows 32
  segno
  playPatNoise PATT_MORNING_DRUMS, 0, 0
  playPatSq1 PATT_MORNING_SQA1, 27, 1
  playPatSq2 PATT_MORNING_SQB, 27, 1
  waitRows 32
  playPatSq1 PATT_MORNING_SQA2, 27, 1
  waitRows 32
  playPatSq1 PATT_MORNING_SQA3, 27, 1
  playPatSq2 PATT_NOTHING, 27, 1
  waitRows 32
  playPatNoise PATT_NOTHING, 0, 0
  playPatSq1 PATT_MORNING_SQA4, 27, 1
  waitRows 32
  dalSegno

morning_sqA1:
  .byt N_DSH|D_8, REST, N_GS|D_8, REST
  .byt N_AS, N_B, N_CSH|D_8, REST
  .byt N_GS|D_8, REST
  .byt N_FS|D_8, N_GS|D_8, REST
  .byt N_AS, REST, N_AS, N_CSH|D_8, N_DSH|D_4, N_GS|D_4
morning_sqA2:
  .byt N_DSH|D_8, REST, N_GS|D_8, REST
  .byt N_AS, N_B, N_CSH|D_8, REST
  .byt N_GS|D_8, REST
  .byt N_FS|D_8, N_GS|D_8, REST
  .byt N_AS, REST, N_AS, N_CSH|D_8, N_FS|D_4, N_GS|D_4
morning_sqA3:
  .byt N_B|D_8, N_DSH, N_GS|D_8
  .byt N_A, N_AS, N_B, N_CSH|D_8
  .byt N_B, N_GS, REST, N_GS, N_CSH|D_8
  .byt N_GS|D_8, N_FS, N_GS|D_8, N_FS, N_AS|D_8
  .byt N_CSH|D_8, N_GS, REST, N_GS, N_AS, N_CSH|D_8  
morning_sqA4:
  .byt N_B|D_8, N_DSH, N_GS, N_GS, N_A, N_AS, N_B, N_CSH|D_8
  .byt N_B, N_GS, REST, N_GS, N_GS, REST, N_GS|D_8, N_FS, N_GS|D_8
  .byt N_FS, N_CSH|D_8, N_DSH|D_8, N_GS, REST, N_GS, N_AS, N_CSH|D_8
morning_sqB:
  .byt REST|D_8, REST, N_DS|D_8, REST, N_FS|D_8, N_GS|D_8, REST, N_CSH|D_8, REST|D_8, REST
  .byt N_DS|D_8, REST, N_FS|D_8, REST|D_8, REST, N_AS|D_8, REST|D_8, N_CSH|D_8, REST|D_8
  .byt 255
morning_nothing:
  .byt REST|D_2
  .byt 255

morning_drums:
;  .byt KICK|D_D8, CLHAT|D_8, CLHAT, CLHAT|D_D8, SNARE|D_D8, CLHAT|D_D4
  .byt KICK, KICK, KICK|D_8, SNARE|D_8
  .byt KICK, KICK, KICK|D_8, SNARE|D_8, SNARE|D_8, KICK|D_8
  .byt 255
.if 0
cleared_conductor:
  setTempo 60
  playPatSq1 4, 15, 2
  playPatSq2 4, 24, 2
  waitRows 5
  fine

cleared_sq1:
  .byt N_F, N_A, N_G, N_C|D_8
  .byt 255
.endif