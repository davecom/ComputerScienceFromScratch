; version 1

; Names are based on
; http://nesdevwiki.org/index.php/NES_PPU
; http://nesdevwiki.org/index.php/2A03

; PPU registers
PPUCTRL     = $2000
NT_2000     = %00000000
NT_2400     = %00000001
NT_2800     = %00000010
NT_2C00     = %00000011
MSB_XSCROLL = %00000001
MSB_YSCROLL = %00000010
VRAM_RIGHT  = %00000000 ; writes/reads to PPUDATA increment PPUADDR
VRAM_ACROSS = %00000000
VRAM_DOWN   = %00000100 ; writes/reads to PPUDATA add 32 to PPUADDR
OBJ_0000    = %00000000
OBJ_1000    = %00001000
OBJ_8X8     = %00000000
OBJ_8X16    = %00100000
BG_0000     = %00000000
BG_1000     = %00010000
VBLANK_NMI  = %10000000

PPUMASK     = $2001
LIGHTGRAY   = %00000001
BG_OFF      = %00000000
BG_CLIP     = %00001000
BG_ON       = %00001010
OBJ_OFF     = %00000000
OBJ_CLIP    = %00010000
OBJ_ON      = %00010100
INT_RED     = %00100000
INT_GREEN   = %01000000
INT_BLUE    = %10000000

PPUSTATUS      = $2002
SPR_OVERFLOW   = %00100000
SPR_HIT        = %01000000
VBLANK_STARTED = %10000000

OAMADDR   = $2003
OAMDATA   = $2004
PPUSCROLL = $2005
PPUADDR   = $2006
PPUDATA   = $2007

; Pulse channel registers
SQ1_VOL   = $4000
SQ1_SWEEP = $4001
SQ1_LO    = $4002
SQ1_HI    = $4003
SQ2_VOL   = $4004
SQ2_SWEEP = $4005
SQ2_LO    = $4006
SQ2_HI    = $4007

SQ_1_8      = $00  ; 1/8 duty (sounds sharp)
SQ_1_4      = $40  ; 1/4 duty (sounds rich)
SQ_1_2      = $80  ; 1/2 duty (sounds hollow)
SQ_3_4      = $C0  ; 3/4 duty (sounds like 1/4)
SQ_HOLD     = $20  ; halt length counter
SQ_CONSTVOL = $10  ; 0: envelope decays from 15 to 0; 1: constant volume
SWEEP_OFF   = $08

; Triangle channel registers
TRI_LINEAR = $4008
TRI_LO     = $400A
TRI_HI     = $400B

TRI_HOLD = $80

; Noise channel registers
NOISE_VOL = $400C
NOISE_LO  = $400E
NOISE_HI  = $400F

NOISE_HOLD = SQ_HOLD
NOISE_CONSTVOL = SQ_CONSTVOL
NOISE_LOOP = $80

; DPCM registers
DMC_FREQ  = $4010
DMC_RAW   = $4011
DMC_START = $4012
DMC_LEN   = $4013

; OAM DMA unit register
; Writing $xx here causes 256 bytes to be copied from $xx00-$xxFF
; to OAMDATA
OAM_DMA = $4014
OAMDMA  = $4014

; Sound channel control and status register
SND_CHN       = $4015
CH_SQ1   = %00000001
CH_SQ2   = %00000010
CH_TRI   = %00000100
CH_NOISE = %00001000
CH_ALL   = %00001111  ; all tone generators, not dpcm
CH_DPCM  = %00010000

JOY1 = $4016
JOY2 = $4017
APUCTRL       = $4017
APUCTRL_5STEP = $80
APUCTRL_NOIRQ = $40

OAM_COLOR_0 =  %00000000
OAM_COLOR_1 =  %00000001
OAM_COLOR_2 =  %00000010
OAM_COLOR_3 =  %00000011
OAM_PRIORITY = %00100000
OAM_XFLIP    = %01000000
OAM_YFLIP    = %10000000

OAM_YPOS = $200
OAM_TILE = $201
OAM_ATTR = $202
OAM_XPOS = $203

KEY_RIGHT = %00000001
KEY_LEFT  = %00000010
KEY_DOWN  = %00000100
KEY_UP    = %00001000
KEY_START = %00010000
KEY_SELECT= %00100000
KEY_B     = %01000000
KEY_A     = %10000000

; and now macros ----------------------------------------------------------

.feature leading_dot_in_identifiers
.macpack generic
.macpack longbranch

; Meant to be an easy replacement for .repeat and .endrepeat
; when you're trying to save space. Uses a zeropage memory location
; instead of a register as a loop counter so as not to disturb any
; registers.
; Times - Number of times to loop ( may be a memory location )
; Free  - Free zeropage memory location to use
.macro .dj_loop Times, Free
  .scope
    DJ_Counter = Free
    lda Times
    sta Free
DJ_Label:
.endmacro
.macro .end_djl
  NextIndex:
    dec DJ_Counter
    jne DJ_Label
  .endscope
.endmacro

; These use increments (useless)
.macro .ij_loop Times, Free
  .scope
    DJ_Times = Times
    DJ_Counter = Free
    lda #0
    sta Free
DJ_Label:
.endmacro
.macro .end_ijl
  NextIndex:
    inc DJ_Counter
    lda DJ_Counter
    cmp Times
    jne DJ_Label
  .endscope
.endmacro

; swap using X
.macro swapx mema, memb
  ldx mema
  lda memb
  stx memb
  sta mema
.endmacro
; swap using Y
.macro swapy mema, memb
  ldy mema
  lda memb
  sty memb
  sta mema
.endmacro
; swap using just A + stack
.macro swapa mema, memb
  lda mema
  pha
  lda memb
  sta mema
  pla
  sta memb
.endmacro

; Imitation of z80's djnz opcode.
; Can be on A, X, Y, or a zeropage memory location
; Label - Label to jump to
; Reg   - Counter register to use: A,X,Y or memory location
.macro djnz Label, Reg
  .if (.match({Reg}, a))
    sub #1
  .elseif (.match({Reg}, x))
    dex
  .elseif (.match({Reg}, y))
    dey
  .else
    dec var
  .endif
  bne Label
.endmacro


; Working with X,Y is much more fun than working with PPU addresses
; give it an X and Y position, as well as a nametable number (0-3),
; and if you want to save the address to a 16-bit zeropage address
; ( big endian ) you can give an additional argument.
; NT - Nametable number (0-3)
; PX - X position in tiles
; PY - Y position in tiles
; Var - Variable to store address in (optional)
.macro PositionXY NT, PX, PY, Var
	.scope
		t0 = $2000 + (NT * 1024)	; Nametable data starts at $2000 
		t1 = PX                 ; and each nametable is 1024 bytes in size
		t2 = PY * 32			; Nametable rows are 32 bytes large
		t3 = t0 + t1 + t2
        .ifblank Var        ; Are we going to be writing this directly to PPUADDR?
          lda #>t3
          sta PPUADDR
          lda #<t3
          sta PPUADDR
        .else               ; Are we going to be storing this to a pointer in zeropage instead?
          lda #>t3
          sta Var+0
          lda #<t3
          sta Var+1
        .endif
	.endscope
.endmacro

.macro .ppuxy NT, PX, PY
	.scope
		t0 = $2000 + (NT * 1024)	; Nametable data starts at $2000 
		t1 = PX                 ; and each nametable is 1024 bytes in size
		t2 = PY * 32			; Nametable rows are 32 bytes large
		t3 = t0 + t1 + t2
        .byt >t3
        .byt <t3
	.endscope
.endmacro

.macro .nyb InpA, InpB		; Makes a .byt storing two 4 bit values
	.byt ( InpA<<4 ) | InpB
.endmacro

.macro .raddr This          ; like .addr but for making "RTS trick" tables with
 .addr This-1
.endmacro

.macro plapha               ; Sometimes I save a value on the stack but want to read it later
    pla                     ;  while leaving it still on the stack for restoring later.
    pha
.endmacro

.macro btr Num, Here
.if .match({Num},"eq")
	beq Here
.elseif .match({Num},"ne")
	bne Here
.elseif .match({Num},"cs")
	bcs Here
.elseif .match({Num},"cc")
	bcc Here
.elseif .match({Num},"vs")
	bvs Here
.elseif .match({Num},"vc")
	bvc Here
.elseif .match({Num},"pl")
	bpl Here
.elseif .match({Num},"mi")
	bmi Here
.endif
.endmacro
.macro bfl Num, Here
.if .match({Num},"eq")
	beq Here
.elseif .match({Num},"ne")
	bne Here
.elseif .match({Num},"cs")
	bcs Here
.elseif .match({Num},"cc")
	bcc Here
.elseif .match({Num},"vs")
	bvs Here
.elseif .match({Num},"vc")
	bvc Here
.elseif .match({Num},"pl")
	bpl Here
.elseif .match({Num},"mi")
	bmi Here
.endif
.endmacro

.macro addx num
  txa
  axs #-num
.endmacro

.macro subx num
  txa
  axs #num
.endmacro

.macro unpack low,high
  pha
  and #15
  sta low
  pla
  lsr
  lsr
  lsr
  lsr
  sta high
.endmacro

.macro asl4
  asl
  asl
  asl
  asl
.endmacro

.macro lsr4
  lsr
  lsr
  lsr
  lsr
.endmacro

.macro inw mem
  inc mem+0
  bne :+
  inc mem+1
:
.endmacro

.macro dew mem
  lda mem+0
  bne :+
  dec mem+1
: dec mem+0
.endmacro

.ifp02
.macro axs Value
  sub Value
  tax
.endmacro
.macro alr Value
  and Value
  lsr
.endmacro
.macro lax Value
  lda Value
  ldx Value
.endmacro
.macro isc Addr, Why
  stx TempX
  pha
  tya
  tax
  inc Addr,x
  pla
  ldx TempX
.endmacro
.macro dcp Addr, Why
  stx TempX
  pha
  tya
  tax
  dec Addr,x
  pla
  ldx TempX
.endmacro
.endif

.macro Mul32_ZP low, high, highbits
  pha
  .ifblank highbits
  lda #0
  .elseif
  lda highbits>>2
  .endif
  sta high
  pla
  asl ; *2
  asl ; *4
  asl ; *8
  asl ; *16, finally needing high bits
  rol high
  asl
  rol high
  sta low
.endmacro

.macro Mul32_PPU temp, highbits, xpos
  pha
  lda highbits>>2
  sta temp
  pla
  asl ; *2
  asl ; *4
  asl ; *8
  asl ; *16, finally needing top bits
  rol temp
  asl
  rol temp
  add xpos
  pha
  lda temp
  sta PPUADDR
  pla
  sta PPUADDR
.endmacro
