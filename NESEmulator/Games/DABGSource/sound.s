; sound.s
; part of sound engine for LJ65, Concentration Room, and Thwaite

;;; Copyright (C) 2009-2011 Damian Yerrick
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

;.import periodTableLo, periodTableHi
;.importzp psg_sfx_state  ; a 32 byte buffer in zp?
;.import update_music, update_music_ch, music_playing, psg_sound_table
;.export init_sound, start_sound, update_sound, soundBSS

SNDCHN = $4015

; Ordinarily, the effect engine will move a pulse sound effect from
; $4000 to $4004 if $4004 is idle and $4000 is not, or if $4004 has
; less sfx data left to play than $4000.  Turn this off to force all
; pulse sfx to be played on $4000.
SQUARE_POOLING = 1

; As of 2011-03-10, a sound effect interrupts a musical instrument on
; the same channel only if the volume of the sfx is greater than that
; of the instrument.  Turn this off to force sound fx to interrupt
; the music whenever sfx data remains on that channel, even if the
; music is louder.
KEEP_MUSIC_IF_LOUDER = 1

;.segment "BSS"


psg_sfx_datalo = psg_sfx_state + 0
psg_sfx_datahi = psg_sfx_state + 1
psg_sfx_lastfreqhi = psg_sfx_state + 18
psg_sfx_remainlen = psg_sfx_state + 19
psg_sfx_rate = soundBSS + 3
psg_sfx_ratecd = soundBSS + 19

;.ifndef SOUND_NTSC_ONLY
;SOUND_NTSC_ONLY = 0
;.endif
;.if (!SOUND_NTSC_ONLY)
;.importzp tvSystem
;.endif

.segment "CODE"

;;
; Initializes all sound channels.
; Use it at the start of a program or as a "panic button" before
; entering a long stretch of code where you don't update_sound.
;
.proc init_sound
  lda #$0F
  sta SNDCHN
  lda #$30
  sta $4000
  sta $4004
  sta $400C
  sta psg_sfx_lastfreqhi+0
  sta psg_sfx_lastfreqhi+8
  sta psg_sfx_lastfreqhi+4
  lda #$80
  sta $4008
  lda #8
  sta $4001
  sta $4005
  lda #0
  sta $4003
  sta $4007
  sta $400F
  sta psg_sfx_remainlen+0
  sta psg_sfx_remainlen+4
  sta psg_sfx_remainlen+8
  sta psg_sfx_remainlen+12
  sta music_playing
  lda #64
  sta $4011
  rts
.endproc

;;
; Starts a sound effect.
; (Trashes $0000-$0004 and Y. (Originally trashed X but X is too important))
;
; @param A sound effect number (0-63)
;
.proc start_sound
snddatalo = 0
snddatahi = 1
sndchno = 2
sndlen = 3
sndrate = 4

  asl a
  asl a
  tay
  lda psg_sound_table,y
  sta snddatalo
  lda psg_sound_table+1,y
  sta snddatahi
  lda psg_sound_table+2,y
  and #$0C
  sta sndchno
  lda psg_sound_table+2,y
  lsr a
  lsr a
  lsr a
  lsr a
  sta sndrate
  
  lda psg_sound_table+3,y
  sta sndlen

  ; split up square wave sounds between $4000 and $4004
  .if ::SQUARE_POOLING
    lda sndchno
    bne not_ch0to4  ; if not ch 0, don't try moving it
      lda psg_sfx_remainlen+4
      cmp psg_sfx_remainlen
      bcs not_ch0to4
      lda #4
      sta sndchno
    not_ch0to4:
  .endif 

  ldy sndchno
  lda sndlen
  cmp psg_sfx_remainlen,y
  bcs ch_not_full
  rts
ch_not_full:

  lda snddatalo
  sta psg_sfx_datalo,y
  lda snddatahi
  sta psg_sfx_datahi,y
  lda sndlen
  sta psg_sfx_remainlen,y
  lda sndrate
  sta psg_sfx_rate,y
  lda #0
  sta psg_sfx_ratecd,y
  rts
.endproc


;;
; Updates sound effect channels.
;
.proc update_sound
  jsr update_music
  ldx #12
loop:
  jsr update_music_ch
  jsr update_one_ch
  dex
  dex
  dex
  dex
  bpl loop
  rts
.endproc

.proc update_one_ch

  ; At this point, the music engine should have left duty and volume
  ; in 2 and pitch in 3.
  lda psg_sfx_remainlen,x
  bne ch_not_done
  lda 2
  bne update_channel_hw

  ; Turn off the channel and force a reinit of the length counter.
  cpx #8
  beq not_triangle_kill
    lda #$30
  not_triangle_kill:
  sta $4000,x
  lda #$FF
  sta psg_sfx_lastfreqhi,x
  rts
ch_not_done:

  ; playback rate divider
  dec psg_sfx_ratecd,x
  bpl rate_divider_cancel
  lda psg_sfx_rate,x
  sta psg_sfx_ratecd,x

  ; fetch the instruction
  lda psg_sfx_datalo+1,x
  sta 1
  lda psg_sfx_datalo,x
  sta 0
  clc
  adc #2
  sta psg_sfx_datalo,x
  bcc :+
  inc psg_sfx_datahi,x
:
  ldy #0
  .if ::KEEP_MUSIC_IF_LOUDER
    lda 2
    and #$0F
    sta 4
    lda (0),y
    and #$0F
    
    ; At this point: A = sfx volume; 4 = musc volume
    cmp 4
    bcc music_was_louder
  .endif
  lda (0),y
  sta 2
  iny
  lda (0),y
  sta 3
music_was_louder:
  dec psg_sfx_remainlen,x

update_channel_hw:
  lda 2
  ora #$30
  cpx #12
  bne notnoise
  sta $400C
  lda 3
  sta $400E
rate_divider_cancel:
  rts

notnoise:
  sta $4000,x
  ldy 3
;.ifndef ::SOUND_NTSC_ONLY
;  lda tvSystem
;  beq :+
;  iny
;:
;.endif
  lda periodTableLo,y
  sta $4002,x
  lda periodTableHi,y
  cmp psg_sfx_lastfreqhi,x
  beq no_change_to_hi_period
  sta psg_sfx_lastfreqhi,x
  sta $4003,x
no_change_to_hi_period:

  rts
.endproc

periodTableLo:
  .byt $f1,$7f,$13,$ad,$4d,$f3,$9d,$4c,$00,$b8,$74,$34
  .byt $f8,$bf,$89,$56,$26,$f9,$ce,$a6,$80,$5c,$3a,$1a
  .byt $fb,$df,$c4,$ab,$93,$7c,$67,$52,$3f,$2d,$1c,$0c
  .byt $fd,$ef,$e1,$d5,$c9,$bd,$b3,$a9,$9f,$96,$8e,$86
  .byt $7e,$77,$70,$6a,$64,$5e,$59,$54,$4f,$4b,$46,$42
  .byt $3f,$3b,$38,$34,$31,$2f,$2c,$29,$27,$25,$23,$21
  .byt $1f,$1d,$1b,$1a,$18,$17,$15,$14
periodTableHi:
  .byt $07,$07,$07,$06,$06,$05,$05,$05,$05,$04,$04,$04
  .byt $03,$03,$03,$03,$03,$02,$02,$02,$02,$02,$02,$02
  .byt $01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01
  .byt $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  .byt $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  .byt $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  .byt $00,$00,$00,$00,$00,$00,$00,$00