# NESEmulator/cpu.py
# From Fun Computer Science Projects in Python
# Copyright 2021 David Kopec
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
# http:#www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
from enum import Enum
from dataclasses import dataclass
from array import array
from NESEmulator.ppu import PPU, SPR_RAM_SIZE
from NESEmulator.rom import ROM

MemMode = Enum("MemMode", "DUMMY ABSOLUTE ABSOLUTE_X ABSOLUTE_Y ACCUMULATOR IMMEDIATE "
                          "IMPLIED INDEXED_INDIRECT INDIRECT INDIRECT_INDEXED RELATIVE "
                          "ZEROPAGE ZEROPAGE_X ZEROPAGE_Y")


InstructionType = Enum("InstructionType", "ADC AHX ALR ANC AND ARR ASL AXS BCC BCS BEQ BIT "
                                          "BMI BNE BPL BRK BVC BVS CLC CLD CLI CLV CMP CPX "
                                          "CPY DCP DEC DEX DEY EOR INC INX INY ISC JMP JSR "
                                          "KIL LAS LAX LDA LDX LDY LSR NOP ORA PHA PHP PLA "
                                          "PLP RLA ROL ROR RRA RTI RTS SAX SBC SEC SED SEI "
                                          "SHX SHY SLO SRE STA STX STY TAS TAX TAY TSX TXA "
                                          "TXS TYA XAA")


@dataclass(frozen=True)
class Instruction:
    type: InstructionType
    mode: MemMode
    length: int
    ticks: int
    page_ticks: int


@dataclass
class Joypad:
    strobe: bool = False
    read_count: int = 0
    a: bool = False
    b: bool = False
    select: bool = False
    start: bool = False
    up: bool = False
    down: bool = False
    left: bool = False
    right: bool = False


Instructions = [
    Instruction(InstructionType.BRK, MemMode.IMPLIED, 1, 7, 0), 			# 00
    Instruction(InstructionType.ORA, MemMode.INDEXED_INDIRECT, 2, 6, 0), 	# 01
    Instruction(InstructionType.KIL, MemMode.IMPLIED, 0, 2, 0), 			# 02
    Instruction(InstructionType.SLO, MemMode.INDEXED_INDIRECT, 0, 8, 0), 	# 03
    Instruction(InstructionType.NOP, MemMode.ZEROPAGE, 2, 3, 0), 			# 04
    Instruction(InstructionType.ORA, MemMode.ZEROPAGE, 2, 3, 0), 			# 05
    Instruction(InstructionType.ASL, MemMode.ZEROPAGE, 2, 5, 0), 			# 06
    Instruction(InstructionType.SLO, MemMode.ZEROPAGE, 0, 5, 0), 			# 07
    Instruction(InstructionType.PHP, MemMode.IMPLIED, 1, 3, 0), 			# 08
    Instruction(InstructionType.ORA, MemMode.IMMEDIATE, 2, 2, 0), 			# 09
    Instruction(InstructionType.ASL, MemMode.ACCUMULATOR, 1, 2, 0), 		# 0a
    Instruction(InstructionType.ANC, MemMode.IMMEDIATE, 0, 2, 0), 			# 0b
    Instruction(InstructionType.NOP, MemMode.ABSOLUTE, 3, 4, 0), 			# 0c
    Instruction(InstructionType.ORA, MemMode.ABSOLUTE, 3, 4, 0), 			# 0d
    Instruction(InstructionType.ASL, MemMode.ABSOLUTE, 3, 6, 0), 			# 0e
    Instruction(InstructionType.SLO, MemMode.ABSOLUTE, 0, 6, 0), 			# 0f
    Instruction(InstructionType.BPL, MemMode.RELATIVE, 2, 2, 1), 			# 10
    Instruction(InstructionType.ORA, MemMode.INDIRECT_INDEXED, 2, 5, 1), 	# 11
    Instruction(InstructionType.KIL, MemMode.IMPLIED, 0, 2, 0), 			# 12
    Instruction(InstructionType.SLO, MemMode.INDIRECT_INDEXED, 0, 8, 0), 	# 13
    Instruction(InstructionType.NOP, MemMode.ZEROPAGE_X, 2, 4, 0), 			# 14
    Instruction(InstructionType.ORA, MemMode.ZEROPAGE_X, 2, 4, 0), 			# 15
    Instruction(InstructionType.ASL, MemMode.ZEROPAGE_X, 2, 6, 0), 			# 16
    Instruction(InstructionType.SLO, MemMode.ZEROPAGE_X, 0, 6, 0), 			# 17
    Instruction(InstructionType.CLC, MemMode.IMPLIED, 1, 2, 0), 			# 18
    Instruction(InstructionType.ORA, MemMode.ABSOLUTE_Y, 3, 4, 1), 			# 19
    Instruction(InstructionType.NOP, MemMode.IMPLIED, 1, 2, 0), 			# 1a
    Instruction(InstructionType.SLO, MemMode.ABSOLUTE_Y, 0, 7, 0), 			# 1b
    Instruction(InstructionType.NOP, MemMode.ABSOLUTE_X, 3, 4, 1), 			# 1c
    Instruction(InstructionType.ORA, MemMode.ABSOLUTE_X, 3, 4, 1), 			# 1d
    Instruction(InstructionType.ASL, MemMode.ABSOLUTE_X, 3, 7, 0), 			# 1e
    Instruction(InstructionType.SLO, MemMode.ABSOLUTE_X, 0, 7, 0), 			# 1f
    Instruction(InstructionType.JSR, MemMode.ABSOLUTE, 3, 6, 0), 			# 20
    Instruction(InstructionType.AND, MemMode.INDEXED_INDIRECT, 2, 6, 0), 	# 21
    Instruction(InstructionType.KIL, MemMode.IMPLIED, 0, 2, 0), 			# 22
    Instruction(InstructionType.RLA, MemMode.INDEXED_INDIRECT, 0, 8, 0), 	# 23
    Instruction(InstructionType.BIT, MemMode.ZEROPAGE, 2, 3, 0), 			# 24
    Instruction(InstructionType.AND, MemMode.ZEROPAGE, 2, 3, 0), 			# 25
    Instruction(InstructionType.ROL, MemMode.ZEROPAGE, 2, 5, 0), 			# 26
    Instruction(InstructionType.RLA, MemMode.ZEROPAGE, 0, 5, 0), 			# 27
    Instruction(InstructionType.PLP, MemMode.IMPLIED, 1, 4, 0), 			# 28
    Instruction(InstructionType.AND, MemMode.IMMEDIATE, 2, 2, 0), 			# 29
    Instruction(InstructionType.ROL, MemMode.ACCUMULATOR, 1, 2, 0),         # 2a
    Instruction(InstructionType.ANC, MemMode.IMMEDIATE, 0, 2, 0), 			# 2b
    Instruction(InstructionType.BIT, MemMode.ABSOLUTE, 3, 4, 0), 			# 2c
    Instruction(InstructionType.AND, MemMode.ABSOLUTE, 3, 4, 0), 			# 2d
    Instruction(InstructionType.ROL, MemMode.ABSOLUTE, 3, 6, 0), 			# 2e
    Instruction(InstructionType.RLA, MemMode.ABSOLUTE, 0, 6, 0), 			# 2f
    Instruction(InstructionType.BMI, MemMode.RELATIVE, 2, 2, 1), 			# 30
    Instruction(InstructionType.AND, MemMode.INDIRECT_INDEXED, 2, 5, 1), 	# 31
    Instruction(InstructionType.KIL, MemMode.IMPLIED, 0, 2, 0), 			# 32
    Instruction(InstructionType.RLA, MemMode.INDIRECT_INDEXED, 0, 8, 0), 	# 33
    Instruction(InstructionType.NOP, MemMode.ZEROPAGE_X, 2, 4, 0), 			# 34
    Instruction(InstructionType.AND, MemMode.ZEROPAGE_X, 2, 4, 0), 			# 35
    Instruction(InstructionType.ROL, MemMode.ZEROPAGE_X, 2, 6, 0), 			# 36
    Instruction(InstructionType.RLA, MemMode.ZEROPAGE_X, 0, 6, 0), 			# 37
    Instruction(InstructionType.SEC, MemMode.IMPLIED, 1, 2, 0), 			# 38
    Instruction(InstructionType.AND, MemMode.ABSOLUTE_Y, 3, 4, 1), 			# 39
    Instruction(InstructionType.NOP, MemMode.IMPLIED, 1, 2, 0), 			# 3a
    Instruction(InstructionType.RLA, MemMode.ABSOLUTE_Y, 0, 7, 0), 			# 3b
    Instruction(InstructionType.NOP, MemMode.ABSOLUTE_X, 3, 4, 1), 			# 3c
    Instruction(InstructionType.AND, MemMode.ABSOLUTE_X, 3, 4, 1), 			# 3d
    Instruction(InstructionType.ROL, MemMode.ABSOLUTE_X, 3, 7, 0), 			# 3e
    Instruction(InstructionType.RLA, MemMode.ABSOLUTE_X, 0, 7, 0), 			# 3f
    Instruction(InstructionType.RTI, MemMode.IMPLIED, 1, 6, 0), 			# 40
    Instruction(InstructionType.EOR, MemMode.INDEXED_INDIRECT, 2, 6, 0), 	# 41
    Instruction(InstructionType.KIL, MemMode.IMPLIED, 0, 2, 0), 			# 42
    Instruction(InstructionType.SRE, MemMode.INDEXED_INDIRECT, 0, 8, 0), 	# 43
    Instruction(InstructionType.NOP, MemMode.ZEROPAGE, 2, 3, 0), 			# 44
    Instruction(InstructionType.EOR, MemMode.ZEROPAGE, 2, 3, 0), 			# 45
    Instruction(InstructionType.LSR, MemMode.ZEROPAGE, 2, 5, 0), 			# 46
    Instruction(InstructionType.SRE, MemMode.ZEROPAGE, 0, 5, 0), 			# 47
    Instruction(InstructionType.PHA, MemMode.IMPLIED, 1, 3, 0), 			# 48
    Instruction(InstructionType.EOR, MemMode.IMMEDIATE, 2, 2, 0), 			# 49
    Instruction(InstructionType.LSR, MemMode.ACCUMULATOR, 1, 2, 0),         # 4a
    Instruction(InstructionType.ALR, MemMode.IMMEDIATE, 0, 2, 0), 			# 4b
    Instruction(InstructionType.JMP, MemMode.ABSOLUTE, 3, 3, 0), 			# 4c
    Instruction(InstructionType.EOR, MemMode.ABSOLUTE, 3, 4, 0), 			# 4d
    Instruction(InstructionType.LSR, MemMode.ABSOLUTE, 3, 6, 0), 			# 4e
    Instruction(InstructionType.SRE, MemMode.ABSOLUTE, 0, 6, 0), 			# 4f
    Instruction(InstructionType.BVC, MemMode.RELATIVE, 2, 2, 1), 			# 50
    Instruction(InstructionType.EOR, MemMode.INDIRECT_INDEXED, 2, 5, 1), 	# 51
    Instruction(InstructionType.KIL, MemMode.IMPLIED, 0, 2, 0), 			# 52
    Instruction(InstructionType.SRE, MemMode.INDIRECT_INDEXED, 0, 8, 0), 	# 53
    Instruction(InstructionType.NOP, MemMode.ZEROPAGE_X, 2, 4, 0), 			# 54
    Instruction(InstructionType.EOR, MemMode.ZEROPAGE_X, 2, 4, 0), 			# 55
    Instruction(InstructionType.LSR, MemMode.ZEROPAGE_X, 2, 6, 0), 			# 56
    Instruction(InstructionType.SRE, MemMode.ZEROPAGE_X, 0, 6, 0), 			# 57
    Instruction(InstructionType.CLI, MemMode.IMPLIED, 1, 2, 0), 			# 58
    Instruction(InstructionType.EOR, MemMode.ABSOLUTE_Y, 3, 4, 1), 			# 59
    Instruction(InstructionType.NOP, MemMode.IMPLIED, 1, 2, 0), 			# 5a
    Instruction(InstructionType.SRE, MemMode.ABSOLUTE_Y, 0, 7, 0), 			# 5b
    Instruction(InstructionType.NOP, MemMode.ABSOLUTE_X, 3, 4, 1), 			# 5c
    Instruction(InstructionType.EOR, MemMode.ABSOLUTE_X, 3, 4, 1), 			# 5d
    Instruction(InstructionType.LSR, MemMode.ABSOLUTE_X, 3, 7, 0), 			# 5e
    Instruction(InstructionType.SRE, MemMode.ABSOLUTE_X, 0, 7, 0), 			# 5f
    Instruction(InstructionType.RTS, MemMode.IMPLIED, 1, 6, 0), 			# 60
    Instruction(InstructionType.ADC, MemMode.INDEXED_INDIRECT, 2, 6, 0), 	# 61
    Instruction(InstructionType.KIL, MemMode.IMPLIED, 0, 2, 0), 			# 62
    Instruction(InstructionType.RRA, MemMode.INDEXED_INDIRECT, 0, 8, 0), 	# 63
    Instruction(InstructionType.NOP, MemMode.ZEROPAGE, 2, 3, 0), 			# 64
    Instruction(InstructionType.ADC, MemMode.ZEROPAGE, 2, 3, 0), 			# 65
    Instruction(InstructionType.ROR, MemMode.ZEROPAGE, 2, 5, 0), 			# 66
    Instruction(InstructionType.RRA, MemMode.ZEROPAGE, 0, 5, 0), 			# 67
    Instruction(InstructionType.PLA, MemMode.IMPLIED, 1, 4, 0), 			# 68
    Instruction(InstructionType.ADC, MemMode.IMMEDIATE, 2, 2, 0), 			# 69
    Instruction(InstructionType.ROR, MemMode.ACCUMULATOR, 1, 2, 0), 		# 6a
    Instruction(InstructionType.ARR, MemMode.IMMEDIATE, 0, 2, 0), 			# 6b
    Instruction(InstructionType.JMP, MemMode.INDIRECT, 3, 5, 0), 			# 6c
    Instruction(InstructionType.ADC, MemMode.ABSOLUTE, 3, 4, 0), 			# 6d
    Instruction(InstructionType.ROR, MemMode.ABSOLUTE, 3, 6, 0), 			# 6e
    Instruction(InstructionType.RRA, MemMode.ABSOLUTE, 0, 6, 0), 			# 6f
    Instruction(InstructionType.BVS, MemMode.RELATIVE, 2, 2, 1), 			# 70
    Instruction(InstructionType.ADC, MemMode.INDIRECT_INDEXED, 2, 5, 1), 	# 71
    Instruction(InstructionType.KIL, MemMode.IMPLIED, 0, 2, 0), 			# 72
    Instruction(InstructionType.RRA, MemMode.INDIRECT_INDEXED, 0, 8, 0), 	# 73
    Instruction(InstructionType.NOP, MemMode.ZEROPAGE_X, 2, 4, 0), 			# 74
    Instruction(InstructionType.ADC, MemMode.ZEROPAGE_X, 2, 4, 0), 			# 75
    Instruction(InstructionType.ROR, MemMode.ZEROPAGE_X, 2, 6, 0), 			# 76
    Instruction(InstructionType.RRA, MemMode.ZEROPAGE_X, 0, 6, 0), 			# 77
    Instruction(InstructionType.SEI, MemMode.IMPLIED, 1, 2, 0), 			# 78
    Instruction(InstructionType.ADC, MemMode.ABSOLUTE_Y, 3, 4, 1), 			# 79
    Instruction(InstructionType.NOP, MemMode.IMPLIED, 1, 2, 0), 			# 7a
    Instruction(InstructionType.RRA, MemMode.ABSOLUTE_Y, 0, 7, 0), 			# 7b
    Instruction(InstructionType.NOP, MemMode.ABSOLUTE_X, 3, 4, 1), 			# 7c
    Instruction(InstructionType.ADC, MemMode.ABSOLUTE_X, 3, 4, 1), 			# 7d
    Instruction(InstructionType.ROR, MemMode.ABSOLUTE_X, 3, 7, 0), 			# 7e
    Instruction(InstructionType.RRA, MemMode.ABSOLUTE_X, 0, 7, 0), 			# 7f
    Instruction(InstructionType.NOP, MemMode.IMMEDIATE, 2, 2, 0), 			# 80
    Instruction(InstructionType.STA, MemMode.INDEXED_INDIRECT, 2, 6, 0), 	# 81
    Instruction(InstructionType.NOP, MemMode.IMMEDIATE, 0, 2, 0), 			# 82
    Instruction(InstructionType.SAX, MemMode.INDEXED_INDIRECT, 0, 6, 0), 	# 83
    Instruction(InstructionType.STY, MemMode.ZEROPAGE, 2, 3, 0), 			# 84
    Instruction(InstructionType.STA, MemMode.ZEROPAGE, 2, 3, 0), 			# 85
    Instruction(InstructionType.STX, MemMode.ZEROPAGE, 2, 3, 0), 			# 86
    Instruction(InstructionType.SAX, MemMode.ZEROPAGE, 0, 3, 0), 			# 87
    Instruction(InstructionType.DEY, MemMode.IMPLIED, 1, 2, 0), 			# 88
    Instruction(InstructionType.NOP, MemMode.IMMEDIATE, 0, 2, 0), 			# 89
    Instruction(InstructionType.TXA, MemMode.IMPLIED, 1, 2, 0), 			# 8a
    Instruction(InstructionType.XAA, MemMode.IMMEDIATE, 0, 2, 0), 			# 8b
    Instruction(InstructionType.STY, MemMode.ABSOLUTE, 3, 4, 0), 			# 8c
    Instruction(InstructionType.STA, MemMode.ABSOLUTE, 3, 4, 0), 			# 8d
    Instruction(InstructionType.STX, MemMode.ABSOLUTE, 3, 4, 0), 			# 8e
    Instruction(InstructionType.SAX, MemMode.ABSOLUTE, 0, 4, 0), 			# 8f
    Instruction(InstructionType.BCC, MemMode.RELATIVE, 2, 2, 1), 			# 90
    Instruction(InstructionType.STA, MemMode.INDIRECT_INDEXED, 2, 6, 0), 	# 91
    Instruction(InstructionType.KIL, MemMode.IMPLIED, 0, 2, 0), 			# 92
    Instruction(InstructionType.AHX, MemMode.INDIRECT_INDEXED, 0, 6, 0), 	# 93
    Instruction(InstructionType.STY, MemMode.ZEROPAGE_X, 2, 4, 0), 			# 94
    Instruction(InstructionType.STA, MemMode.ZEROPAGE_X, 2, 4, 0), 			# 95
    Instruction(InstructionType.STX, MemMode.ZEROPAGE_Y, 2, 4, 0), 			# 96
    Instruction(InstructionType.SAX, MemMode.ZEROPAGE_Y, 0, 4, 0), 			# 97
    Instruction(InstructionType.TYA, MemMode.IMPLIED, 1, 2, 0), 			# 98
    Instruction(InstructionType.STA, MemMode.ABSOLUTE_Y, 3, 5, 0), 			# 99
    Instruction(InstructionType.TXS, MemMode.IMPLIED, 1, 2, 0), 			# 9a
    Instruction(InstructionType.TAS, MemMode.ABSOLUTE_Y, 0, 5, 0), 			# 9b
    Instruction(InstructionType.SHY, MemMode.ABSOLUTE_X, 0, 5, 0), 			# 9c
    Instruction(InstructionType.STA, MemMode.ABSOLUTE_X, 3, 5, 0), 			# 9d
    Instruction(InstructionType.SHX, MemMode.ABSOLUTE_Y, 0, 5, 0), 			# 9e
    Instruction(InstructionType.AHX, MemMode.ABSOLUTE_Y, 0, 5, 0), 			# 9f
    Instruction(InstructionType.LDY, MemMode.IMMEDIATE, 2, 2, 0), 			# a0
    Instruction(InstructionType.LDA, MemMode.INDEXED_INDIRECT, 2, 6, 0), 	# a1
    Instruction(InstructionType.LDX, MemMode.IMMEDIATE, 2, 2, 0), 			# a2
    Instruction(InstructionType.LAX, MemMode.INDEXED_INDIRECT, 0, 6, 0), 	# a3
    Instruction(InstructionType.LDY, MemMode.ZEROPAGE, 2, 3, 0), 			# a4
    Instruction(InstructionType.LDA, MemMode.ZEROPAGE, 2, 3, 0), 			# a5
    Instruction(InstructionType.LDX, MemMode.ZEROPAGE, 2, 3, 0), 			# a6
    Instruction(InstructionType.LAX, MemMode.ZEROPAGE, 0, 3, 0), 			# a7
    Instruction(InstructionType.TAY, MemMode.IMPLIED, 1, 2, 0), 			# a8
    Instruction(InstructionType.LDA, MemMode.IMMEDIATE, 2, 2, 0), 			# a9
    Instruction(InstructionType.TAX, MemMode.IMPLIED, 1, 2, 0), 			# aa
    Instruction(InstructionType.LAX, MemMode.IMMEDIATE, 0, 2, 0), 			# ab
    Instruction(InstructionType.LDY, MemMode.ABSOLUTE, 3, 4, 0), 			# ac
    Instruction(InstructionType.LDA, MemMode.ABSOLUTE, 3, 4, 0), 			# ad
    Instruction(InstructionType.LDX, MemMode.ABSOLUTE, 3, 4, 0), 			# ae
    Instruction(InstructionType.LAX, MemMode.ABSOLUTE, 0, 4, 0), 			# af
    Instruction(InstructionType.BCS, MemMode.RELATIVE, 2, 2, 1), 			# b0
    Instruction(InstructionType.LDA, MemMode.INDIRECT_INDEXED, 2, 5, 1), 	# b1
    Instruction(InstructionType.KIL, MemMode.IMPLIED, 0, 2, 0), 			# b2
    Instruction(InstructionType.LAX, MemMode.INDIRECT_INDEXED, 0, 5, 1), 	# b3
    Instruction(InstructionType.LDY, MemMode.ZEROPAGE_X, 2, 4, 0), 			# b4
    Instruction(InstructionType.LDA, MemMode.ZEROPAGE_X, 2, 4, 0), 			# b5
    Instruction(InstructionType.LDX, MemMode.ZEROPAGE_Y, 2, 4, 0), 			# b6
    Instruction(InstructionType.LAX, MemMode.ZEROPAGE_Y, 0, 4, 0), 			# b7
    Instruction(InstructionType.CLV, MemMode.IMPLIED, 1, 2, 0), 			# b8
    Instruction(InstructionType.LDA, MemMode.ABSOLUTE_Y, 3, 4, 1), 			# b9
    Instruction(InstructionType.TSX, MemMode.IMPLIED, 1, 2, 0), 			# ba
    Instruction(InstructionType.LAS, MemMode.ABSOLUTE_Y, 0, 4, 1), 			# bb
    Instruction(InstructionType.LDY, MemMode.ABSOLUTE_X, 3, 4, 1), 			# bc
    Instruction(InstructionType.LDA, MemMode.ABSOLUTE_X, 3, 4, 1), 			# bd
    Instruction(InstructionType.LDX, MemMode.ABSOLUTE_Y, 3, 4, 1), 			# be
    Instruction(InstructionType.LAX, MemMode.ABSOLUTE_Y, 0, 4, 1), 			# bf
    Instruction(InstructionType.CPY, MemMode.IMMEDIATE, 2, 2, 0), 			# c0
    Instruction(InstructionType.CMP, MemMode.INDEXED_INDIRECT, 2, 6, 0), 	# c1
    Instruction(InstructionType.NOP, MemMode.IMMEDIATE, 0, 2, 0), 			# c2
    Instruction(InstructionType.DCP, MemMode.INDEXED_INDIRECT, 0, 8, 0), 	# c3
    Instruction(InstructionType.CPY, MemMode.ZEROPAGE, 2, 3, 0), 			# c4
    Instruction(InstructionType.CMP, MemMode.ZEROPAGE, 2, 3, 0), 			# c5
    Instruction(InstructionType.DEC, MemMode.ZEROPAGE, 2, 5, 0), 			# c6
    Instruction(InstructionType.DCP, MemMode.ZEROPAGE, 0, 5, 0), 			# c7
    Instruction(InstructionType.INY, MemMode.IMPLIED, 1, 2, 0), 			# c8
    Instruction(InstructionType.CMP, MemMode.IMMEDIATE, 2, 2, 0), 			# c9
    Instruction(InstructionType.DEX, MemMode.IMPLIED, 1, 2, 0), 			# ca
    Instruction(InstructionType.AXS, MemMode.IMMEDIATE, 0, 2, 0), 			# cb
    Instruction(InstructionType.CPY, MemMode.ABSOLUTE, 3, 4, 0), 			# cc
    Instruction(InstructionType.CMP, MemMode.ABSOLUTE, 3, 4, 0), 			# cd
    Instruction(InstructionType.DEC, MemMode.ABSOLUTE, 3, 6, 0), 			# ce
    Instruction(InstructionType.DCP, MemMode.ABSOLUTE, 0, 6, 0), 			# cf
    Instruction(InstructionType.BNE, MemMode.RELATIVE, 2, 2, 1), 			# d0
    Instruction(InstructionType.CMP, MemMode.INDIRECT_INDEXED, 2, 5, 1), 	# d1
    Instruction(InstructionType.KIL, MemMode.IMPLIED, 0, 2, 0), 			# d2
    Instruction(InstructionType.DCP, MemMode.INDIRECT_INDEXED, 0, 8, 0), 	# d3
    Instruction(InstructionType.NOP, MemMode.ZEROPAGE_X, 2, 4, 0), 			# d4
    Instruction(InstructionType.CMP, MemMode.ZEROPAGE_X, 2, 4, 0), 			# d5
    Instruction(InstructionType.DEC, MemMode.ZEROPAGE_X, 2, 6, 0), 			# d6
    Instruction(InstructionType.DCP, MemMode.ZEROPAGE_X, 0, 6, 0), 			# d7
    Instruction(InstructionType.CLD, MemMode.IMPLIED, 1, 2, 0), 			# d8
    Instruction(InstructionType.CMP, MemMode.ABSOLUTE_Y, 3, 4, 1), 			# d9
    Instruction(InstructionType.NOP, MemMode.IMPLIED, 1, 2, 0), 			# da
    Instruction(InstructionType.DCP, MemMode.ABSOLUTE_Y, 0, 7, 0), 			# db
    Instruction(InstructionType.NOP, MemMode.ABSOLUTE_X, 3, 4, 1), 			# dc
    Instruction(InstructionType.CMP, MemMode.ABSOLUTE_X, 3, 4, 1), 			# dd
    Instruction(InstructionType.DEC, MemMode.ABSOLUTE_X, 3, 7, 0), 			# de
    Instruction(InstructionType.DCP, MemMode.ABSOLUTE_X, 0, 7, 0), 			# df
    Instruction(InstructionType.CPX, MemMode.IMMEDIATE, 2, 2, 0), 			# e0
    Instruction(InstructionType.SBC, MemMode.INDEXED_INDIRECT, 2, 6, 0), 	# e1
    Instruction(InstructionType.NOP, MemMode.IMMEDIATE, 0, 2, 0), 			# e2
    Instruction(InstructionType.ISC, MemMode.INDEXED_INDIRECT, 0, 8, 0), 	# e3
    Instruction(InstructionType.CPX, MemMode.ZEROPAGE, 2, 3, 0), 			# e4
    Instruction(InstructionType.SBC, MemMode.ZEROPAGE, 2, 3, 0), 			# e5
    Instruction(InstructionType.INC, MemMode.ZEROPAGE, 2, 5, 0), 			# e6
    Instruction(InstructionType.ISC, MemMode.ZEROPAGE, 0, 5, 0), 			# e7
    Instruction(InstructionType.INX, MemMode.IMPLIED, 1, 2, 0), 			# e8
    Instruction(InstructionType.SBC, MemMode.IMMEDIATE, 2, 2, 0), 			# e9
    Instruction(InstructionType.NOP, MemMode.IMPLIED, 1, 2, 0), 			# ea
    Instruction(InstructionType.SBC, MemMode.IMMEDIATE, 0, 2, 0), 			# eb
    Instruction(InstructionType.CPX, MemMode.ABSOLUTE, 3, 4, 0), 			# ec
    Instruction(InstructionType.SBC, MemMode.ABSOLUTE, 3, 4, 0), 			# ed
    Instruction(InstructionType.INC, MemMode.ABSOLUTE, 3, 6, 0), 			# ee
    Instruction(InstructionType.ISC, MemMode.ABSOLUTE, 0, 6, 0), 			# ef
    Instruction(InstructionType.BEQ, MemMode.RELATIVE, 2, 2, 1), 			# f0
    Instruction(InstructionType.SBC, MemMode.INDIRECT_INDEXED, 2, 5, 1), 	# f1
    Instruction(InstructionType.KIL, MemMode.IMPLIED, 0, 2, 0), 			# f2
    Instruction(InstructionType.ISC, MemMode.INDIRECT_INDEXED, 0, 8, 0), 	# f3
    Instruction(InstructionType.NOP, MemMode.ZEROPAGE_X, 2, 4, 0), 			# f4
    Instruction(InstructionType.SBC, MemMode.ZEROPAGE_X, 2, 4, 0), 			# f5
    Instruction(InstructionType.INC, MemMode.ZEROPAGE_X, 2, 6, 0), 			# f6
    Instruction(InstructionType.ISC, MemMode.ZEROPAGE_X, 0, 6, 0), 			# f7
    Instruction(InstructionType.SED, MemMode.IMPLIED, 1, 2, 0), 			# f8
    Instruction(InstructionType.SBC, MemMode.ABSOLUTE_Y, 3, 4, 1), 			# f9
    Instruction(InstructionType.NOP, MemMode.IMPLIED, 1, 2, 0), 			# fa
    Instruction(InstructionType.ISC, MemMode.ABSOLUTE_Y, 0, 7, 0), 			# fb
    Instruction(InstructionType.NOP, MemMode.ABSOLUTE_X, 3, 4, 1), 			# fc
    Instruction(InstructionType.SBC, MemMode.ABSOLUTE_X, 3, 4, 1), 			# fd
    Instruction(InstructionType.INC, MemMode.ABSOLUTE_X, 3, 7, 0), 			# fe
    Instruction(InstructionType.ISC, MemMode.ABSOLUTE_X, 0, 7, 0), 			# ff
]


STACK_POINTER_RESET = 0xFD
STACK_START = 0x100
RESET_VECTOR = 0xFFFC
NMI_VECTOR = 0xFFFA
IRQ_BRK_VECTOR = 0xFFFE
MEM_SIZE = 2048


class CPU:
    def __init__(self, ppu: PPU, rom: ROM):
        # Connections to Other Parts of the Console
        self.ppu: PPU = ppu
        self.rom: ROM = rom
        # Memory on the CPU
        self.ram = array('B', [0] * MEM_SIZE)
        # Registers
        self.A: int = 0
        self.X: int = 0
        self.Y: int = 0
        self.SP: int = STACK_POINTER_RESET
        self.PC: int = self.read_memory(RESET_VECTOR, MemMode.ABSOLUTE) | \
                       (self.read_memory(RESET_VECTOR + 1, MemMode.ABSOLUTE) << 8)
        # Flags
        self.C: bool = False # Carry
        self.Z: bool = False # Zero
        self.I: bool = True # Interrupt Disable
        self.D: bool = False # Decimal Mode
        self.B: bool = False # Break Command
        self.V: bool = False # oVerflow
        self.N: bool = False # Negative
        # Miscellaneous State
        self.page_crossed: bool = False
        self.cpu_ticks: int = 0
        self.stall: int = 0 # Number of cycles to stall
        self.joypad1 = Joypad()

    def step(self):
        if self.stall > 0:
            self.stall -= 1
            self.cpu_ticks += 1
            return

        opcode = self.read_memory(self.PC, MemMode.ABSOLUTE)
        self.page_crossed = False
        jumped = False
        instruction = Instructions[opcode]
        data = 0
        for i in range(1, instruction.length):
            data |= (self.read_memory(self.PC + i, MemMode.ABSOLUTE) << ((i - 1) * 8))

        # debug print

        # Switch this to match statement in Python 3.10
        if instruction.type == InstructionType.ADC: # add memory to accumulator with carry
            src = self.read_memory(data, instruction.mode)
            signed_result = src + self.A + self.C
            self.V = bool(~(self.A ^ src) & (self.A ^ signed_result) & 0x80)
            self.A = (self.A + src + self.C) % 256
            self.C = signed_result > 0xFF
            self.setZN(self.A)
        elif instruction.type == InstructionType.AND: # bitwise AND with accumulator
            src = self.read_memory(data, instruction.mode)
            self.A = self.A & src
            self.setZN(self.A)
        elif instruction.type == InstructionType.ASL: # arithmetic shift left
            src = self.A if instruction.mode == MemMode.ACCUMULATOR else self.read_memory(data, instruction.mode)
            self.C = bool(src >> 7) # carry is set to 7th bit
            src = (src << 1) & 0xFF
            self.setZN(src)
            if instruction.mode == MemMode.ACCUMULATOR:
                self.A = src
            else:
                self.write_memory(data, instruction.mode, src)
        elif instruction.type == InstructionType.BCC: # branch if carry clear
            if not self.C:
                self.PC = self.address_for_mode(data, instruction.mode)
                jumped = True
        elif instruction.type == InstructionType.BCS: # branch if carry set
            if self.C:
                self.PC = self.address_for_mode(data, instruction.mode)
                jumped = True
        elif instruction.type == InstructionType.BEQ: # branch on result zero
            if self.Z:
                self.PC = self.address_for_mode(data, instruction.mode)
                jumped = True
        elif instruction.type == InstructionType.BIT: # bit test bits in memory with accumulator
            src = self.read_memory(data, instruction.mode)
            self.V = bool((src >> 6) & 1)
            self.Z = ((src & self.A) == 0)
            self.N = ((src >> 7) == 1)
        elif instruction.type == InstructionType.BMI: # branch on result minus
            if self.N:
                self.PC = self.address_for_mode(data, instruction.mode)
                jumped = True
        elif instruction.type == InstructionType.BNE: # branch on result not zero
            if not self.Z:
                self.PC = self.address_for_mode(data, instruction.mode)
                jumped = True
        elif instruction.type == InstructionType.BPL: # branch on result plus
            if not self.N:
                self.PC = self.address_for_mode(data, instruction.mode)
                jumped = True
        elif instruction.type == InstructionType.BRK: # force break
            self.PC += 2
            # push pc to stack
            self.stack_push((self.PC >> 8) & 0xFF)
            self.stack_push(self.PC & 0xFF)
            # push status to stack
            self.B = True
            self.stack_push(self.status)
            self.B = False
            self.I = True
            # set PC to reset vector
            self.PC = (self.read_memory(IRQ_BRK_VECTOR, MemMode.ABSOLUTE)) | \
                      (self.read_memory(IRQ_BRK_VECTOR + 1, MemMode.ABSOLUTE) << 8)
            jumped = True
        elif instruction.type == InstructionType.BVC: # branch on overflow clear
            if not self.V:
                self.PC = self.address_for_mode(data, instruction.mode)
                jumped = True
        elif instruction.type == InstructionType.BVS: # branch on overflow set
            if self.V:
                self.PC = self.address_for_mode(data, instruction.mode)
                jumped = True
        elif instruction.type == InstructionType.CLC: # clear carry
            self.C = False
        elif instruction.type == InstructionType.CLD: # clear decimal
            self.D = False
        elif instruction.type == InstructionType.CLI: # clear interrupt
            self.I = False
        elif instruction.type == InstructionType.CLV: # clear overflow
            self.V = False
        elif instruction.type == InstructionType.CMP: # compare accumulator
            src = self.read_memory(data, instruction.mode)
            self.C = self.A >= src
            self.setZN(self.A - src)
        elif instruction.type == InstructionType.CPX:  # compare X register
            src = self.read_memory(data, instruction.mode)
            self.C = self.X >= src
            self.setZN(self.X - src)
        elif instruction.type == InstructionType.CPY:  # compare Y register
            src = self.read_memory(data, instruction.mode)
            self.C = self.Y >= src
            self.setZN(self.Y - src)
        elif instruction.type == InstructionType.DEC:  # decrement memory
            src = self.read_memory(data, instruction.mode)
            src = (src - 1) & 0xFF
            self.write_memory(data, instruction.mode, src)
            self.setZN(src)
        elif instruction.type == InstructionType.DEX:  # decrement X
            self.X = (self.X - 1) & 0xFF
            self.setZN(self.X)
        elif instruction.type == InstructionType.DEY:  # decrement Y
            self.Y = (self.Y - 1) & 0xFF
            self.setZN(self.Y)
        elif instruction.type == InstructionType.EOR:  # exclusive or memory with accumulator
            self.A ^= self.read_memory(data, instruction.mode)
            self.setZN(self.A)
        elif instruction.type == InstructionType.INC:  # increment memory
            src = self.read_memory(data, instruction.mode)
            src = (src + 1) & 0xFF
            self.write_memory(data, instruction.mode, src)
            self.setZN(src)
        elif instruction.type == InstructionType.INX:  # increment X
            self.X = (self.X + 1) & 0xFF
            self.setZN(self.X)
        elif instruction.type == InstructionType.INY:  # increment Y
            self.Y = (self.Y + 1) & 0xFF
            self.setZN(self.Y)
        elif instruction.type == InstructionType.JMP: # jump
            self.PC = self.address_for_mode(data, instruction.mode)
            jumped = True
        elif instruction.type == InstructionType.JSR: # jump to subroutine
            self.PC += 2
            # push pc to stack
            self.stack_push((self.PC >> 8) & 0xFF)
            self.stack_push(self.PC & 0xFF)
            # jump to subroutine
            self.PC = self.address_for_mode(data, instruction.mode)
            jumped = True
        elif instruction.type == InstructionType.LDA:  # load accumulator with memory
            self.A = self.read_memory(data, instruction.mode)
            self.setZN(self.A)
        elif instruction.type == InstructionType.LDX:  # load X with memory
            self.X = self.read_memory(data, instruction.mode)
            self.setZN(self.X)
        elif instruction.type == InstructionType.LDY:  # load Y with memory
            self.Y = self.read_memory(data, instruction.mode)
            self.setZN(self.Y)
        elif instruction.type == InstructionType.LSR:  # logical shift right
            src = self.A if instruction.mode == MemMode.ACCUMULATOR else self.read_memory(data, instruction.mode)
            self.C = bool(src & 1)  # carry is set to 0th bit
            src >>= 1
            self.setZN(src)
            if instruction.mode == MemMode.ACCUMULATOR:
                self.A = src
            else:
                self.write_memory(data, instruction.mode, src)
        elif instruction.type == InstructionType.NOP:  # no op
            pass
        elif instruction.type == InstructionType.ORA:  # or memory with accumulator
            self.A |= self.read_memory(data, instruction.mode)
            self.setZN(self.A)
        elif instruction.type == InstructionType.PHA:  # push accumulator
            self.stack_push(self.A)
        elif instruction.type == InstructionType.PHP:  # push status
            self.B = True # http://nesdev.com/the%20'B'%20flag%20&%20BRK%20instruction.txt
            self.stack_push(self.status)
            self.B = False
        elif instruction.type == InstructionType.PLA: # pull accumulator
            self.A = self.stack_pop()
            self.setZN(self.A)
        elif instruction.type == InstructionType.PLP: # pull status
            self.set_status(self.stack_pop())
        elif instruction.type == InstructionType.ROL:  # rotate one bit left
            src = self.A if instruction.mode == MemMode.ACCUMULATOR else self.read_memory(data, instruction.mode)
            old_c = self.C
            self.C = bool((src >> 7) & 1)  # carry is set to 7th bit
            src = ((src << 1) | old_c) & 0xFF
            self.setZN(src)
            if instruction.mode == MemMode.ACCUMULATOR:
                self.A = src
            else:
                self.write_memory(data, instruction.mode, src)
        elif instruction.type == InstructionType.ROR:  # rotate one bit right
            src = self.A if instruction.mode == MemMode.ACCUMULATOR else self.read_memory(data, instruction.mode)
            old_c = self.C
            self.C = bool(src & 1)  # carry is set to 0th bit
            src = ((src >> 1) | (old_c << 7)) & 0xFF
            self.setZN(src)
            if instruction.mode == MemMode.ACCUMULATOR:
                self.A = src
            else:
                self.write_memory(data, instruction.mode, src)
        elif instruction.type == InstructionType.RTI: # return from interrupt
            # pull Status out
            self.set_status(self.stack_pop())
            # pull PC out
            lb = self.stack_pop()
            hb = self.stack_pop()
            self.PC = ((hb << 8) | lb)
            jumped = True
        elif instruction.type == InstructionType.RTS:  # return from subroutine
            # pull PC out
            lb = self.stack_pop()
            hb = self.stack_pop()
            self.PC = ((hb << 8) | lb) + 1 # 1 past last instruction
            jumped = True
        elif instruction.type == InstructionType.SBC:  # subtract with carry
            src = self.read_memory(data, instruction.mode)
            signed_result = self.A - src - (1 - self.C)
            self.V = bool((self.A ^ src) & (self.A ^ signed_result) & 0x80) # set overflow
            self.A = (self.A - src - (1 - self.C)) % 256
            self.C = not (signed_result < 0) # set carry
            self.setZN(self.A)
        elif instruction.type == InstructionType.SEC: # set carry
            self.C = True
        elif instruction.type == InstructionType.SED: # set decimal
            self.D = True
        elif instruction.type == InstructionType.SEI: # set interrupt
            self.I = True
        elif instruction.type == InstructionType.STA: # store accumulator
            self.write_memory(data, instruction.mode, self.A)
        elif instruction.type == InstructionType.STX: # store X register
            self.write_memory(data, instruction.mode, self.X)
        elif instruction.type == InstructionType.STY: # store Y register
            self.write_memory(data, instruction.mode, self.Y)
        elif instruction.type == InstructionType.TAX: # transfer A to X
            self.X = self.A
            self.setZN(self.X)
        elif instruction.type == InstructionType.TAY: # transfer A to Y
            self.Y = self.A
            self.setZN(self.Y)
        elif instruction.type == InstructionType.TSX: # transfer stack pointer to X
            self.X = self.SP
            self.setZN(self.X)
        elif instruction.type == InstructionType.TXA: # transfer X to A
            self.A = self.X
            self.setZN(self.A)
        elif instruction.type == InstructionType.TXS: # transfer X to SP
            self.SP = self.X
        elif instruction.type == InstructionType.TYA: # transfer Y to A
            self.A = self.Y
            self.setZN(self.A)
        else:
            print(f"Unimplemented Instruction: {instruction.type.name}")

        if not jumped:
            self.PC += instruction.length
        elif instruction.type in [InstructionType.BCC, InstructionType.BCS, InstructionType.BEQ, InstructionType.BMI,
                                  InstructionType.BNE, InstructionType.BPL, InstructionType.BVC, InstructionType.BVS]:
            # branch instructions are +1 ticks if they succeeded
            self.cpu_ticks += 1
        self.cpu_ticks += instruction.ticks
        if self.page_crossed:
            self.cpu_ticks += instruction.page_ticks

    def address_for_mode(self, data: int, mode: MemMode) -> int:
        def different_pages(address1: int, address2: int) -> bool:
            return ((address1 & 0xFF00) != (address2 & 0xFF00))
        address = 0
        if mode == MemMode.ABSOLUTE:
            address = data
        elif mode == MemMode.ABSOLUTE_X:
            address = (data + self.X) & 0xFFFF
            self.page_crossed = different_pages(address, address - self.X)
        elif mode == MemMode.ABSOLUTE_Y:
            address = (data + self.Y) & 0xFFFF
            self.page_crossed = different_pages(address, address - self.Y)
        elif mode == MemMode.INDEXED_INDIRECT:
            ls = self.ram[(data + self.X) & 0xFF] # 0xFF for zero-page wrapping
            ms = self.ram[(data + self.X + 1) & 0xFF] # 0xFF for zero-page wrapping
            address = (ms << 8) | ls
        elif mode == MemMode.INDIRECT:
            ls = self.ram[data]
            ms = self.ram[data + 1]
            if (data & 0xFF) == 0xFF:
                ms = self.ram[data & 0xFF00]
            address = (ms << 8) | ls
        elif mode == MemMode.INDIRECT_INDEXED:
            ls = self.ram[data & 0xFF]  # 0xFF for zero-page wrapping
            ms = self.ram[(data + 1) & 0xFF]  # 0xFF for zero-page wrapping
            address = (ms << 8) | ls
            address = (address + self.Y) & 0xFFFF
            self.page_crossed = different_pages(address, address - self.Y)
        elif mode == MemMode.RELATIVE:
            address = (self.PC + 2 + data) & 0xFFFF if (data < 0x80) else (self.PC + 2 + (data - 256)) & 0xFFFF # signed
        elif mode == MemMode.ZEROPAGE:
            address = data
        elif mode == MemMode.ZEROPAGE_X:
            address = (data + self.X) & 0xFF
        elif mode == MemMode.ZEROPAGE_Y:
            address = (data + self.Y) & 0xFF
        return address

    def read_memory(self, location: int, mode: MemMode) -> int:
        if mode == MemMode.IMMEDIATE:
            return location # location is actually data in this case
        address = self.address_for_mode(location, mode)

        # Memory map at http://wiki.nesdev.com/w/index.php/CPU_memory_map
        if address < 0x2000: # main ram 2 KB goes up to 0x800
            return self.ram[address % 0x800] # mirrors for next 6 KB
        elif address < 0x3FFF: # 2000-2007 is PPU, up to 3FFF mirrors it every 8 bytes
            temp = ((address % 8) | 0x2000) # get data from ppu register
            return self.ppu.read_register(temp)
        elif address == 0x4016: # Joypad 1 status
            if self.joypad1.strobe:
                return self.joypad1.a
            self.joypad1.read_count += 1
            if self.joypad1.read_count == 1:
                return 0x40 | self.joypad1.a
            elif self.joypad1.read_count == 2:
                return 0x40 | self.joypad1.b
            elif self.joypad1.read_count == 3:
                return 0x40 | self.joypad1.select
            elif self.joypad1.read_count == 4:
                return 0x40 | self.joypad1.start
            elif self.joypad1.read_count == 5:
                return 0x40 | self.joypad1.up
            elif self.joypad1.read_count == 6:
                return 0x40 | self.joypad1.down
            elif self.joypad1.read_count == 7:
                return 0x40 | self.joypad1.left
            elif self.joypad1.read_count == 8:
                return 0x40 | self.joypad1.right
            else:
                return 0x41
        elif address < 0x6000:
            return 0 # Unimplemented other kinds of IO
        else: # Addresses from 0x6000 to 0xFFFF are from the cartridge
            return self.rom.read_cartridge(address)

    def write_memory(self, location: int, mode: MemMode, value: int):
        if mode == MemMode.IMMEDIATE:
            self.ram[location] = value
            return

        address = self.address_for_mode(location, mode)
        # Memory map at http://wiki.nesdev.com/w/index.php/CPU_memory_map
        if address < 0x2000:  # main ram 2 KB goes up to 0x800
            self.ram[address % 0x800] = value  # mirrors for next 6 KB
        elif address < 0x3FFF:  # 2000-2007 is PPU, up to 3FFF mirrors it every 8 bytes
            temp = ((address % 8) | 0x2000)  # write data to ppu register
            self.ppu.write_register(temp, value)
        elif address == 0x4014:  # DMA Transfer of Sprite Data
            from_address = value * 0x100 # this is the address to start copying from
            for i in range(SPR_RAM_SIZE): # copy all 256 bytes over to sprite ram
                self.ppu.spr[i] = self.read_memory((from_address + i), MemMode.ABSOLUTE)
            # stall for 512 cycles while this completes
            self.stall = 512
        elif address == 0x4016: # Joypad 1
            if self.joypad1.strobe and (not bool(value & 1)):
                self.joypad1.read_count = 0
            self.joypad1.strobe = bool(value & 1)
            return
        elif address < 0x6000:
            return # Unimplemented other kinds of IO
        else:  # Addresses from 0x6000 to 0xFFFF are from the cartridge
            # We haven't implemented support for cartridge RAM
            return self.rom.write_cartridge(address, value)

    def setZN(self, value: int):
        self.Z = (value == 0)
        self.N = bool(value & 0x80) or (value < 0)

    def stack_push(self, value: int):
        self.ram[(0x100 | self.SP)] = value
        self.SP = (self.SP - 1) & 0xFF

    def stack_pop(self) -> int:
        self.SP = (self.SP + 1) & 0xFF
        return self.ram[(0x100 | self.SP)]

    @property
    def status(self) -> int:
        return (self.C | self.Z << 1 | self.I << 2 | self.D << 3 |
                self.B << 4 | 1 << 5 | self.V << 6 | self.N << 7)

    def set_status(self, temp: int):
        self.C = bool(temp & 0b00000001)
        self.Z = bool(temp & 0b00000010)
        self.I = bool(temp & 0b00000100)
        self.D = bool(temp & 0b00001000)
        self.B = False # http://nesdev.com/the%20'B'%20flag%20&%20BRK%20instruction.txt
        self.V = bool(temp & 0b01000000)
        self.N = bool(temp & 0b10000000)

    def trigger_NMI(self):
        self.stack_push((self.PC >> 8) & 0xFF)
        self.stack_push(self.PC & 0xFF)
        self.B = True # http://nesdev.com/the%20'B'%20flag%20&%20BRK%20instruction.txt
        self.stack_push(self.status)
        self.B = False
        self.I = True
        # set PC to NMI vector
        self.PC = (self.read_memory(NMI_VECTOR, MemMode.ABSOLUTE)) | \
                  (self.read_memory(NMI_VECTOR + 1, MemMode.ABSOLUTE) << 8)

    def log(self) -> str:
        opcode = self.read_memory(self.PC, MemMode.ABSOLUTE)
        instruction = Instructions[opcode]
        data1 = "  " if instruction.length < 2 else f"{self.read_memory(self.PC + 1, MemMode.ABSOLUTE):02X}"
        data2 = "  " if instruction.length < 3 else f"{self.read_memory(self.PC + 2, MemMode.ABSOLUTE):02X}"
        return f"{self.PC:04X}  {opcode:02X} {data1} {data2}  {instruction.type.name}{29 * ' '}" \
               f"A:{self.A:02X} X:{self.X:02X} Y:{self.Y:02X} P:{self.status:02X} SP:{self.SP:02X}"
