.if 0 ; old powerups list
.enum
  POWERUP_STUN_ALL    ; stuns all enemies
  POWERUP_STUNNED     ; placeholder for a stunned enemy
  POWERUP_MONEY       ; for money-collecting levels 
  POWERUP_HEALTH      ; health recovering
  POWERUP_POINTS      ; add points
  POWERUP_BOMBS       ; player can throw bombs for awhile
.endenum
.endif

.enum
  POWERUP_UNUSED
  POWERUP_STUNNED
  POWERUP_MONEY
  POWERUP_HEALTH
  POWERUP_DIAGSHOOT
  POWERUP_BOMBS
  POWERUP_JUMP
  POWERUP_BILLBLOCK
.endenum

.proc CreatePowerup ; A = powerup type; output is in Y
  sta 0
  ldy #0
: lda PowerupF,y
  beq Success
  iny
  cpy #PowerupLen
  bne :-
  clc
  rts
Success:
  lda #0
  sta PowerupVX,y
  lda 0
  ora #128 ; enabled
  sta PowerupF,y
  sty 0
  jsr rand_8_safe
  ldy 0
  pha
  and #$f0
  add #4
  sta PowerupPX,y
  stx 1
  pla
  and #1
  tax
  lda VertSpeeds,x
  sta PowerupVY,y
  lda VertPositions,x
  sta PowerupPY,y
  ldx 1
  sec
  rts
VertSpeeds:
  .byt 1, -1
VertPositions:
  .byt 0, 240-16
.endproc

.proc RunPowerups
  lda #0
  sta 0 ; current powerup counter

Loop:
  ldx 0
  lda PowerupF,x
  bpl SkipPowerup
  ldy OamPtr
  and #15
  ora #$40
  sta OAM_TILE+(4*0),y
  ora #$50
  sta OAM_TILE+(4*1),y

  lda PowerupPX,x
  add PowerupVX,x
  sta PowerupPX,x

  lda PowerupPY,x
  add PowerupVY,x
  sta PowerupPY,x

  lda PowerupPY,x
  sta OAM_YPOS+(4*0),y
  add #8
  sta OAM_YPOS+(4*1),y
  lda #3
  sta OAM_ATTR+(4*0),y
  sta OAM_ATTR+(4*1),y
  lda PowerupPX,x
  sub ScrollX+1
  sta OAM_XPOS+(4*0),y
  sta OAM_XPOS+(4*1),y
 
  lda PowerupPY,x
  cmp #241
  bcc :+
  lda #0
  sta PowerupF,x
  beq SkipTouch
: jsr PowerupPlayerTouch
SkipTouch:
  lda OamPtr
  add #8
  sta OamPtr
  tay

SkipPowerup:
  inc 0
  lda 0
  cmp #PowerupLen
  bne Loop
  sty OamPtr
  rts
.endproc

.proc PowerupPlayerTouch
  ldy #0
PlayerLoop:
  lda PlayerPX,y
  sta TouchLeftA
  lda PlayerPYH,y
  sta TouchTopA

  lda PowerupPX,x
  sta TouchLeftB
  lda PowerupPY,x
  sta TouchTopB

  lda #8
  sta TouchWidthA
  sta TouchWidthB
  asl
  sta TouchHeightA
  sta TouchHeightB

  jsr ChkTouchGeneric
  bcs Touched
  iny
  cpy #MaxNumPlayers
  bne PlayerLoop
  rts
Touched:
  stx TempVal+2
  ; for some bizarre reason I can't just go and play a sound effect here
  ; because then it would corrupt memory in addition to playing the sound
  lda #1
  sta NeedPowerupSound

  lda PowerupF,x  ; get type, push address from table
  pha
  lda #0          ; destroy powerup after we read it
  sta PowerupF,x
  pla
  and #7
  asl
  tax
  lda Effects+1,x
  pha
  lda Effects+0,x
  pha
  ldx TempVal+2
  rts
Effects:
  .raddr PowerupJump
  .raddr PowerupJump
  .raddr PowerupMoney
  .raddr PowerupHealth
  .raddr PowerupDiagShoot
  .raddr PowerupBombs
  .raddr PowerupJump
  .raddr PowerupBillBlock
.endproc

.proc PowerupJump
  lda #APOWERUP_JUMP
  sta PlayerPowerType,y
  lda #50
  sta PlayerPowerTime,y
  rts
.endproc

.proc PowerupDiagShoot
  lda #APOWERUP_DIAGSHOOT
  sta PlayerPowerType,y
  lda #50
  sta PlayerPowerTime,y
  rts
.endproc

.proc PowerupBombs
  lda #APOWERUP_BOMBS
  sta PlayerPowerType,y
  lda #50
  sta PlayerPowerTime,y
  rts
.endproc

.proc PowerupBillBlock
  lda #APOWERUP_BILLBLOCK
  sta PlayerPowerType,y
  lda #50
  sta PlayerPowerTime,y
  rts
.endproc

.if 0
.proc PowerupStunAll
  stx 0
  sty 1
  ldx #0
Loop:
  lda ObjectF1,x
  beq Skip
  alr #%111110
  tay
  lda ObjectIsEnemy,y
  beq Skip
  lda #ENEMY_STATE_STUNNED
  sta ObjectF2,x
  lda #250
  sta ObjectTimer,x
Skip:
  inx
  cpx #ObjectLen
  bne Loop
  ldx 0
  ldy 1
  rts
.endproc
.endif

.proc PowerupMoney
  lda LevelGoalType
  cmp #1
  bne :+
  lda LevelGoalParam
  beq :+
  dec LevelGoalParam
: ; now add points
  stx TempVal
  tya
  tax
  lda #1
  jsr PlayerAddScore
  ldx TempVal
  rts
.endproc
.proc PowerupHealth
  lda PlayerHealth,y
  cmp #MaxHealthNormal
  bcs :+
  isc PlayerHealth,y
: rts
.endproc
