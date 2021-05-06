.proc StartMainMenu
  jsr init_sound
  lda #0
  sta EnableNMIDraw
  sta LevelNumber
  sta LevelEditMode
  sta IsScoreMode
  sta IsFightMode
  sta VersusPowerups
  sta VersusMode

  lda #DIFFICULTY_STANDARD
  sta GameDifficulty

  lda #0
  sta PPUMASK
  sta PPUSCROLL
  sta PPUSCROLL
  jsr ClearOAM

  lda #<TitleName
  sta 0
  lda #>TitleName
  sta 1
  lda #$20
  sta PPUADDR
  lda #$00
  sta PPUADDR
  jsr PKB_unpackblk
  lda #0
  sta PPUSCROLL
  sta PPUSCROLL

  jsr wait_vblank

  lda #BG_ON | OBJ_ON
  sta PPUMASK
  jsr WaitForKey
  jsr EnableForPress
  jsr wait_vblank
.endproc
.proc StartMainMenu2
  ldy #MainMenuData-MenuData
  jsr RunChoiceMenu
  asl
  tax

  lda retraces
  beq :+
  ora #1
: sta r_seed

  lda MainMenuAddrs+1,x
  pha
  lda MainMenuAddrs+0,x
  pha
  rts
.endproc

TitleName:
.incbin "title.pkb"

.proc MainMenuAddrs
  .raddr MenuNewGame
  .raddr StartEditorFromMenu
  .raddr ShowDirections
  .raddr ShowCredits
  .raddr ExitToMenu
.endproc

.proc ExitToMenu
  jmp (VectorAddrs+2)
.endproc

.if 0
.proc ExtrasMenuAddrs
  .raddr StartEditorFromMenu
  .raddr ShowCredits
  .raddr StartMainMenu2
.endproc

.proc LevelpackMenuAddrs
  .raddr NewGameStart1
  .raddr NewGameStart2
  .raddr NewGameStart3
  .raddr MenuNewGameBonus
  .raddr StartMainMenu2
.endproc

.proc LevelpackBonusMenuAddrs
  .raddr NewGameStart4
  .raddr NewGameStart5
  .raddr NewGameStart6
  .raddr StartMainMenu2
.endproc

.proc VersusMenuAddrs
  .raddr VersusScore
  .raddr VersusFight
  .raddr VersusMix3
  .raddr VersusMix5
  .raddr StartMainMenu2
.endproc

MenuNewGameHard:
  lda #DIFFICULTY_HARDER
  sta GameDifficulty
MenuNewGame:
  ldy #LevelPackMenuData-MenuData
  jsr RunChoiceMenu
  asl
  tax

  lda retraces
  beq :+
  ora #1
: sta r_seed

  lda LevelpackMenuAddrs+1,x
  pha
  lda LevelpackMenuAddrs+0,x
  pha
  rts

MenuNewGameBonus:
  ldy #LevelPackBonusMenuData-MenuData
  jsr RunChoiceMenu
  asl
  tax

  lda LevelpackBonusMenuAddrs+1,x
  pha
  lda LevelpackBonusMenuAddrs+0,x
  pha
  rts

NewGameStart1:
  lda #0
  beq LPJumpNewGame
NewGameStart2:
  lda #12
  bne LPJumpNewGame
NewGameStart3:
  lda #24
  bne LPJumpNewGame
NewGameStart4:
  lda #32
  bne LPJumpNewGame
NewGameStart5:
  lda #40
  bne LPJumpNewGame
NewGameStart6:
  lda #48
LPJumpNewGame:
  sta LevelNumber
  inc JustPickedFromMenu
  jmp NewGame

VersusMix3:
  lda #3
  .byt $2c  
VersusMix5:
  lda #5
  bne VersusStartAny

VersusScore:
  lda #0
  .byt $2c
VersusFight:
  lda #1
  sta VersusIsFight
VersusStart1Turn:
  lda #1
VersusStartAny:
  sta VersusNeed2Win
  sta PlayerEnabled+0
  sta PlayerEnabled+1
  lda #1
  sta VersusMode
  lda #0
  sta VersusWins+0
  sta VersusWins+1
  jmp StartMainMenu

.proc StartExtrasMenu
  ldy #ExtrasMenuData-MenuData
  jsr RunChoiceMenu
  asl
  tax

  lda retraces
  beq :+
  ora #1
: sta r_seed

  lda ExtrasMenuAddrs+1,x
  pha
  lda ExtrasMenuAddrs+0,x
  pha
  rts  
.endproc

.proc StartVersusMenu
  ldy #VersusMenuData-MenuData
  jsr RunChoiceMenu
  asl
  tax

  lda retraces
  beq :+
  ora #1
: sta r_seed

  lda VersusMenuAddrs+1,x
  pha
  lda VersusMenuAddrs+0,x
  pha
  rts  
.endproc
.endif

MenuData:
.proc MainMenuData
  .byt 5
  .ppuxy 0, 10, 20
  .byt "Play Game",0
  .ppuxy 0, 10, 21
  .byt "Level Edit",0
  .ppuxy 0, 10, 22
  .byt "How To Play",0
  .ppuxy 0, 10, 23
  .byt "Credits",0
  .ppuxy 0, 10, 24
  .byt "Exit to menu",0
.endproc

.if 0
.proc LevelPackMenuData
  .byt 5
  .ppuxy 0, 10, 20
  .byt "Level 1",0
  .ppuxy 0, 10, 21
  .byt "Level 13",0
  .ppuxy 0, 10, 22
  .byt "Level 25",0
  .ppuxy 0, 10, 23
  .byt "Bonus Levels",0
  .ppuxy 0, 10, 24
  .byt "BACK",0
  .ppuxy 0, 10, 25
.endproc

.proc LevelPackBonusMenuData
  .byt 4
  .ppuxy 0, 10, 20
  .byt "Level 33",0
  .ppuxy 0, 10, 21
  .byt "Level 41",0
  .ppuxy 0, 10, 22
  .byt "Level 49",0
  .ppuxy 0, 10, 23
  .byt "BACK",0
  .ppuxy 0, 10, 25
  .byt " ",0
.endproc
.endif

.proc EnableForPress
  lda keydown+0
  beq :+
  lda #1
  sta PlayerEnabled+0
:
  lda keydown+1
  beq :+
  lda #1
  sta PlayerEnabled+1
: rts
.endproc
.proc RunChoiceMenu ; returns choice selected in A
  ldx MenuData,y
  stx 1             ; keep number of choices for later
  jsr ClearMenuChoices

NewRow:
  lda #0
  sta PPUSCROLL
  sta PPUSCROLL
  jsr wait_vblank
  iny               ; also skips over zeroes when branched here
  dex
  bmi NoMoreRows
  lda MenuData,y
  sta PPUADDR
  iny
  lda MenuData,y
  sta PPUADDR
  iny
: lda MenuData,y
  beq NewRow
  sta PPUDATA
  iny
  jmp :-
NoMoreRows:
  jsr ClearOAM
  lda #0
  sta 0            ; current pos

ChoiceLoop:
  jsr ReadJoy
  jsr EnableForPress

  lda keydown
  ora keydown+1
  and #KEY_UP
  beq :+
    lda keylast
    ora keylast+1
    and #KEY_UP
    bne :+
      dec 0
      bpl :+
        lda 1
        sta 0
        dec 0
  :

  lda keydown
  ora keydown+1
  and #KEY_DOWN
  beq :+
    lda keylast
    ora keylast+1
    and #KEY_DOWN
    bne :+
      inc 0
      lda 0
      cmp 1
      bcc :+
        lda #0
        sta 0
  :

  lda #10*8-16
  sta OAM_XPOS+(4*0)
  lda 0
  asl
  asl
  asl
  add #20*8-1
  sta OAM_YPOS+(4*0)
  sta 2
  lda #$28
  sta OAM_TILE+(4*0)
  lda #0
  sta OAM_ATTR+(4*0)

  lda keydown
  ora keydown+1
  and #KEY_A|KEY_START
  beq :+
    lda keylast
    ora keylast+1
    and #KEY_A|KEY_START
    beq ChoiceSelected
  :
  jsr wait_vblank
  jmp ChoiceLoop

ChoiceSelected:
  jsr ClearOAM
  lda 0
  rts
.endproc

.proc ClearMenuChoices
  lda #0
  sta PPUSCROLL
  sta PPUSCROLL
  jsr wait_vblank
  PositionXY 0, 10, 20
  jsr PrintSpaces
  PositionXY 0, 10, 21
  jsr PrintSpaces
  PositionXY 0, 10, 22
  jsr PrintSpaces
  PositionXY 0, 10, 23
  jsr PrintSpaces
  PositionXY 0, 10, 24
PrintSpaces:
  lda #' '
  .repeat 12
    sta PPUDATA
  .endrep
  rts
.endproc

.macro PositionPrintXY NT, XP, YP, String
  PositionXY NT, XP, YP
  jsr PutStringImmediate
  .byt String, 0
.endmacro

.proc WaitForKeyTimed
: jsr wait_vblank
  jsr ReadJoy
  dey
  beq :+
  lda keydown
  ora keydown+1
  beq :-
  lda keylast
  ora keylast+1
  bne :-
: rts

.endproc

.proc PreLevelScreen
  jsr wait_vblank
  lda #0
  sta PPUMASK
  jsr ClearName

  PositionPrintXY 0, 8,6,  "= NEXT LEVEL ="
  PositionPrintXY 0, 10, 9, "Level: "
  lda LevelEditMode
  bne :+
  lda LevelNumber
  add #1
  jsr PutDecimal
: lda LevelEditMode
  beq :+
  jsr PutStringImmediate
  .byt "Custom", 0
:
  PositionPrintXY 0, 10,11, "Lives: "

  lda PlayerEnabled
  beq :+
    lda PlayerLives
    jsr PutDecimal
    lda #' '
    sta PPUDATA
  :
  lda PlayerEnabled+1
  beq :+
    lda PlayerLives+1
    jsr PutDecimal
  :

  PositionXY 0, 7,13
  jsr DispGoal

  lda #0
  sta PPUSCROLL
  sta PPUSCROLL
  jsr wait_vblank
  lda #BG_ON | OBJ_ON
  sta PPUMASK
  ldy #100
  jsr WaitForKeyTimed

: lda keydown
  ora keydown+1
  and #KEY_START
  beq :+
  jsr ReadJoy
  jmp :-
:

  lda #0
  sta PPUMASK
  rts

DispGoal:
  lda LevelGoalType
  asl
  tax
  lda GoalAddrs+1,x
  pha
  lda GoalAddrs+0,x
  pha
  rts
GoalAddrs:
  .raddr Defeat
  .raddr Collect 
  .raddr Survive
  .raddr Step
Defeat:
  jsr PutStringImmediate
  .byt "Defeat ",0
  lda IsFightMode
  bne :+
  lda LevelGoalParam
  jsr PutDecimal 
  jsr PutStringImmediate
  .byt " enemies",0
  rts
: jsr PutStringImmediate
 .byt "the other guy!",0
  rts
Collect:
  jsr PutStringImmediate
  .byt "Collect ",0
  lda LevelGoalParam
  jsr PutDecimal
  jsr PutStringImmediate
  .byt " dollars",0
  rts
Survive:
  jsr PutStringImmediate
  .byt "Survive ",0
  lda LevelGoalParam
  jsr PutDecimal
  jsr PutStringImmediate
  .byt " seconds",0
  rts
Step:
  jsr PutStringImmediate
  .byt "Green to red",0
  rts
.endproc

.proc ShowDirections
  jsr wait_vblank
  lda #0
  sta PPUMASK
  jsr ClearName
  PositionPrintXY 0, 8,4,  "Double Action"
  PositionPrintXY 0, 9,5,  "Blaster Guys"

  PositionPrintXY 0, 2,8,  "Complete the objectives for"
  PositionPrintXY 0, 2,9,  "each level to move on to the"
  PositionPrintXY 0, 2,10, "next one, while avoiding any"
  PositionPrintXY 0, 2,11, "hazards like enemy bullets."
  PositionPrintXY 0, 2,12, "Players can join in at any"
  PositionPrintXY 0, 2,13, "time by pressing A and B."

  PositionPrintXY 0, 8,16, "A-Jump"
  PositionPrintXY 0, 8,17, "B-Shoot"
  PositionPrintXY 0, 8,18, "Start-Pause"
  PositionPrintXY 0, 8,19, "Select-Skip level"

  PositionPrintXY 0, 2,22, "Press anything to continue"

  lda #0
  sta PPUSCROLL
  sta PPUSCROLL
  jsr wait_vblank
  lda #BG_ON | OBJ_ON
  sta PPUMASK
  jsr WaitForKey
  jmp StartMainMenu
.endproc

.proc ShowCredits
  jsr wait_vblank
  lda #0
  sta PPUMASK
  jsr ClearName
  PositionPrintXY 0, 8,4,  "Double Action"
  PositionPrintXY 0, 9,5,  "Blaster Guys"

  PositionPrintXY 0, 2,8,  "Nearly everything"
  PositionPrintXY 0, 3,9,  "by NovaSquirrel"
  PositionPrintXY 0, 3,10, "(NovaSquirrel.com)"

  PositionPrintXY 0, 2,12, "Sound and trig code, some"
  PositionPrintXY 0, 3,13, "sounds & sprites by Tepples"
  PositionPrintXY 0, 3,14, "(PinEight.com)"

  PositionPrintXY 0, 2,16, "Music is a heavily edited"
  PositionPrintXY 0, 3,17, "version of Morning Mood"

  PositionPrintXY 0, 8,25, "Built 11/22/2014"
  PositionPrintXY 0, 2,21, "Press anything to continue"

  lda #0
  sta PPUSCROLL
  sta PPUSCROLL
  jsr wait_vblank
  lda #BG_ON | OBJ_ON
  sta PPUMASK
  jsr WaitForKey
  jmp StartMainMenu
.endproc

.proc LevelWasWon
  lda #0
  sta EnableNMIDraw
;  jsr init_sound
  lda #0
  sta PlayerVYH
  sta PlayerVYH+1
  sta PlayerVYL
  sta PlayerVYL+1
SoarLoop:
  jsr wait_vblank
  jsr ClearOAM
  jsr SlowdownMusic
  jsr update_sound

  ldx #0
  stx 15
SoarAllPlayers:
  jsr PlayerSoar
  bcc :+
  inc 15
: inx
  cpx #MaxNumPlayers
  bne SoarAllPlayers

  lda 15
  cmp #2
  bne SoarLoop

  lda LevelEditMode
  jeq NewLevel
  lda IsScoreMode
  jne VersusScoreWinScreen
  jmp StartEditorNormal

PlayerSoarDone:
  sec
  rts
PlayerSoar:
  lda PlayerEnabled,x ; skip if not enabled
  beq PlayerSoarDone
  lda PlayerPYH,x     ; skip if they're already up
  cmp #8
  bcc PlayerSoarDone

  lda PlayerPYL,x
  sub PlayerVYL,x
  bcs :+
    inc PlayerPYH,x
: sta PlayerPYL,x
  lda PlayerVYL,x
  add #32
  bcc :+
    inc PlayerVYH,x
: sta PlayerVYL,x
  lda PlayerPYH,x
  sub PlayerVYH,x
  sta PlayerPYH,x
NoSoar:
  jsr DispPlayer
  clc
  rts
.endproc

.proc SlowdownMusic
  lda music_tempoLo
  sub #<5
  sta music_tempoLo
  lda music_tempoHi
  sbc #>5
  sta music_tempoHi
  bmi :+
  rts
: lda #0
  sta music_tempoHi
  sta music_tempoLo
  jsr stop_music
  rts
.endproc


GameSet_ChoiceRows:
.byt ChoiceRow_Players - GameSet_ChoiceText
.byt ChoiceRow_1PlayerModes - GameSet_ChoiceText
.byt ChoiceRow_2PlayerModes - GameSet_ChoiceText
.byt ChoiceRow_Difficulty - GameSet_ChoiceText
.byt ChoiceRow_Level1 - GameSet_ChoiceText
.byt ChoiceRow_Level2 - GameSet_ChoiceText
.byt ChoiceRow_ScoreLevels - GameSet_ChoiceText
.byt ChoiceRow_Powerups - GameSet_ChoiceText
.byt ChoiceRow_ExitEditor - GameSet_ChoiceText
.byt ChoiceRow_PlayAgainVs - GameSet_ChoiceText
GameSet_ChoiceText:
ChoiceRow_Players:
.byt "Player_1, Player_2, Both",0
ChoiceRow_1PlayerModes:
.byt "Original",0
ChoiceRow_2PlayerModes:
.byt "Co-op, Score, Fight",0
ChoiceRow_Difficulty:
.byt "Normal, Harder",0
ChoiceRow_Level1:
.byt "1 5 9 13 17 21 25 29 Bonus",0
ChoiceRow_Level2:
.byt "33 37 41 45 49",0 ; 53 57 61",0
ChoiceRow_ScoreLevels:
.byt "3 9 14 18 21 22 27 30 Edit",0
ChoiceRow_Powerups:
.byt "Off, Low, Powerups",0
ChoiceRow_ExitEditor:
.byt "Cancel, Exit",0
ChoiceRow_PlayAgainVs:
.byt "Same, New, Exit",0

GameSet_Question4ChoiceRow:
.byt 0, 1, 1, 2, 3, 3, 3, 4, 5, 6

.enum
  CHOICES_NUM_PLAYERS
  CHOICES_1P_MODES
  CHOICES_2P_MODES
  CHOICES_DIFFICULTY
  CHOICES_LEVEL1
  CHOICES_LEVEL2
  CHOICES_SCORELEVELS
  CHOICES_POWERUPS
  CHOICES_EXITEDITOR
  CHOICES_PLAYAGAINVS
.endenum

GameSet_Questions:
.byt GameSet_QuestionPlayers - GameSet_QuestionText
.byt GameSet_QuestionMode - GameSet_QuestionText
.byt GameSet_QuestionDifficulty - GameSet_QuestionText
.byt GameSet_QuestionLevel - GameSet_QuestionText
.byt GameSet_QuestionPowerups - GameSet_QuestionText
.byt GameSet_QuestionExitEditor - GameSet_QuestionText
.byt GameSet_QuestionPlayAgainVs - GameSet_QuestionText
GameSet_QuestionText:
GameSet_QuestionPlayers:
.byt "Who's playing?",0
GameSet_QuestionMode:
.byt "What game mode?",0
GameSet_QuestionDifficulty:
.byt "Which difficulty?",0
GameSet_QuestionLevel:
.byt "Level to start at?",0
GameSet_QuestionPowerups:
.byt "Enable powerups?",0
GameSet_QuestionExitEditor:
.byt "Exit the editor?",0
GameSet_QuestionPlayAgainVs:
.byt "Play again on same level?",0

.proc GameSet_DisplayChoice ; A = screen row, X = choice of row, Y = initial choice ---> A = chosen option
ScreenRow = 4
RowStartsAt = 5
CurrentChoice = 6
NumChoices = 7
NameYPos = 8
SpritesYPos = 9
ChoiceList = TouchRight
  sta ScreenRow
  sty CurrentChoice
  txa
  pha

  jsr wait_vblank
  lda #0
  sta PPUMASK
  sta NumChoices

  ; selection sprites use left half of CHR
  lda #VBLANK_NMI | NT_2000 | OBJ_8X8 | BG_0000 | OBJ_0000
  sta PPUCTRL

  PositionXY 0, 4, 4
  lda #'-'
  sta PPUDATA
  lda #' '
  sta PPUDATA

  lda GameSet_Question4ChoiceRow,x
  tax
  lda GameSet_Questions,x
  tax
: lda GameSet_QuestionText,x
  beq :+
  sta PPUDATA
  inx
  bne :-
: ; clear out some space after the question,
  ; to clean up when switching to a shorter question
  ldx #10
  jsr PutXSpaces

  jsr wait_vblank
  lda ScreenRow
  asl
  add #8

  pha
    pha
    asl
    asl
    asl
    sta SpritesYPos
    pla
  add #2
  jsr Mul32PPU1202
  jsr Put32Spaces
  pla
  sta NameYPos
  jsr Mul32PPU1202

; display row of text
  pla
  tax
  lda GameSet_ChoiceRows,x
  tax
  stx RowStartsAt
  stx ChoiceList
  ldy #1
WriteText:
  lda GameSet_ChoiceText,x
  beq EndText

  cmp #' ' ; note spaces in list
  bne :+
  pha
  inx
  txa
  dex
  sta ChoiceList,y
  inc NumChoices
  iny
  pla
: cmp #'_' ; change underscore to spaces
  bne :+
  lda #' '
:

  sta PPUDATA
  inx
  bne WriteText
EndText:
  bit PPUSTATUS
  lda #0
  sta PPUSCROLL
  sta PPUSCROLL
  jsr wait_vblank
  lda #OBJ_ON|BG_ON
  sta PPUMASK

; now let the user choose 
ChooseLoop:
  jsr ClearOAM

  ldx CurrentChoice
  lda ChoiceList,x
  tax
  ldy OamPtr
DrawLoop:
  lda #$1d
  sta OAM_TILE+(4*0),y
  lda #OAM_PRIORITY | 3
  sta OAM_ATTR+(4*0),y
  txa
  sub ChoiceList
  asl
  asl
  asl
  add #$2*8
  sta OAM_XPOS+(4*0),y

  lda SpritesYPos
  sub #1
  sta OAM_YPOS+(4*0),y
  iny
  iny
  iny
  iny
  inx
  lda GameSet_ChoiceText,x
  beq :+
  cmp #' '
  beq :+
  cmp #','
  beq :+
  bne DrawLoop
:

  jsr ReadJoy
  lda keydown
  ora keydown+1
  sta keydown

  lda keylast
  ora keylast+1
  sta keylast

  lda keydown
  and #KEY_LEFT
  beq :+
    lda keylast
    and #KEY_LEFT
    bne :+
    dec CurrentChoice
    bpl :+
      lda NumChoices
      sta CurrentChoice
  :

  lda keydown
  and #KEY_RIGHT
  beq :+
    lda keylast
    and #KEY_RIGHT
    bne :+
      inc CurrentChoice
      lda NumChoices
      cmp CurrentChoice
      bcs :+
        lda #0
        sta CurrentChoice
  :

  lda keydown
  and #KEY_A
  beq :+
    lda keylast
    and #KEY_A
    jeq PickedOption
  :

  lda keydown
  and #KEY_B
  beq :+
    lda keylast
    and #KEY_B
    bne :+
      jsr ClearOAM
      lda #VBLANK_NMI | NT_2000 | OBJ_8X8 | BG_0000 | OBJ_1000
      sta PPUCTRL
      clc
      rts
  :

  jsr wait_vblank
  jmp ChooseLoop

PickedOption:
  jsr ClearOAM
  jsr wait_vblank
  lda #0
  sta PPUMASK
  lda NameYPos
  jsr Mul32PPU1202

  ldx CurrentChoice
  lda ChoiceList,x
  tax
: lda GameSet_ChoiceText,x
  beq ExitPick
  cmp #' '
  beq ExitPick
  cmp #'_'
  bne :+
  lda #' '
: cmp #','
  beq ExitPick
  sta PPUDATA
  inx
  bne :--
ExitPick:

  jsr Put32Spaces

  lda #VBLANK_NMI | NT_2000 | OBJ_8X8 | BG_0000 | OBJ_1000
  sta PPUCTRL

  lda #0
  sta PPUSCROLL
  sta PPUSCROLL
  lda CurrentChoice
  sec
  rts

Put32Spaces:
  ldx #32
PutXSpaces:
  lda #' '
: sta PPUDATA
  dex
  bne :-
  rts

Mul32PPU1202:
  Mul32_PPU 1, #$20, #2
  rts
.endproc

.proc MenuNewGame
  jsr wait_vblank
  lda #0
  sta PPUMASK
  jsr ClearName
  jsr ClearOAM
  jsr wait_vblank

; warning: spaghetti ahead

PickPlayers:
  ; set selection according to enables
  lda PlayerEnabled+1
  asl
  ora PlayerEnabled+0
  tay
  dey
  lda #0
;  sta ScrollGameMode
  ldx #CHOICES_NUM_PLAYERS
  jsr GameSet_DisplayChoice
  jcc StartMainMenu
  ; set enables according to selection
  pha
  add #1
  pha
  lda #0
  sta PlayerEnabled+0
  sta PlayerEnabled+1
  pla
  lsr
  rol PlayerEnabled+0
  lsr
  rol PlayerEnabled+1
  pla
  ; decide what game modes to show
  cmp #2 ; 2 = both
  jeq Modes2P
Modes1P:
    lda #1
    ldx #CHOICES_1P_MODES
    ldy #0
    jsr GameSet_DisplayChoice
    bcc PickPlayers
.if 0
    beq PickDifficulty
ScrollMode:
    lda #2
    ldx #CHOICES_DIFFICULTY
    ldy GameDifficulty
    jsr GameSet_DisplayChoice
    bcc Modes1P

    ; start scroll mode
    lda #0
    sta LevelNumber
    lda #1
;    sta ScrollMode
;    lda #%00000110
;    sta ScrollGameMode
    jmp NewGame
.endif
PickDifficulty:
    lda #2
    ldx #CHOICES_DIFFICULTY
    ldy GameDifficulty
    jsr GameSet_DisplayChoice

    bcs :+ ; don't have to return to old menu
      lda PlayerEnabled
      add PlayerEnabled+1
      cmp #2
      jne Modes1P
      jmp Modes2P
    :
    sta GameDifficulty

OriginalPickLevel:
    lda #3
    sta JustPickedFromMenu
    ldx #CHOICES_LEVEL1
    ldy #0
    jsr GameSet_DisplayChoice
    bcc PickDifficulty

    cmp #8
    beq :+ ; more levels
    asl
    asl
    sta LevelNumber
    jmp NewGame
  :
OriginalPickLevel2:
    lda #3
    sta JustPickedFromMenu
    ldx #CHOICES_LEVEL2
    ldy #0
    jsr GameSet_DisplayChoice
    bcc OriginalPickLevel

    asl
    asl
    add #32
    sta LevelNumber
    jmp NewGame

Modes2P:
  lda #1
  ldx #CHOICES_2P_MODES
  ldy #0
  sty VersusNeed2Win
  sty VersusWins+0
  sty VersusWins+1
  sty IsScoreMode
  sty IsFightMode
  jsr GameSet_DisplayChoice
  jcc PickPlayers
  jeq PickDifficulty
  ; 1 = score, 2 = fight
   cmp #2 ; fight
   beq Fight

Score:
  lda #2
  sta IsScoreMode
  ldx #CHOICES_POWERUPS
  ldy #0
  jsr GameSet_DisplayChoice
  jcc Modes2P
  sta VersusPowerups

  lda #3
  sta JustPickedFromMenu
  ldx #CHOICES_SCORELEVELS
  ldy #0
  jsr GameSet_DisplayChoice
  jcc Score
  jmp HandleScoreLevelChoice

Fight:
  lda #2
  sta IsFightMode
  ldx #CHOICES_POWERUPS
  ldy #2
  jsr GameSet_DisplayChoice
  jcc Modes2P
  sta VersusPowerups

  lda #0
  sta LevelNumber
  jmp NewGame
.endproc

.proc HandleScoreLevelChoice
  cmp #8
  jeq StartEditorFromMenu
  tax
  lda ScoreLevels,x
  sta LevelNumber
  jmp NewGame  
ScoreLevels:
  .byt 2, 8, 13, 17, 20, 21, 26, 29
.endproc

.proc VersusScoreWinScreen
P1Score = ScoreDigits
P2Score = ScoreDigits + NumScoreDigits

  jsr init_sound
  jsr wait_vblank
  lda #0
  sta PPUMASK
  jsr ClearName

  lda #'2'
  sta 10

  ; determine who won
  ldx #0
: lda P1Score,x
  cmp P2Score,x
  bne SomeoneWon
  inx
  cpx #NumScoreDigits
  bne :-
  ; tie
  PositionPrintXY 0, 8,14,  "NOBODY"
  jmp PrintWins

SomeoneWon:
  bcc :+   ; if the different digit in score
    dec 10 ; in P1's score > P2's score
  :        ; then say player 1 won

  PositionPrintXY 0, 8,14,  "PLAYER "
  lda 10
  sta PPUDATA
PrintWins:
  jsr PutStringImmediate
  .byt " WINS!",0

  ; p1 scorer
  PositionPrintXY 0, 5,16,  "Scores: "
  ldx #NumScoreDigits-1
: lda ScoreDigits,x
  sta PPUDATA
  dex
  bpl :-

  ; break inbetween
  lda #' '
  sta PPUDATA

  ; p2 score
  ldx #NumScoreDigits*2-1
: lda ScoreDigits,x
  sta PPUDATA
  dex
  cpx #NumScoreDigits
  bpl :-

  lda LevelEditMode
  beq :+
    lda #0
    sta PPUSCROLL
    sta PPUSCROLL
    jsr init_sound
    jsr wait_vblank
    lda #OBJ_ON|BG_ON
    sta PPUMASK
    jsr WaitForKey
    jmp StartEditorNormal
  :

PlayAgainSelection:
  lda #0
  ldx #CHOICES_PLAYAGAINVS
  ldy #0
  jsr GameSet_DisplayChoice
  jcc StartMainMenu
  cmp #2
  jeq StartMainMenu

  cmp #1
  beq :+
    inc JustPickedFromMenu
    dec LevelNumber
    jmp NewGame
  :
  lda #1
  sta JustPickedFromMenu
  ldx #CHOICES_SCORELEVELS
  ldy #0
  jsr GameSet_DisplayChoice
  bcc PlayAgainSelection
  jmp HandleScoreLevelChoice
.endproc

.proc VersusFightWinScreen
  jsr init_sound
  jsr wait_vblank
  lda #0
  sta PPUMASK
  jsr ClearName

  lda #'2'
  sta 10

  ; determine who won
  lda PlayerEnabled+1
  bne :+
    dec 10
  :

  PositionPrintXY 0, 8,12,  "PLAYER "
  lda 10
  sta PPUDATA

  jsr PutStringImmediate
  .byt " WINS!",0

  PositionPrintXY 0, 2,16, "Press anything to continue"

  lda #0
  sta PPUSCROLL
  sta PPUSCROLL
  jsr wait_vblank
  lda #OBJ_ON|BG_ON
  sta PPUMASK

  ldx #30
: jsr wait_vblank
  dex
  bne :-

  jsr WaitForKey
  jmp StartMainMenu
.endproc
