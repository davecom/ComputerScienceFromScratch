.proc RunObjects
  ldx #0
Loop:
  jsr Launch
  inx
  cpx #ObjectLen
  beq Exit
  jmp Loop

Launch:
  lda #2
  sta DispEnemyHead
  lda #8
  sta EnemyWidth
  lda ObjectF1,x
  and #%111110
  beq Exit
  tay
  lda ObjectTable+1,y
  pha
  lda ObjectTable+0,y
  pha
Exit:
  rts
.endproc

.proc EmptyObject
  rts
.endproc

.proc rand_8_safe
  stx TempVal
  jsr rand_8
  ldx TempVal
  rts
.endproc

.proc EnemyShoot
  sta 0 ; 0 - bullet type
  asl
  sta 1 ; 1 - bullet type * 2
  lda ObjectF1,x
  and #1
  sta 2 ; 2 - just the direction bit
  jsr FindFreeBulletY
  bcc Exit
  lda ObjectPX,x
  sta BulletPX,y
  lda ObjectPYH,x
  add #4
  sta BulletPY,y
  lda 0
  ora #%10000000
  sta BulletF,y

  stx 3 ; temp to hold X while we look up stuff not related to it
  lda 1
  ora 2
  tax
  lda BulletXSpeedTable,x
  sta BulletVX,y
  ldx 0
  lda BulletLifeTable,x
  sta BulletLife,y
  ldx 3

  lda #0
  sta BulletVY,y
  sta BulletVXL,y
  sta BulletVYL,y
  sta BulletPXL,y
  sta BulletPYL,y

  lda 0
  cmp #GUN_VERTICAL
  bne :+
    lda #-4
    sta BulletVY,y
    lda ObjectPYH,x
    bmi :+
      lda #4
      sta BulletVY,y
  :

  lda 0
  cmp #GUN_DIAGONAL
  bne :+
    lda #-4
    sta BulletVY,y
    lda retraces
    and #%1000000
    beq :+
      lda #4
      sta BulletVY,y
  :

  lda BulletPX,y
  add BulletVX,y
  add BulletVX,y
  sta BulletPX,y
  sec
Exit:
  rts
.endproc

.proc EnemyShootAtPlayer
  WhichPlayer = 4
  BulletType = 5
  Temp = 6
  Speed = 7
  sta BulletType
  sty WhichPlayer
  
  cpy #-1 ; pick either player
  bne :+
    lda retraces
    and #1
    sta WhichPlayer
: ldy WhichPlayer
  lda PlayerEnabled,y
  bne :+
    tya
    eor #1
    sta WhichPlayer
  :

  jsr FindFreeBulletY
  bcc Exit
  lda ObjectPX,x
  sta BulletPX,y
  sta 0
  lda ObjectPYH,x
  add #4
  sta BulletPY,y
  sta 1
  lda BulletType
  ora #%10000000
  sta BulletF,y

  stx Temp
  lda BulletType
  tax
  lda BulletXSpeedTable,x
  asl
  asl
  sta Speed
  ldx BulletType
  lda BulletLifeTable,x
  asl
  sta BulletLife,y
  ldx WhichPlayer
  lda PlayerPX,x
  sta 2
  lda PlayerPYH,x
  add #4
  sta 3
  ldx Temp

  sty Temp
  jsr getAngle
  tay
  lda Speed
  jsr SpeedAngle2Offset
  ldy Temp

  lda #0
  sta BulletPYL,y

  lda 0
  sta BulletVXL,y
  lda 1
  sta BulletVX,y
  lda 2
  sta BulletVYL,y
  lda 3
  sta BulletVY,y
  sec
Exit:
  rts
.endproc

.proc BulletXSpeedTable
  .byt 0, -0
  .byt 2, -2
  .byt 3, -3 ; faster
  .byt 2, -2 ; energy thing
  .byt 0,  0 ; energy thing (vertical)
  .byt 5, -5 ; FAST energy thing
  .byt 3, -3 ; fast spiky thing
  .byt 2, -2 ; energy thing
  .byt 2, -2 ; player's weapon
  .byt 4, -4 ; diagonal
  .byt 5, -5 ; spike
  .byt 3, -3 ; block
  .byt 3, -3 ; bomb
.endproc
GUN_DIAGONAL = 9
GUN_VERTICAL = 4

.proc BulletLifeTable
  .byt 0
  .byt 40
  .byt 20
  .byt 20
  .byt 20
  .byt 20
  .byt 20
  .byt 20
  .byt 20
  .byt 20
  .byt 20
  .byt 20
  .byt 10
.endproc

.proc EnemyHurt
  lda ObjectF1,x
  cmp #%01000000 ; any HP left?
  bcc :+         ; if so, just take away 1HP
  sub #%01000000
  sta ObjectF1,x
  sty TempVal
  lda #SOUND_ENEMYHURT2
  jsr start_sound
  ldy TempVal
  rts
: lda #ENEMY_STATE_STUNNED
  sta ObjectF2,x
  lda #200 ; same amount of time as in FHBG
  sta ObjectTimer,x
  sty TempVal
  lda #SOUND_ENEMYHURT
  jsr start_sound
  ldy TempVal
  rts
.endproc

.proc EnemyKill
  lda #0
  sta ObjectF1,x
  sta ObjectF2,x
  dec ScreenEnemiesCount
  lda EnemyWidth
  cmp #16
  bne :+
    lda #OBJECT_BOMB*2
    sta ObjectF1,x
    lda #EXTOBJ_POOF
    sta ObjectF3,x
    lda #12
    sta ObjectTimer,x
    ; give a boost
    lda #-3
    sta PlayerVYH,y
    lda #0
    sta PlayerVYL,y
    lda #10
    sta PlayerJumpCancelLock,y
  :
  lda LevelGoalType
  bne :+
    lda LevelGoalParam
    beq :+
      dec LevelGoalParam
: rts
.endproc

.proc EnemyPlayerTouch
  ldy #0
PlayerLoop:
  lda PlayerPX,y
  sta TouchLeftA
  lda PlayerPYH,y
  sta TouchTopA

  lda ObjectPX,x
  sta TouchLeftB
  lda ObjectPYH,x
  sta TouchTopB

  lda EnemyWidth
  sta TouchWidthB
  lda #8
  sta TouchWidthA
  asl
  sta TouchHeightA
  sta TouchHeightB

  jsr ChkTouchGeneric
  bcc NotTouched
    lda ObjectF2,x
    cmp #ENEMY_STATE_STUNNED
    beq IsStunned
    bne IsNotStunned
NotTouched:
  iny
  cpy #MaxNumPlayers
  bne PlayerLoop
  rts
IsStunned:
  ; award points for removing the enemy
  stx TempVal+2
  sty TempVal+3
  lda ObjectF1,x ; get the enemy type number from the flags
  alr #%111110
  tay
  lda ObjectPointsTable,y
  ldx TempVal+3
  jsr PlayerAddScore

  lda #SOUND_COLLECT
  jsr start_sound
  ldx TempVal+2
  ldy TempVal+3
  clc
  jsr EnemyKill
  jmp NotTouched
IsNotStunned:
  lda EnemyWidth ; wide enemies always hurt
  cmp #8
  beq :+
    lda ObjectF1,x ; unless it's a Goomba then you can stomp it
    alr #%111110
    cmp #OBJECT_GOOMBA
    beq Goomba
    jsr PlayerHurt
    bne NotTouched
: lda GameDifficulty
  cmp #DIFFICULTY_HARDER
  bcc NotTouched
HurtPlayer:
  jsr PlayerHurt
  jmp NotTouched

Goomba:
  lda PlayerVYH,y
  bmi HurtPlayer
  cmp #1
  bcs IsStunned
  lda PlayerVYL,y
  bne IsStunned
  beq HurtPlayer
.endproc

.proc EnemyGetShot
  lda ObjectPYH,x
  add #8
  lsr
  lsr
  and #%111000
  sta TempVal
  lda ObjectPX,x
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
  and #%11000000
  cmp #%11000000 ;enabled, player-made bullets only
  bne SkipBullet

  lda BulletPX,y
  sta TouchLeftA
  lda BulletPY,y
  sta TouchTopA

  lda ObjectPX,x
  sta TouchLeftB
  lda ObjectPYH,x
  sta TouchTopB

  lda EnemyWidth
  sta TouchWidthB
  lda #8
  sta TouchWidthA
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
  lda #0
  sta BulletF,y
  sec
  rts
.endproc

.proc EnemyWalk
  ldy GameDifficulty
  cpy #DIFFICULTY_HARDER ; if hard mode, add 1 to enemy speed
  adc #0                 ; carry set if equal or greater than
  sta 0

  lda EnemyWidth
  sta 1
  dec 1

  ; if facing left, negate the speed
  lda ObjectF1,x
  and #1
  beq :+
    lda 0
    eor #255
    add #1
    sta 0
    lda #0               ; also start from left instead of right
    sta 1
  :

  ; bump check
  lda ObjectPX,x
  add 1                  ; add offset from direction
  add 0                  ; add offset from walking
  lsr
  lsr
  lsr
  lsr
  sta 1
  lda ObjectPYH,x
  add #8
  and #$f0
  ora 1
  tay
  lda LevelBuf,y
  jsr BlockIsSolid
  beq :+ 
    sec
    rts
  :

  ; no bump? add X offset then
  lda ObjectPX,x
  add 0
  sta ObjectPX,x
  clc
  rts
.endproc

.proc EnemyAutoBump
  bcc NoBump
  lda ObjectPX,x
  lsr
  lsr
  lsr
  lsr
  sta 0
  lda ObjectPYH,x
  add #15
  and #$f0
  ora 0
  tay
  lda LevelBuf,y
  cmp #METATILE_LAUNCH
  bne :+
    lda #-2
    sta ObjectVYH,x
    lda #0
    sta ObjectVYL,x
    lda ObjectF1,x
    and #1
    tay
    lda ObjectPX,x
    add OffsetAmount,y
    sta ObjectPX,x
    rts
: lda ObjectF1,x
  eor #1
  sta ObjectF1,x
NoBump:
  rts
OffsetAmount:
  .byt 4, -6
.endproc

.proc EnemyGravity
  lda ObjectPYL,x
  add ObjectVYL,x
  bcc :+
    inc ObjectPYH,x
: sta ObjectPYL,x

  lda ObjectVYH,x
  bmi GravityOkay
  cmp #8
  bcs SkipGravity
GravityOkay:
  lda ObjectVYL,x
  add #32
  bcc :+
    inc ObjectVYH,x
: sta ObjectVYL,x
  SkipGravity:
  lda ObjectPYH,x
  add ObjectVYH,x
  sta ObjectPYH,x
  rts
.endproc

.proc EnemyRemoveFromFalling
  lda #0
  sta ObjectF1,x
  sta ObjectF2,x
  dec ScreenEnemiesCount
  rts
.endproc

.proc EnemyFallGravityOnly
  lda ObjectPYH,x ; save old py
  sta 0
  jsr EnemyGravity

  lda ObjectVYH,x
  bmi :+
    lda ObjectPYH,x
    cmp 0
    bcs :+
      lda LevelGoalType
      bne EnemyRemoveFromFalling
      stx 0
      jsr rand_8
      ldx 0
      sta ObjectPX,x
      and #1
      eor ObjectF1,x
      sta ObjectF1,x
: rts
.endproc

.proc EnemyFall ; carry = standing on platform
  lda ObjectPYH,x ; save old py
  sta 0
  jsr EnemyGravity

  lda ObjectVYH,x
  bmi :+
    lda ObjectPYH,x
    cmp 0
    bcs :+
      lda LevelGoalType
      bne EnemyRemoveFromFalling
      stx 0
      jsr rand_8
      ldx 0
      sta ObjectPX,x
      and #1
      eor ObjectF1,x
      sta ObjectF1,x
: lda ObjectPX,x
  add #4
.endproc
; -- inline tail call --
.proc EnemyCollidePlatforms ; A = ObjectPX,x
  ldy ObjectVYH,x
  bmi :+
  lsr
  lsr
  lsr
  lsr
  sta 0
  lda ObjectPYH,x
  add #16          ; maybe change to allow taller enemies?
  and #$f0
  ora 0
  tay
  lda LevelBuf,y
  cmp #FirstSolidTop
  bcc :+
    lda ObjectPYH,x
    and #$f0
    sta ObjectPYH,x
    lda #0
    sta ObjectVYH,x
    sta ObjectVYL,x
    sec
    rts
: clc
  rts
.endproc

.proc EnemyFallWide ; carry = standing on platform
  lda ObjectPYH,x ; save old py
  sta 0
  jsr EnemyGravity

  lda ObjectVYH,x
  bmi :+
    lda ObjectPYH,x
    cmp 0
    bcs :+
      lda LevelGoalType
      jne EnemyRemoveFromFalling
      stx 0
      jsr rand_8
      ldx 0
      sta ObjectPX,x
      and #1
      eor ObjectF1,x
      sta ObjectF1,x
  :

  lda #0
  sta 1
  lda ObjectPX,x
  pha
  jsr EnemyCollidePlatforms
  rol 1
  pla
  add #15
  jsr EnemyCollidePlatforms
  rol 1
  lda 1
  cmp #1
  rts
.endproc

.proc AddEnemies
  lda retraces
  and #31
  bne Exit
  lda ScreenEnemiesCount
  cmp MaxScreenEnemies
  bcs Exit
  jsr rand_8
  lsr
  lsr
  and #15
  tax
  lda LevelEnemyPool,x
  sta 0
  jsr FindFreeObjectX
  bcc Exit

  lda 0
  pha
  and #%00011111  ; extract enemy type
  asl
  sta ObjectF1,x

  cmp #OBJECT_RETARD*2
  bne :+
    ora #%01000000
    sta ObjectF1,x
: cmp #OBJECT_FLAPPY*2
  bne :+
    ora #%01000000
    sta ObjectF1,x
: cmp #OBJECT_TOASTBOT*2
  bne :+
    ora #%10000000
    sta ObjectF1,x    
: cmp #OBJECT_BURGER3*2
  bne :+
    ora #%01000000
    sta ObjectF1,x    
: cmp #OBJECT_POTION*2
  bne :+
    ora #%11000000
    sta ObjectF1,x
  :

  jsr rand_8_safe ; random direction
  lsr
  bcc :+
  inc ObjectF1,x
:
  pla
  and #%11100000  ; also put in the parameters
  sta ObjectF3,x

  lda #0
  sta ObjectPYH,x
  sta ObjectPYL,x
  sta ObjectVYH,x
  sta ObjectVYL,x
  sta ObjectTimer,x
  jsr rand_8_safe
  sta ObjectPX,x

  inc ScreenEnemiesCount
Exit:
  rts
.endproc

.proc FindFreeObjectX ; carry = success
  pha
  ldx #0
: lda ObjectF1,x
  beq Found
  inx
  cpx #ObjectLen
  bne :-
NotFound:
  pla
  clc
  rts
Found:
  pla
  sec
  rts
.endproc

; originally 3, 4, 5
;DispEnemyBodyType = 3
;DispEnemyWeapon   = 4
;DispEnemyHead     = 5

.proc DispEnemy
  ; 0 - attribute
  ; 1 - used to preserve Y (register)
  ; 2 - used to preserve Y (position)
  ; x - enemy num
  lda ObjectF2,x
  cmp #ENEMY_STATE_STUNNED
  bne :+
    ldy OamPtr
    lda ObjectPYH,x
    sub #1
    sta OAM_YPOS+(4*0),y
    add #8
    sta OAM_YPOS+(4*1),y

    lda #OAM_COLOR_1
    sta OAM_ATTR+(4*0),y
    sta OAM_ATTR+(4*1),y

    lda #$41
    sta OAM_TILE+(4*0),y
    lda #$51
    sta OAM_TILE+(4*1),y

    lda ObjectPX,x
    sub ScrollX+1
    sta OAM_XPOS+(4*0),y
    sta OAM_XPOS+(4*1),y

    tya
    add #8
    sta OamPtr
    rts
:

  ldy #OAM_COLOR_1
  lda ObjectF1,x
  and #1
  beq :+
    ldy #OAM_XFLIP|OAM_COLOR_1
: sty 0
  ldy OamPtr

  lda ObjectPYH,x
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

  lda DispEnemyWeapon
  cmp #GUN_DIAGONAL
  bne :+
    lda retraces
    and #%1000000
    beq :+
      lda 0
      ora #OAM_YFLIP
      sta OAM_ATTR+(4*2),y
  :

  lda DispEnemyHead ; player head
  sta OAM_TILE+(4*0),y

  ; walking animation
  sty 1 ; save Y (holds OAM pointer)
  lda DispEnemyBodyType ; body type
  asl
  asl
  sta 0
  tay
; always moving, don't do the check
  lda retraces
  lsr
  lsr
  and #3
  add 0
  tay

  lda BodyTypeAnims,y
  ldy 1 ; restore Y
  sta OAM_TILE+(4*1),y
  lda DispEnemyWeapon ; held item
  ora #$20
  sta OAM_TILE+(4*2),y

  lda ObjectPX,x
  sub ScrollX+1
  sta OAM_XPOS+(4*0),y
  sta OAM_XPOS+(4*1),y

  sty 1
  lda ObjectF1,x
  and #1
  tay
  lda OffsetHeldX,y
  ldy 1
  add ObjectPX,x
  sub ScrollX+1
  sta OAM_XPOS+(4*2),y

  tya
  add #16
  tay
  sty OamPtr
  rts
.endproc

DispEnemyWide:
  ; 0 - tile 0 (top left)
  ; 1 - tile 1 (bottom left)
  ; 2 - tile 2 (top right)
  ; 3 - tile 3 (bottom right)
  ; 4 - attribute
  ; 5 - flags (from accumulator)
  ; x - enemy num
  ; y - enemy tiles
  sty 0
  iny
  sty 1
  iny
  sty 2
  iny
  sty 3
.proc DispEnemyWideCustom
  Attribute = 4
  Flags = 5
  sta Flags

  ldy #OAM_COLOR_1
  lda Flags
  and #2
  bne NoHFlip
  ; flip horizontally
  lsr Flags
  bcc :+
    lda retraces
    and #%100
    beq DoHFlip
    bne NoHFlip
  :
  lda ObjectF1,x
  and #1
  beq NoHFlip
DoHFlip:
    swapy 0, 2
    swapy 1, 3
    ldy #OAM_XFLIP|OAM_COLOR_1
NoHFlip:
  sty Attribute

  ; flip vertically
  lda ObjectF2,x
  cmp #ENEMY_STATE_STUNNED
  bne :+
    swapy 0, 1
    swapy 2, 3
    lda Attribute
    ora #OAM_YFLIP
    sta Attribute
:

  ldy OamPtr

  lda ObjectPYH,x
  sta OAM_YPOS+(4*0),y
  sta OAM_YPOS+(4*2),y
  add #8
  sta OAM_YPOS+(4*1),y
  sta OAM_YPOS+(4*3),y

  lda Attribute
  sta OAM_ATTR+(4*0),y
  sta OAM_ATTR+(4*1),y
  sta OAM_ATTR+(4*2),y
  sta OAM_ATTR+(4*3),y

  lda 0
  sta OAM_TILE+(4*0),y
  lda 1
  sta OAM_TILE+(4*1),y
  lda 2
  sta OAM_TILE+(4*2),y
  lda 3
  sta OAM_TILE+(4*3),y

  lda ObjectPX,x
  sub ScrollX+1
  sta OAM_XPOS+(4*0),y
  sta OAM_XPOS+(4*1),y
  add #8
  sta OAM_XPOS+(4*2),y
  sta OAM_XPOS+(4*3),y

  tya
  add #16
  tay
  sty OamPtr
  rts
.endproc


ENEMY_STATE_BITS    = %1111
ENEMY_STATE_NORMAL  = 0
ENEMY_STATE_PAUSE   = 1
ENEMY_STATE_STUNNED = 2
ENEMY_STATE_ACTIVE  = 3

; enemy types follow this line                 ;
.proc ObjectTable
  .raddr EmptyObject
  .raddr WalkerEnemy
  .raddr JumpyEnemy
  .raddr DiagShooterEnemy
  .raddr WaitingShooterEnemy
  .raddr BombObject
  .raddr FlyBomberEnemy
  .raddr FlyDiagonalEnemy
  .raddr FloatVertShootEnemy
  .raddr GoombaEnemy
  .raddr SneakerEnemy
  .raddr GeorgeEnemy
  .raddr RetardEnemy
  .raddr ToastbotEnemy
  .raddr BurgerEnemy
  .raddr BurgerEnemy
  .raddr BurgerEnemy
  .raddr BillHeadEnemy
  .raddr RollBallEnemy
  .raddr JumpBallEnemy
  .raddr TrigWalkerEnemy
  .raddr TrigBombShooterEnemy
  .raddr ThwompEnemy
  .raddr ThwompEnemy
  .raddr FlappyEnemy
  .raddr PotionEnemy
  .raddr SpearsEnemy
;  .raddr EmptyObject
.endproc

ObjectIsEnemy: ; doubles as a table to find out if an object is an enemy or not
               ; as non-enemies do not give points
.proc ObjectPointsTable
  .byt 0
  .byt 3   ;walker
  .byt 5   ;jumpy
  .byt 7   ;diagshoot
  .byt 10  ;waitshoot
  .byt 0   ;bomb
  .byt 15  ;flybomber
  .byt 12  ;flydiag
  .byt 10  ;floatvertshoot
  .byt 10  ;goomba
  .byt 20  ;sneaker
  .byt 20  ;george
  .byt 14  ;retard
  .byt 13  ;toastbot
  .byt 18  ;burger1
  .byt 24  ;burger2
  .byt 20  ;burger3
  .byt 40  ;bill nye
  .byt 10  ;roll ball
  .byt 15  ;jump ball
  .byt 10  ;trig walk
  .byt 27  ;trig bomber
  .byt 20  ;thwomp static
  .byt 20  ;thwomp move
  .byt 20  ;flappy
  .byt 20  ;potion
  .byt 7   ;spears
.endproc

.enum
  OBJECT_NONE
  OBJECT_WALKER
  OBJECT_JUMPY
  OBJECT_DIAGSHOOT
  OBJECT_WAITSHOOT
  OBJECT_BOMB
  OBJECT_FLYBOMBER
  OBJECT_FLYDIAG
  OBJECT_FLOATVERTSHOOT
  OBJECT_GOOMBA
  OBJECT_SNEAKER
  OBJECT_GEORGE
  OBJECT_RETARD
  OBJECT_TOASTBOT
  OBJECT_BURGER1
  OBJECT_BURGER2
  OBJECT_BURGER3
  OBJECT_BILL_HEAD
; new stuff, starting at index 18, 13 more slots to go
  OBJECT_ROLL_BALL
  OBJECT_BOUNCE_BALL
  OBJECT_TRIGWALK ; shoots as it walks
  OBJECT_TRIGBOMB ; gun direction indicates which player it points at
  OBJECT_THWOMP_STATIC
  OBJECT_THWOMP_MOVE
  OBJECT_FLAPPY
  OBJECT_POTION
  OBJECT_SPEARS
.endenum

.enum
  EXTOBJ_BOMB
  EXTOBJ_WATER
  EXTOBJ_BILLBLOCK
  EXTOBJ_POOF
  EXTOBJ_HPLAT
  EXTOBJ_VPLAT
  EXTOBJ_HHURT
  EXTOBJ_VHURT
.endenum

.proc EnemyDecTimer
  lda ObjectTimer,x
  beq :+
    dec ObjectTimer,x
    bne :+
      lda #ENEMY_STATE_NORMAL
      sta ObjectF2,x
: rts
.endproc

.proc BillHeadEnemy
  lda ObjectF2,x
  jne NoFly
    lda #4
    jsr EnemyWalk

    lda retraces
    and #3
    bne NotDropBomb
    lda MaxScreenEnemies
    cmp #1
    beq :+
      jsr rand_8_safe
      and #7
      beq DoDropBomb
      bne NotDropBomb
    :
    jsr rand_8_safe
    and #3
    bne NotDropBomb
DoDropBomb:
    lda ObjectPX,x
    pha
    add #12
    sta ObjectPX,x
    jsr DropBomb
    pla
    sta ObjectPX,x
  NotDropBomb:

    lda ObjectF1,x ; pick between left/right values for flying into wall
    and #1
    tay
    beq :+         ; left edge
      lda ObjectPX,x
      cmp #10
      bcs NoFly
      bcc HitWall
  : lda ObjectPX,x ; right edge
    cmp #256-24-10
    bcc NoFly
  HitWall:
    lda SideStartX,y
    sta ObjectPX,x
    lda ObjectF1,x
    eor #1
    sta ObjectF1,x
    lda #60
    sta ObjectTimer,x
    lda #ENEMY_STATE_PAUSE
    sta ObjectF2,x
    sty TempVal+1
    jsr rand_8_safe
    lsr
    add #80
    sta ObjectPYH,x
    stx TempVal
    jsr FindFreeObjectX
    bcc NoFly
    ldy TempVal+1
    lda SideStartX2,y
    sta ObjectPX,x

    ldy TempVal

    lda ObjectF1,y
    and #1
    ora #OBJECT_BOMB*2
    sta ObjectF1,x
    lda #EXTOBJ_BILLBLOCK
    sta ObjectF3,x

    lda ObjectPYH,y
    add #4
    sta ObjectPYH,x
    lda #20
    sta ObjectTimer,x

    tya
    tax
  NoFly:

  ; collide with blocks
  ldy #0
ObjLoop:
  lda ObjectF1,y
  bpl SkipObj ; don't react to blocks that haven't been reflected
  and #%111110
  cmp #OBJECT_BOMB*2
  bne SkipObj

  lda ObjectF3,y
  cmp #EXTOBJ_BILLBLOCK
  bne SkipObj

  lda ObjectPX,y
  sta TouchLeftA
  lda ObjectPYH,y
  sta TouchTopA

  lda ObjectPX,x
  sta TouchLeftB
  lda ObjectPYH,x
  sta TouchTopB

  lda #16
  sta TouchWidthA
  sta TouchHeightA
  lda #24
  sta TouchWidthB
  sta TouchHeightB

  jsr ChkTouchGeneric
  bcc :+
    lda #0
    sta ObjectF1,y
    lda #10
    sta ObjectTimer,x
    lda #ENEMY_STATE_PAUSE
    sta ObjectF2,x
    inc ObjectF3,x
    lda ObjectF3,x
    cmp #4
    bcc NotKilled
      sty TempVal
      lda #SOUND_EXPLODE1
      jsr start_sound
      lda #SOUND_EXPLODE2
      jsr start_sound
      lda #-2
      sta ObjectVYH,x
      ldy TempVal
      jmp :+
    NotKilled:

    sty TempVal
    lda #SOUND_ENEMYHURT2
    jsr start_sound
    ldy TempVal
  :
SkipObj:
  iny
  cpy #ObjectLen
  bne ObjLoop

  ; fall when dying
  lda ObjectF3,x
  cmp #4
  bcc :+
    jsr EnemyFallGravityOnly
    lda #1
    sta ObjectF2,x
    lda #10
    sta ObjectTimer,x
    lda ObjectPYH,x
    cmp #240
    bcc :+
      jmp EnemyKill
  :

  lda ObjectF1,x
  jeq Exit

  jsr EnemyDecTimer

; draw sprite                     
  ldy OamPtr
  lda ObjectPYH,x
  sta OAM_YPOS+(4*0),y
  sta OAM_YPOS+(4*1),y
  sta OAM_YPOS+(4*2),y
  add #8
  sta OAM_YPOS+(4*3),y
  sta OAM_YPOS+(4*4),y
  sta OAM_YPOS+(4*5),y
  add #8
  sta OAM_YPOS+(4*6),y
  sta OAM_YPOS+(4*7),y
  sta OAM_YPOS+(4*8),y

  lda #OAM_COLOR_1
  sta 1

  lda ObjectF1,x
  and #1
  sta 0
  pha
  stx TempVal
  ldx #0
  pla
  beq :+
    ldx #9
    lda #OAM_COLOR_1 + OAM_XFLIP
    sta 1
  :

  lda 1
  sta OAM_ATTR+(4*0),y
  sta OAM_ATTR+(4*1),y
  sta OAM_ATTR+(4*2),y
  sta OAM_ATTR+(4*3),y
  sta OAM_ATTR+(4*4),y
  sta OAM_ATTR+(4*5),y
  sta OAM_ATTR+(4*6),y
  sta OAM_ATTR+(4*7),y
  sta OAM_ATTR+(4*8),y

  lda Tiles1+0,x
  sta OAM_TILE+(4*0),y
  lda Tiles1+1,x
  sta OAM_TILE+(4*1),y
  lda Tiles1+2,x
  sta OAM_TILE+(4*2),y
  lda Tiles1+3,x
  sta OAM_TILE+(4*3),y
  lda Tiles1+4,x
  sta OAM_TILE+(4*4),y
  lda Tiles1+5,x
  sta OAM_TILE+(4*5),y
  lda Tiles1+6,x
  sta OAM_TILE+(4*6),y
  lda Tiles1+7,x
  sta OAM_TILE+(4*7),y
  lda Tiles1+8,x
  sta OAM_TILE+(4*8),y
  ldx TempVal

  lda ObjectPX,x
  sub ScrollX+1
  sta OAM_XPOS+(4*0),y
  sta OAM_XPOS+(4*3),y
  sta OAM_XPOS+(4*6),y
  add #8
  sta OAM_XPOS+(4*1),y
  sta OAM_XPOS+(4*4),y
  sta OAM_XPOS+(4*7),y
  add #8
  sta OAM_XPOS+(4*2),y
  sta OAM_XPOS+(4*5),y
  sta OAM_XPOS+(4*8),y
  tya
  add #36
  sta OamPtr
Exit:
  rts

Tiles1: .byt $70, $71, $72, $80, $81, $82, $90, $91, $92 
Tiles2: .byt $72, $71, $70, $82, $81, $80, $92, $91, $90

SideStartX: .byt 256-24, 0
SideStartX2: .byt 256-24-16, 24
.endproc

.proc BillBlockObject
  asl EnemyWidth
  lda ObjectTimer,x
  bne :+
    lda ObjectF1,x
    and #1
    tay
    lda ObjectPX,x
    add Dirs,y
    sta ObjectPX,x
  :
  jsr EnemyPlayerTouch
  jsr EnemyGetShot
  bcc :+
    lda ObjectF1,x
    bmi :+     ; only reverse position once
    eor #1+128 ; EOR will always set the most significant bit since it can't get here if set
    sta ObjectF1,x
  :

  lda ObjectPX,x
  cmp #16
  bcc Remove
  cmp #256-16
  bcs Remove

  jsr EnemyDecTimer
  ldy #$64
  lda #2
  jsr DispEnemyWide
  rts
Remove:
  lda #0
  sta ObjectF1,x
  rts
Dirs:
  .byt 4, -4
.endproc

.proc PoofObject
  ldy OamPtr
  lda ObjectPYH,x
  sta OAM_YPOS+(4*0),y
  sta OAM_YPOS+(4*1),y
  add #8
  sta OAM_YPOS+(4*2),y
  sta OAM_YPOS+(4*3),y
  lda #OAM_COLOR_1
  sta OAM_ATTR+(4*0),y
  lda #OAM_COLOR_1 + OAM_XFLIP
  sta OAM_ATTR+(4*1),y
  lda #OAM_COLOR_1 + OAM_YFLIP
  sta OAM_ATTR+(4*2),y
  lda #OAM_COLOR_1 + OAM_XFLIP + OAM_YFLIP
  sta OAM_ATTR+(4*3),y

  lda #12
  sub ObjectTimer,x
  lsr
  lsr
  add #$61
  sta OAM_TILE+(4*0),y
  sta OAM_TILE+(4*1),y
  sta OAM_TILE+(4*2),y
  sta OAM_TILE+(4*3),y

  lda ObjectPX,x
  sub ScrollX+1
  sta OAM_XPOS+(4*0),y
  sta OAM_XPOS+(4*2),y
  add #8
  sta OAM_XPOS+(4*1),y
  sta OAM_XPOS+(4*3),y
  tya
  add #16
  sta OamPtr

  dec ObjectTimer,x
  bne :+
    lda #0
    sta ObjectF1,x
: rts
.endproc

.proc WalkerEnemy
  lda #1
  sta DispEnemyBodyType
  lda #1
  sta DispEnemyWeapon

  jsr GetShot

  jsr EnemyFall

  lda ObjectF1,x
  beq Exit
  bcc DontMove
    lda ObjectF2,x
    bne DontMove

    lda #2
    jsr EnemyWalk
    jsr EnemyAutoBump

    jsr rand_8_safe
    and #%1111
    bne DontMove
      lda #1
      jsr EnemyShoot
DontMove:

  jsr EnemyPlayerTouch
  lda ObjectF1,x
  beq Exit

  jsr EnemyDecTimer
  jsr DispEnemy
Exit:
  rts
.endproc

.proc PotionEnemy
  asl EnemyWidth
  jsr GetShot

  jsr EnemyFallWide
  bcc DontMove
  lda ObjectF1,x
  beq Exit
    lda #1
    jsr EnemyWalk
    jsr EnemyAutoBump

    lda ObjectF2,x
    bne DontMove
    jsr rand_8_safe
    and #15
    bne DontMove
      jsr LaunchWaterBottle
DontMove:

  jsr EnemyPlayerTouch
  lda ObjectF1,x
  beq Exit

  jsr EnemyDecTimer

  lda retraces
  ldy #$b4
  lda #2
  jsr DispEnemyWide
Exit:
  rts
.endproc

.proc SpearsEnemy
  lda #1
  sta DispEnemyBodyType
  lda #10
  sta DispEnemyWeapon

  jsr GetShot

  jsr EnemyFall

  lda ObjectF1,x
  beq Exit
  bcc DontMove
    lda ObjectF2,x
    bne DontMove

    lda #3
    jsr EnemyWalk
    jsr EnemyAutoBump

    jsr rand_8_safe
    and #%1111
    bne DontMove

      lda ObjectF1,x
      pha
      and #~1
      sta ObjectF1,x
      lda #10
      jsr EnemyShoot
      pla
      sta ObjectF1,x
DontMove:

  jsr EnemyPlayerTouch
  lda ObjectF1,x
  beq Exit

  jsr EnemyDecTimer
  lda ObjectF1,x
  pha
  and #~1
  sta ObjectF1,x
  jsr DispEnemy
  pla
  sta ObjectF1,x
Exit:
  rts
.endproc


.proc TrigWalkerEnemy
  lda #1
  sta DispEnemyBodyType
  lda #6
  sta DispEnemyWeapon

  jsr GetShot
  jsr EnemyFall

  lda ObjectF1,x
  beq Exit
  bcc DontMove
    lda ObjectF2,x
    bne DontMove

    lda #2
    jsr EnemyWalk
    jsr EnemyAutoBump

    jsr rand_8_safe
    and #%1111
    bne DontMove
      lda #6
      ldy #-1
      jsr EnemyShootAtPlayer
DontMove:

  jsr EnemyPlayerTouch
  lda ObjectF1,x
  beq Exit

  jsr EnemyDecTimer
  jsr DispEnemy
Exit:
  rts
.endproc

.proc TrigBombShooterEnemy
  lda #1
  sta DispEnemyBodyType
  lda #12
  sta DispEnemyWeapon

  jsr GetShot
  jsr EnemyFall

  lda ObjectF1,x
  beq Exit
  bcc DontMove
    lda ObjectF2,x
    bne DontMove

    lda #2
    jsr EnemyWalk
    jsr EnemyAutoBump

    jsr rand_8_safe
    and #%1111
    bne DontMove
      lda retraces
      and #%1000000
      beq :+
        lda #1
    : tay
      lda PlayerEnabled,y
      beq DontMove
      lda #12
      jsr EnemyShootAtPlayer
DontMove:

  jsr EnemyPlayerTouch
  lda ObjectF1,x
  beq Exit

  jsr EnemyDecTimer
  jsr DispEnemy
Exit:
  rts
.endproc

.proc DropBomb
  txa
  tay
  lda #-1
  sta BombDroppedIndex ; error code for if the index is invalid due to no free slots
  jsr FindFreeObjectX
  php
  bcc Restore

  lda #OBJECT_BOMB*2
  sta ObjectF1,x

  lda ObjectPYH,y
  sta ObjectPYH,x
  lda #-1
  sta ObjectVYH,x
  lda #0
  sta ObjectPYL,x
  sta ObjectVYL,x
  sta ObjectTimer,x
  sta ObjectF3,x
  lda ObjectPX,y
  sta ObjectPX,x
  stx BombDroppedIndex
  inc ScreenEnemiesCount
Restore:
  tya
  tax
  plp
  rts
.endproc

.proc FlyBomberEnemy
  lda #6
  sta DispEnemyBodyType
  asl ;lda #12
  sta DispEnemyWeapon
  lda #14
  sta DispEnemyHead

  jsr EnemyFall
  lda ObjectF1,x
  jeq Exit

  lda ObjectVYH,x
  bmi :+
  cmp #2
  bcc :+
    jsr rand_8_safe
    and #7
    bne :+
    lda #-2
    sta ObjectVYH,x
    lda #80
    sta ObjectVYL,x
  :

  jsr GetShot

  lda ObjectF2,x
  bne DontMove
    lda #2
    jsr EnemyWalk
    jsr EnemyAutoBump

    lda retraces
    and #7
    bne DontMove
    jsr rand_8_safe
    and #%1111
    bne DontMove
      jsr DropBomb
DontMove:

  jsr EnemyPlayerTouch
  lda ObjectF1,x
  beq Exit

  jsr EnemyDecTimer
  jsr DispEnemy
Exit:
  rts
.endproc

.proc FlyDiagonalEnemy
  lda #6
  sta DispEnemyBodyType
  lda #GUN_DIAGONAL
  sta DispEnemyWeapon
  lda #3
  sta DispEnemyHead

  jsr EnemyFall
  lda ObjectF1,x
  jeq Exit

  lda ObjectVYH,x
  bmi :+
  cmp #2
  bcc :+
    jsr rand_8_safe
    and #7
    bne :+
    lda #-2
    sta ObjectVYH,x
    lda #80
    sta ObjectVYL,x
  :

  jsr GetShot

  lda ObjectF2,x
  bne DontMove
    lda #2
    jsr EnemyWalk
    jsr EnemyAutoBump

    lda retraces
    and #7
    bne DontMove
    jsr rand_8_safe
    and #%1111
    bne DontMove
      lda #GUN_DIAGONAL
      jsr EnemyShoot
DontMove:

  jsr EnemyPlayerTouch
  lda ObjectF1,x
  beq Exit

  jsr EnemyDecTimer
  jsr DispEnemy
Exit:
  rts
.endproc

.proc BombObject
  lda ObjectF3,x
  cmp #EXTOBJ_BILLBLOCK
  jeq BillBlockObject
  cmp #EXTOBJ_POOF
  jeq PoofObject
  cmp #EXTOBJ_HPLAT
  jcs MovingObject
  jeq PoofObject

  jsr EnemyFall
  bcc NoExplode

  lda ObjectPX,x
  sta 0
  lda ObjectPYH,x
  add #8
  sta 1
  lda #20
  jsr CreateExplosion
  jmp EnemyRemoveFromFalling
NoExplode:
  lda ObjectPYH,x
  cmp #255-16
  jcs EnemyRemoveFromFalling

  ldy OamPtr

  lda ObjectF3,x
  bne WaterBottle
  lda ObjectPYH,x
  add #7
  sta OAM_YPOS+(4*0),y
  lda #OAM_COLOR_1
  sta OAM_ATTR+(4*0),y
  lda #$3c
  sta OAM_TILE+(4*0),y
  lda ObjectPX,x
  sub ScrollX+1
  sta OAM_XPOS+(4*0),y

  tya
  add #4
  sta OamPtr
Exit:
  rts

WaterBottle:
  lda ObjectPYH,x
  sta OAM_YPOS+(4*0),y
  add #8
  sta OAM_YPOS+(4*1),y
  lda #OAM_COLOR_1
  sta OAM_ATTR+(4*0),y
  sta OAM_ATTR+(4*1),y
  lda #$75
  sta OAM_TILE+(4*0),y
  lda #$85
  sta OAM_TILE+(4*1),y
  lda ObjectVYH,x
  bmi :+
    lda #OAM_COLOR_1 + OAM_YFLIP
    sta OAM_ATTR+(4*0),y
    sta OAM_ATTR+(4*1),y
    lda #$85
    sta OAM_TILE+(4*0),y
    lda #$75
    sta OAM_TILE+(4*1),y
: lda ObjectPX,x
  sub ScrollX+1
  sta OAM_XPOS+(4*0),y
  sta OAM_XPOS+(4*1),y

  tya
  add #8
  sta OamPtr
  rts
.endproc

.proc DoMoveHorizOrVert
  cpy #1
  beq DoVert
  lda ObjectF1,x
  and #1
  tay
  lda ObjectPX,x
  add Move4Dir,y
  sta ObjectPX,x  
  add Offset4Dir,y
  lsr
  lsr
  lsr
  lsr
  sta 0
  lda ObjectPYH,x
  and #$f0
  ora 0
  tay
  lda LevelBuf,y
  cmp #FirstSolidTop
  bcc :+
  lda ObjectF1,x
  eor #1
  sta ObjectF1,x
: rts

DoVert:
  lda ObjectF1,x
  eor #1
  and #1
  tay
  lda ObjectPYH,x
  add Move4Dir,y
  sta ObjectPYH,x  
  and #$f0
  sta 0
  lda ObjectPX,x
  lsr
  lsr
  lsr
  lsr
  ora 0
  tay
  lda LevelBuf+1+16,y
  cmp #FirstSolidTop
  bcs :+
  lda LevelBuf-1+16,y
  cmp #FirstSolidTop
  bcs :+
  rts
: lda ObjectF1,x
  eor #1
  sta ObjectF1,x
  rts

Move4Dir:
  .byt 1,-1
Offset4Dir:
  .byt 15,0
.endproc

.proc PlayerOnMovingPlatform
  ldy #0
  jsr Try
  iny
  jsr Try
  rts
Try:
  lda PlayerEnabled,y
  beq No
  lda PlayerPX,y
  sta TouchLeftA
  lda PlayerPYH,y
  sta TouchTopA

  lda ObjectPX,x
  sta TouchLeftB
  lda ObjectPYH,x
  sta TouchTopB

  lda #16
  sta TouchWidthB
  sta TouchHeightA
  sta TouchHeightB
  lsr
  sta TouchWidthA

  jsr ChkTouchGeneric
  bcs Yes
No:
  rts
Yes:
  lda PlayerDead,y
  bne No
  lda PlayerVYH,y
  bmi No
  lda #-2
  sta PlayerVYH,y
  lda #0
  sta PlayerVYL,y
  lda #1
  sta PlayerJumpCancelLock,y

  lda ObjectPYH,x
  sub #16
  sta PlayerPYH,y

  inc 4 ;NeedSpringNoise
  rts
.endproc

.proc MovingObject
  IsVert = 0
  IsHurt = 1
  AddTile = 3
  NeedSpringNoise = 4
  sub #EXTOBJ_HPLAT
  pha
  and #1
  sta IsVert
  lda #0
  sta NeedSpringNoise
  pla
  lsr
  sta IsHurt
; --- move ---
  bne :+
    jsr PlayerOnMovingPlatform
  :

  ldy IsVert
  jsr DoMoveHorizOrVert
; --- draw ---  
  lda IsHurt
  beq :+
  ldy #$7c
  lda #0
  asl EnemyWidth
  jsr DispEnemyWide
  jmp EnemyPlayerTouch
:
  ldy OamPtr
  lda ObjectPYH,x
  sta OAM_YPOS+(4*0),y
  sta OAM_YPOS+(4*1),y
  add #8
  sta OAM_YPOS+(4*2),y
  sta OAM_YPOS+(4*3),y

  lda #OAM_COLOR_1
  sta OAM_ATTR+(4*0),y
  sta OAM_ATTR+(4*3),y
  lda #OAM_COLOR_1 | OAM_XFLIP
  sta OAM_ATTR+(4*1),y
  sta OAM_ATTR+(4*2),y

  lda ObjectPX,x
  sub ScrollX+1
  sta OAM_XPOS+(4*0),y
  sta OAM_XPOS+(4*3),y
  add #8
  sta OAM_XPOS+(4*1),y
  sta OAM_XPOS+(4*2),y

  lda retraces
  and #%10000
  add #$74
  sta OAM_TILE+(4*2),y
  sta OAM_TILE+(4*3),y
  lda #$73
  sta OAM_TILE+(4*0),y
  sta OAM_TILE+(4*1),y
  tya
  add #16
  sta OamPtr

  lda NeedSpringNoise
  beq :+
    lda #SOUND_SPRING
    jsr start_sound
: rts
.endproc

.proc JumpyEnemy
  lda #5
  sta DispEnemyBodyType
  lda #2
  sta DispEnemyWeapon

  jsr GetShot

  lda ObjectF2,x
  bne :+
    lda #2
    jsr EnemyWalk
    jsr EnemyAutoBump
  :

  jsr EnemyFall
  bcc DontMove
  lda ObjectF1,x
  beq Exit
    lda ObjectF2,x
    bne DontMove

    jsr rand_8_safe
    ora #%11111100
    sta ObjectVYH,x
    jsr rand_8_safe
    ora #%10000000
    sta ObjectVYL,x

    jsr rand_8_safe
    pha
    asl
    bcc :+
    lda ObjectF1,x
    eor #1
    sta ObjectF1,x
:
    pla
    and #11
    bne DontMove
      lda #2
      jsr EnemyShoot
DontMove:

  jsr EnemyPlayerTouch
  lda ObjectF1,x
  beq Exit

  jsr EnemyDecTimer

  jsr DispEnemy
Exit:
  rts
.endproc

.proc DiagShooterEnemy
  lda #0
  sta DispEnemyBodyType
  lda #GUN_DIAGONAL
  sta DispEnemyWeapon
  lda #3
  sta DispEnemyHead

  jsr GetShot

  jsr EnemyFall
  lda ObjectF1,x
  beq Exit
  bcc DontMove
    lda ObjectF2,x
    bne DontMove

    lda #1
    jsr EnemyWalk
    jsr EnemyAutoBump

    jsr rand_8_safe
    and #%1111
    bne DontMove
      lda #GUN_DIAGONAL
      jsr EnemyShoot
DontMove:

  jsr EnemyPlayerTouch
  lda ObjectF1,x
  beq Exit

  jsr EnemyDecTimer
  jsr DispEnemy
Exit:
  rts
.endproc

.proc WaitingShooterEnemy
  lda #0
  sta DispEnemyBodyType
  lda #GUN_DIAGONAL
  sta DispEnemyWeapon

  jsr GetShot

  jsr EnemyFall
  lda ObjectF1,x
  beq Exit
  bcc DontMove
  jsr rand_8_safe
  and #3
  bne :+
    lda ObjectF2,x
    bne DontMove

    lda #1
    jsr EnemyWalk
    jsr EnemyAutoBump

    jsr rand_8_safe
    and #%1111
    bne DontMove
      lda #GUN_DIAGONAL
      jsr EnemyShoot
      lda #2
      jsr EnemyShoot
      lda ObjectF1,x
      eor #1
      sta ObjectF1,x
DontMove:

  jsr EnemyPlayerTouch
  lda ObjectF1,x
  beq Exit

  jsr EnemyDecTimer
  jsr DispEnemy
Exit:
  rts
.endproc

.proc FloatVertShootEnemy
  lda #6
  sta DispEnemyBodyType
  lda #GUN_VERTICAL
  sta DispEnemyWeapon
  lda #5
  sta DispEnemyHead

  jsr GetShot

  lda ObjectPYH,x
  add #16
  sta ObjectPYH,x
  jsr EnemyFall
  bcc :+
    jsr rand_8_safe
    ora #%11111100
    sta ObjectVYH,x
    jsr rand_8_safe
    ora #%10000000
    sta ObjectVYL,x
  :
  lda ObjectPYH,x
  sub #16
  sta ObjectPYH,x

  lda ObjectF1,x
  beq Exit
  bcc DontMove
    lda ObjectF2,x
    bne DontMove

    lda #2
    jsr EnemyWalk
    jsr EnemyAutoBump

    jsr rand_8_safe
    and #%1111
    bne DontMove
      lda #GUN_VERTICAL
      jsr EnemyShoot
DontMove:

  jsr EnemyPlayerTouch
  lda ObjectF1,x
  beq Exit

  jsr EnemyDecTimer

  jsr DispEnemy
Exit:
  rts
.endproc

.proc GoombaEnemy
  asl EnemyWidth

  jsr GetShot

  jsr EnemyFallWide
;  bcc DontMove
  lda ObjectF1,x
  beq Exit
    lda ObjectF2,x
    bne DontMove

    lda #1
    jsr EnemyWalk
    jsr EnemyAutoBump
DontMove:

  jsr EnemyPlayerTouch
  lda ObjectF1,x
  beq Exit

  jsr EnemyDecTimer

  lda retraces
  lsr
  lsr
  lsr
  and #3
  tay
  lda EnemyFrames,y
  tay
  lda #0
  jsr DispEnemyWide
Exit:
  rts
EnemyFrames:
  .byt $a0, $a4, $a8, $a4
.endproc

.proc ThwompEnemy
  State = 10
  asl EnemyWidth
  jsr GetShot

  lda ObjectF2,x ; cancel smashing
  sta State
  cmp #ENEMY_STATE_ACTIVE
  bne :+
    lda ObjectPYH,x
    cmp #-24
    bcc :+
      lda #0
      sta ObjectF2,x
  :

  lda ObjectF1,x
  jeq Exit
    and #%111110
    cmp #OBJECT_THWOMP_MOVE*2
    bne DontMoveStatic
      lda ObjectF2,x
      bne DontMove
        lda #1
        jsr EnemyWalk
        jmp DontMove
  DontMoveStatic:
    lda ObjectPX,x
    cmp #24
    bcs :+
      inc ObjectPX,x
    :
    lda ObjectPX,x
    cmp #-24
    bcc :+
      dec ObjectPX,x
    :
DontMove:

  lda State
  cmp #ENEMY_STATE_STUNNED
  beq :+
    jsr EnemyFallGravityOnly
    jmp :++
: jsr EnemyFallWide
:

  lda State
  bne :+ ; smashing and vulnerable modes don't retain a constant height
  lda ObjectPYH,x
  cmp #32
  bcc :+
    lda #-2
    sta ObjectVYH,x
    lda #0
    sta ObjectVYL,x
  :

  lda ObjectF2,x ; if not hovering, don't check if it should fall
  bne NotHovering

  lda ObjectPX,x
  add #4
  lsr
  lsr
  lsr
  lsr
  sta 0
  ldy #0
TryNear:
  lda PlayerPX,y
  lsr
  lsr
  lsr
  lsr
  cmp 0
  beq NeedToFall
  iny
  cpy #2
  bne TryNear
  beq NotHovering
NeedToFall:
  lda #ENEMY_STATE_ACTIVE
  sta ObjectF2,x
NotHovering:

  jsr EnemyPlayerTouch
  lda ObjectF1,x
  beq Exit

  lda ObjectF2,x
  cmp #ENEMY_STATE_ACTIVE
  beq :+
  jsr EnemyDecTimer
:

  ldy #$cc
  lda #2
  jsr DispEnemyWide
Exit:
  rts
.endproc

.proc RollBallEnemy
  asl EnemyWidth
  jsr GetShot
  jsr EnemyFallWide
  bcc DontMove
  lda ObjectF1,x
  beq Exit
    lda ObjectF2,x
    bne DontMove

    lda #4
    jsr EnemyWalk
    jsr EnemyAutoBump
DontMove:

  jsr EnemyPlayerTouch
  lda ObjectF1,x
  beq Exit

  jsr EnemyDecTimer

  ldy #$b8
  lda #2
  jsr DispEnemyWide
Exit:
  rts
.endproc

.proc JumpBallEnemy
  asl EnemyWidth
  jsr GetShot

  lda ObjectF2,x
  bne :+
    lda #2
    jsr EnemyWalk
    jsr EnemyAutoBump
  :

  jsr EnemyFallWide
  bcc DontMove

  lda ObjectF1,x
  beq Exit
    lda ObjectF2,x
    bne DontMove

    jsr rand_8_safe
    ora #%11111000
    sta ObjectVYH,x
    jsr rand_8_safe
    ora #%10000000
    sta ObjectVYL,x

    jsr rand_8_safe
    pha
    asl
    bcc :+
    lda ObjectF1,x
    eor #1
    sta ObjectF1,x
:
    pla
    and #11
    bne DontMove
      lda #2
      jsr EnemyShoot
DontMove:

  jsr EnemyPlayerTouch
  lda ObjectF1,x
  beq Exit

  jsr EnemyDecTimer

  ldy #$bc
  lda #2
  jsr DispEnemyWide
Exit:
  rts
.endproc

.proc SneakerEnemy
  asl EnemyWidth
  jsr GetShot
  jsr EnemyFallWide
;  bcc DontMove

  lda ObjectF1,x
  beq Exit
    lda ObjectF2,x
    bne DontMove

    lda #4
    jsr EnemyWalk
    jsr EnemyAutoBump
DontMove:

  ; run away from bullets
  lda ObjectPYH,x
  add #8
  lsr
  lsr
  and #%111000
  sta TempVal
  lda ObjectPX,x
  add #12
  lsr ; / 32 pixels
  lsr
  lsr
  lsr
  lsr
  ora TempVal
  tay
  and #15
  pha
  beq LeftEdge
  lda BulletMap-1,y
  beq LeftEdge
  lda ObjectF1,x
  and #~1
  sta ObjectF1,x
LeftEdge:
  pla
  cmp #15
  beq RightEdge
  lda BulletMap+1,y
  beq RightEdge
  lda ObjectF1,x
  ora #1
  sta ObjectF1,x
RightEdge:

  jsr EnemyPlayerTouch
  lda ObjectF1,x
  beq Exit

  jsr EnemyDecTimer


  lda retraces
  lsr
  and #4
  add #$68
  tay
  lda #0
  jsr DispEnemyWide
Exit:
  rts
.endproc

.proc GeorgeEnemy
  asl EnemyWidth

  jsr GetShot

  jsr EnemyFallWide
  bcc DontMove
  lda ObjectF1,x
  beq Exit
    lda ObjectF2,x
    bne DontMove

    lda #2
    jsr EnemyWalk
    jsr EnemyAutoBump

    lda retraces
    and #63
    bne DontMove
    jsr rand_8_safe
    and #1
    bne DontMove
    lda #ENEMY_STATE_PAUSE
    sta ObjectF2,x
    lda #10
    sta ObjectTimer,x
    jsr LaunchWaterBottle    
DontMove:

  jsr EnemyPlayerTouch
  lda ObjectF1,x
  beq Exit

  jsr EnemyDecTimer

  ldy #$78
  lda #0
  jsr DispEnemyWide
Exit:
  rts
.endproc

LaunchWaterBottle:
  txa
  tay
  jsr FindFreeObjectX
  php
  bcc @Restore

  lda #OBJECT_BOMB*2
  sta ObjectF1,x

  lda #EXTOBJ_WATER
  sta ObjectF3,x
  lda ObjectPYH,y
  sta ObjectPYH,x
  lda #-4
  sta ObjectVYH,x
  lda #0
  sta ObjectPYL,x
  sta ObjectVYL,x
  sta ObjectTimer,x
  lda ObjectPX,y
  sta ObjectPX,x

  inc ScreenEnemiesCount
@Restore:
  tya
  tax
  plp
  rts

.proc RetardEnemy
  asl EnemyWidth

  jsr GetShot

  lda ObjectF2,x
  bne :+
    lda retraces
    and #63
    bne :+
    jsr rand_8_safe
    and #1
    bne :+
    lda #-2
    sta ObjectVYH,x
  :

  jsr EnemyFallWide
  bcc DontMove
  lda ObjectF1,x
  beq Exit
    lda ObjectF2,x
    bne DontMove

    lda #2
    jsr EnemyWalk
    jsr EnemyAutoBump
DontMove:

  jsr EnemyPlayerTouch
  lda ObjectF1,x
  beq Exit

  jsr EnemyDecTimer

  lda retraces
  lsr
  and #4
  add #$ac
  tay
  lda #0
  jsr DispEnemyWide
Exit:
  rts
.endproc

.proc FlappyEnemy
  asl EnemyWidth

  jsr GetShot

  jsr EnemyFallWide
  bcc :+
    lda ObjectF2,x
    bne DontMove
    lda #-5
    sta ObjectVYH,x
    lda #0
    sta ObjectVYL,x
    bne DontMove
  :
  lda ObjectF1,x
  beq Exit
    lda ObjectF2,x
    bne DontMove

    lda #2
    jsr EnemyWalk
    bcc DontMove
      lda #-4
      sta ObjectVYH,x
      lda #0
      sta ObjectVYL,x

      lda #GUN_VERTICAL
      jsr EnemyShoot
      sec
      jsr EnemyAutoBump
DontMove:

  lda ObjectVYH,x
  bmi :+
  cmp #2
  bcc :+
    lda ObjectF2,x
    bne :+
    jsr rand_8_safe
    and #7
    bne :+
    lda #-2
    sta ObjectVYH,x
    lda #80
    sta ObjectVYL,x
  :

  jsr EnemyPlayerTouch
  lda ObjectF1,x
  beq Exit

  jsr EnemyDecTimer

  lda retraces
  lsr
  and #4
  add #$ac
  tay
  lda #0
  jsr DispEnemyWide
Exit:
  rts
.endproc

.proc ToastbotEnemy
  asl EnemyWidth

  jsr GetShot

  jsr EnemyFallWide
  bcc DontMove
  lda ObjectF1,x
  beq Exit
    lda ObjectF2,x
    bne DontMove

    lda #1
    jsr EnemyWalk
    jsr EnemyAutoBump
DontMove:

  jsr EnemyPlayerTouch
  lda ObjectF1,x
  beq Exit

  jsr EnemyDecTimer

  ldy #$88
  lda retraces
  and #%1000
  beq :+
  ldy #$8c
: lda #0
  jsr DispEnemyWide
Exit:
  rts
.endproc

.proc EnemyLookAtPlayer
  ; check for the cases of both or no players being active
  lda PlayerEnabled+0
  add PlayerEnabled+1
  beq Exit
  cmp #2
  beq TwoPlayers

  ; if only one player, select the right one
  ldy #0
  lda PlayerEnabled,y
  bne OnePlayer
  inx
  lda PlayerEnabled,y
  bne OnePlayer
  rts
OnePlayer:
  lsr ObjectF1,x
  lda ObjectPX,x
  cmp PlayerPX,x
  rol ObjectF1,x
  rts
TwoPlayers:
Exit:
  rts
.endproc

.proc GetShot
  lda ObjectF2,x
  cmp #ENEMY_STATE_STUNNED
  beq :+
    jsr EnemyGetShot
    bcc :+
      jsr EnemyHurt
  :
  rts
.endproc

.proc BurgerEnemy
  asl EnemyWidth
  lda ObjectF1,x
  alr #%111110
  sub #OBJECT_BURGER1
  sta 8

  jsr GetShot

  lda retraces
  and #%100000
  bne :+
    jsr rand_8_safe
    sta ObjectF3,x
  :

  lda 8
  cmp #1
  bne :+
    lda ObjectF2,x
    bne :+
    jsr rand_8_safe
    and #%1111
    bne :+
    lda ObjectPX,x
    pha
    add #4
    sta ObjectPX,x
    lda #GUN_VERTICAL
    jsr EnemyShoot
    pla
    sta ObjectPX,x
  :

  jsr EnemyFallGravityOnly

  lda ObjectPYH,x
  cmp ObjectF3,x
  bcc :+
    lda #-1
    sta ObjectVYH,x
  :

  jsr EnemyDecTimer

  lda ObjectF1,x
  beq Exit
    lda ObjectF2,x
    bne DontMove

    lda #2
    ldy 8
    cpy #2
    bne :+
      asl
  : jsr EnemyWalk
    jsr EnemyAutoBump
DontMove:

  jsr EnemyPlayerTouch
  lda ObjectF1,x
  beq Exit

  jsr EnemyDecTimer

  lda 8
  asl
  asl
  add #$94
  tay
  lda #0
  jsr DispEnemyWide
Exit:
  rts
.endproc

.proc FlickerEnemies
  jsr rand_8
  and #7
  tax
  jsr rand_8_safe
  and #7
  tay
  lda ObjectPX,x
  sta 0
  lda ObjectPYH,x
  sta 1
  lda ObjectPYL,x
  sta 2
  lda ObjectVYH,x
  sta 3
  lda ObjectVYL,x
  sta 4
  lda ObjectF1,x
  sta 5
  lda ObjectF2,x
  sta 6
  lda ObjectF3,x
  sta 7
  lda ObjectTimer,x
  sta 8

  lda ObjectPX,y
  sta ObjectPX,x
  lda ObjectPYH,y
  sta ObjectPYH,x
  lda ObjectPYL,y
  sta ObjectPYL,x
  lda ObjectVYH,y
  sta ObjectVYH,x
  lda ObjectVYL,y
  sta ObjectVYL,x
  lda ObjectF1,y
  sta ObjectF1,x
  lda ObjectF2,y
  sta ObjectF2,x
  lda ObjectF3,y
  sta ObjectF3,x
  lda ObjectTimer,y
  sta ObjectTimer,x

  lda 0
  sta ObjectPX,y
  lda 1
  sta ObjectPYH,y
  lda 2
  sta ObjectPYL,y
  lda 3
  sta ObjectVYH,y
  lda 4
  sta ObjectVYL,y
  lda 5
  sta ObjectF1,y
  lda 6
  sta ObjectF2,y
  lda 7
  sta ObjectF3,y
  lda 8
  sta ObjectTimer,y
  rts
.endproc
