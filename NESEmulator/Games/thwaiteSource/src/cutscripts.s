; cutscripts.s
; Cut scene scripts for Thwaite

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

.export cut_scripts
.segment "RODATA"
cut_scripts:
  ; 0-7: perfect run scripts
  .addr perfect_sun_script, perfect_mon_script, perfect_tue_script
  .addr perfect_wed_script, perfect_thu_script, perfect_fri_script
  .addr perfect_sat_script, perfect_next_week_script
  ; 8-9: first after entering a given damage class
  .addr enter_poor_1, enter_poor_2
  ; 10-13: the investigation
  .addr discover_clue_1, discover_clue_2, discover_clue_3, 0
  ; 14: the ending
  .addr end_script
  ; 15: intro script for debugging
  .addr default_script

default_script:
  .byt "XYZN"  ; actors
;  .byt "NA new game has begun",10
;  .byt  "with actors $X, $Y,",10
;  .byt  "and $Z.",12
  .byt  "NMove the crosshair with the",10
  .byt   "Control Pad, and shoot a",10
  .byt   "firework with B or A.",12
  .byt  "NAnd watch your ammo!",0

perfect_sun_script:
  .byt "XYZN"
  .byt "ZOK, last night, what happen?",12
  .byt "XSomebody set up us the bomb.",12
  .byt "YI only wish we get signal.",12
  .byt "XI'm just glad none of those",10
  .byt  "miss¯es hit.",0

perfect_mon_script:
  .byt "XYZN"
  .byt "Y$C and $J are doing",10
  .byt  "a great job.",12
  .byt "XThey'd better. Because if",10
  .byt  "one of those lands on",10
  .byt  "my house...",12
  .byt "ZThen you can come live",10
  .byt  "with me!",0

perfect_tue_script:
  .byt "XYZN"
  .byt "ZIt's like we get a fireworks",10
  .byt  "show every night!  We don't",10
  .byt  "even have to wait for July.",12
  .byt "XCool it, $Z.",10
  .byt  "It's not fun and games.",0

perfect_wed_script:
  .byt "XYZN"
  .byt "ZLast night's show was even",10
  .byt  "more impressive!",12
  .byt "YYou know what, $Z?",10
  .byt  "I'm starting to think",10
  .byt  "you're right.",12
  .byt "YBecause if it weren't just",10
  .byt  "a show, something would",10
  .byt  "have been blown up by now.",12
  .byt "XI don't know, but it makes",10
  .byt  "me so nervous I can't sleep.",0

perfect_thu_script:
  .byt "XYZN"
  .byt "ZI think I'll go in and tell",10
  .byt  "them what a great show!",12
  .byt "YDon't bother.",10
  .byt  "It's probably scripted.",12
  .byt "YA machine aims the",10
  .byt  "shells on set paths.",12
  .byt "YAnd even if they did hit the",10
  .byt  "ground, which won't happen,",12
  .byt "YI bet they wouldn't",10
  .byt  "actually do anything.",12
  .byt "XKeep saying that and",10
  .byt  "there'll *certainly* be",10
  .byt  "a caTAStrophe.",0

perfect_fri_script:
  .byt "XYZN"
  .byt "XI st¯l think the threat is",10
  .byt  "real, but no one believes me.",12
  .byt "XEveryone else in the",10
  .byt  "v¯lage has bought into",10
  .byt  "$Y's theory",12
  .byt "Xthat it's all a show and",10
  .byt  "no one is in any danger.",12
  .byt "ZThey're fan-TAS-tic!",0

perfect_sat_script:
; Set perfect next week script the same as perfect saturday script
; for the compo edition.  The script for "next Sunday" is supposed
; to add a dummy SUN 01 level with no missiles for 60 seconds, but
; that didn't make the compo deadline.
.if 0
  .byt "XYZN"
  .byt "NIt's Saturday.",12
  .byt  "I st¯l need to write",12
  .byt  "the script for today.",0
.endif

perfect_next_week_script:
  .byt "XYZN"
  .byt "ZAww man, no more fireworks!",12
  .byt "XMy life is a steaming p¯e",10
  .byt  "of tech demo.",12
  .byt "NIt's a secret to everybody.",12
  .byt "NThank you for TASing Thwaite.",10
  .byt  "Feel free to play again",10
  .byt  "at full speed :P",0

; Displayed on the day after houses standing dip below 10
; for the first time.
enter_poor_1:
  .byt "XYZN"  ; actors
;  .byt "NEntered class 1 with actors",10
;  .byt  "$X, $Y, and $Z.",12
  .byt "XMy house!",0

; Displayed on the day after houses standing dip below 4
; for the first time.
enter_poor_2:
  .byt "XYZN"  ; actors
;  .byt "NEntered class 2 with actors",10
;  .byt  "$X, $Y, and $Z.",12
  .byt "XOur houses! Ruined!",12
  .byt "ZIf we can just hold",10
  .byt  "together, I know we can",10
  .byt  "get through this.",0

discover_clue_1:
  .byt "XYZN"  ; actors
  .byt "YI was looking in the",10
  .byt  "wreckage of $X's house",10
  .byt  "when I noticed something.",12
  .byt "YLook at this.",12
  .byt "ZIt's half melted.",10
  .byt  "What's that supposed",10
  .byt  "to be?",12
  .byt "YI'm not sure.",10
  .byt  "There's some writing on it,",10
  .byt  "but I can't make it out.",12
  .byt "XCould be a guitar pick.",10
  .byt  "Someone has a strange taste",10
  .byt  "in shrapnel.",0

discover_clue_2:
  .byt "XYZN"  ; actors
  .byt "YI found some wire in the",10
  .byt  "ruins of your house, $X.",12
  .byt "YIt looks sort of like",10
  .byt  "piano wire. Do you play",10
  .byt  "an instrument?",12
  .byt "XNo. Why do you ask?",12
  .byt "YIt might be from the miss¯e",10
  .byt  "that hit your house.",12
  .byt "ZI'd go look myself, but",10
  .byt  "I keep thinking about my",10
  .byt  "tummy.",0

discover_clue_3:
  .byt "XYZN"  ; actors
  .byt "YI got back from the police",10
  .byt  "station. I was checking out",10
  .byt  "the evidence,",12
  .byt "Yand I'm not positive it's",10
  .byt  "piano wire. It might be a",10
  .byt  "guitar string.",12
  .byt "XGuitar pick? Guitar string?",10
  .byt  "I bet $M is behind this!",12
  .byt "XI *knew* something was up",10
  .byt  "with him last Saturday night.",0

end_script:
  .byt "XYZM"  ; actors
  .byt "X$M! My house! You...",12
  .byt "MOK, man, I confess.",10
  .byt  "I did it.",12
  .byt "XShame on you!",10
  .byt  "You better never show your",10
  .byt  "face in this town again.",12
  .byt "ZCh¯l, $X. Hear him out.",12
  .byt "MI don't know what came",10
  .byt  "over me.",12
  .byt "MIt all started after",10
  .byt  "Videomation.",12
  .byt "MPeople drew things, but",10
  .byt  "they couldn't save them.",12
  .byt "MOnce Mario Paint came out,",10
  .byt  "people could make drawings",10
  .byt  "and music to last.",12
  .byt "MAfter that, creativity",10
  .byt  "exploded.",12
  .byt "ZExploded, yeah, like",10
  .byt  "the O in the title.",12
  .byt "MThere are things you don't",10
  .byt  "know about me.",12
  .byt "MI've been playing with",10
  .byt  "explosives for a long time.",12
  .byt "MThey're like music: they can",10
  .byt  "be used for good or bad.",12
  .byt "YAs Alfred Nobel found out",10
  .byt  "soon after he invented",10
  .byt  "dynamite.",12
  .byt "MGood things like blowing up",10
  .byt  "the west and east cliffs",10
  .byt  "for more living space.",12
  .byt "MAnd bad things like",10
  .byt  "what I ended up doing.",12
  .byt "MI'm sorry, man.",10
  .byt  "Let me make it up to you.",12
  .byt "MFirst I'll give the museum",10
  .byt  "a full set of my bootlegs.",12
  .byt "MThen I'll help rebu¯d all",10
  .byt  "your houses.",12
  .byt "MAnd about your wasted",10
  .byt  "fireworks:",10
  .byt  "I've got better ones.",12
  .byt "XI don't know...",12
  .byt "ZCome on, $X.",0

