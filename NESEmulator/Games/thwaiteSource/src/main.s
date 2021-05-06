; main.s
; Main program for Thwaite

;;; Copyright (C) 2011 Damian Yerrick
;
;   This program is free software; you can redistribute it and/or
;   modify it under the terms of the GNU General Public License
;   as published by the Free Software Foundation; either version 3
;   of the License, or (at your option) any later version.
;
;   This program is distributed in the hope that it will be useful,
;   but WITHOUT ANY WARRANTY; without even the implied warranty of
;   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;   GNU General Public License for more details.
;
;   You should have received a copy of the GNU General Public License
;   along with this program; if not, write to 
;     Free Software Foundation, Inc., 59 Temple Place - Suite 330,
;     Boston, MA  02111-1307, USA.
;
;   Visit http://www.pineight.com/ for more information.

.include "src/nes.h"
.include "src/ram.h"
.p02
.segment "ZEROPAGE"
psg_sfx_state: .res 32
.export psg_sfx_state

LAWN_MOWER_NMI = 1

.if LAWN_MOWER_NMI
  nmis_old: .res 1  ; Using nmis from lawn mower
  nmis = $FF
.else
  nmis: .res 1
.endif
oamIndex: .res 1
debugHex1: .res 1
debugHex2: .res 1
cur_keys: .res 2
new_keys: .res 2
das_keys: .res 2
das_timer: .res 2
gameState: .res 1
numPlayers: .res 1
tvSystem: .res 1
mouseEnabled: .res 2

housesLeftClass: .res 1
investigationStep: .res 1

PROFILE_LIGHTGRAY = 0

; If this is nonzero, the game will start at 5 AM instead of 1 AM,
; allowing certain cut scene related things to be tested faster.
; Always set to 0 for release builds.
START_AT_5AM = 0

; When debugging villager selection, allow forcing the choice of one
; villager as the paranoid.
; Always set to 0 for release builds.
FORCE_PARANOID = 0

; When debugging cut scenes and shit, 
; Always set to 0 for release builds.
ONE_MISSILE_PER_LEVEL = 0

.segment "INESHDR"
  .byt "NES",$1A
  .byt 1  ; 16 KiB PRG ROM
  .byt 1  ; 8 KiB CHR ROM
  .byt 1  ; vertical mirroring; low mapper nibble: 0
  .byt 0  ; high mapper nibble: 0; no NES 2.0 features used

.segment "VECTORS"
  .addr nmi, reset, irq

.segment "CODE"

; we don't use irqs yet
.proc irq
  rti
.endproc

; tokumaru thinks only simple little single-screen puzzle games
; can get away with waiting for vblank
; http://nesdev.parodius.com/bbs/viewtopic.php?t=6229
; and he isn't a big fan of simple little single-screen puzzle games
; http://nesdev.parodius.com/bbs/viewtopic.php?t=5927
; http://nesdev.parodius.com/bbs/viewtopic.php?p=59105#59105
; but my philosophy is to do the simplest thing that could work
; http://c2.com/xp/DoTheSimplestThingThatCouldPossiblyWork.html
; and without a status bar, 'inc nmis' is the simplest thing because
; there isn't much of a penalty for missing a vblank
.proc nmi
  inc nmis
  rti
.endproc

.proc reset
  sei

  ; Acknowledge and disable interrupt sources during bootup
  ldx #0
  stx PPUCTRL    ; disable vblank NMI
  stx PPUMASK    ; disable rendering (and rendering-triggered mapper IRQ)
  lda #$40
  sta $4017      ; disable frame IRQ
  stx $4010      ; disable DPCM IRQ
  bit PPUSTATUS  ; ack vblank NMI
  bit $4015      ; ack DPCM IRQ
  cld            ; disable decimal mode to help generic 6502 debuggers
                 ; http://magweasel.com/2009/08/29/hidden-messagin/
  dex            ; set up the stack
  txs

  ; Wait for the PPU to warm up (part 1 of 2)
vwait1:
  bit PPUSTATUS
  bpl vwait1

  ; While waiting for the PPU to finish warming up, we have about
  ; 29000 cycles to burn without touching the PPU.  So we have time
  ; to initialize some of RAM to known values.
  ; Ordinarily the "new game" initializes everything that the game
  ; itself needs, so we'll just do zero page and shadow OAM.
  ldy #$00
  lda #$F0
  ldx #$00
clear_zp:
  sty $00,x
  sta OAM,x
  inx
  bne clear_zp
  ; the most basic sound engine possible
;  lda #$0F
;  sta $4015
  jsr init_sound
  
  lda #2
  sta practiceSide
  sta rand1
  sta rand2
  sta rand3
  sta rand0
  
  ; Wait for the PPU to warm up (part 2 of 2)
vwait2:
  bit PPUSTATUS
  bpl vwait2
  
  lda #VBLANK_NMI
  sta PPUCTRL

  jsr getTVSystem
  sta tvSystem
restart:
  jsr stop_music
  
  lda isPractice
  bne practice_skiptitle
  jsr titleScreen
  lda numPlayers
  cmp #3
  bcc practice_skiptitle
  sta isPractice
practice_skiptitle:
  lda #$C0
  sta debugHex1
  lda #$DE
  sta debugHex2

  jsr newGame
  lda isPractice
  beq practice_skippracticemenu
  jsr practice_menu
  lda isPractice
  beq restart
  bne practice_nocutscene
practice_skippracticemenu:

  .if ::FORCE_PARANOID
    lda #4
    sta actor_paranoid
    ldx #0
  .else
    ldx #1
  .endif
  jsr cut_choose_villagers
  
  lda #15  ; message from Pino before the game starts
  jsr load_cutscene
practice_nocutscene:

  jsr setupGameBG
  jsr clearAllSmoke
  jsr clearAllMissiles
  jsr clearExplosions
  jsr initVillagers
  lda #STATE_NEW_LEVEL
  sta gameState
  lda #0
  sta housesLeftClass
  sta investigationStep
  lda #4
  sta oamIndex

.if ::START_AT_5AM
  sta gameHour  ; DEBUG! testing the cut scene code
.endif
  
gameLoop:
  jsr incGameClock
  jsr read_pads
  jsr mouse_to_vel
  jsr update_sound

  lda new_keys
  and #KEY_START
  beq notPaused
  jsr pauseScreen
notPaused:
  ldx #0
  jsr moveCrosshairPlayerX
  inx
  jsr moveCrosshairPlayerX

.if ::PROFILE_LIGHTGRAY
  ldx #BG_ON|OBJ_ON|LIGHTGRAY|TINT_R
  stx PPUMASK
.endif  
  ldx #0
drawAllCrosshairs:
  jsr drawCrosshairPlayerX
  inx
  cpx numPlayers
  bcc drawAllCrosshairs
.if ::PROFILE_LIGHTGRAY
  ldx #BG_ON|OBJ_ON
  stx PPUMASK
.endif  
  
  jsr doStateAction
  
.if ::PROFILE_LIGHTGRAY
  ldx #BG_ON|OBJ_ON|LIGHTGRAY|TINT_G
  stx PPUMASK
.endif  

  jsr updateAllExplosions
  jsr updateMissiles
  jsr updateVillagers
  jsr updateSmoke
  jsr buildBGUpdate

  lda gameSubTenth
  cmp #1
  bne :+
  jsr testMissileThreats
:

.if ::PROFILE_LIGHTGRAY
  ldx #BG_ON|OBJ_ON
  stx PPUMASK
.endif  
  jsr clearRestOfOAM
  
  ; we're done preparing all updates
  lda nmis
:
  cmp nmis
  beq :-
  jsr blitBGUpdate

  lda #0
  sta $2003
  sta PPUSCROLL
  sta PPUSCROLL
  lda #>OAM
  sta $4014
  lda #VBLANK_NMI|BG_0000|OBJ_1000
  sta PPUCTRL
  lda #BG_ON|OBJ_ON
  sta PPUMASK

  lda gameState  
  cmp #STATE_INACTIVE
  beq :+
  jmp gameLoop
:
  jmp restart
.endproc

.proc clearRestOfOAM
  lda oamIndex
  and #$FC
  tax
  beq nothingToClear
  lda #$FF
xloop:
  sta OAM,x
  inx
  inx
  inx
  inx
  bne xloop
nothingToClear:
.if 0  ; whether using sprite 0
  lda #15
  sta OAM+1
  lda #%00100010
  sta OAM+2
  lda #S0_TRIGGER_X * 8
  sta OAM+3
  lda #S0_TRIGGER_Y * 8 - 1
.else
  lda #$FF
.endif
  sta OAM
  ldx #4
  stx oamIndex
  rts
.endproc

.proc pauseScreen
  ldy #4  ; leave room for sprite 0 in case tip is on screen
  ldx #0
buildPauseText:
  lda #111
  sta OAM,y
  lda pauseText,x
  sta OAM+1,y
  lda #%00000001
  sta OAM+2,y
  txa
  asl a
  asl a
  asl a
  asl a
  adc #92
  sta OAM+3,y
  iny
  iny
  iny
  iny
  inx
  cpx #5
  bcc buildPauseText
  sty oamIndex
  jsr clearRestOfOAM

loop:
  lda nmis
:
  cmp nmis
  beq :-
  sta nmis  ; in pause, NMI counting is frozen
  lda #0
  sta OAMADDR
  lda #>OAM
  sta OAM_DMA
  lda #VBLANK_NMI|OBJ_0000|BG_0000
  sta PPUCTRL
  lda #OBJ_ON|BG_ON
  sta PPUMASK
  jsr update_sound
  jsr read_pads
  lda new_keys
  and #KEY_SELECT
  beq notSelect
  lda isPractice
  beq notSelect
  lda #STATE_INACTIVE
  sta gameState
  rts
notSelect:
  lda new_keys
  and #KEY_START
  beq loop
  rts
.endproc

.segment "RODATA"
pauseText:
  .byt "PAUSE"

stateHandlers:
  .addr doStateInactive-1, doStateNewLevel-1, doStateActive-1
  .addr doStateLevelReward-1, doStateRebuildSilo-1, doStateCutscene-1
  .addr doStateRebuildHouse-1, doStateGameOver-1

.segment "CODE"
.proc doStateAction
  lda gameState
  asl a
  tax
  lda stateHandlers+1,x
  pha
  lda stateHandlers,x
  pha
  rts
.endproc

.proc doStateInactive
  rts
.endproc

.proc doStateNewLevel
  lda gameDay
  cmp #NUM_MADE_DAYS  ; the rest of the game isn't made yet
  bne notRestart
restart:
  lda #STATE_INACTIVE
  sta gameState
  rts
notRestart:
  asl a
  asl a
  adc gameDay
  adc gameHour
  jsr loadLevel
  .if ::ONE_MISSILE_PER_LEVEL
    lda #1
    sta enemyMissilesLeft
  .endif
  lda #BG_DIRTY_STATUS
  ora bgDirty
  sta bgDirty

  ; put missiles in silos
  lda #15
  sta siloMissilesLeft+1
  sta siloMissilesLeft
  
  ; but don't replenish destroyed silos
  lda housesStanding+2
  bne standing0
  sta siloMissilesLeft
  lda #20
  sta siloMissilesLeft+1
standing0:
  lda housesStanding+9
  bne standing1
  sta siloMissilesLeft+1
  lda #20
  sta siloMissilesLeft
standing1:

  lda #0
  sta buildingsDestroyedThisLevel
  lda #STATE_ACTIVE
  sta gameState

  ; choose song
  lda isPractice
  cmp #2
  bcs notPracticeMenu
  ldx gameHour
  lda hourlyMusic,x
  jsr init_music
notPracticeMenu:

  jmp initRandomTarget
.segment "RODATA"
hourlyMusic:
  .byt 0, 1, 2, 3, 4
.segment "CODE"
.endproc

; "Active" is the only state in which player missiles get fired.
.proc doStateActive
  ; end game if no silos are standing
  lda housesStanding+2
  ora housesStanding+9
  bne silosStillExist
  lda #STATE_GAMEOVER
  sta gameState
  jsr stop_music
  rts
silosStillExist:

  ; First player fires from left silo
  lda #KEY_B
  ldx numPlayers
  cpx #2
  bne :+
  lda #KEY_B|KEY_A
:
  ldx #0
  and new_keys,x
  beq notPressB
  lda crosshairXHi,x
  sta 2
  lda crosshairYHi,x
  sta 3
  ldx #0
  jsr firePlayerMissile
notPressB:

  ; Last player fires from right silo
  lda #KEY_A
  ldx numPlayers
  cpx #2
  bne :+
  lda #KEY_B|KEY_A
:
  dex
  and new_keys,x
  beq notPressA
  lda crosshairXHi,x
  sta 2
  lda crosshairYHi,x
  sta 3
  ldx #1
  jsr firePlayerMissile
notPressA:

  lda enemyMissilesLeft
  bne levelNotOver
  ldx #4
levelOverSearchLoop:
  lda missileYHi,x
  bne levelNotOver
  inx
  cpx #NUM_MISSILES
  bcc levelOverSearchLoop
  lda #STATE_LEVEL_REWARD
  sta gameState

levelNotOver:
  rts
.endproc

.proc doStateLevelReward
  lda #2
  cmp curTip
  beq alreadySet

  ; and add 10 * houses to the score
  jsr stop_music
  jsr countHousesLeft
  sty 0
  tya
  asl a
  asl a
  adc 0
  bne notHousesGameOver
housesGameOver:
  lda #STATE_GAMEOVER
  sta gameState
  rts
notHousesGameOver:
  asl a
  adc siloMissilesLeft
  adc siloMissilesLeft+1
  sta 1
  jsr addScore
  jsr villagersGoHome
  jmp buildLevelRewardBar

alreadySet:
  lda tipTimeLeft
  bne notYet

  jsr warpVillagersToTargets
  lda #STATE_REBUILDING_SILO
  ldy isPractice
  beq notPractice
  lda #STATE_INACTIVE
notPractice:
  sta gameState
notYet:
  lda tipTimeLeft

  ; Change music once 47.0 tenths are left
  eor #47
  ora gameSubTenth
  bne notMusic
  lda #MUSIC_CLEARED_LEVEL
  jsr init_music
notMusic:
  rts
.endproc

.proc doStateRebuildSilo

  ; 2011-05-03: The NPCs have time to repair both silos
  ; during the daytime cut scene.
  ; $04 (5 AM) means next screen will be the daytime cut scene
  lda gameHour
  cmp #$04
  beq repairEvenIfHouseDestroyed

  ; In any other hour, if any houses were destroyed this level,
  ; don't repair the silo.
  lda buildingsDestroyedThisLevel
  bne stateIsDone

repairEvenIfHouseDestroyed:
  
  ; If the tip is being displayed, don't repair another one.
  lda #3
  cmp curTip
  beq alreadySet
  ldx housesStanding+2
  bne leftIsStillStanding
  inc housesStanding+2
  bne finishStateSetup

leftIsStillStanding:
  ldx housesStanding+9
  bne stateIsDone
  inc housesStanding+9
finishStateSetup:
  sta curTip
  lda #40
  sta tipTimeLeft
  lda #BG_DIRTY_TIP|BG_DIRTY_HOUSES
  ora bgDirty
  sta bgDirty

alreadySet:
  lda tipTimeLeft
  bne notYet
stateIsDone:
  lda #STATE_CUTSCENE
  sta gameState
notYet:
  rts
.endproc

.proc doStateCutscene
  ; and go to the next level
  inc gameHour
  lda gameHour
  cmp #5
  bcc readyForNextLevel

  ; Check if we're still on the perfect run track
  lda gameDay
  ldy firstDestroyedHouse
  bmi haveCutsceneNumberInA

  ; Count the number of buildings left, then decide on a level
  cpy actor_paranoid
  beq no_pick_new_actors
  sty actor_paranoid
  ldx #0
  jsr cut_choose_villagers
  
no_pick_new_actors:
  lda gameDay
  cmp #NUM_MADE_DAYS-1
  bne notLastDay
  lda #14
  bne haveCutsceneNumberInA
notLastDay:
  jsr countHousesLeft
  sty 0
  ldx #2
  cpy #4
  bcc :+
  dex
  cpy #10
  bcc :+
  dex
:

  ; At thois point, x=0 means perfect, x=1 means 4-9 left
  ; and x=2 means 1-3 left.
  cpx housesLeftClass
  ; At this point, P is set for old - new.  If old <= new, skip to
  ; advancePlot
  beq advancePlot
  bcc advancePlot
  stx housesLeftClass
  txa
  adc #6  ; 8 and 9, and carry is 1
  bne haveCutsceneNumberInA
advancePlot:

  ; Advance the investigation forward one step
  lda investigationStep
  inc investigationStep
  cmp #2
  bcc :+
  lda #2
  clc
:
  adc #10

haveCutsceneNumberInA:
  jsr load_cutscene
  
  ; The cutscene code trashes gameState, the missile states, and the
  ; background, so make sure those are set sanely before continuing.
  jsr clearAllMissiles
  lda #STATE_REBUILDING_HOUSE
  sta gameState
  jmp setupGameBG

readyForNextLevel:
  lda #STATE_NEW_LEVEL
  sta gameState
  rts
.endproc  

.proc doStateRebuildHouse
  lda #4
  cmp curTip
  beq alreadySet

  ; so now the level is at the end of the day.
.if ::START_AT_5AM
  lda #4
.else
  lda #0
.endif
  sta gameHour
  inc gameDay
  lda #BG_DIRTY_TIP|BG_DIRTY_HOUSES
  ora bgDirty
  sta bgDirty

  jsr findRandomDestroyedHouse
  cpy #NUM_BUILDINGS
  bcs nothingToRebuild

  ; rebuild house #Y
  lda #1
  sta housesStanding,y
  lda #4
  sta curTip
  lda #40
  sta tipTimeLeft
  lda #BG_DIRTY_HOUSES|BG_DIRTY_TIP
  ora bgDirty
  sta bgDirty
  jmp buildHouseRebuiltBar
  
alreadySet:
  lda tipTimeLeft
  bne notYet
nothingToRebuild:
  lda #STATE_NEW_LEVEL
  sta gameState
notYet:
  rts
.endproc

.proc doStateGameOver
  lda #1
  cmp curTip
  beq tipAlreadySet
  sta curTip
  lda #50
  sta tipTimeLeft
  lda #BG_DIRTY_TIP
  ora bgDirty
  sta bgDirty
  rts
tipAlreadySet:
  lda tipTimeLeft
  bne :+
  lda #STATE_INACTIVE
  sta gameState
:
  rts
.endproc


