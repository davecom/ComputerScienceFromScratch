;
; ppppppmm - win condition, parameter
; ffffdeee - level effect, enemy distribution, max enemy number
; pppeeeee - enemy type 1
; pppeeeee - enemy type 2
; pppeeeee - enemy type 3
; pppeeeee - enemy type 4
; aaaaaaaa - map address low
; aaaaaaaa - map address high

WINMODE_REGULAR    = 0
WINMODE_GET_COINS  = 1
WINMODE_SURVIVAL   = 2
WINMODE_HOTELMARIO = 3
EPARAM_0           = 0 << 5
EPARAM_1           = 1 << 5
EPARAM_2           = 2 << 5
EPARAM_3           = 3 << 5
EPARAM_4           = 4 << 5
EPARAM_5           = 5 << 5
EPARAM_6           = 6 << 5
EPARAM_7           = 7 << 5

EFFECT_NONE = $00
EFFECT_SCROLL1 = $10 ; scrolling right, slow
EFFECT_SCROLL2 = $20 ; scrolling right, medium
EFFECT_SCROLL3 = $30 ; scrolling right, fast
EFFECT_NOCYCLE = $40 ; no level cycling


; 1 2 3 - pack 1
; 4 5 6 - pack 2
; 7 8   - challenge

.proc LevelParamTable
;  .byt WINMODE_REGULAR +(5-1)*4,   DIST_EQUAL4 +(3-1), OBJECT_WAITSHOOT, OBJECT_WAITSHOOT, OBJECT_WAITSHOOT, OBJECT_WAITSHOOT, 0, 0
; world 1 - pack 1
  .byt WINMODE_REGULAR +(5-1)*4,   EFFECT_NOCYCLE|DIST_EQUAL4 +(3-1), OBJECT_WALKER, OBJECT_WALKER, OBJECT_WALKER, OBJECT_WALKER,   0, 0
  .byt WINMODE_REGULAR +(8-1)*4,   DIST_EQUAL4 +(2-1), OBJECT_WALKER, OBJECT_WALKER, OBJECT_JUMPY, OBJECT_JUMPY,     0, 0
  .byt WINMODE_REGULAR +(10-1)*4,  DIST_EQUAL4 +(3-1), OBJECT_WALKER, OBJECT_WALKER, OBJECT_JUMPY, OBJECT_DIAGSHOOT, 0, 0
  .byt WINMODE_SURVIVAL+(15-1)*4,  DIST_EQUAL4 +(4-1), OBJECT_WALKER, OBJECT_JUMPY,  OBJECT_JUMPY, OBJECT_DIAGSHOOT, 0, 0
; world 2
  .byt WINMODE_GET_COINS +(8-1)*4, DIST_EQUAL4 +(3-1), OBJECT_JUMPY, OBJECT_JUMPY, OBJECT_WALKER, OBJECT_WALKER, <LevelSimple1, >LevelSimple1
  .byt WINMODE_REGULAR +(7-1)*4,   DIST_EQUAL4 +(3-1), OBJECT_FLYBOMBER, OBJECT_FLYBOMBER, OBJECT_JUMPY, OBJECT_JUMPY, 0, 0
  .byt WINMODE_GET_COINS +(8-1)*4, DIST_EQUAL4 +(3-1), OBJECT_FLOATVERTSHOOT, OBJECT_FLOATVERTSHOOT, OBJECT_DIAGSHOOT, OBJECT_WALKER, 0, 0
  .byt WINMODE_REGULAR +(10-1)*4,  DIST_EQUAL4 +(7-1), OBJECT_BOMB, OBJECT_WALKER, OBJECT_WALKER, OBJECT_WALKER, <LevelBowl, >LevelBowl
; world 3
  .byt WINMODE_REGULAR +(10-1)*4,  DIST_EQUAL4 +(4-1), OBJECT_FLOATVERTSHOOT, OBJECT_FLOATVERTSHOOT, OBJECT_DIAGSHOOT, OBJECT_DIAGSHOOT, <LevelSimple2, >LevelSimple2
  .byt WINMODE_GET_COINS +(6-1)*4, DIST_EQUAL4 +(5-1), OBJECT_GOOMBA, OBJECT_JUMPY, OBJECT_JUMPY, OBJECT_JUMPY, <LevelManyPlatforms1, >LevelManyPlatforms1
  .byt WINMODE_REGULAR +(5-1)*4,   DIST_EQUAL4 +(5-1), OBJECT_WALKER, OBJECT_BOMB, OBJECT_BOMB, OBJECT_BOMB, <LevelBowl, >LevelBowl
  .byt WINMODE_REGULAR +(8-1)*4,  DIST_EQUAL4 +(2-1), OBJECT_FLOATVERTSHOOT, OBJECT_FLOATVERTSHOOT, OBJECT_DIAGSHOOT, OBJECT_FLYBOMBER, <LevelStairs1, >LevelStairs1
; world 4 - pack 2
  .byt WINMODE_HOTELMARIO,   DIST_EQUAL4 +(3-1), OBJECT_DIAGSHOOT, OBJECT_DIAGSHOOT, OBJECT_JUMPY, OBJECT_JUMPY, <LevelMoney1, >LevelMoney1
  .byt WINMODE_REGULAR +(10-1)*4,   DIST_SPLIT53 +(3-1), OBJECT_GOOMBA, OBJECT_GOOMBA, OBJECT_SNEAKER, OBJECT_SNEAKER, <LevelSShape, >LevelSShape
  .byt WINMODE_REGULAR +(10-1)*4,   DIST_EQUAL4 +(3-1), OBJECT_BURGER1, OBJECT_FLYDIAG, OBJECT_RETARD, OBJECT_WALKER, 0, 0
  .byt WINMODE_GET_COINS +(7-1)*4,   DIST_EQUAL4 +(3-1), OBJECT_SNEAKER, OBJECT_JUMPY, OBJECT_SNEAKER, OBJECT_WALKER, <LevelStairs1, >LevelStairs1
; world 5
  .byt WINMODE_REGULAR +(7-1)*4,   DIST_EQUAL4 +(6-1), OBJECT_JUMPY, OBJECT_JUMPY, OBJECT_JUMPY, OBJECT_JUMPY, <LevelNarrow1, >LevelNarrow1
  .byt WINMODE_REGULAR +(10-1)*4,  DIST_EQUAL4 +(3-1), OBJECT_GOOMBA, OBJECT_GOOMBA, OBJECT_SNEAKER, OBJECT_SNEAKER, <LevelNarrow1, >LevelNarrow1 
  .byt WINMODE_GET_COINS +(5-1)*4, DIST_EQUAL4 +(3-1), OBJECT_BURGER2, OBJECT_BURGER2, OBJECT_FLOATVERTSHOOT, OBJECT_FLOATVERTSHOOT, 0, 0
  .byt WINMODE_HOTELMARIO,         DIST_EQUAL4 +(3-1), OBJECT_BURGER1, OBJECT_BURGER1, OBJECT_BURGER2, OBJECT_BURGER2, <LevelMoney1, >LevelMoney1
; world 6
  .byt WINMODE_REGULAR +(10-1)*4,   DIST_EQUAL4 +(5-1), OBJECT_GEORGE, OBJECT_GEORGE, OBJECT_GEORGE, OBJECT_GEORGE, 0, 0
  .byt WINMODE_REGULAR +(9-1)*4,   DIST_EQUAL4 +(5-1), OBJECT_DIAGSHOOT, OBJECT_RETARD, OBJECT_DIAGSHOOT, OBJECT_GOOMBA, <LevelManyPlatforms2, >LevelManyPlatforms2
  .byt WINMODE_REGULAR +(9-1)*4,   DIST_EQUAL4 +(8-1), OBJECT_WALKER, OBJECT_WALKER, OBJECT_WALKER, OBJECT_WALKER, <LevelNarrow1, >LevelNarrow1
  .byt WINMODE_GET_COINS +(6-1)*4,   DIST_EQUAL4 +(3-1), OBJECT_TOASTBOT, OBJECT_TOASTBOT, OBJECT_DIAGSHOOT, OBJECT_BURGER1, 0, 0
; world 7 - challenge levels
  .byt WINMODE_GET_COINS +(7-1)*4,   DIST_EQUAL4 +(5-1), OBJECT_SNEAKER, OBJECT_SNEAKER, OBJECT_SNEAKER, OBJECT_SNEAKER, <LevelDollarSign, >LevelDollarSign
  .byt WINMODE_REGULAR +(5-1)*4,   DIST_EQUAL4 +(5-1), OBJECT_RETARD, OBJECT_RETARD, OBJECT_TOASTBOT, OBJECT_GEORGE, <LevelTriangle, >LevelTriangle
  .byt WINMODE_REGULAR +(8-1)*4,   DIST_EQUAL4 +(3-1), OBJECT_GEORGE, OBJECT_GEORGE, OBJECT_FLYBOMBER, OBJECT_FLYBOMBER, <LevelSimple1, >LevelSimple1
  .byt WINMODE_REGULAR +(18-1)*4,  DIST_EQUAL4 +(6-1), OBJECT_SNEAKER, OBJECT_SNEAKER, OBJECT_SNEAKER, OBJECT_SNEAKER, <LevelSShape, >LevelSShape
; world 8
  .byt WINMODE_HOTELMARIO,   DIST_EQUAL4 +(5-1), OBJECT_RETARD, OBJECT_RETARD, OBJECT_WAITSHOOT, OBJECT_WAITSHOOT, <LevelTriangle, >LevelTriangle
  .byt WINMODE_REGULAR +(12-1)*4,  DIST_EQUAL4 +(8-1), OBJECT_RETARD, OBJECT_RETARD, OBJECT_RETARD, OBJECT_RETARD, <LevelTriangle, >LevelTriangle
  .byt WINMODE_GET_COINS +(5-1)*4, DIST_EQUAL4 +(8-1), OBJECT_SNEAKER, OBJECT_SNEAKER, OBJECT_SNEAKER, OBJECT_SNEAKER, <LevelStairs1, >LevelStairs1
  .byt WINMODE_REGULAR +(1-1)*4,   DIST_EQUAL4 +(1-1), OBJECT_BILL_HEAD, OBJECT_BILL_HEAD, OBJECT_BILL_HEAD, OBJECT_BILL_HEAD, <LevelFinal, >LevelFinal

; world 9 - bonus levels
  .byt WINMODE_REGULAR +(5-1)*4,   DIST_SPLIT53 +(3-1), OBJECT_TRIGWALK, OBJECT_TRIGWALK, OBJECT_WALKER, OBJECT_WALKER,   0, 0
  .byt WINMODE_REGULAR +(7-1)*4,   DIST_SPLIT53 +(3-1), OBJECT_ROLL_BALL, OBJECT_ROLL_BALL, OBJECT_GOOMBA, OBJECT_GOOMBA,   0, 0
  .byt WINMODE_REGULAR +(5-1)*4,   DIST_EQUAL4 +(3-1), OBJECT_TRIGWALK, OBJECT_TRIGWALK, OBJECT_TRIGWALK, OBJECT_TRIGWALK,   <LevelZJ, >LevelZJ
  .byt WINMODE_GET_COINS +(5-1)*4, DIST_EQUAL4 +(3-1), OBJECT_WALKER, OBJECT_WALKER, OBJECT_JUMPY, OBJECT_JUMPY,   <LevelExplode, >LevelExplode
; world 10
  .byt WINMODE_REGULAR +(9-1)*4,   DIST_EQUAL4 +(3-1), OBJECT_RETARD, OBJECT_RETARD, OBJECT_WALKER, OBJECT_WALKER,   <LevelFlipMirror, >LevelFlipMirror
  .byt WINMODE_REGULAR +(11-1)*4,  DIST_EQUAL4 +(5-1), OBJECT_THWOMP_STATIC, OBJECT_THWOMP_STATIC, OBJECT_THWOMP_STATIC, OBJECT_THWOMP_STATIC,   0, 0
  .byt WINMODE_GET_COINS +(7-1)*4, DIST_EQUAL4 +(6-1), OBJECT_FLYDIAG, OBJECT_FLYDIAG, OBJECT_DIAGSHOOT, OBJECT_DIAGSHOOT,   <LevelX, >LevelX
  .byt WINMODE_REGULAR +(7-1)*4,   DIST_EQUAL4 +(4-1), OBJECT_GEORGE, OBJECT_GEORGE, OBJECT_TOASTBOT, OBJECT_TOASTBOT,   <LevelTPSpikes, >LevelTPSpikes
; world 11
  .byt WINMODE_REGULAR +(10-1)*4,   DIST_EQUAL4 + EFFECT_SCROLL1 +(3-1), OBJECT_TRIGBOMB, OBJECT_TRIGBOMB, OBJECT_DIAGSHOOT, OBJECT_DIAGSHOOT,   <LevelScrolling1, >LevelScrolling1
  .byt WINMODE_GET_COINS +(7-1)*4,  DIST_EQUAL4 + EFFECT_SCROLL1 +(3-1), OBJECT_BOUNCE_BALL, OBJECT_BOUNCE_BALL, OBJECT_JUMPY, OBJECT_JUMPY,   <LevelSimple1, >LevelSimple1
  .byt WINMODE_HOTELMARIO, DIST_EQUAL4 + EFFECT_SCROLL2 +(3-1), OBJECT_SPEARS, OBJECT_SPEARS, OBJECT_SPEARS, OBJECT_SPEARS,   <LevelMoney1, >LevelMoney1
  .byt WINMODE_HOTELMARIO, DIST_EQUAL4 +(6-1), OBJECT_ROLL_BALL, OBJECT_ROLL_BALL, OBJECT_ROLL_BALL, OBJECT_ROLL_BALL,   <LevelTriangle, >LevelTriangle
; world 12
  .byt WINMODE_REGULAR +(7-1)*4,   DIST_EQUAL4 +(5-1), OBJECT_BOUNCE_BALL, OBJECT_BOUNCE_BALL, OBJECT_THWOMP_MOVE, OBJECT_THWOMP_MOVE,   <LevelSimple3, >LevelSimple3
  .byt WINMODE_REGULAR +(5-1)*4,   DIST_EQUAL4 + EFFECT_SCROLL1 +(5-1), OBJECT_FLAPPY, OBJECT_FLAPPY, OBJECT_BURGER2, OBJECT_BURGER2,   <LevelScrolling2, >LevelScrolling2
  .byt WINMODE_REGULAR +(10-1)*4,  DIST_EQUAL4 +(6-1), OBJECT_BOUNCE_BALL, OBJECT_BOUNCE_BALL, OBJECT_BOUNCE_BALL, OBJECT_BOUNCE_BALL,   <LevelX, >LevelX
  .byt WINMODE_REGULAR +(7-1)*4,   DIST_EQUAL4 +(6-1), OBJECT_TRIGBOMB, OBJECT_TRIGBOMB, OBJECT_TRIGBOMB, OBJECT_TRIGBOMB,   <LevelStairs1, >LevelStairs1
; world 13
  .byt WINMODE_GET_COINS +(6-1)*4,   DIST_EQUAL4 +(5-1), OBJECT_TRIGBOMB, OBJECT_TRIGBOMB, OBJECT_FLYBOMBER, OBJECT_FLYBOMBER,   <LevelTPIslands, >LevelTPIslands
  .byt WINMODE_REGULAR +(7-1)*4,   DIST_EQUAL4 +(3-1), OBJECT_FLAPPY, OBJECT_FLAPPY, OBJECT_FLAPPY, OBJECT_FLAPPY,   <LevelScrolling2, >LevelScrolling2
  .byt WINMODE_REGULAR +(12-1)*4,  DIST_EQUAL4 +(3-1), OBJECT_GEORGE, OBJECT_GEORGE, OBJECT_POTION, OBJECT_POTION,   <LevelSpringsCycle, >LevelSpringsCycle
.if 0
  .byt WINMODE_REGULAR +(5-1)*4,   DIST_EQUAL4 +(3-1), OBJECT_WALKER, OBJECT_WALKER, OBJECT_WALKER, OBJECT_WALKER,   0, 0
; world 14
  .byt WINMODE_REGULAR +(5-1)*4,   DIST_EQUAL4 +(3-1), OBJECT_WALKER, OBJECT_WALKER, OBJECT_WALKER, OBJECT_WALKER,   0, 0
  .byt WINMODE_REGULAR +(5-1)*4,   DIST_EQUAL4 +(3-1), OBJECT_WALKER, OBJECT_WALKER, OBJECT_WALKER, OBJECT_WALKER,   0, 0
  .byt WINMODE_REGULAR +(5-1)*4,   DIST_EQUAL4 +(3-1), OBJECT_WALKER, OBJECT_WALKER, OBJECT_WALKER, OBJECT_WALKER,   0, 0
  .byt WINMODE_REGULAR +(5-1)*4,   DIST_EQUAL4 +(3-1), OBJECT_WALKER, OBJECT_WALKER, OBJECT_WALKER, OBJECT_WALKER,   0, 0
; world 15
  .byt WINMODE_REGULAR +(5-1)*4,   DIST_EQUAL4 +(3-1), OBJECT_WALKER, OBJECT_WALKER, OBJECT_WALKER, OBJECT_WALKER,   0, 0
  .byt WINMODE_REGULAR +(5-1)*4,   DIST_EQUAL4 +(3-1), OBJECT_WALKER, OBJECT_WALKER, OBJECT_WALKER, OBJECT_WALKER,   0, 0
  .byt WINMODE_REGULAR +(5-1)*4,   DIST_EQUAL4 +(3-1), OBJECT_WALKER, OBJECT_WALKER, OBJECT_WALKER, OBJECT_WALKER,   0, 0
  .byt WINMODE_REGULAR +(5-1)*4,   DIST_EQUAL4 +(3-1), OBJECT_WALKER, OBJECT_WALKER, OBJECT_WALKER, OBJECT_WALKER,   0, 0
; world 16
  .byt WINMODE_REGULAR +(5-1)*4,   DIST_EQUAL4 +(3-1), OBJECT_WALKER, OBJECT_WALKER, OBJECT_WALKER, OBJECT_WALKER,   0, 0
  .byt WINMODE_REGULAR +(5-1)*4,   DIST_EQUAL4 +(3-1), OBJECT_WALKER, OBJECT_WALKER, OBJECT_WALKER, OBJECT_WALKER,   0, 0
  .byt WINMODE_REGULAR +(5-1)*4,   DIST_EQUAL4 +(3-1), OBJECT_WALKER, OBJECT_WALKER, OBJECT_WALKER, OBJECT_WALKER,   0, 0
.endif
  .byt WINMODE_REGULAR +(2-1)*4,   DIST_EQUAL4 + EFFECT_SCROLL2 + (2-1), OBJECT_BILL_HEAD, OBJECT_BILL_HEAD, OBJECT_BILL_HEAD, OBJECT_BILL_HEAD, <LevelFinal, >LevelFinal
.endproc

.proc LoadLevelParams ; A = level to load
  ldy LevelEditMode
  bne EditMode

  pha
  lda #0
  sta 1
  pla
  asl ; don't need a ROL after every single ASL due to range of level numbers
  asl ; 1 increases support to 64 levels, 2 to 128 etc, but we only need 64 currently
  asl
  rol 1
  add #<LevelParamTable
  sta 0

  lda 1
  adc #>LevelParamTable
  sta 1

  ldy #0
: lda (0),y
  sta LevelConfigBytes,y
  iny
  cpy #8
  bne :-

EditMode:
; goal type and goal param are stored in the same byte
  lda LevelConfigBytes
  pha
  lsr
  lsr
  sta LevelGoalParam
  inc LevelGoalParam

  lda IsScoreMode ; make the level longer if it's versus score
  beq :+
  lda LevelGoalParam
  asl
  add LevelGoalParam
  sta LevelGoalParam
:

  pla
  and #3
  sta LevelGoalType

; fetch the four different types of enemies
  lda LevelConfigBytes+2
  sta 0
  lda LevelConfigBytes+3
  sta 1
  lda LevelConfigBytes+4
  sta 2
  lda LevelConfigBytes+5
  sta 3

; get max enemies per screen, then fill out the big 16 entry table based on the distribution flag
  lda LevelConfigBytes+1
  pha
  and #7
  sta MaxScreenEnemies
  inc MaxScreenEnemies
  pla     ; the distribution defaults to 4/16 chance for all enemies
  ldx #0  ; but if the flag for it is set, the chance is changed to 5/16 for the first two
  ldy #0  ; and 3/16 for the last two
  and #DIST_SPLIT53
  tax

: lda EnemyDistributionTable,x
  sty 4
  tay
  lda 0, y ; look up from list of enemies for this level
  ldy 4
  sta LevelEnemyPool,y
  inx
  iny
  cpy #16
  bne :-

; apply level effects
  lda LevelConfigBytes+1
  and #$f0
  cmp #EFFECT_NOCYCLE
  bne :+
  inc NoLevelCycle
  rts
: cmp #EFFECT_SCROLL1
  bne :+
  lda #1
  sta ScrollMode
: cmp #EFFECT_SCROLL2
  bne :+
  lda #2
  sta ScrollMode
  rts
: cmp #EFFECT_SCROLL3
  bne :+
  lda #3
  sta ScrollMode
  rts
:
  rts
.endproc

DIST_EQUAL4   = 0 << 3
DIST_SPLIT53  = 1 << 3
.proc EnemyDistributionTable
  .byt 0, 0, 0, 0, 1, 1, 1, 1, 2, 2, 2, 2, 3, 3, 3, 3
  .byt 0, 0, 0, 0, 0, 1, 1, 1, 1, 1, 2, 2, 2, 3, 3, 3
.endproc

LVL_PLAYER = $00
; single tile stuff continues until $1f
LVL_HSOLID = $20
LVL_HEMPTY = $30
LVL_HCOFFS = $40
LVL_HCONS  = $50
LVL_PLATFM = $60
LVL_HCOFFP = $70
LVL_HCONP  = $80
LVL_VSOLID = $90
LVL_VEMPTY = $a0
LVL_VCOFFS = $b0
LVL_VCONS  = $c0
LVL_RECTFL = $d0

.enum
  LVL_EMPTY
  LVL_SPIKES
  LVL_SPRING
  LVL_LAUNCH
  LVL_SOLID
  LVL_MIRROR
  LVL_PLATFM2
  LVL_MONEY
;
  LVL_CYCSOFF
  LVL_CYCSON
  LVL_CYCPOFF
  LVL_CYCPON
  LVL_TELEL
  LVL_TELER
  LVL_BOMB
  LVL_KILL
;
  LVL_HMOVEP
  LVL_VMOVEP
  LVL_HMOVEH
  LVL_VMOVEH
  LVL_EXPLODE
  LVL_SWITCH
.endenum

LevelData_MetaList: ; used anywhere a single nybble specifies a block type
  .byt METATILE_EMPTY, METATILE_SPIKES, METATILE_SPRING, METATILE_LAUNCH, METATILE_SOLID, METATILE_MIRROR, METATILE_PLATFM, METATILE_MONEY
  .byt METATILE_CYCLE_OFF_SOLID, METATILE_CYCLE_ON_SOLID, METATILE_CYCLE_OFF_PLATF, METATILE_CYCLE_ON_PLATF
  .byt METATILE_TELEPORT_LEFT, METATILE_TELEPORT_RIGHT, METATILE_BOMB_TRAP, METATILE_KILL_SPIKES
LevelData_MetaList2: ; alternate expansion list
  .byt METATILE_HMOVING_PLAT, METATILE_VMOVING_PLAT, METATILE_HMOVING_HARM, METATILE_VMOVING_HARM
  .byt METATILE_EXPLODE, METATILE_INSTANT_SWITCH

; LIST OF LEVEL DESIGNS STARTS HERE
LevelBowl:
  .byt $a0, LVL_RECTFL+LVL_SOLID, $4f
  .byt $a1, LVL_HEMPTY+13
  .byt $a1, LVL_LAUNCH
  .byt $ae, LVL_LAUNCH
  .byt $b2, LVL_HEMPTY+11
  .byt $b2, LVL_LAUNCH
  .byt $bd, LVL_LAUNCH
  .byt $c3, LVL_HEMPTY+9
  .byt $c3, LVL_LAUNCH
  .byt $cc, LVL_LAUNCH
  .byt $d4, LVL_HEMPTY+7
  .byt $d4, LVL_LAUNCH
  .byt $db, LVL_LAUNCH
  .byt $d7, $00
LevelSimple1:
  .byt $b1, LVL_RECTFL+LVL_SOLID, $33
  .byt $a1, LVL_HSOLID+0
  .byt $91, LVL_SPIKES
  .byt $eb, LVL_HSOLID+3
  .byt $dc, LVL_SPRING
  .byt $d7, LVL_SOLID
  .byt $b9, LVL_SOLID
  .byt $ba, LVL_PLATFM+2
  .byt $87, LVL_SOLID
  .byt $84, LVL_PLATFM+2
  .byt $56, LVL_PLATFM+2
  .byt $59, LVL_SOLID
  .byt $a3, $00
LevelSimple2:
  .byt $e1, LVL_HSOLID+4
  .byt $e8, LVL_HSOLID+3
  .byt $ed, LVL_HSOLID+1
  .byt $c5, LVL_PLATFM+3
  .byt $a0, LVL_PLATFM+3
  .byt $90, LVL_HSOLID
  .byt $80, LVL_SPIKES
  .byt $83, LVL_HSOLID+1
  .byt $45, LVL_VSOLID+4
  .byt $46, LVL_PLATFM+4
  .byt $97, LVL_PLATFM+3
  .byt $6a, LVL_PLATFM+2
  .byt $de, LVL_SPIKES
  .byt $d2, $00
LevelManyPlatforms1:
  .byt $e1, LVL_HSOLID+12
  .byt $a0, LVL_PLATFM+4
  .byt $a6, LVL_PLATFM+3
  .byt $c7, LVL_PLATFM+1
  .byt $ca, LVL_PLATFM+1
  .byt $d7, LVL_SPIKES
  .byt $d8, LVL_SPIKES
  .byt $d9, LVL_SPIKES
  .byt $da, LVL_SPIKES
  .byt $d2, LVL_SPIKES
  .byt $ae, LVL_PLATFM+1
  .byt $8a, LVL_PLATFM+1
  .byt $85, LVL_PLATFM+3
  .byt $75, LVL_LAUNCH
  .byt $74, LVL_HSOLID
  .byt $71, LVL_PLATFM+2
  .byt $54, LVL_PLATFM+1
  .byt $57, LVL_PLATFM+2
  .byt $78, LVL_MIRROR
  .byt $92, $00
LevelManyPlatforms2:
  .byt $e1, LVL_HSOLID+3
  .byt $d4, LVL_SPRING
  .byt $e7, LVL_HSOLID+2
  .byt $c9, LVL_VSOLID+1
  .byt $ca, LVL_PLATFM+1
  .byt $cc, LVL_VSOLID+1
  .byt $ec, LVL_HSOLID+2
  .byt $ba, LVL_SPRING
  .byt $93, LVL_PLATFM+4
  .byt $83, LVL_RECTFL+LVL_SPIKES, $04
  .byt $71, LVL_PLATFM+6
  .byt $62, LVL_RECTFL+LVL_LAUNCH, $02
  .byt $63, LVL_SOLID
  .byt $68, LVL_PLATFM
  .byt $59, LVL_PLATFM+1
  .byt $8a, LVL_PLATFM+2
  .byt $7b, LVL_SPRING
  .byt $43, LVL_PLATFM+1
  .byt $20, LVL_PLATFM+2
  .byt $24, LVL_PLATFM+2
  .byt $2a, LVL_PLATFM+2
  .byt $1b, LVL_SPRING
  .byt $d2, $00
LevelStairs1:
  .byt $e2, LVL_HSOLID+6
  .byt $73, LVL_PLATFM+8
  .byt $63, LVL_SPRING
  .byt $64, LVL_HEMPTY
  .byt $b4, LVL_PLATFM
  .byt $a4, LVL_SPRING
  .byt $9f, LVL_SOLID
  .byt $9d, LVL_PLATFM
  .byt $8c, LVL_SOLID
  .byt $8d, LVL_MIRROR
  .byt $ae, LVL_PLATFM
  .byt $bd, LVL_PLATFM
  .byt $cc, LVL_PLATFM
  .byt $cb, LVL_MIRROR
  .byt $d9, LVL_PLATFM+2
  .byt $d4, $00
LevelMoney1:
  .byt $e1, LVL_PLATFM
  .byt $e2, LVL_RECTFL+LVL_SPIKES, $0c
  .byt $e6, LVL_SOLID
  .byt $d6, LVL_SPRING
  .byt $93, LVL_RECTFL+LVL_MONEY, $29
  .byt $83, LVL_PLATFM+9
  .byt $4c, LVL_PLATFM
  .byt $5c, LVL_RECTFL+LVL_MONEY, $20
  .byt $55, LVL_RECTFL+LVL_MONEY, $05
  .byt $52, LVL_RECTFL+LVL_MONEY, $60
  .byt $53, LVL_MONEY
  .byt $73, LVL_MONEY
  .byt $6c, LVL_PLATFM
  .byt $76, LVL_VEMPTY+5
  .byt $c3, LVL_PLATFM+2
  .byt $a3, LVL_PLATFM+2
  .byt $c7, LVL_PLATFM+5
  .byt $a7, LVL_PLATFM+5
  .byt $63, LVL_PLATFM+7
  .byt $43, LVL_PLATFM+7
  .byt $44, LVL_VSOLID+4
  .byt $34, LVL_RECTFL+LVL_MONEY, $05
  .byt $36, LVL_SPIKES
  .byt $3a, LVL_SPIKES
  .byt $b4, $00
LevelDollarSign:
  .byt $e0, LVL_HSOLID+10
  .byt $29, LVL_RECTFL+LVL_MONEY, $a0
  .byt $a2, LVL_PLATFM+10
  .byt $76, LVL_PLATFM+6
  .byt $46, LVL_PLATFM+8
  .byt $56, LVL_RECTFL+LVL_PLATFM2, $20
  .byt $8c, LVL_RECTFL+LVL_PLATFM2, $20
  .byt $84, $00
LevelNarrow1:
  .byt $20, LVL_VSOLID+9
  .byt $81, LVL_PLATFM+1
  .byt $83, LVL_HSOLID+1
  .byt $d1, LVL_RECTFL+LVL_SOLID, $1b
  .byt $29, LVL_RECTFL+LVL_SOLID, $96
  .byt $b8, LVL_RECTFL+LVL_SOLID, $15
  .byt $c1, LVL_SPRING
  .byt $c4, $00
LevelSShape:
  .byt $e3, LVL_HSOLID+11
  .byt $8e, LVL_VSOLID+6
  .byt $88, LVL_HSOLID+6
  .byt $38, LVL_VSOLID+5
  .byt $38, LVL_HSOLID+6
  .byt $28, LVL_RECTFL+LVL_SPIKES, $06
  .byt $d5, LVL_SPRING
  .byt $b4, LVL_PLATFM+2
  .byt $d3, $00
LevelTriangle:
  .byt $e1, LVL_HSOLID+13
  .byt $d1, LVL_RECTFL+LVL_MONEY, $0c
  .byt $b2, LVL_HSOLID+7
  .byt $b4, LVL_PLATFM+2
  .byt $90, LVL_HSOLID
  .byt $bc, LVL_HSOLID+2
  .byt $af, LVL_HSOLID
  .byt $ce, LVL_VSOLID+2
  .byt $9d, LVL_PLATFM
  .byt $83, LVL_HSOLID+1
  .byt $87, LVL_HSOLID+6
  .byt $63, LVL_VSOLID+1
  .byt $52, LVL_VSOLID
  .byt $d5, LVL_SPRING
  .byt $55, LVL_PLATFM
  .byt $56, LVL_HSOLID+1
  .byt $5a, LVL_HSOLID+2
  .byt $5c, LVL_VSOLID+2
  .byt $36, LVL_VSOLID+1
  .byt $35, LVL_RECTFL+LVL_LAUNCH, $10
  .byt $3a, LVL_VSOLID+1
  .byt $29, LVL_VSOLID
  .byt $26, LVL_PLATFM
  .byt $28, LVL_RECTFL+LVL_MONEY, $50
  .byt $76, LVL_RECTFL+LVL_MONEY, $04
  .byt $76, LVL_RECTFL+LVL_MONEY, $30
  .byt $a3, LVL_RECTFL+LVL_MONEY, $0b
  .byt $bb, LVL_RECTFL+LVL_MONEY, $10
  .byt $d3, $00
LevelFinal:
  .byt $e1, LVL_HSOLID+13
  .byt $d4, $00

LevelScrolling1:
  .byt $e0, LVL_HSOLID+12
  .byt $d3, LVL_SPRING
  .byt $d4, LVL_HSOLID+6
  .byt $c4, LVL_HSOLID+3
  .byt $b6, LVL_SPRING
  .byt $aa, LVL_PLATFM+2
  .byt $9b, LVL_SPRING
  .byt $9d, LVL_PLATFM+2
  .byt $8f, LVL_SPRING
  .byt $b4, $00
LevelScrolling2:
  .byt $e0, LVL_RECTFL+LVL_SPIKES, $0f
  .byt $51, LVL_VSOLID+9
  .byt $93, LVL_VSOLID+5
  .byt $25, LVL_VSOLID+12
  .byt $54, LVL_HSOLID
  .byt $86, LVL_HSOLID
  .byt $b7, LVL_HSOLID+3
  .byt $8b, LVL_RECTFL+LVL_SOLID, $63
  .byt $7c, $00
LevelTPSpikes:
  .byt $ea, LVL_RECTFL+LVL_KILL, $04
  .byt $b0, LVL_HSOLID+12
  .byt $80, LVL_VSOLID+3
  .byt $71, LVL_RECTFL+LVL_KILL, $05
  .byt $57, LVL_VSOLID+2
  .byt $57, LVL_HSOLID+5
  .byt $4c, LVL_HSOLID
  .byt $4c, LVL_TELER
  .byt $a4, LVL_TELEL
  .byt $a7, LVL_BOMB
  .byt $aa, LVL_SPRING
  .byt $a8, $00
LevelX:
  .byt $c2, LVL_RECTFL+LVL_CYCSON, $22
  .byt $95, LVL_RECTFL+LVL_CYCSON, $22
  .byt $68, LVL_RECTFL+LVL_CYCSON, $22
  .byt $3b, LVL_RECTFL+LVL_CYCSON, $22
  .byt $cb, LVL_RECTFL+LVL_CYCSOFF, $22
  .byt $98, LVL_RECTFL+LVL_CYCSOFF, $22
  .byt $65, LVL_RECTFL+LVL_CYCSOFF, $22
  .byt $32, LVL_RECTFL+LVL_CYCSOFF, $22
  .byt $b3, $00
LevelTPIslands:
  .byt $e2, LVL_HSOLID+2
  .byt $c7, LVL_VSOLID+2
  .byt $b7, LVL_SPRING
  .byt $b9, LVL_RECTFL+LVL_SOLID, $22
  .byt $7c, LVL_VSOLID+4
  .byt $72, LVL_RECTFL+LVL_SOLID, $32
  .byt $d3, LVL_TELER
  .byt $63, LVL_TELER
  .byt $ab, LVL_TELER
  .byt $75, LVL_HMOVEP
  .byt $d4, $00
LevelSpringsCycle:
  .byt $e2, LVL_HSOLID+5
  .byt $c3, LVL_RECTFL+LVL_SOLID, $33
  .byt $e8, LVL_RECTFL+LVL_SPRING, $06
  .byt $c7, LVL_HCONS+7
  .byt $b8, LVL_RECTFL+LVL_LAUNCH, $05
  .byt $a9, LVL_RECTFL+LVL_LAUNCH, $03
  .byt $b9, LVL_HCONS+3
  .byt $aa, LVL_HCONS+1
  .byt $2e, LVL_HCOFFS
  .byt $37, LVL_HCOFFS+7
  .byt $b3, $00
LevelZJ:
  .byt $e0, LVL_HSOLID+3
  .byt $b0, LVL_VSOLID+3
  .byt $d2, LVL_SPRING
  .byt $e8, LVL_RECTFL+LVL_KILL, $07
  .byt $8d, LVL_RECTFL+LVL_SOLID, $62
  .byt $b2, LVL_PLATFM+5
  .byt $a5, LVL_SPRING
  .byt $84, LVL_PLATFM+2
  .byt $87, LVL_VSOLID+2
  .byt $88, LVL_HMOVEP
  .byt $d3, $00
LevelFlipMirror:
  .byt $e1, LVL_HCOFFS+3
  .byt $eb, LVL_HCONS+3
  .byt $d4, LVL_SPRING
  .byt $db, LVL_SPRING
  .byt $c5, LVL_RECTFL+LVL_CYCSON, $22
  .byt $c8, LVL_RECTFL+LVL_CYCSOFF, $22
  .byt $b4, LVL_HCOFFP+2
  .byt $b9, LVL_HCONP+2
  .byt $93, LVL_HCOFFP+4
  .byt $98, LVL_HCONP+4
  .byt $d4, $00
LevelExplode:
  .byt $d1, LVL_RECTFL+LVL_SOLID, $17
  .byt $c4, LVL_SPRING
  .byt $b6, LVL_RECTFL+LVL_SOLID, $12
  .byt $a7, LVL_HSOLID+1
  .byt $a6, LVL_EXPLODE
  .byt $a2, LVL_HCONP+1
  .byt $81, LVL_HCONP+3
  .byt $67, LVL_EXPLODE
  .byt $98, LVL_SPRING
  .byt $9b, LVL_RECTFL+LVL_SOLID, $12
  .byt $8b, LVL_RECTFL+LVL_SPIKES, $02
  .byt $6a, LVL_HCOFFP+3
  .byt $c2, $00
LevelSimple3:
  .byt $e2, LVL_HSOLID+12
  .byt $d6, LVL_SPRING
  .byt $be, LVL_VSOLID+2
  .byt $cd, LVL_VSOLID+1
  .byt $dc, LVL_VSOLID+0
  .byt $b5, LVL_PLATFM+2
  .byt $a5, LVL_SPRING
  .byt $9a, LVL_PLATFM+2
  .byt $79, LVL_VSOLID+1
  .byt $76, LVL_PLATFM+2
  .byt $48, LVL_VSOLID+2
  .byt $49, LVL_PLATFM+2
  .byt $d4, $00
LevelBowlSwitch:
  .byt $e2, LVL_HSOLID+11
  .byt $d2, LVL_SPIKES
  .byt $dd, LVL_SPIKES
  .byt $62, LVL_VSOLID+6
  .byt $63, LVL_VSOLID
  .byt $6d, LVL_VSOLID+6
  .byt $6c, LVL_VSOLID
  .byt $84, LVL_HCOFFP+7
  .byt $c6, LVL_HCONP+3
  .byt $d4, $00
LevelTwoHills:
  .byt $e2, LVL_HSOLID+11
  .byt $d5, LVL_SPRING
  .byt $b5, LVL_RECTFL+LVL_SOLID, $22
  .byt $ab, LVL_RECTFL+LVL_SOLID, $32
  .byt $e8, LVL_RECTFL+LVL_SPIKES, $02
  .byt $9c, LVL_SPRING
  .byt $81, LVL_HSOLID+2
  .byt $52, LVL_PLATFM+3
  .byt $56, LVL_HCOFFP+2
  .byt $d4, $00
LevelManyPlatforms3:
  .byt $e1, LVL_HSOLID+13
  .byt $d1, LVL_RECTFL+LVL_SPIKES, 13
  .byt $e8, LVL_RECTFL+LVL_SPIKES, $03
  .byt $d8, LVL_PLATFM+3
  .byt $b1, LVL_HCOFFP+4
  .byt $b7, LVL_HCONP+3
  .byt $a0, LVL_HCONP+4
  .byt $96, LVL_HCOFFP+4
  .byt $82, LVL_HCONP+3
  .byt $86, LVL_HCONP+3
  .byt $74, LVL_HCOFFP+3
  .byt $6a, LVL_HCOFFP+3
  .byt $57, LVL_HCONP+3
  .byt $44, LVL_HCOFFP+3
  .byt $c8, $00
;LevelStairs2:
;  .byt $d4, $00

.proc DecodeLevelMap
BufPos = 0
Param = 1
Temp = 2
Code = 3
Width = 4
Height = 5
Pointer = 6 ;is also 7
BlockId = 8
  lda LevelMapPointer+0 ; LevelMapPointer isn't in zeropage, so copy it there
  sta Pointer+0
  lda LevelMapPointer+1
  sta Pointer+1

  lda #1
  sta IsMappedLevel
  ldy #0
Loop:
  lda (Pointer),y
  sta BufPos
  iny
  lda (Pointer),y
  bne :+
    lda BufPos ; reload the position, we need that
    unpack LevelEditStartX, LevelEditStartY
    rts
: iny

  pha ; get param
  and #15
  sta Param
  tax ; just in case this needs to use the param as a block number
  lda LevelData_MetaList,x
  sta BlockId
  pla

  and #$f0 ; get function
  lsr
  lsr
  lsr

  sty Temp
  jsr Call
  ldy Temp
  jmp Loop
Call:
  tax
  lsr
  sta Code
  lda ObjectTypeTable+1,x
  pha
  lda ObjectTypeTable+0,x
  pha
  lda Code
  ldx BufPos
  rts
ObjectTypeTable:
  .raddr ZeroType
  .raddr OneType
  .raddr HorzRepeat ; solid
  .raddr HorzRepeat ; empty
  .raddr HorzRepeat ; cycle off solid
  .raddr HorzRepeat ; cycle on solid
  .raddr HorzRepeat ; platform
  .raddr HorzRepeat ; cycle off platform
  .raddr HorzRepeat ; cycle on platform
  .raddr VertRepeat ; solid
  .raddr VertRepeat ; empty
  .raddr VertRepeat ; cycle off solid
  .raddr VertRepeat ; cycle on solid
  .raddr RectFill
ZeroType:
  lda BlockId
  sta LevelBuf,x
  rts
OneType:
  sty TempVal+1
  ldy Param
  lda LevelData_MetaList+16,y
  ldy TempVal+1
  sta LevelBuf,x
  rts
HorzRepeat:
  sub #2
  tay
  lda FillTypeTable,y
  ldy Param
  iny
: sta LevelBuf,x
  inx
  dey
  bne :-
  rts
VertRepeat:
  sub #9
  tay
  lda FillTypeTable,y
  ldy Param
  iny
: sta LevelBuf,x
  pha
  txa
  axs #-16
  pla
  dey
  bne :-
  rts
RectFill:
  inc Temp
  lda (Pointer),y
  unpack Width,Height
  inc Width
  inc Height

HeightLoop:
  ldy Width
  lda BlockId
  stx BufPos
WidthLoop:
  sta LevelBuf,x
  inx
  dey
  bne WidthLoop

  lax BufPos
  axs #-16

  dec Height
  bne HeightLoop
  rts
FillTypeTable:
  .byt METATILE_SOLID, METATILE_EMPTY, METATILE_CYCLE_OFF_SOLID, METATILE_CYCLE_ON_SOLID
  .byt METATILE_PLATFM, METATILE_CYCLE_OFF_PLATF, METATILE_CYCLE_ON_PLATF
.endproc
