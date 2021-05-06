.proc RunBullets
  lda #0
  sta 0 ; current bullet counter

  tax   ; clear bullet map out first
: sta BulletMap+0,x
  sta BulletMap+8,x
  sta BulletMap+16,x
  sta BulletMap+24,x
  sta BulletMap+32,x
  sta BulletMap+40,x
  sta BulletMap+48,x
  sta BulletMap+56,x
  inx
  cpx #8
  bne :-

  ldy OamPtr

BulletLoop:
  ldx 0
  lda BulletF,x
  jpl SkipBullet

  lda BulletPXL,x
  add BulletVXL,x
  sta BulletPXL,x

  lda BulletPX,x
  adc BulletVX,x
  sta BulletPX,x

  lda BulletPYL,x
  add BulletVYL,x
  sta BulletPYL,x

  lda BulletPY,x
  adc BulletVY,x
  sta BulletPY,x

  sty TempVal+1
  ; write to bullet map: 00yyyxxx
  lda BulletPY,x
  lsr
  lsr
  and #%111000
  sta 1 ; Y is used for both versions
  lda BulletPX,x
  alr #%11100000
  sta 2
  lsr ; ALR already takes care of the first shift
  lsr
  lsr
  lsr
  ora 1
  tay
  lda #1
  sta BulletMap,y
  lda 2
  add #7
  and #%01110000
  cmp 2
  bne :+ ; most of the time the second write isn't needed, so avoid it when possible
  lsr ; / 32 pixels (right side)
  lsr
  lsr
  lsr
  ora 1
  tay
  lda #1
  sta BulletMap,y
:
; now do the bottom half to be extra sure
  lda BulletPY,x
  add #7
  lsr
  lsr
  and #%111000
  sta 1
  lda BulletPX,x
  add #4
  lsr ; / 32 pixels (bottom
  lsr
  lsr
  lsr
  lsr
  ora 1
  tay
  lda #1
  sta BulletMap,y

  ; check against level stuff
  lda BulletPX,x
  add #4
  lsr
  lsr
  lsr
  lsr
  sta 1
  lda BulletPY,x
  and #$f0
  ora 1
  tay
  lda LevelBuf,y
  cmp #METATILE_MIRROR
  bne NoBounce
  lda BulletVX,x
  eor #255
  add #1
  sta BulletVX,x
  lda BulletLife,x
  add #12
  sta BulletLife,x
  jsr rand_8_safe
  sta BulletVYL,x
  jsr rand_8_safe
  and #1
  sub #1
  sta BulletVY,x
NoBounce:

  lda BulletF,x
  and #15
  cmp #12 ; bomb
  bne :++
    lda BulletLife,x
    cmp #1
    bne :++

    lda 0
    pha
    lda BulletPX,x
    sta 0
    lda BulletPY,x
    sta 1
    lda #14
    ldy IsFightMode
    beq :+
      lda #30
    :
    jsr CreateExplosion
    pla
    sta 0
  :

  ldy TempVal+1

;  lda BulletF,x
;  and #15
;  cmp #11 ; FHBG block
;  bne :+
;    lda BulletVYL,x
;    add #$80
;    sta BulletVYL,x
;    bne :+
;    inc BulletVY,x
;  :

  lda BulletPY,x
  sta OAM_YPOS+(4*0),y
  lda #0
  sta OAM_ATTR+(4*0),y
  lda BulletF,x        ; if second biggest bit is off, it's an enemy bullet and set color accordingly
  and #%01000000
  bne :+
    lda #1
    sta OAM_ATTR+(4*0),y
: lda BulletF,x
  and #15
  ora #$30
  sta OAM_TILE+(4*0),y
  lda BulletPX,x
  sub ScrollX+1
  sta OAM_XPOS+(4*0),y

  dec BulletLife,x
  bne :+
    lda #0
    sta BulletF,x
  :

  .repeat 4
    iny
  .endrep
SkipBullet:
  inc 0
  lda 0
  cmp #BulletLen
  jne BulletLoop

  lda #0
  sta OAM_YPOS+(4*0),y
  sta OAM_ATTR+(4*0),y
  sta OAM_TILE+(4*0),y
  sta OAM_XPOS+(4*0),y

  sty OamPtr
  rts
.endproc

.proc FindFreeBulletY ; carry set = success?
  pha
  ldy #0
: lda BulletF,y
  bpl Found
  iny
  cpy #BulletLen
  bne :-
NotFound:
  pla
  clc
  rts
Found:
  lda #0
  sta BulletVY,y
  pla
  sec
  rts
.endproc
