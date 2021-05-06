.proc ClearOAM
  lda #-16
  ldx #0
: sta OAM_YPOS,x
  inx
  inx
  inx
  inx
  bne :-
  rts
.endproc

;http://codebase64.org/doku.php?id=base:two_very_fast_16bit_pseudo_random_generators_as_lfsr
.proc huge_rand
  jsr rand64k       ;Factors of 65535: 3 5 17 257
  jsr rand32k       ;Factors of 32767: 7 31 151 are independent and can be combined
;  lda random1+1        ;can be left out 
;  eor random2+1        ;if you dont use
;  tay                  ;y as suggested
  lda random1           ;mix up lowbytes of random1
  eor random2           ;and random2 to combine both 
  rts
.endproc
 
;periode with 65535
;10+12+13+15
.proc rand64k
  lda random1+1
  asl
  asl
  eor random1+1
  asl
  eor random1+1
  asl
  asl
  eor random1+1
  asl
  rol random1         ;shift this left, "random" bit comes from low
  rol random1+1
  rts
.endproc
 
;periode with 32767
;13+14
.proc rand32k
  lda random2+1
  asl
  eor random2+1
  asl
  asl
  ror random2         ;shift this right, random bit comes from high - nicer when eor with random1
  rol random2+1
  rts
.endproc

.if 0
.proc CopyFromCHR ; A: <address, X: >address - outputs to $500
  stx PPUADDR
  sta PPUADDR
  lda PPUDATA ; dummy read

  ldy #0      ; prepare destination address (always $500)
  sty 0
  lda #5
  sta 1

  ldx PPUDATA ; read size low
  lda PPUDATA ; read size high
  sta 2
  inc 2

Loop:
  lda PPUDATA
  sta (0),y
  iny
  bne :+      ; fix destination address if we roll over
    inc 1
  :
  dex
  cpx #-1     ; fix size if we roll over
  bne :+
    lda 2
    beq Exit
    dec 2
    bmi Exit
  :
  bne Loop
Exit:
  rts
.endproc
.endif
