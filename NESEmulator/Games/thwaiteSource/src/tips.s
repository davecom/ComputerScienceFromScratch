; tips.s
; In-game play tips for Thwaite

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

.export levelTips, tipTexts

MISSILE_SYMBOL_TILE = $AC
HOUSE_SYMBOL_TILE = $7F
.segment "RODATA"
tipNova:
  .byt "¯legal miss¯e quantity",10,"you l¯ cheater",0

levelTips:
  .byt  5, 6, 7, 8, 9
  .byt 12,10, 0, 0, 0
  .byt  0, 0, 0, 0, 0
  .byt 14, 0, 0, 0, 0
  .byt  0, 0, 0, 0, 0
  .byt  0, 0, 0, 0, 0
  .byt  0, 0, 0, 0, 0
; Level $01's tip is replaced with tipTwoPlayer
; inside levels.s::loadLevel

tipTexts:
  .addr tipNone, tipGameOver, tipNiceJob, tipRebuildSilo, tipRebuildHouse
  .addr tipSun1, tipBothSilos, tipPathsCross, tipPayload, tipRebuilt
  .addr tipTopToBottom, tipTwoPlayer, tipWreckage, tipNova, tipBalloonFever1

;length"There is a limit of 28      ",10,"characters per line.        ",0
tipNone:
  .byt 0
tipGameOver:
  .byt "         GAME OVER",0
tipNiceJob:
  .byt "         Nice Job!",          10
  .byt "Left:  *",HOUSE_SYMBOL_TILE,"  *",MISSILE_SYMBOL_TILE,"   Bonus:    00",0
tipRebuildSilo:
  .byt "Repairs to the s¯o",          10,"are complete.",0
tipRebuildHouse:
  .byt "'s house has",                10,"been rebu¯t.",0
tipSun1:
  .byt "Shoot down incoming miss¯es", 10,"to defend the town!",0
tipBothSilos:
  .byt "Shoot from both s¯os:",       10,"press B or A.",0
tipTwoPlayer:
  .byt "Each player's s¯o has",       10,"its own stock of ABMs.",0
tipPathsCross:
  .byt "You can destroy two miss¯es", 10,"by aiming where paths cross.",0
tipPayload:
  .byt "Destroy balloons and MIRVs",  10,"before they drop a payload.",0
tipRebuilt:
  .byt "Survive unt¯ morning and",    10,"a house w¯l be rebu¯t.",0
tipTopToBottom:
  .byt "TIP: Start at the top",       10,"and progress to the bottom.",0
tipWreckage:
  .byt "Don't worry about miss¯es",   10,"that are aimed at wreckage.",0
tipBalloonFever1:
  .byt "When you say ",34,"that's so gay",34,",",10,"do you realize what you say?",0
