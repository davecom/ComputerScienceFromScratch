.zeropage
r_seed: .res 1
.code

.proc ReadJoy
  lda keydown
  sta keylast
  lda keydown+1
  sta keylast+1
  lda #1
  sta keydown+0
  sta keydown+1
  sta JOY1
  lda #0
  sta JOY1
  : lda JOY1
    and #$03
    cmp #1
    rol keydown+0
    lda JOY2
    and #$03
    cmp #1
    rol keydown+1
    bcc :-
  rts
.endproc
.proc wait_vblank
  lda retraces
  loop:
    cmp retraces
    beq loop
  rts
.endproc

.proc PutHex
	pha
	pha
	lsr a
	lsr a
	lsr a
	lsr a
	tax
	lda hexdigits,x
	sta PPUDATA
	pla
	and #$0f
	tax
	lda hexdigits,x
	sta PPUDATA
	pla
	rts
hexdigits:	.byt "0123456789ABCDEF"
.endproc

.proc PutDecimal ; Prints with anywhere from 1 to 3 digits
   cmp #10 ; only one char
   bcs :+
     add #'0'    ; char is number+'0'
     sta PPUDATA
     rts
   :

   ; the hundreds digit if necessary
   cmp #200
   bcc LessThan200
   ldx #'2'
   stx PPUDATA
   sub #200
   jmp :+
LessThan200:
   cmp #100
   bcc :+
   ldx #'1'
   stx PPUDATA
   sub #100
:
   ldx #'0'    ; now calculate the tens digit
:  cmp #10
   bcc Finish
   sbc #10     ; carry will be set if this runs anyway
   inx
   jmp :-
Finish:
   stx PPUDATA ; display tens digit
   add #'0'
   sta PPUDATA ; display ones digit
   rts
.endproc
.proc ClearName
;Clear the nametable
  ldx #$20
  ldy #$00
  stx PPUADDR
  sty PPUADDR
  ldx #64
  ldy #4
  lda #' '
: sta PPUDATA
  inx
  bne :-
  dey
  bne :-
;Clear the attributes
  ldy #64
  lda #0
: dey
  bne :-
  sta PPUSCROLL
  sta PPUSCROLL
  rts
.endproc

.proc WaitForKey
: jsr ReadJoy
  lda keydown
  ora keydown+1
  beq :-
  lda keylast
  ora keylast+1
  bne :-
  rts
.endproc
.proc PutStringImmediate
	DPL = $02
	DPH = $03
	pla					; Get the low part of "return" address
                        ; (data start address)
	sta     DPL     
	pla 
	sta     DPH         ; Get the high part of "return" address
                        ; (data start address)
						; Note: actually we're pointing one short
PSINB:	ldy #1
	lda (DPL),y         ; Get the next string character
	inc DPL             ; update the pointer
	bne PSICHO          ; if not, we're pointing to next character
	inc DPH             ; account for page crossing
PSICHO:	ora #0          ; Set flags according to contents of 
                        ;    Accumulator
	beq     PSIX1       ; don't print the final NULL 
	sta PPUDATA         ; write it out
	jmp     PSINB       ; back around
PSIX1:	inc     DPL     ; 
	bne     PSIX2       ;
	inc     DPH         ; account for page crossing
PSIX2:	jmp     (DPL)   ; return to byte following final NULL
.endproc
.macro LoadPalette Addr
    lda #0
    sta PPUMASK
	lda #$3F
	sta PPUADDR
	lda #$00
	sta PPUADDR
	ldy #0
:	lda Addr,y
	sta PPUDATA
	iny
	cpy #16
	bne :-

	ldy #0
:	lda Addr,y
	sta PPUDATA
	iny
	cpy #16
	bne :-
.endmacro
.macro LoadNametable Addr
	lda #$20
	sta PPUADDR
	lda #$00
	sta PPUADDR

	lda #<Addr
	sta 0
	lda #>Addr
	sta 1
	ldx #4
	ldy #0
:	lda ($0), y
	sta PPUDATA
	iny
	bne :-
	inc 1
	dex
	bne :-
    lda #0
    sta PPUSCROLL
    sta PPUSCROLL
.endmacro
.proc rand_8    ; From some site
  lda   r_seed  ; get seed
  and   #$B8    ; mask non feedback bits
                ; for maximal length run with 8 bits we need
                ; taps at b7, b5, b4 and b3
  ldx   #$05    ; bit count (shift top 5 bits)
  ldy   #$00    ; clear feedback count
F_loop:
  asl   A       ; shift bit into carry
  bcc   bit_clr ; branch if bit = 0

  iny           ; increment feedback count (b0 is XOR all the	
                ; shifted bits from A)
bit_clr:
  dex           ; decrement count
  bne   F_loop  ; loop if not all done
no_clr:
  tya           ; copy feedback count
  lsr   A       ; bit 0 into Cb
  lda   r_seed  ; get seed back
  rol   A       ; rotate carry into byte
  sta   r_seed  ; save number as next seed
  rts           ; done
.endproc

.proc BitSelect
 .byt %00000001
 .byt %00000010
 .byt %00000100
 .byt %00001000
 .byt %00010000
 .byt %00100000
 .byt %01000000
 .byt %10000000
.endproc
.proc BitCancel
 .byt %11111110
 .byt %11111101
 .byt %11111011
 .byt %11110111
 .byt %11101111
 .byt %11011111
 .byt %10111111
 .byt %01111111
.endproc
