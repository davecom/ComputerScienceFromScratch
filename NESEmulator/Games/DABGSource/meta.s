.enum
METATILE_EMPTY
METATILE_SPIKES
METATILE_SPRING
METATILE_LAUNCH
METATILE_MIRROR
METATILE_CLOUDL
METATILE_CLOUDR
METATILE_SPRING2
METATILE_PICKUP
METATILE_MONEY
METATILE_CYCLE_OFF_SOLID ;
METATILE_CYCLE_OFF_PLATF ;
METATILE_HMOVING_PLAT ;
METATILE_VMOVING_PLAT ;
METATILE_HMOVING_HARM ;
METATILE_VMOVING_HARM ;
METATILE_TELEPORT_LEFT
METATILE_TELEPORT_RIGHT
METATILE_BOMB_TRAP
METATILE_KILL_SPIKES
METATILE_INSTANT_SWITCH
; solid area
METATILE_SOLID
METATILE_PLATFL
METATILE_PLATFM
METATILE_PLATFR
METATILE_EXPLODE ;
METATILE_CYCLE_ON_SOLID ;
METATILE_CYCLE_ON_PLATF ;
METATILE_GRASSL
METATILE_GRASSM
METATILE_GRASSR
METATILE_GRASST
METATILE_DIRT_L
METATILE_DIRT_M
METATILE_DIRT_R
METATILE_DIRT_T
.endenum
FirstSolidTop = METATILE_SOLID

.proc MetatileTiledata
  .byt $20, $20, $20, $20 ; empty
  .byt $20, $20, $84, $84 ; spikes
  .byt $20, $20, $94, $95 ; spring
  .byt $20, $20, $b4, $b5 ; up
  .byt $c4, $c5, $c4, $c5 ; mirror
  .byt $d0, $d1, $e0, $e1 ; cloud (left)
  .byt $d1, $d2, $e1, $e2 ; cloud (right)
  .byt $20, $20, $a4, $a5 ; spring blocks
  .byt $d4, $d5, $d4, $d5 ; powerup pickup
  .byt $e4, $e5, $e4, $e5 ; money pickup
  .byt $85, $85, $85, $85 ; cycle off solid
  .byt $93, $93, $20, $20 ; cycle off platform
  .byt $20, $20, $20, $20 ; 
  .byt $20, $20, $20, $20 ; 
  .byt $20, $20, $20, $20 ; 
  .byt $20, $20, $20, $20 ; 
  .byt $b0, $b1, $b0, $b1 ; teleport left
  .byt $b2, $b3, $b2, $b3 ; teleport right
  .byt $20, $20, $83, $83 ; bomb trap
  .byt $20, $20, $82, $82 ; kill spikes
  .byt $e6, $e7, $e6, $e7 ; instant switch
  .byt $89, $8a, $8b, $8c ; solid blocks
  .byt $90, $91, $20, $20 ; platform (left edge)
  .byt $91, $91, $20, $20 ; platform (middle)
  .byt $91, $92, $20, $20 ; platform (right edge)
  .byt $99, $9a, $9b, $9c ; explode
  .byt $86, $86, $86, $86 ; cycle on solid
  .byt $96, $96, $20, $20 ; cycle on platform
  .byt $da, $db, $ea, $eb ; solid grass (left)
  .byt $db, $db, $eb, $eb ; solid grass (middle)
  .byt $db, $dc, $eb, $ec ; solid grass (right)
  .byt $da, $dc, $ea, $ec ; solid grass (tower)
  .byt $ea, $eb, $ea, $eb ; solid grass (bottom left)
  .byt $eb, $eb, $eb, $eb ; solid grass (bottom middle)
  .byt $eb, $ec, $eb, $ec ; solid grass (bottom right)
  .byt $ea, $ec, $ea, $ec ; solid grass (bottom tower)
.endproc

.proc MetatileBecomes
  .byt METATILE_EMPTY     ; empty
  .byt METATILE_SPIKES    ; spike
  .byt METATILE_SPRING    ; spring
  .byt METATILE_LAUNCH    ; up
  .byt METATILE_MIRROR    ; mirror
  .byt METATILE_EMPTY     ; cloud (left)
  .byt METATILE_EMPTY     ; cloud (right)
  .byt METATILE_SPRING    ; spring pressed
  .byt METATILE_PICKUP    ; powerup pickup
  .byt METATILE_MONEY     ; money pickup
  .byt METATILE_CYCLE_OFF_SOLID
  .byt METATILE_CYCLE_OFF_PLATF
  .byt METATILE_HMOVING_PLAT
  .byt METATILE_VMOVING_PLAT
  .byt METATILE_HMOVING_HARM
  .byt METATILE_VMOVING_HARM
  .byt METATILE_TELEPORT_LEFT
  .byt METATILE_TELEPORT_RIGHT
  .byt METATILE_BOMB_TRAP
  .byt METATILE_KILL_SPIKES
  .byt METATILE_INSTANT_SWITCH
  .byt METATILE_SOLID     ; solid blocks
  .byt METATILE_PLATFM    ; platform (left edge)
  .byt METATILE_PLATFM    ; platform (middle)
  .byt METATILE_PLATFM    ; platform (right edge)
  .byt METATILE_EXPLODE
  .byt METATILE_CYCLE_ON_SOLID
  .byt METATILE_CYCLE_ON_PLATF
  .byt METATILE_SOLID     ; solid grass (left)
  .byt METATILE_SOLID     ; solid grass (middle)
  .byt METATILE_SOLID     ; solid grass (right)
  .byt METATILE_SOLID     ; solid grass (tower)
  .byt METATILE_SOLID     ; solid grass (bottom left)
  .byt METATILE_SOLID     ; solid grass (bottom middle)
  .byt METATILE_SOLID     ; solid grass (bottom right)
  .byt METATILE_SOLID     ; solid grass (bottom tower)
.endproc

.proc MetatileFlags
  ;     .....spp
  .byt %00000000          ; empty
  .byt %00000000          ; spikes
  .byt %00000000          ; spring
  .byt %00000000          ; up
  .byt %00000000          ; mirror
  .byt %00000000          ; cloud (left)
  .byt %00000000          ; cloud (right)
  .byt %00000000          ; spring pressed
  .byt %00000001          ; powerup pickup
  .byt %00000001          ; money pickup
  .byt %00000010          ; cycle off solid
  .byt %00000010          ; cycle off platform
  .byt %00000000          ; 
  .byt %00000000          ; 
  .byt %00000000          ; 
  .byt %00000000          ; 
  .byt %00000000          ; teleport left
  .byt %00000000          ; teleport right
  .byt %00000000          ; bomb trap
  .byt %00000000          ; kill spikes
  .byt %00000000          ; instant switch
  .byt %00000100          ; solid blocks
  .byt %00000000          ; platform (left edge)
  .byt %00000000          ; platform (middle)
  .byt %00000000          ; platform (right edge)
  .byt %00000100          ; explode
  .byt %00000110          ; cycle on solid
  .byt %00000010          ; cycle on platform
  .byt %00000101          ; solid grass (left)
  .byt %00000101          ; solid grass (middle)
  .byt %00000101          ; solid grass (right)
  .byt %00000101          ; solid grass (tower)
  .byt %00000101          ; solid grass (bottom left)
  .byt %00000101          ; solid grass (bottom middle)
  .byt %00000101          ; solid grass (bottom right)
  .byt %00000101          ; solid grass (bottom tower)
.endproc

.proc BlockIsSolid
  sty TempVal+2
  tay
  lda MetatileFlags,y
  ldy TempVal+2
  and #%100
  rts
.endproc

.proc GenerateLevel
  lda LevelEditMode
  jne JustFinishLevel

  lda #0
  sta NumRowsMade
  tax
: sta LevelBuf,x  ; clear buffer first
  inx
  bne :-

  ; if level specifies a map, don't make random platforms
  lda LevelConfigBytes+6
  jne EmptyMap

; if level specifies a map, and doesn't turn the composite bit on, clear first
;  lda LevelConfigBytes+6
;  beq :+
;    lda LevelConfigBytes+1
;    and #COMPOSITE_MAP
;    jeq EmptyMap
;  :

  .dj_loop #12, 0 ; zp0 = row count
    jsr rand_8
    and #%1100
    beq DontMakeRow
    inc NumRowsMade

    lda 0
    cmp #1
    jeq DontMakeRow
    .repeat 4
      asl
    .endrep
    sta 2          ; zp2 = row pointer

    jsr huge_rand
    clc
    ror
    ror
    ror
    and #%00001111 ; pick random column to start from
    ora 2
    tax

    .dj_loop #4, 1 ; zp1 = ledge width count 
      lda #METATILE_PLATFM
      sta LevelBuf,x

      txa      ; increment low nybble of X
      and #$f0
      sta 2
      inx
      txa
      and #$0f
      ora 2
      tax
    .end_djl

  DontMakeRow:
  .end_djl

  lda NumRowsMade
  cmp #5
  jcc GenerateLevel

  jsr MakeBottomPlatforms
EmptyMap:
  lda LevelConfigBytes+7 ; if an address is present, decode the level it points to
  beq JustFinishLevel
  jsr DecodeLevelMap
JustFinishLevel:
  jsr PreLevelScreen
  jsr PrettyLevel
  jsr RenderLevelBuf
  rts
.endproc
.proc MakeBottomPlatforms
  lda #METATILE_SOLID  ; make a run of blocks at the bottom
  ldx #0
: sta LevelBuf + $E1,x
  inx
  cpx #14
  bne :-

  lda #0              ; add in the two empty blocks in the very center
  sta LevelBuf + $E7
  sta LevelBuf + $E8
  rts
.endproc

.proc MakeClouds
  .dj_loop #10, 0
    jsr rand_8
    lsr
    lsr
    tax
    and #15
    cmp #15
    beq NoGood
    txa
    axs #-32
    lda LevelBuf+0,x
    bne NoGood
    lda LevelBuf+1,x
    bne NoGood
    lda #METATILE_CLOUDL
    sta LevelBuf+0,x
    lda #METATILE_CLOUDR
    sta LevelBuf+1,x
NoGood:
  .end_djl
  rts
.endproc

IsGrassOrSolid: ; returns result in carry
  cmp #METATILE_SOLID
  beq IsGrassOrSolid_Yes
TileIsGrass:
  cmp #METATILE_GRASSL
  bcc :+
  cmp #METATILE_DIRT_T+1
  bcs :+
IsGrassOrSolid_Yes:
  sec
  rts
: clc
  rts  

.proc GrassTryRow
  lda 0
  sub #16
  sta 0
  tax
  cpx #$30
  bcc Exit
  lda 1
  sub #16
  sta 1
Check:
  lda LevelBuf,x
  cmp #METATILE_SOLID
  bne Exit
  inx
  cpx 1
  bne Check

  ldx 0
  lda #METATILE_GRASSM
Replace:
  sta LevelBuf,x
  inx
  cpx 1
  bne Replace

  beq GrassTryRow
Exit:
  rts
.endproc
.proc PrettyLevel
  jsr MakeClouds
  ldx #0
  stx 0 ; for BottomGrass later
PrettyPlatforms:
  txa
  and #15
  tay
  lda LevelBuf,x
  cmp #METATILE_PLATFM
  bne FRL_NotPlatform
    cpy #0 ; check for left ledge
    beq :+
      lda LevelBuf-1,x
      beq :+
        inc LevelBuf,x
    :
    cpy #15 ; check for right ledge
    beq :+
      lda LevelBuf+1,x
      beq :+
        dec LevelBuf,x
    :
  FRL_NotPlatform:
  inx
  cpx #$f0
  bcc PrettyPlatforms

  ldx #$e0
BottomGrass:
  lda LevelBuf,x
  cmp #METATILE_SOLID
  bne NotSolid
    ; store index the grass starts on if it didn't already start
    lda 0
    bne :+
      stx 0
    :
    ; replace the current tile with grass
    lda #METATILE_GRASSM
    sta LevelBuf,x
    bne WasSolid
  NotSolid:
    lda 0
    beq WasSolid
    stx 1
    txa
    pha
    jsr GrassTryRow
    lda #0
    sta 0
    pla
    tax
  WasSolid:
  inx
  cpx #$f0
  bne BottomGrass
  ; still work even if the platform touches the right edge
  lda 0
  beq :+
    stx 1
    jsr GrassTryRow
  :

; now check for left and right corners
  ldx #$ef
GrassCornerLoop:
  lda LevelBuf,x
  cmp #METATILE_GRASSM
  bne NotEvenGrass
  txa
  pha
  and #$f0
  sta 0
  pla
  add #1
  and #15
  ora 0
  tay

  lda #0 ; clear index we'll make by shifting in two values
  sta 1

  lda LevelBuf,y
  jsr IsGrassOrSolid
  rol 1

  txa
  sub #1
  and #15
  ora 0
  tay
  lda LevelBuf,y
  jsr IsGrassOrSolid
  rol 1

  ldy 1
  lda GrassFromSideTiles,y
  sta LevelBuf,x

  ; make tiles under grass just dirt
  cpx #$e0
  bcs :+
  lda LevelBuf+16,x
  cmp #METATILE_GRASSL
  bcc :+
  cmp #METATILE_DIRT_T+1
  bcs :+
    lda LevelBuf+16,x
    add #4
    sta LevelBuf+16,x
  :

NotEvenGrass:
  dex
  cpx #$2f
  bne GrassCornerLoop

  rts
GrassFromSideTiles:
  .byt METATILE_GRASST, METATILE_GRASSR, METATILE_GRASSL, METATILE_GRASSM
.endproc

.proc RenderLevelBuf ; We should only need to do this once per level; mostly taken from FHBG
  lda #0
  sta PPUSCROLL
  sta PPUSCROLL

  tax
: sta AttribMap,x
  inx
  cpx #64
  bne :-

  PositionXY 0,   0, 0
  tax
MoreObj:
  ; Draw the top half of the blocks on the current row
  .dj_loop #16, 0

    lda LevelBuf,x
    asl
    asl
    tay
    lda MetatileTiledata+0,y
    sta PPUDATA
    lda MetatileTiledata+1,y
    sta PPUDATA

    inx
  .end_djl

  ; Go back and step through that row again!
  ; ( the bottom half still needs drawn )

  txa
  axs #16

  ; Draw the bottom half of the current row
  .dj_loop #16, 0
    txa
    lda LevelBuf,x
    pha
    pha
    tay
    lda MetatileBecomes,y
    sta LevelBuf,x

    pla    ; get block number
    asl
    asl
    tay
    lda MetatileTiledata+2,y
    sta PPUDATA
    lda MetatileTiledata+3,y
    sta PPUDATA

    pla    ; get block number
    tay
    lda MetatileFlags,y
    pha
    txa
    tay
    pla
    and #3
    beq :+ ; optimization: if it's zero it's already correct
    ora #128
    jsr ChangeBlockColor
  :

    inx
  .end_djl
  cpx #256-16 ; skip last 64 bytes (attributes table)
  jne MoreObj

  ldx #0
: lda AttribMap,x
  sta PPUDATA
  inx
  cpx #64
  bne :-

  lda #0
  sta PPUSCROLL
  sta PPUSCROLL
  rts
.endproc

.proc ChangeBlock ; A-New block, Y-Block index
  sty 1
  stx 2
  cmp #-1 ; if -1, remove the block visually but leave it in LevelBuf and set a bit in CollectMap
  bne :+
    jsr IndexToBitmap ; first set bit in CollectMap
    ora CollectMap,y
    sta CollectMap,y
    ldy 1 ; restore Y

    lda #0 ; we'll be replacing with metatile 0
    beq JustUpdateScreen
  :
  sta LevelBuf,y
JustUpdateScreen:
  sty 0           ; we need Y later when we calculate the PPU address
  asl
  asl
  tax             ; will fetch tiles from MetatileTiledata
                  ; now find a slot to put the block update in
  ldy #0
: lda BlockUpdateA1,y
  beq :+          ; empty slot found
  iny
  cpy #MaxNumBlockUpdates
  bne :-
  ldy 1
  ldx 2
  clc
  rts ;  no free slots
:
  lda MetatileTiledata+0,x
  sta BlockUpdateT1,y
  lda MetatileTiledata+1,x
  sta BlockUpdateT2,y
  lda MetatileTiledata+2,x
  sta BlockUpdateT3,y
  lda MetatileTiledata+3,x
  sta BlockUpdateT4,y

  tya
  tax

  lda 0           ; calculate PPU address now
  pha             ; starting with the top nybble
  lsr
  lsr
  alr #%111100    ; <- replacing "lsr, and #%11110"
  tay             ; index into PPURowAddr
  pla
  and #$0f        ; bottom nybble is the X index
  asl             ; multiply by two because blocks are 16 pixels wide
  sta 0
  lda PPURowAddrHi+0,y
  sta BlockUpdateA1,x
  lda PPURowAddrHi+1,y
  sta BlockUpdateB1,x

  lda PPURowAddrLo+0,y
  add 0
  sta BlockUpdateA2,x
  lda PPURowAddrLo+1,y
  add 0
  sta BlockUpdateB2,x
  sec             ; success
  ldy 1
  ldx 2
  rts
.endproc

PPURowAddrHi:
.repeat 30, I
  .byt >($2000+I*32)
.endrep
PPURowAddrLo:
.repeat 30, I
  .byt <($2000+I*32)
.endrep

.proc ChangeBlockColor ; A-New color (0 to 3), Y-Block index
                       ; http://wiki.nesdev.com/w/index.php/Attribute_table
  AttrIndexTemp = 4
  OnValue = 5
  SaveColor = 6
  SaveX = 7

  stx SaveX       ; level renderer uses X, so save it
  sta SaveColor
  and #3
  tax         ; save the particular color being used
  lda ValueMasks,x  ; start with it unshifted
  sta OnValue
  ; now determine how much to shift
  ldx #0      ; start at no shift
  tya
  lsr         ; odd X? move up one
  bcc :+
    inx
: tya
  and #$10 ;odd Y? move up two
  beq :+
    inx
    inx
  :

  lda OnValue
  and ShiftOnMasks,x
  sta OnValue

  ; Take the level buffer index and make it into an AttribMap index
  tya
  alr #$e0 ; Y half (discard last bit)
  lsr
  sta AttrIndexTemp
  tya
  alr #$e     ; X half (discard last bit)
  ora AttrIndexTemp
  tay

  lda AttribMap,y
  and ShiftOffMasks,x
  ora OnValue
  sta AttribMap,y
  sta OnValue
  ldx SaveX

  bit SaveColor
  bpl :+
    rts
  :
; Now locate a slot to queue the actual change
  ldx #0
: lda TileUpdateA1,x
  beq Found
  inx
  cpx #MaxNumTileUpdates
  bne :-
  clc ; failed
  rts
Found:

  lda OnValue
  sta TileUpdateT,x
  lda #$23
  sta TileUpdateA1,x
  tya
  add #$c0
  sta TileUpdateA2,x
  sec
  ldx SaveX
  rts

ValueMasks:
  .byt %00000000
  .byt %01010101
  .byt %10101010
  .byt %11111111
ShiftOnMasks:
  .byt %00000011
  .byt %00001100
  .byt %00110000
  .byt %11000000
ShiftOffMasks:
  .byt %11111100
  .byt %11110011
  .byt %11001111
  .byt %00111111
.endproc

.proc IndexToBitmap ; Y = $yx -> Y = index, A = mask
  tya
  pha
  lsr
  lsr
  lsr
  sta TempVal+1
  pla
  and #7
  tay
  lda BitSelect,y
  ldy TempVal+1
  rts
.endproc

.proc AddDelayMetaEdit ; Y = $yx, A = type, 0 = time (destroys 1 and 2)
  sta 1
  sty 2
  ldy #0
: lda DelayedMetaEditType,y
  beq Found
  iny
  cpy #MaxDelayedMetaEdits
  bne :-
  ldy 2
  clc
  rts
Found:
  lda 0
  sta DelayedMetaEditTime,y
  lda 1
  sta DelayedMetaEditType,y
  lda 2
  sta DelayedMetaEditIndx,y
  ldy 2
  sec
  rts
.endproc
