.proc PlayerGameOver
  lda #0
  sta PlayerEnabled,x
  rts
.endproc

.proc RunPlayer
  lda PlayerDead,x
  beq NotDead

  ; increase gravity
  lda PlayerVYL,x
  add #32
  bcc :+
    inc PlayerVYH,x
: sta PlayerVYL,x

  ; apply gravity
  lda PlayerPYL,x
  add PlayerVYL,x
  sta PlayerPYL,x
  
  lda PlayerPYH,x
  adc PlayerVYH,x
  sta PlayerPYH,x  

  cmp #-12
  bcc :+
  ; revive player
  dec PlayerLives,x
  lda PlayerLives,x
  jeq PlayerGameOver

  lda #0
  sta PlayerDead,x
  jsr PlayerResetPos
  lda #60
  sta PlayerInvincible
  jsr ResetPlayerHealthX
:
  jsr DispPlayer
  rts
NotDead:

  lda #255
  sta PlayerPowerEnabled

  lda PlayerPowerTime,x
  beq :+
    lda PlayerPowerType,x
    sta PlayerPowerEnabled
    lda retraces
    and #3
    bne :+
      dec PlayerPowerTime,x
  :

  lda keydown,x
  sta 0

  ; keep running if you were running before you jumped,
  ; or keep walkng if you were walking before you jumped
  lda PlayerVYH,x
  ora PlayerVYL,x
  beq :+
    lda PlayerWasRunning,x
    sta 0
  :

  ; holding B lets you go twice as fast
  ldy #2
  lda 0
  and #KEY_B
  beq :+
    ldy #4
: sty 0

  ; moving left and right
  lda keydown,x
  and #KEY_LEFT
  beq :+
    lda PlayerPX,x
    sub 0
    lsr
    lsr
    lsr
    lsr
    sta 1
    lda PlayerPYH,x
    add #8
    and #$f0
    ora 1
    tay
    lda LevelBuf,y
    jsr BlockIsSolid
    bne :+
      lda PlayerPX,x
      sub 0
      sta PlayerPX,x
      lda #1
      sta PlayerDir,x
: lda keydown,x
  and #KEY_RIGHT
  beq :+
    lda PlayerPX,x
    add #7
    add 0
    lsr
    lsr
    lsr
    lsr
    sta 1
    lda PlayerPYH,x
    add #8
    and #$f0
    ora 1
    tay
    lda LevelBuf,y
    jsr BlockIsSolid
    bne :+
      lda PlayerPX,x
      add 0
      sta PlayerPX,x
      lda #0
      sta PlayerDir,x
  :

  ; select skips to the next level, or skips to the level edit screen
  lda keydown,x
  and #KEY_SELECT
  beq :+
;    lda ScrollGameMode
;    bne :+
    jsr init_sound
    lda LevelEditMode
    jne StartEditorNormal
    lda retraces
    beq :+
      sta r_seed
      pla             ; don't mess up the stack
      pla
      jmp NewLevel
  :

  ; gravity
  lda PlayerPYL,x
  add PlayerVYL,x
  bcc :+
    inc PlayerPYH,x
: sta PlayerPYL,x

  lda PlayerVYH,x
  bmi GravityOkay
  cmp #8
  bcs GravitySkip
GravityOkay:
  lda PlayerVYL,x
  add #32
  bcc :+
    inc PlayerVYH,x
: sta PlayerVYL,x
GravitySkip:

  ; check for collision with blocks above before adding gravity
  lda PlayerVYH,x
  bpl :+
  lda PlayerPX,x
  add #4
  lsr
  lsr
  lsr
  lsr
  sta 1
  lda PlayerPYH,x
  add PlayerVYH,x
  and #$f0
  ora 1
  tay
  lda LevelBuf,y
  jsr BlockIsSolid
  beq :+
    lda #0
    sta PlayerVYH,x
  :

  ; more gravity
  lda PlayerPYH,x
  add PlayerVYH,x
  sta PlayerPYH,x

  ; rapid fire
  lda PlayerPowerEnabled
  cmp #APOWERUP_DIAGSHOOT
  bne :+
    lda keydown,x
    and #KEY_B
    beq :+
      lda retraces
      and #7
      beq ShootAnyway
  :

  lda keydown,x
  and #KEY_B
  beq NoShoot
    lda keylast,x
    and #KEY_B
    bne NoShoot
ShootAnyway:
      lda #SOUND_SHOOT
      jsr start_sound

      lda PlayerPowerEnabled
      cmp #APOWERUP_BILLBLOCK
      jeq ShootBillBlock

      jsr FindFreeBulletY
      bcc NoShoot
      sty 0
      ldy PlayerDir,x
      lda OffsetHeldX,y
      ldy 0

      add PlayerPX,x
      sta BulletPX,y

      ldy PlayerDir,x
      lda BulletSpeed,y
      ldy 0
      sta BulletVX,y

      lda #0
      sta BulletVY,y
      sta BulletVXL,y
      sta BulletVYL,y
      sta BulletPYL,y
      sta BulletPYL,y

      lda PlayerPYH,x
      add #4
      sta BulletPY,y
      lda #8
      sta 1 ; bullet type

      lda PlayerPowerEnabled
      cmp #APOWERUP_BOMBS
      bne :+
        lda #12 ; bomb
        sta 1
      :

      lda PlayerPowerEnabled
      cmp #APOWERUP_DIAGSHOOT
      bne :+
        jsr huge_rand
        and #3
        sub #2
        sta BulletVY,y
      :

      lda #%11000000 ; enabled, player-made
      ora 1          ; bullet type
      sta BulletF,y

      lda #15
      sta BulletLife,y
  NoShoot:

  lda PlayerVYH,x
  bpl :+
    lda keydown,x        ; cancel a jump (doesn't appear to work?)
    and #KEY_A
    bne :+
      lda PlayerJumpCancelLock,x
      bne :+
        lda #0
        sta PlayerVYH,x
        sta PlayerVYL,x
  :

  ; lower PlayerDropLock if it isn't zero yet
  lda PlayerDropLock
  beq :+
  dec PlayerDropLock
:

  lda PlayerPX,x
  add #4 ; start from middle
  lsr
  lsr
  lsr
  lsr
  sta PlayerXShifted
  sta 0 ; for the falling through platforms stuff after
  pha

  lda PlayerPYH,x
  add #15
  and #$f0
  ora 0
  tay
  sty 11
; check for things that don't care about Y velocity first
  lda LevelBuf,y
  cmp #METATILE_PICKUP
  bne NotPickup
    lda #0
    jsr ChangeBlock

    lda #POWERUP_HEALTH
    jsr CreatePowerup

    lda #SOUND_MONEY
    jsr start_sound
    jmp SkipWalkthrough2
NotPickup:
  cmp #METATILE_BOMB_TRAP
  bne NotBombTrap
  lda PlayerTeleportCooldown,x
  jne SkipWalkthrough2

  lda #20
  sta PlayerTeleportCooldown,x

  jsr DropBomb
  ldy BombDroppedIndex
  bmi :+
  lda 11
  and #$f0
  sub #32
  sta ObjectPYH,y
  lda 11
  asl
  asl
  asl
  asl
  add #4
  sta ObjectPX,y
:
  jmp SkipWalkthrough2

NotBombTrap:
  cmp #METATILE_INSTANT_SWITCH
  bne NotInstaswitch
  lda PlayerTeleportCooldown,x
  jne SkipWalkthrough2

.if 0
  lda ScrollGameMode ; only instant switch on metatile boundaries
  beq :+
    lda ScrollX+1
    and #15
    jne SkipWalkthrough2
  :
.endif

  lda #40
  sta PlayerTeleportCooldown,x

  jsr wait_vblank
  lda #0
  sta PPUMASK

  ldy #0
: sty 9
  lda LevelBuf,y
  jsr DoCycleChange

  lda BlockUpdateA1
  beq :+
    sta PPUADDR
    lda BlockUpdateA2
    sta PPUADDR
    lda BlockUpdateT1
    sta PPUDATA
    lda BlockUpdateT2
    sta PPUDATA

    lda BlockUpdateB1
    sta PPUADDR
    lda BlockUpdateB2
    sta PPUADDR
    lda BlockUpdateT3
    sta PPUDATA
    lda BlockUpdateT4
    sta PPUDATA
    lda #0
    sta BlockUpdateA1
  :

  ldy 9
  iny
  cpy #240
  bne :--

  lda ScrollX+1
  sta PPUSCROLL
  lda #0
  sta PPUSCROLL
  jsr wait_vblank
  lda #BG_ON|OBJ_ON
  sta PPUMASK
  jmp SkipWalkthrough2

NotInstaswitch:

  lda LevelBuf,y
  cmp #METATILE_MONEY
  bne NotMoney
    sty 1
    jsr IndexToBitmap
    sta 0
    and CollectMap,y
    bne NotMoney
    lda 0
    ora CollectMap,y
    sta CollectMap,y
    ldy 1

    lda #0
    jsr ChangeBlockColor

    lda LevelGoalType
    cmp #3
    bne NotMoneyType
      lda LevelGoalParam
      beq NotMoneyType
        dec LevelGoalParam
    NotMoneyType:

    lda #SOUND_MONEY
    jsr start_sound

    lda #1
    jsr PlayerAddScore
NotMoney:
  lda LevelBuf,y
  cmp #METATILE_TELEPORT_LEFT
  bne NotTeleportLeft
    lda PlayerTeleportCooldown,x
    jne SkipWalkthrough2
  : dey
    lda LevelBuf,y
    cmp #METATILE_TELEPORT_LEFT
    beq :+
    cmp #METATILE_TELEPORT_RIGHT
    beq :+
    bne :-
  : jsr MovePlayerToLevelY

    lda #60
    sta PlayerTeleportCooldown,x
    lda #SOUND_TELEPORT
    jsr start_sound

    jmp SkipWalkthrough2
NotTeleportLeft:

  cmp #METATILE_TELEPORT_RIGHT
  bne NotTeleportRight
    lda PlayerTeleportCooldown,x
    jne SkipWalkthrough2
  : iny
    lda LevelBuf,y
    cmp #METATILE_TELEPORT_LEFT
    beq :+
    cmp #METATILE_TELEPORT_RIGHT
    beq :+
    bne :-
  : jsr MovePlayerToLevelY

    lda #60
    sta PlayerTeleportCooldown,x
    lda #SOUND_TELEPORT
    jsr start_sound

    jmp SkipWalkthrough2
NotTeleportRight:

;---------------------------------------------
SkipWalkthrough2:
  pla
  sta 0

  lda PlayerPowerEnabled,x
  cmp #APOWERUP_JUMP
  bne :+
    lda keydown,x
    and #KEY_A
    beq :+
      lda keylast,x
      and #KEY_A
      jeq StartJump
  :

  ; it's only OK to fall through platforms, nothing else
  lda PlayerPYH,x
  add #16
  and #$f0
  ora 0
  tay
  lda LevelBuf,y
  cmp #METATILE_CYCLE_ON_PLATF
  beq :+
  cmp #METATILE_PLATFM
  bne :++
: lda keydown,x
  and #KEY_A|KEY_DOWN
  cmp #KEY_A|KEY_DOWN
  beq DropThroughPlatform ; fallthrough
  lda PlayerDropLock,x
  bne SkipPlatformCheck
: ; collision with platforms
  lda PlayerVYH,x
  bpl NotSkipMi
  jmp :+
NotSkipMi:
  lda PlayerXShifted
  sta 0
  lda PlayerPYH,x
  add #16
  and #$f0
  ora 0
  tay
  sty 0
  lda LevelBuf,y
  cmp #FirstSolidTop
  bcc SkipPlatformCheck
    lda PlayerPYH,x
    and #$f0
    sta PlayerPYH,x

    lda keydown,x
    and #KEY_B
    sta PlayerWasRunning,x

    lda #0
    sta PlayerVYH,x
    sta PlayerVYL,x
    sta PlayerJumpCancelLock,x

    lda keydown,x      ; start a jump
    and #KEY_A
    beq SkipPlatformCheck
StartJump:
      lda #SOUND_JUMP
      jsr start_sound

      lda #-4
      sta PlayerVYH,x
      lda #0
      sta PlayerVYL,x
      beq SkipPlatformCheck
DropThroughPlatform:
  lda #13
  sta PlayerDropLock

SkipPlatformCheck:
; check for block types you walk through instead
  ldy 11
  lda LevelBuf,y
  cmp #METATILE_SPRING
  bne NotSpring
    lda #METATILE_SPRING2
    jsr ChangeBlock
    lda retraces
    add #4
    sta 0
    lda #METATILE_SPRING
    jsr AddDelayMetaEdit

    lda #-5
    sta PlayerVYH,x
    lda #80
    sta PlayerVYL,x
    lda #1
    sta PlayerJumpCancelLock,x
    lda #SOUND_SPRING
    jsr start_sound

    jmp SkipWalkthrough
NotSpring:

  cmp #METATILE_SPIKES
  bne NotSpikes
    txa
    tay
    jsr PlayerHurt
    jmp SkipWalkthrough
NotSpikes:
  cmp #METATILE_KILL_SPIKES
  bne NotDeathSpikes
    lda #1
    sta PlayerDead,x

    lda #SOUND_YOUDEAD
    jsr start_sound
NotDeathSpikes:
SkipWalkthrough:


  lda ScrollMode
  beq NotScrollMode
  lda PlayerPX,x
  sub ScrollX+1
  cmp #16+2+8
  bcs :+
    lda #1
    sta PlayerDead,x
    lda #SOUND_YOUDEAD
    jsr start_sound
  :


NotScrollMode:

  lda PlayerInvincible,x
  beq :+
    dec PlayerInvincible,x
  :

  lda PlayerTeleportCooldown,x
  beq :+
    dec PlayerTeleportCooldown,x
  :

  ; collision with bullets
  jsr PlayerGetShot
  bcc :+
    txa
    tay
    jsr PlayerHurt
: jsr DispPlayer
  rts
BlockXSpeed:
  .byt 3, -3
BlockXOffset:
  .byt 12, -12-16

ShootBillBlock:
  stx TempVal
  jsr FindFreeObjectX
  bcc :+
  ldy TempVal

  lda PlayerDir,y
  sta 3
  and #1
  ora #OBJECT_BOMB*2
  sta ObjectF1,x
  lda #EXTOBJ_BILLBLOCK
  sta ObjectF3,x

  lda PlayerPX,y
  ldy 3
  add BlockXOffset,y
  sta ObjectPX,x

  ldy TempVal

  lda PlayerPYH,y
  add #4
  sta ObjectPYH,x
  lda #5
  sta ObjectTimer,x
: ldx TempVal
  jmp NoShoot

.endproc

.proc MovePlayerToLevelY
  tya
  pha
  asl
  asl
  asl
  asl
  add #4
  sta PlayerPX,x
  pla
  and #$f0
  sta PlayerPYH,x
  rts
.endproc

.proc BodyTypeAnims
  .byt $18, $19, $18, $1a ; style the player uses
  .byt $3f, $1c, $3f, $1d ; stick figure style
  .byt $11, $12, $11, $12 ; fat guy
  .byt $14, $14, $14, $14 ; hover guy?
  .byt $15, $15, $15, $15 ; solid guy
  .byt $16, $17, $16, $17 ; tilty pogo guy
  .byt $1e, $1e, $1e, $1e ; hover guy 2
.endproc

.proc PlayerGetShot
  lda PlayerPYH,x
  add #8
  lsr
  lsr
  and #%111000
  sta TempVal
  lda PlayerPX,x
  add #4
  lsr ; / 32 pixels
  lsr
  lsr
  lsr
  lsr
  ora TempVal
  tay
  lda BulletMap,y
  beq Exit

  ldy #0
BulletLoop:
  lda BulletF,y
  and #%10000000
  cmp #%10000000 ;enabled, enemy-made bullets only
  bne SkipBullet

  lda BulletPX,y
  sta TouchLeftA
  lda BulletPY,y
  sta TouchTopA

  lda PlayerPX,x
  sta TouchLeftB
  lda PlayerPYH,x
  sta TouchTopB

  lda #8
  sta TouchWidthA
  sta TouchWidthB
  sta TouchHeightA
  asl
  sta TouchHeightB

  jsr ChkTouchGeneric
  bcs ShotHit
SkipBullet:
  iny
  cpy #BulletLen
  bne BulletLoop
Exit:
  clc
  rts
ShotHit:
  lda PlayerInvincible,x
  bne :+
  lda #0
  sta BulletF,y
  sec
: rts
.endproc

.proc DispPlayer
  ; 0 - attribute
  ; 1 - used to preserve Y (register)
  ; 2 - used to preserve Y (position)
  ; x - player num

  lda PlayerInvincible,x
  beq :+
    lda retraces
    and #1
    beq :+
      rts
  :

  ; change stuff when player is facing left
  lda #0|OAM_COLOR_0
  ldy PlayerDir,x   ; garbage load; we only care about the flags
  beq :+
    lda #OAM_XFLIP|OAM_COLOR_0
: sta 0

  lda PlayerPowerTime,x ; flashy if we have a powerup
  beq :+
    lda 0
    ora #OAM_COLOR_3
    sta 0
  :

  ldy OamPtr

  lda PlayerPYH,x
  sub #1
  sta OAM_YPOS+(4*0),y
  add #6
  sta OAM_YPOS+(4*2),y
  add #2
  sta OAM_YPOS+(4*1),y

  lda 0
  sta OAM_ATTR+(4*0),y
  sta OAM_ATTR+(4*1),y
  sta OAM_ATTR+(4*2),y

  lda PlayerHead,x
  sta OAM_TILE+(4*0),y

  ; walking animation
  sty 1 ; save Y
  lda PlayerBody,x
  asl
  asl
  sta 0
  tay
  lda keydown,x
  and #KEY_LEFT + KEY_RIGHT
  beq :+
    lda retraces
    lsr
    lsr
    and #3
    add 0
    tay
  :
  lda BodyTypeAnims,y
  ldy 1 ; restore Y
  sta OAM_TILE+(4*1),y
  lda PlayerHeld,x
  ora #$20
  sta OAM_TILE+(4*2),y

  lda PlayerPX,x
  sub ScrollX+1
  sta OAM_XPOS+(4*0),y
  sta OAM_XPOS+(4*1),y

  sty 1
  lda PlayerDir,x
  tay
  lda OffsetHeldX,y
  ldy 1
  add PlayerPX,x
  sub ScrollX+1
  sta OAM_XPOS+(4*2),y

  tya
  add #16
  tay
  sty OamPtr
  rts
.endproc
.proc OffsetHeldX
  .byt 8, -8
.endproc
.proc BulletSpeed
  .byt 6, -6
.endproc

.proc IsPlayerTouching
  ; X - player number
  lda PlayerPX,x
  sta TouchLeftA,x
  lda PlayerPYH,x
  sta TouchTopA,x
  lda #8
  sta TouchWidthA
  lda #16
  sta TouchHeightA
;  jmp ChkTouchGeneric
.endproc

.proc ChkTouchGeneric
  jsr :+
  swapa TouchLeftA,   TouchLeftB
  swapa TouchTopA,    TouchTopB
  swapa TouchWidthA,  TouchWidthB
  swapa TouchHeightA, TouchHeightB
  jsr :+
  clc ; no collision
  rts
: lda TouchLeftB
  add TouchWidthB
  sta TouchRight
  lda TouchTopB
  add TouchHeightB
  sta TouchBottom

  lda TouchLeftA
  cmp TouchLeftB
  bcc :+

  lda TouchLeftA
  cmp TouchRight
  bcs :+

  lda TouchTopA
  cmp TouchTopB
  bcc :+

  lda TouchTopA
  cmp TouchBottom
  bcs :+
  pla
  pla
  sec ; collision detected
: rts
.endproc

.proc PlayerHurt ; Y is actually the player here, not X
  txa
  pha

  lda PlayerHealth,y
  beq :+
    lda PlayerInvincible,y
    bne :+
      sty TempVal
      lda #SOUND_YOUHURT
      jsr start_sound
      ldy TempVal

      dcp PlayerHealth,y
      lda #60
      sta PlayerInvincible,y
      lda PlayerHealth,y
      bne :+
        lda #1
        sta PlayerDead,y
: pla
  tax
  rts
.endproc

.proc PlayerAddScore
  tay
  lda BCD64,y
  unpack TempVal,TempVal+1
  ldy PlayerScoreIndex,x
  tya
  pha
  lda ScoreDigits+2,y
  pha

  lda ScoreDigits,y
  add TempVal
  sta ScoreDigits,y
  lda ScoreDigits+1,y
  add TempVal+1
  sta ScoreDigits+1,y
FixLoop: ; if it goes past 9, carry it over
  lda ScoreDigits,y
  cmp #'9'+1 ; 9 or less: no fixing
  bcc Next
  sub #10
  sta ScoreDigits,y
  isc ScoreDigits+1,y
Next:
  iny
  cpy #NumScoreDigits
  beq Exit
  cpy #NumScoreDigits*2
  bne FixLoop
Exit:
  pla
  sta TempVal
  pla
  tay
  lda TempVal
  cmp ScoreDigits+2,y
  beq :+
    lda ScoreDigits+2,y
    cmp #'0'
    beq AddLife
    cmp #'5'
    beq AddLife
  :
  rts
AddLife:
  lda PlayerLives,x
  cmp #9
  beq :+
  inc PlayerLives,x
  rts
.endproc

PlayerScoreIndex:
  .byt 0, NumScoreDigits
