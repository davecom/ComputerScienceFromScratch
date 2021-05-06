ResetPlayerX:
  lda #3
  sta PlayerLives,x
  ldy PlayerScoreIndex,x
  lda #'0'
  sta ScoreDigits,y
  sta ScoreDigits+1,y
  sta ScoreDigits+2,y
  sta ScoreDigits+3,y
  sta ScoreDigits+4,y
ResetPlayerLifeX:
  lda #$8
  sta PlayerHeld,x
  lda #0
  sta PlayerDead,x
ResetPlayerHealthX:
  lda #4
  sta PlayerHealth,x
  lda GameDifficulty
  cmp #DIFFICULTY_HARDER
  bcc :+
    dec PlayerHealth,x
: rts

.proc NewGame
  ldx #0
  jsr ResetPlayerX
  inx
  jsr ResetPlayerX

  lda #6
  sta PlayerHead
  asl
  sta PlayerHead+1
  lda #0
  sta PlayerBody
  sta PlayerBody+1
;  jmp NewLevel
.endproc
.proc NewLevel
  lda JustPickedFromMenu
  bne :+
  lda IsScoreMode
  jne VersusScoreWinScreen

  lda LevelNumber
  cmp #52 ;64
  jeq StartMainMenu
:

  jsr init_sound
  jsr ClearStatusRows
  jsr ClearOAM

  ldx #0 ; clear the entire page
  txa    ; nothing is persistent from level to level here and some needs clearing
: sta $600,x
  inx
  bne :-
  sta TileCycleIndex
  sta PlayerVYH
  sta PlayerVYH+1
  sta PlayerVYL
  sta PlayerVYL+1
  sta BothDeadTimer
  sta IsMappedLevel
  sta ScreenEnemiesCount
  sta PlayerJumpCancelLock+0
  sta PlayerJumpCancelLock+1
  sta PlayerPYL+0
  sta PlayerVYH+0
  sta PlayerVYL+0
  sta PlayerInvincible
  sta PlayerPYL+1
  sta PlayerVYH+1
  sta PlayerVYL+1
  sta PlayerTeleportCooldown+0
  sta PlayerTeleportCooldown+1
  sta PlayerInvincible+1
  sta LevelWon
  sta Timer60
  sta PlayerDir
  sta JustPickedFromMenu
  sta ScrollX
  sta ScrollX+1
  sta PlayerPowerType+0
  sta PlayerPowerType+1
  sta PlayerPowerTime+0
  sta PlayerPowerTime+1
  sta NoLevelCycle
;  sta ScrollGenerator

  tax
: sta ObjectPYH,x
  sta ObjectPYL,x
  sta ObjectVYH,x
  sta ObjectVYL,x
  sta ObjectTimer,x
  sta ObjectF1,x
  sta ObjectF2,x
  sta ObjectF3,x
  inx
  cpx #ObjectLen
  bne :-

  tax
: sta BulletF,x
  inx
  cpx #BulletLen
  bne :-

  tax
: sta ExplosionSize,x
  inx
  cpx #MaxExplosions
  bne :-

  tax
: sta DelayedMetaEditTime,x
  sta DelayedMetaEditType,x
  inx
  cpx #MaxDelayedMetaEdits
  bne :-
  tax
: sta AttribMap,x
  inx
  cpx #64
  bne :-

  lda #4
  sta PlayerHealth
  sta PlayerHealth+1
  lda GameDifficulty
  cmp #DIFFICULTY_HARDER
  bcc :+
    dec PlayerHealth
    dec PlayerHealth+1
  :

;  lda ScrollGameMode
  lda #0
  sta ScrollMode

  lda #32
  sta PlayerPX+1
  add #8
  sta PlayerPX
  lda #240-32
  sta PlayerPYH
  sta PlayerPYH+1

  lda #1
  sta PlayerDir+1

  lda #0
  sta PPUMASK

  lda LevelNumber
  jsr LoadLevelParams

  jsr GenerateLevel

  lda LevelEditMode
  ora IsMappedLevel
  beq :+
    lda LevelEditStartX
    asl
    asl
    asl
    asl
    sta PlayerPX+1
    add #8
    sta PlayerPX
    lda LevelEditStartY
    asl
    asl
    asl
    asl
    sta PlayerPYH
    sta PlayerPYH+1
  :

  jsr wait_vblank
  lda #BG_ON|OBJ_ON
  sta PPUMASK
  inc LevelNumber

; count coins that need to be collected
  lda LevelGoalType
  cmp #3
  bne NotCollect
  ldx #0
  stx LevelGoalParam
: lda LevelBuf,x
  cmp #METATILE_MONEY
  bne :+
    inc LevelGoalParam
: inx
  bne :--
NotCollect:

  lda PlayerPX
  sta PlayerStartPX
  lda PlayerPYH
  sta PlayerStartPY

; init moving platforms
  ldy #0
: lda LevelBuf,y
  cmp #METATILE_HMOVING_PLAT
  bcc NotMoving
  cmp #METATILE_VMOVING_HARM+1
  bcs NotMoving
    pha
    jsr FindFreeObjectX
    pla
    bcc NotMoving
    sub #METATILE_HMOVING_PLAT
    add #EXTOBJ_HPLAT
    sta ObjectF3,x

    tya
    and #$0f
    asl
    asl
    asl
    asl
    sta ObjectPX,x
    tya
    and #$f0
    sta ObjectPYH,x

    lda #OBJECT_BOMB*2
    sta ObjectF1,x
NotMoving:
  iny
  cpy #240
  bne :-

; ready to go
  jsr init_sound
  lda #0
  jsr init_music

  jmp MainLoop
.endproc
