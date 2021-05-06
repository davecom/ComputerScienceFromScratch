;
; NES controller reading code (non-DPCM-safe version)
; Copyright 2010 Damian Yerrick
;
; Copying and distribution of this file, with or without
; modification, are permitted in any medium without royalty provided
; the copyright notice and this notice are preserved in all source
; code copies.  This file is offered as-is, without any warranty.
;
.export read_pads, autorepeat
.importzp cur_keys, new_keys, das_keys, das_timer

JOY1      = $4016
JOY2      = $4017

; time until autorepeat starts making keypresses
DAS_DELAY = 15
; time between autorepeat keypresses
DAS_SPEED = 3

.segment "CODE"
.proc read_pads
thisRead = 0
firstRead = 2
lastFrameKeys = 4

  ; store the current keypress state to detect key-down later
  lda cur_keys
  sta lastFrameKeys
  lda cur_keys+1
  sta lastFrameKeys+1

  ; Read the joypads once.  We have no DPCM in the game and therefore
  ; no need to reread to detect bit deletions.
  jsr read_pads_once

  ldx #1
@fixupKeys:

  ; if the player's keys read out the same ways both times, update
  lda thisRead,x
  sta cur_keys,x
@dontUpdateGlitch:
  
  lda lastFrameKeys,x   ; A = keys that were down last frame
  eor #$FF              ; A = keys that were up last frame
  and cur_keys,x        ; A = keys down now and up last frame
  sta new_keys,x
  dex
  bpl @fixupKeys
  rts
.endproc

read_pads_once:
  lda #1
  sta 0
  sta 1
  sta JOY1
  lda #0
  sta JOY1
  loop:
    lda JOY1
    and #$03
    cmp #1
    rol 0
    lda JOY2
    and #$03
    cmp #1
    rol 1
    bcc loop
  rts

;;
; Computes autorepeat (delayed-auto-shift) on the gamepad for one
; player, ORing result into the player's new_keys.
; @param X which player to calculate autorepeat for
.proc autorepeat
  lda cur_keys,x
  beq no_das
  lda new_keys,x
  beq no_restart_das
  sta das_keys,x
  lda #DAS_DELAY
  sta das_timer,x
  bne no_das
no_restart_das:
  dec das_timer,x
  bne no_das
  lda #DAS_SPEED
  sta das_timer,x
  lda das_keys,x
  and cur_keys,x
  ora new_keys,x
  sta new_keys,x
no_das:
  rts
.endproc
