NewColumn = StatusRow2

.proc UpdateScrollColumn
  WhichMetaColumn = 1
  LevelBufIndex = 14

  lda ScrollX+1
  and #127
  bne :+
    jsr huge_rand
    sta ScrollGenVars+0
    jsr huge_rand
    sta ScrollGenVars+1
    lda #0
    sta ScrollGenVars+2
    sta ScrollGenVars+3

    inc ScrollGenerator
    lda ScrollGenerator
    cmp #8
    bne :+
      lda #0
      sta ScrollGenerator
  :

; calculate PPU address to write the 28 byte buffer to
; (repurposed from being a status bar)
  lda #$20
  sta Update28Address+0
  lda ScrollX+1
  lsr
  lsr
  lsr
  sta 0   ; nametable column used to determine what level column to update
  add #64 ; start one block down
  sta Update28Address+1

  ldy #0 ; y will be Update28 index
  sty WhichMetaColumn
  lda 0
  lsr    ; get the LevelBuf index
  sta LevelBufIndex

; we split the tasks for scrolling into different parts per frame
; partly to leave more CPU for other stuff and partly 
ChooseTask:
  lda ScrollX+1
  and #15
  cmp #8
  jeq RenderRight
  bcc :+
    rts
: asl
  tax
  lda ScrollTasks+1,x
  pha
  lda ScrollTasks+0,x
  pha
  rts

RenderLeftGenerate:
; generate new level stuff here, if left column

  jsr LaunchScrollGen1
  tay

  ldx #15
  lda #0
: lda ScrollColumnTemplates,y
  sta NewColumn,x
  iny
  dex
  bpl :-

  jsr LaunchScrollGen2

  ldy #0
RenderLeft:
  tya
  lsr
  tax
  lda NewColumn,x
  sta TempVal

  lda LevelBufIndex ; step to next metatile
  tax               ; but for this iteration, use the previous value
  add #16
  sta LevelBufIndex

  lda TempVal
  sta LevelBuf+16,x ; find index into MetatileData
  asl
  asl
  tax

  lda MetatileTiledata,x
  sta Update28+0,y
  lda MetatileTiledata+2,x
  sta Update28+1,y

  iny
  iny
  cpy #28
  bne RenderLeft
  rts

RenderRight:
  lda LevelBufIndex ; step to next metatile
  tax               ; but for this iteration, use the previous value
  add #16
  sta LevelBufIndex

  lda LevelBuf+16,x ; find index into MetatileData
  asl
  asl
  tax

  lda MetatileTiledata+1,x
  sta Update28+0,y
  lda MetatileTiledata+3,x
  sta Update28+1,y

  iny
  iny
  cpy #28
  bne RenderRight
  rts

FixColors1:
  ldx #0
  ldy #FixColorSet2-FixColorSet1
  bne FixColors
FixColors2:
  ldx #FixColorSet2-FixColorSet1
  ldy #FixColorSet3-FixColorSet2
  bne FixColors
FixColors3:
  ldx #FixColorSet3-FixColorSet1
  ldy #FixColorSetEnd-FixColorSet3

FixColors:
  ColorSetIndex = 12
  ColorSetLoopCount = 13
  stx ColorSetIndex
  sty ColorSetLoopCount
FixColorsLoop:
  ldx ColorSetIndex
  inc ColorSetIndex

  lda FixColorSet1,x   ; what block to do currently
  add LevelBufIndex
  tay
  sty 0
  lda LevelBuf,y       ; get tile we're going to be coloring
  tay
  lda MetatileFlags,y  ; get the flags for this tile
  and #3               ; mask off just the palette number
  ldy 0
  jsr ChangeBlockColor ; A = new palette, Y = LevelBuf index

  dec ColorSetLoopCount
  bne FixColorsLoop
  rts

; two consecutive rows are going to share the same byte
; so I spread it out so we're not rewriting the same byte twice in one NMI
FixColorSet1: .byt 1*16,  3*16,  5*16,  7*16, 9*16
FixColorSet2: .byt 11*16, 13*16, 2*16,  4*16
FixColorSet3: .byt 6*16,  8*16,  10*16, 12*16, 14*16
FixColorSetEnd:

ScrollTasks:
  .raddr RenderLeftGenerate
  .raddr FixColors1
  .raddr FixColors2
  .raddr FixColors3
  .raddr EmptyObject
  .raddr EmptyObject
  .raddr EmptyObject
  .raddr EmptyObject

LaunchScrollGen1:
  lda ScrollGenerator
  asl
  tax
  lda ScrollGen1Table+1,x
  pha
  lda ScrollGen1Table+0,x
  pha
DoLaunch:
  lda LevelBufIndex
  and #7
  rts

LaunchScrollGen2:
  lda ScrollGenerator
  asl
  tax
  lda ScrollGen2Table+1,x
  pha
  lda ScrollGen2Table+0,x
  pha
  jmp DoLaunch
.endproc

.enum
  SCROLLCOL_EMPTY
  SCROLLCOL_GROUND
  SCROLLCOL_MIDGROUND
  SCROLLCOL_HIGHGROUND
  SCROLLCOL_SPRINGGROUND
  SCROLLCOL_ALLGROUND
  SCROLLCOL_WALL_CYCLE_ON
  SCROLLCOL_WALL_CYCLE_OFF
.endenum

.proc ScrollColumnTemplates ; backwards
  .byt 0,0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
  .byt 0,0, METATILE_SOLID, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
  .byt 0,0, METATILE_SOLID, METATILE_SOLID, METATILE_SOLID, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
  .byt 0,0, METATILE_SOLID, METATILE_SOLID, METATILE_SOLID, METATILE_SOLID, METATILE_SOLID, 0, 0, 0, 0, 0, 0, 0, 0, 0
  .byt 0,0, METATILE_SOLID, METATILE_SOLID, METATILE_SOLID, METATILE_SOLID, METATILE_SOLID, METATILE_SOLID, METATILE_SOLID, 0, 0, 0, 0, 0, 0, 0
  .byt 0,0, METATILE_SOLID,METATILE_SOLID,METATILE_SOLID,METATILE_SOLID,METATILE_SOLID,METATILE_SOLID,METATILE_SOLID,METATILE_SOLID, METATILE_SOLID,METATILE_SOLID,METATILE_SOLID,METATILE_SOLID,METATILE_SOLID,METATILE_SOLID
  .byt 0,0, METATILE_SOLID, METATILE_CYCLE_ON_SOLID, METATILE_CYCLE_ON_SOLID, METATILE_CYCLE_ON_SOLID, METATILE_CYCLE_ON_SOLID, METATILE_CYCLE_ON_SOLID, METATILE_CYCLE_ON_SOLID, METATILE_CYCLE_ON_SOLID, METATILE_CYCLE_ON_SOLID, METATILE_CYCLE_ON_SOLID, METATILE_CYCLE_ON_SOLID, METATILE_CYCLE_ON_SOLID, METATILE_CYCLE_ON_SOLID, METATILE_CYCLE_ON_SOLID
  .byt 0,0, METATILE_SOLID, METATILE_CYCLE_OFF_SOLID, METATILE_CYCLE_OFF_SOLID, METATILE_CYCLE_OFF_SOLID, METATILE_CYCLE_OFF_SOLID, METATILE_CYCLE_OFF_SOLID, METATILE_CYCLE_OFF_SOLID, METATILE_CYCLE_OFF_SOLID, METATILE_CYCLE_OFF_SOLID, METATILE_CYCLE_OFF_SOLID, METATILE_CYCLE_OFF_SOLID, METATILE_CYCLE_OFF_SOLID, METATILE_CYCLE_OFF_SOLID, METATILE_CYCLE_OFF_SOLID
  .byt 0,0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
  .byt 0,0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
.endproc

.enum
  SCROLLGEN_FLAT
  SCROLLGEN_PLATFORM_FIELD
  SCROLLGEN_GAP_THROUGH_SOLID
  SCROLLGEN_STAIRGAP_THROUGH_SOLID
  SCROLLGEN_SPRING_OVER_WALL
  SCROLLGEN_FALL_UNDER_WALL
  SCROLLGEN_SPRING_OVER_SPIKES
  SCROLLGEN_SPRINGFIELD_OVER_SPIKES
.endenum

; gen 1 decides what column template to use
.proc ScrollGen1Table
  .raddr ScrollGen1_Flat ;
  .raddr ScrollGen1_PlatformField
  .raddr ScrollGen1_GapThruSolid
  .raddr ScrollGen1_CycleSwitchWalls ;
  .raddr ScrollGen1_SpringOverWall
  .raddr ScrollGen1_FallUnderWall ;
  .raddr ScrollGen1_SpringOverSpikes
  .raddr ScrollGen1_SpringFieldOverSpikes
.endproc

; gen 2 does additional changes
.proc ScrollGen2Table
  .raddr ScrollGen2_Flat
  .raddr ScrollGen2_PlatformField
  .raddr ScrollGen2_GapThruSolid
  .raddr ScrollGen2_CycleSwitchWalls
  .raddr ScrollGen2_SpringOverWall
  .raddr ScrollGen2_FallUnderWall
  .raddr ScrollGen2_SpringOverSpikes
  .raddr ScrollGen2_SpringFieldOverSpikes
.endproc

ScrollGen1_CycleSwitchWalls:
  cmp #3
  beq :+
  cmp #7
  beq :++
  lda #SCROLLCOL_GROUND*16
  rts
: lda #SCROLLCOL_WALL_CYCLE_ON*16
  rts
: lda #SCROLLCOL_WALL_CYCLE_OFF*16
  rts


ScrollGen1_GapThruSolid:
ScrollGen1_SpringOverWall:
  lda #SCROLLCOL_GROUND*16
  rts

ScrollGen1_FallUnderWall:
  beq :+
  lda #SCROLLCOL_ALLGROUND*16
  rts
ScrollGen1_PlatformField:
: lda #SCROLLCOL_EMPTY*16
  rts

ScrollGen1_Flat:
  lda #SCROLLCOL_GROUND*16
  rts

ScrollGen1_SpringOverSpikes:
ScrollGen1_SpringFieldOverSpikes:
  lda #SCROLLCOL_GROUND*16
  rts

ScrollGen2_CycleSwitchWalls:
  and #3
  cmp #2
  bne :+
  lda #METATILE_INSTANT_SWITCH
  sta NewColumn+12
: rts

ScrollGen2_PlatformField:
  lda #10
  sub ScrollGenVars+2
  tax
  lda #METATILE_PLATFM
  sta NewColumn,x

  jsr huge_rand
  and #7
  sub #4
  add ScrollGenVars+2

  and #7
  sta ScrollGenVars+2
  rts

ScrollGen2_GapThruSolid:
ScrollGen2_SpringOverWall:
  rts
ScrollGen2_FallUnderWall:
  beq :+
  lda #METATILE_SPIKES
  sta NewColumn
  lda ScrollGenVars
  and #7
  add #2
  tax
  lda #METATILE_EMPTY
  sta NewColumn+0,x
  sta NewColumn+1,x
: rts

ScrollGen2_Flat = EmptyObject

ScrollGen2_SpringOverSpikes:
  bne :+
  lda #METATILE_SPRING
  sta NewColumn+12
  rts
: lda #METATILE_SPIKES
  sta NewColumn+12
  rts

ScrollGen2_SpringFieldOverSpikes:
  jsr huge_rand
  and #7
  add #2
  tax
  lda #METATILE_SPRING
  sta NewColumn,x
  rts
