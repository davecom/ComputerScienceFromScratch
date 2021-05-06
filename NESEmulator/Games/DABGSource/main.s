;.define ExtraDebugStuff 1

.code

ScrollAddLo:
 .byt 0, 128, 0, 128
ScrollAddHi:
 .byt 0, 0, 1, 1

.proc PlayerResetPos
  lda #0
  sta PlayerPYL,x
  sta PlayerVYH,x
  sta PlayerVYL,x

  lda ScrollMode
  bne :+
  lda PlayerStartPX
  sub #4
  sta PlayerPX,x
  lda PlayerStartPY
  sta PlayerPYH,x
  rts
: lda #0
  sta PlayerPYH,x
  lda ScrollX+1
  add #128
  sta PlayerPX,x
  rts
.endproc
.proc MainLoop
forever:
  jsr wait_vblank
  bit PPUSTATUS
  lda ScrollX+1
  sta PPUSCROLL
  lda #0
  sta PPUSCROLL

  lda ScrollMode
  and #3
  tax
  lda ScrollX
  add ScrollAddLo,x
  sta ScrollX
  lda ScrollX+1
  adc ScrollAddHi,x
  sta ScrollX+1

  jsr ReadJoy

  ; if you leave it going too long without anyone playing, just go to the title
  lda retraces
  and #3
  bne :+
  inc BothDeadTimer
  lda PlayerEnabled+0
  ora PlayerEnabled+1
  beq :+
    lda #0
    sta BothDeadTimer
  :
  lda BothDeadTimer
  cmp #150
  bcc :+
    lda LevelEditMode
    jeq StartMainMenu
  :

  ldx #0
: lda PlayerEnabled,x
  bne SkipJoinIn
  lda keydown,x
  cmp #KEY_A|KEY_B
  bne SkipJoinIn
  jsr PlayerResetPos
  jsr ResetPlayerX
  lda #1
  sta PlayerEnabled,x
SkipJoinIn:
  inx
  cpx #2
  bne :-

  lda keydown ; pause routine
  ora keydown+1
  and #KEY_START
  beq NoPause
    ; display "paused" text
;    lda ScrollGameMode
;    bne :+
      jsr ClearStatusRows
;    :
;    ldx #0
;  : lda PauseString,x
;    beq :+
;    sta StatusRow1+0,x
;    inx
;    bne :-
;  :

    lda keylast
    ora keylast+1
    and #KEY_START
    beq NoPause
      jsr stop_music
      jsr update_sound
      lda #BG_ON|OBJ_ON|1
;      eor ScrollGameMode
      sta PPUMASK
:     jsr ReadJoy
      stx TempVal
      jsr update_sound
      ldx TempVal
      lda keydown
      ora keydown+1
      cmp #KEY_START|KEY_SELECT
      jeq StartMainMenu
      and #KEY_START
      bne :-
      ldx #15
    : jsr wait_vblank
      stx TempVal
      jsr update_sound
      ldx TempVal
      dex
      bne :-
:     jsr ReadJoy
      stx TempVal
      jsr update_sound
      ldx TempVal
      lda keydown
      ora keydown+1
      and #KEY_START
      beq :-
:     jsr ReadJoy
      lda keydown
      ora keydown+1
      and #KEY_START
      bne :-
      ldx #15
    : jsr wait_vblank
      dex
      bne :-

;      lda ScrollGameMode
;      bne :+
      jsr ClearStatusRows
;    : 
      lda #1
      sta music_playing
  NoPause:
  lda #1
  sta EnableNMIDraw
 .ifdef ExtraDebugStuff
    lda #BG_ON|OBJ_ON|1
    sta PPUMASK
 .endif

  jsr FlickerEnemies

;  jsr rand_8
;  and #3
;  sta 0
;  lda retraces
;  and #$ff
;  tay
;  lda 0
;  jsr ChangeBlock

  inc Timer60
  lda Timer60
  cmp #60
  bne :+
    lda #0
    sta Timer60
    lda LevelGoalType
    cmp #WINMODE_SURVIVAL
    bne :+
      lda LevelGoalParam
      beq :+
        dec LevelGoalParam
  :

  lda NoLevelCycle
  jne NoCycling

  ldy TileCycleIndex
  lda LevelBuf,y
  jeq NotSpecialCycle
  cmp #METATILE_EXPLODE
  bne :+
    tya
    and #$0f
    asl
    asl
    asl
    asl
    add #4
    sta 0
    tya
    and #$f0
    add #4
    sta 1
    lda #30
    jsr CreateExplosion
    jmp NotSpecialCycle
  : jsr DoCycleChange
NotSpecialCycle:

  inc TileCycleIndex
  lda TileCycleIndex
  cmp #240
  bcc :+
    lda #0
    sta TileCycleIndex
  :
NoCycling:

  jsr ClearOAM
  lda IsFightMode
  bne :+
    jsr AddEnemies
  :

  lda IsFightMode
  beq :+
    lda PlayerEnabled+0
    and PlayerEnabled+1
    jeq VersusFightWinScreen
  :

  lda PlayerEnabled+0
  beq :+
  ldx #0
  jsr RunPlayer
: lda PlayerEnabled+1
  beq :+
  ldx #1
  jsr RunPlayer
:

  jsr RunBullets
  jsr RunObjects
  lda ScrollMode
  bne :+
  jsr UpdateStatus
: lda ScrollMode
  beq :+
  jsr UpdateScrollInfo
:

  lda NeedPowerupSound
  beq :+
    lda #SOUND_MONEY
    jsr start_sound
    dec NeedPowerupSound
  :

  jsr RunExplosions
  jsr RunPowerups

  lda LevelGoalType ; add money if money collecting mode
  cmp #1
  bne :+
    lda retraces
    bne :+
      lda #POWERUP_MONEY
      jsr CreatePowerup
:
  lda VersusPowerups ; add powerups if you have them enabled
  beq :++
    lda retraces
    bne :++
      lda VersusPowerups
      cmp #1 ; "low" setting
      bne :+
        jsr rand_8_safe
        and #3
        bne :++
    : jsr rand_8_safe
      lsr
      and #3
      add #POWERUP_DIAGSHOOT
      tax
      jsr CreatePowerup
  :

  jsr update_sound
; check for winning (all win conditions wait for zero)
  lda LevelGoalParam
  bne :+
    inc LevelWon
    lda LevelWon
    cmp #10
    jcs LevelWasWon
  :

  ldx #0
MetaEditLoop:
  lda DelayedMetaEditType,x
  beq SkipMetaEdit
    lda retraces
    cmp DelayedMetaEditTime,x
    bne SkipMetaEdit
    ldy DelayedMetaEditIndx,x
    lda DelayedMetaEditType,x
    bpl :+
      lda #0
  : jsr ChangeBlock
    lda #0
    sta DelayedMetaEditType,x
SkipMetaEdit:
  inx
  cpx #MaxDelayedMetaEdits
  bne MetaEditLoop

  lda #BG_ON|OBJ_ON
;  eor ScrollGameMode
  sta PPUMASK

  jmp forever

PauseString:
  .byt "Game paused",0
.endproc

.proc DoCycleChange
  cmp #METATILE_CYCLE_OFF_SOLID
  bne :+
  lda #METATILE_CYCLE_ON_SOLID
  bne CycleTileChange
: cmp #METATILE_CYCLE_OFF_PLATF
  bne :+
  lda #METATILE_CYCLE_ON_PLATF
  bne CycleTileChange
: cmp #METATILE_CYCLE_ON_SOLID
  bne :+
  lda #METATILE_CYCLE_OFF_SOLID
  bne CycleTileChange
: cmp #METATILE_CYCLE_ON_PLATF
  bne :+
  lda #METATILE_CYCLE_OFF_PLATF
  bne CycleTileChange
: rts
CycleTileChange:
  sty 8
  jsr ChangeBlock
  ldy 8
  jsr IndexToBitmap
  eor CollectMap,y
  sta CollectMap,y
  ldy 8
  rts
.endproc

.proc UpdateStatus
  lda #$09
  sta StatusRow1+0
  sta StatusRow2+0
  lda #$0A
  sta StatusRow1+1
  sta StatusRow2+1
  lda #$19
  sta StatusRow1+2
  sta StatusRow2+2
  lda #$1A
  sta StatusRow1+3
  sta StatusRow2+3
  lda #' '
  sta StatusRow1+4 ; clear lives
  sta StatusRow2+4
  sta StatusRow1+6 ; clear out score
  sta StatusRow2+6
  sta StatusRow1+7
  sta StatusRow2+7
  sta StatusRow1+8
  sta StatusRow2+8
  sta StatusRow1+9
  sta StatusRow2+9
  sta StatusRow1+10
  sta StatusRow2+10

  lda PlayerEnabled+0
  beq P1Disabled
  ldx #0
  lda #4
: cpx PlayerHealth+0
  bcc :+
  lda #2
: sta StatusRow1,x
  inx
  cpx #MaxHealthNormal
  bne :--
  lda PlayerLives
  add #'0'
  sta StatusRow1,x

  lda ScoreDigits+4
  sta StatusRow1+6
  lda ScoreDigits+3
  sta StatusRow1+7
  lda ScoreDigits+2
  sta StatusRow1+8
  lda ScoreDigits+1
  sta StatusRow1+9
  lda ScoreDigits+0
  sta StatusRow1+10
P1Disabled:
  lda PlayerEnabled+1
  beq P2Disabled
  ldx #0
  lda #4
: cpx PlayerHealth+1
  bcc :+
  lda #2
: sta StatusRow2,x
  inx
  cpx #MaxHealthNormal
  bne :--
  lda PlayerLives+1
  add #'0'
  sta StatusRow2,x

  lda ScoreDigits+9
  sta StatusRow2+6
  lda ScoreDigits+8
  sta StatusRow2+7
  lda ScoreDigits+7
  sta StatusRow2+8
  lda ScoreDigits+6
  sta StatusRow2+9
  lda ScoreDigits+5
  sta StatusRow2+10
P2Disabled:

  lda LevelGoalType
  cmp #4
  bcs NoShowGoal
    add #$13
    sta StatusRow1+28-5
    ldx LevelGoalParam
    lda BCD64,x
    pha
    and #$f0
    .repeat 4
      lsr
    .endrep
    add #'0'
    sta StatusRow1+28-5+1
    pla
    and #$0f
    add #'0'
    sta StatusRow1+28-5+2
NoShowGoal:
  rts
.endproc
.proc BCD64
  .byt $00, $01, $02, $03, $04, $05, $06, $07, $08, $09, $10, $11, $12, $13, $14, $15, $16, $17, $18, $19
  .byt $20, $21, $22, $23, $24, $25, $26, $27, $28, $29, $30, $31, $32, $33, $34, $35, $36, $37, $38, $39
  .byt $40, $41, $42, $43, $44, $45, $46, $47, $48, $49, $50, $51, $52, $53, $54, $55, $56, $57, $58, $59
  .byt $60, $61, $62, $63, $64, $65, $66, $67, $68, $69, $70, $71, $72, $73, $74, $75, $76, $77, $78, $79
  .byt $80, $81, $82, $83, $84, $85, $86, $87, $88, $89, $90, $91, $92, $93, $94, $95, $96, $97, $98, $99
.endproc

.proc UpdateScrollInfo
  ldx #0
  jsr DoStatusSprites
  ldx #1
  jsr DoStatusSprites

; level objective stuff
  ldy OamPtr

  lda #1
  sta OAM_ATTR+(4*0),y
  sta OAM_ATTR+(4*1),y
  sta OAM_ATTR+(4*2),y
  lda #256-40
  sta OAM_XPOS+(4*0),y
  lda #256-40+8
  sta OAM_XPOS+(4*1),y
  lda #256-40+16
  sta OAM_XPOS+(4*2),y

  lda #20
  sta OAM_YPOS+(4*0),y
  sta OAM_YPOS+(4*1),y
  sta OAM_YPOS+(4*2),y

  ldx LevelGoalType
  lda LevelGoalTypeTiles,x
  sta OAM_TILE+(4*0),y
  ldx LevelGoalParam
  lda BCD64,x
  pha
  and #$f0
  lsr
  lsr
  lsr
  lsr
  add #$c0
  sta OAM_TILE+(4*1),y
  pla
  and #$0f
  add #$c0
  sta OAM_TILE+(4*2),y

  tya
  add #12
  sta OamPtr

.if 0
; thing on the left for showing that going too far left kills you
  ldy OamPtr
  lda #1
  sta OAM_ATTR+(4*0),y
  sta OAM_ATTR+(4*1),y
  lda #8
  sta OAM_XPOS+(4*0),y
  lda #8+8+2
  sta OAM_XPOS+(4*1),y
  lda retraces
  asl
  asl
  bcc :+
    eor #255
    add #1
: sta OAM_YPOS+(4*0),y
  sta OAM_YPOS+(4*1),y
  lda #$2f
  sta OAM_TILE+(4*0),y
  sta OAM_TILE+(4*1),y

  tya
  add #8
  sta OamPtr
.endif

;  lda ScrollGameMode
;  jne UpdateScrollColumn
  rts

DoStatusSprites:
  lda PlayerEnabled,x
  beq PlayerDisabled
  ldy OamPtr

  lda #1
  sta OAM_ATTR+(4*0),y
  sta OAM_ATTR+(4*1),y
  lda #16
  sta OAM_XPOS+(4*0),y
  lda #16+8+2
  sta OAM_XPOS+(4*1),y

  txa
  asl
  asl
  asl
  add #20
  sta OAM_YPOS+(4*0),y
  sta OAM_YPOS+(4*1),y

  stx 0
  lda PlayerHealth,x
  tax
  lda LifeSprites,x
  ldx 0
  sta OAM_TILE+(4*0),y
  lda PlayerLives,x
  add #$c0
  sta OAM_TILE+(4*1),y
 
  tya
  add #8
  sta OamPtr
PlayerDisabled:
  rts

LifeSprites:
  .byt $00, $ca, $cb, $2f, $93
LevelGoalTypeTiles:
  .byt $4a, $5a, $4b, $5b
.endproc
