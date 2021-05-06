.export read_mouse, mouse_change_sensitivity
.exportzp cur_mbuttons, new_mbuttons
.segment "ZEROPAGE"
cur_mbuttons: .res 2
new_mbuttons: .res 2

.segment "CODE"
;;
; @param X player number
.proc read_mouse
  lda #1
  sta 1
  sta 2
  sta 3
:
  lda $4016,x
  lsr a
  rol 1
  bcc :-
  lda cur_mbuttons,x
  eor #$FF
  and 1
  sta new_mbuttons,x
  lda 1
  sta cur_mbuttons,x
:
  lda $4016,x
  lsr a
  rol 2
  bcc :-
:
  lda $4016,x
  lsr a
  rol 3
  bcc :-
  rts
.endproc

.proc mouse_change_sensitivity
  lda #1
  sta $4016
  lda $4016,x
  lda #0
  sta $4016
  rts
.endproc

