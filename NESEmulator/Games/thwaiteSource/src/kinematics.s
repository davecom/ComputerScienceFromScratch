;
; acceleration/brake mechanics
; Copyright 2011 Damian Yerrick
;
; Copying and distribution of this file, with or without
; modification, are permitted in any medium without royalty provided
; the copyright notice and this notice are preserved in any source
; code copies.  This file is offered as-is, without any warranty.
;
.include "src/ram.h"

;; 
; Applies acceleration, braking, and speed limit.
; XY untouched.
.proc accelBrakeLimit
  lsr abl_keys
  bcc notAccelRight

  ; if traveling to left, brake instead
  lda abl_vel+1
  bmi notAccelRight
  
  ; Case 1: nonnegative velocity, accelerating positive
  clc
  lda abl_accelRate
  adc abl_vel
  sta abl_vel
  lda #0
  adc abl_vel+1
  sta abl_vel+1
  
  ; clamp maximum velocity
  lda abl_vel
  cmp abl_maxVel
  lda abl_vel+1
  sbc abl_maxVel+1
  bcc notOverPosLimit
  lda abl_maxVel
  sta abl_vel
  lda abl_maxVel+1
  sta abl_vel+1
notOverPosLimit:
  rts
notAccelRight:

  lsr abl_keys
  bcc notAccelLeft
  ; if traveling to right, brake instead
  lda abl_vel+1
  bmi isAccelLeft
  ora abl_vel
  bne notAccelLeft
isAccelLeft:

  ; Case 2: nonpositive velocity, accelerating negative
  ;sec  ; already guaranteed set from bcc statement above
  lda abl_accelRate
  eor #$FF
  adc abl_vel
  sta abl_vel
  lda #$FF
  adc abl_vel+1
  sta abl_vel+1

  ; clamp maximum velocity
  clc
  lda abl_maxVel
  adc abl_vel
  lda abl_maxVel+1
  adc abl_vel+1
  bcs notUnderNegLimit
  sec
  lda #0
  sbc abl_maxVel
  sta abl_vel
  lda #0
  sbc abl_maxVel+1
  sta abl_vel+1
notUnderNegLimit:
  rts
notAccelLeft:

  lda abl_vel+1
  bmi brakeNegVel
  
  ; Case 3: Velocity > 0 and brake
  sec
  lda abl_vel
  sbc abl_brakeRate
  sta abl_vel
  lda abl_vel+1
  sbc #0
  bcs notZeroVelocity
zeroVelocity:
  lda #0
  sta abl_vel
notZeroVelocity:
  sta abl_vel+1
  rts

brakeNegVel:
  ; Case 4: Velocity < 0 and brake
  clc
  lda abl_vel
  adc abl_brakeRate
  sta abl_vel
  lda abl_vel+1
  adc #0
  bcs zeroVelocity
  sta abl_vel+1
  rts
.endproc


