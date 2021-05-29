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
from typing import NamedTuple
from array import array
from ppu import PPU
from rom import ROM

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


class InstructionInfo(NamedTuple):
    type: InstructionType
    mode: MemMode
    length: int
    ticks: int
    page_ticks: int


Instructions: list[InstructionInfo] = [
    InstructionInfo(InstructionType.BRK, MemMode.IMPLIED, 1, 7, 0), 			# 00
    InstructionInfo(InstructionType.ORA, MemMode.INDEXED_INDIRECT, 2, 6, 0), 	# 01
    InstructionInfo(InstructionType.KIL, MemMode.IMPLIED, 0, 2, 0), 			# 02
    InstructionInfo(InstructionType.SLO, MemMode.INDEXED_INDIRECT, 0, 8, 0), 	# 03
    InstructionInfo(InstructionType.NOP, MemMode.ZEROPAGE, 2, 3, 0), 			# 04
    InstructionInfo(InstructionType.ORA, MemMode.ZEROPAGE, 2, 3, 0), 			# 05
    InstructionInfo(InstructionType.ASL, MemMode.ZEROPAGE, 2, 5, 0), 			# 06
    InstructionInfo(InstructionType.SLO, MemMode.ZEROPAGE, 0, 5, 0), 			# 07
    InstructionInfo(InstructionType.PHP, MemMode.IMPLIED, 1, 3, 0), 			# 08
    InstructionInfo(InstructionType.ORA, MemMode.IMMEDIATE, 2, 2, 0), 			# 09
    InstructionInfo(InstructionType.ASL, MemMode.ACCUMULATOR, 1, 2, 0), 		# 0a
    InstructionInfo(InstructionType.ANC, MemMode.IMMEDIATE, 0, 2, 0), 			# 0b
    InstructionInfo(InstructionType.NOP, MemMode.ABSOLUTE, 3, 4, 0), 			# 0c
    InstructionInfo(InstructionType.ORA, MemMode.ABSOLUTE, 3, 4, 0), 			# 0d
    InstructionInfo(InstructionType.ASL, MemMode.ABSOLUTE, 3, 6, 0), 			# 0e
    InstructionInfo(InstructionType.SLO, MemMode.ABSOLUTE, 0, 6, 0), 			# 0f
    InstructionInfo(InstructionType.BPL, MemMode.RELATIVE, 2, 2, 1), 			# 10
    InstructionInfo(InstructionType.ORA, MemMode.INDIRECT_INDEXED, 2, 5, 1), 	# 11
    InstructionInfo(InstructionType.KIL, MemMode.IMPLIED, 0, 2, 0), 			# 12
    InstructionInfo(InstructionType.SLO, MemMode.INDIRECT_INDEXED, 0, 8, 0), 	# 13
    InstructionInfo(InstructionType.NOP, MemMode.ZEROPAGE_X, 2, 4, 0), 			# 14
    InstructionInfo(InstructionType.ORA, MemMode.ZEROPAGE_X, 2, 4, 0), 			# 15
    InstructionInfo(InstructionType.ASL, MemMode.ZEROPAGE_X, 2, 6, 0), 			# 16
    InstructionInfo(InstructionType.SLO, MemMode.ZEROPAGE_X, 0, 6, 0), 			# 17
    InstructionInfo(InstructionType.CLC, MemMode.IMPLIED, 1, 2, 0), 			# 18
    InstructionInfo(InstructionType.ORA, MemMode.ABSOLUTE_Y, 3, 4, 1), 			# 19
    InstructionInfo(InstructionType.NOP, MemMode.IMPLIED, 1, 2, 0), 			# 1a
    InstructionInfo(InstructionType.SLO, MemMode.ABSOLUTE_Y, 0, 7, 0), 			# 1b
    InstructionInfo(InstructionType.NOP, MemMode.ABSOLUTE_X, 3, 4, 1), 			# 1c
    InstructionInfo(InstructionType.ORA, MemMode.ABSOLUTE_X, 3, 4, 1), 			# 1d
    InstructionInfo(InstructionType.ASL, MemMode.ABSOLUTE_X, 3, 7, 0), 			# 1e
    InstructionInfo(InstructionType.SLO, MemMode.ABSOLUTE_X, 0, 7, 0), 			# 1f
    InstructionInfo(InstructionType.JSR, MemMode.ABSOLUTE, 3, 6, 0), 			# 20
    InstructionInfo(InstructionType.AND, MemMode.INDEXED_INDIRECT, 2, 6, 0), 	# 21
    InstructionInfo(InstructionType.KIL, MemMode.IMPLIED, 0, 2, 0), 			# 22
    InstructionInfo(InstructionType.RLA, MemMode.INDEXED_INDIRECT, 0, 8, 0), 	# 23
    InstructionInfo(InstructionType.BIT, MemMode.ZEROPAGE, 2, 3, 0), 			# 24
    InstructionInfo(InstructionType.AND, MemMode.ZEROPAGE, 2, 3, 0), 			# 25
    InstructionInfo(InstructionType.ROL, MemMode.ZEROPAGE, 2, 5, 0), 			# 26
    InstructionInfo(InstructionType.RLA, MemMode.ZEROPAGE, 0, 5, 0), 			# 27
    InstructionInfo(InstructionType.PLP, MemMode.IMPLIED, 1, 4, 0), 			# 28
    InstructionInfo(InstructionType.AND, MemMode.IMMEDIATE, 2, 2, 0), 			# 29
    InstructionInfo(InstructionType.ROL, MemMode.ACCUMULATOR, 1, 2, 0),         # 2a
    InstructionInfo(InstructionType.ANC, MemMode.IMMEDIATE, 0, 2, 0), 			# 2b
    InstructionInfo(InstructionType.BIT, MemMode.ABSOLUTE, 3, 4, 0), 			# 2c
    InstructionInfo(InstructionType.AND, MemMode.ABSOLUTE, 3, 4, 0), 			# 2d
    InstructionInfo(InstructionType.ROL, MemMode.ABSOLUTE, 3, 6, 0), 			# 2e
    InstructionInfo(InstructionType.RLA, MemMode.ABSOLUTE, 0, 6, 0), 			# 2f
    InstructionInfo(InstructionType.BMI, MemMode.RELATIVE, 2, 2, 1), 			# 30
    InstructionInfo(InstructionType.AND, MemMode.INDIRECT_INDEXED, 2, 5, 1), 	# 31
    InstructionInfo(InstructionType.KIL, MemMode.IMPLIED, 0, 2, 0), 			# 32
    InstructionInfo(InstructionType.RLA, MemMode.INDIRECT_INDEXED, 0, 8, 0), 	# 33
    InstructionInfo(InstructionType.NOP, MemMode.ZEROPAGE_X, 2, 4, 0), 			# 34
    InstructionInfo(InstructionType.AND, MemMode.ZEROPAGE_X, 2, 4, 0), 			# 35
    InstructionInfo(InstructionType.ROL, MemMode.ZEROPAGE_X, 2, 6, 0), 			# 36
    InstructionInfo(InstructionType.RLA, MemMode.ZEROPAGE_X, 0, 6, 0), 			# 37
    InstructionInfo(InstructionType.SEC, MemMode.IMPLIED, 1, 2, 0), 			# 38
    InstructionInfo(InstructionType.AND, MemMode.ABSOLUTE_Y, 3, 4, 1), 			# 39
    InstructionInfo(InstructionType.NOP, MemMode.IMPLIED, 1, 2, 0), 			# 3a
    InstructionInfo(InstructionType.RLA, MemMode.ABSOLUTE_Y, 0, 7, 0), 			# 3b
    InstructionInfo(InstructionType.NOP, MemMode.ABSOLUTE_X, 3, 4, 1), 			# 3c
    InstructionInfo(InstructionType.AND, MemMode.ABSOLUTE_X, 3, 4, 1), 			# 3d
    InstructionInfo(InstructionType.ROL, MemMode.ABSOLUTE_X, 3, 7, 0), 			# 3e
    InstructionInfo(InstructionType.RLA, MemMode.ABSOLUTE_X, 0, 7, 0), 			# 3f
    InstructionInfo(InstructionType.RTI, MemMode.IMPLIED, 1, 6, 0), 			# 40
    InstructionInfo(InstructionType.EOR, MemMode.INDEXED_INDIRECT, 2, 6, 0), 	# 41
    InstructionInfo(InstructionType.KIL, MemMode.IMPLIED, 0, 2, 0), 			# 42
    InstructionInfo(InstructionType.SRE, MemMode.INDEXED_INDIRECT, 0, 8, 0), 	# 43
    InstructionInfo(InstructionType.NOP, MemMode.ZEROPAGE, 2, 3, 0), 			# 44
    InstructionInfo(InstructionType.EOR, MemMode.ZEROPAGE, 2, 3, 0), 			# 45
    InstructionInfo(InstructionType.LSR, MemMode.ZEROPAGE, 2, 5, 0), 			# 46
    InstructionInfo(InstructionType.SRE, MemMode.ZEROPAGE, 0, 5, 0), 			# 47
    InstructionInfo(InstructionType.PHA, MemMode.IMPLIED, 1, 3, 0), 			# 48
    InstructionInfo(InstructionType.EOR, MemMode.IMMEDIATE, 2, 2, 0), 			# 49
    InstructionInfo(InstructionType.LSR, MemMode.ACCUMULATOR, 1, 2, 0),         # 4a
    InstructionInfo(InstructionType.ALR, MemMode.IMMEDIATE, 0, 2, 0), 			# 4b
    InstructionInfo(InstructionType.JMP, MemMode.ABSOLUTE, 3, 3, 0), 			# 4c
    InstructionInfo(InstructionType.EOR, MemMode.ABSOLUTE, 3, 4, 0), 			# 4d
    InstructionInfo(InstructionType.LSR, MemMode.ABSOLUTE, 3, 6, 0), 			# 4e
    InstructionInfo(InstructionType.SRE, MemMode.ABSOLUTE, 0, 6, 0), 			# 4f
    InstructionInfo(InstructionType.BVC, MemMode.RELATIVE, 2, 2, 1), 			# 50
    InstructionInfo(InstructionType.EOR, MemMode.INDIRECT_INDEXED, 2, 5, 1), 	# 51
    InstructionInfo(InstructionType.KIL, MemMode.IMPLIED, 0, 2, 0), 			# 52
    InstructionInfo(InstructionType.SRE, MemMode.INDIRECT_INDEXED, 0, 8, 0), 	# 53
    InstructionInfo(InstructionType.NOP, MemMode.ZEROPAGE_X, 2, 4, 0), 			# 54
    InstructionInfo(InstructionType.EOR, MemMode.ZEROPAGE_X, 2, 4, 0), 			# 55
    InstructionInfo(InstructionType.LSR, MemMode.ZEROPAGE_X, 2, 6, 0), 			# 56
    InstructionInfo(InstructionType.SRE, MemMode.ZEROPAGE_X, 0, 6, 0), 			# 57
    InstructionInfo(InstructionType.CLI, MemMode.IMPLIED, 1, 2, 0), 			# 58
    InstructionInfo(InstructionType.EOR, MemMode.ABSOLUTE_Y, 3, 4, 1), 			# 59
    InstructionInfo(InstructionType.NOP, MemMode.IMPLIED, 1, 2, 0), 			# 5a
    InstructionInfo(InstructionType.SRE, MemMode.ABSOLUTE_Y, 0, 7, 0), 			# 5b
    InstructionInfo(InstructionType.NOP, MemMode.ABSOLUTE_X, 3, 4, 1), 			# 5c
    InstructionInfo(InstructionType.EOR, MemMode.ABSOLUTE_X, 3, 4, 1), 			# 5d
    InstructionInfo(InstructionType.LSR, MemMode.ABSOLUTE_X, 3, 7, 0), 			# 5e
    InstructionInfo(InstructionType.SRE, MemMode.ABSOLUTE_X, 0, 7, 0), 			# 5f
    InstructionInfo(InstructionType.RTS, MemMode.IMPLIED, 1, 6, 0), 			# 60
    InstructionInfo(InstructionType.ADC, MemMode.INDEXED_INDIRECT, 2, 6, 0), 	# 61
    InstructionInfo(InstructionType.KIL, MemMode.IMPLIED, 0, 2, 0), 			# 62
    InstructionInfo(InstructionType.RRA, MemMode.INDEXED_INDIRECT, 0, 8, 0), 	# 63
    InstructionInfo(InstructionType.NOP, MemMode.ZEROPAGE, 2, 3, 0), 			# 64
    InstructionInfo(InstructionType.ADC, MemMode.ZEROPAGE, 2, 3, 0), 			# 65
    InstructionInfo(InstructionType.ROR, MemMode.ZEROPAGE, 2, 5, 0), 			# 66
    InstructionInfo(InstructionType.RRA, MemMode.ZEROPAGE, 0, 5, 0), 			# 67
    InstructionInfo(InstructionType.PLA, MemMode.IMPLIED, 1, 4, 0), 			# 68
    InstructionInfo(InstructionType.ADC, MemMode.IMMEDIATE, 2, 2, 0), 			# 69
    InstructionInfo(InstructionType.ROR, MemMode.ACCUMULATOR, 1, 2, 0), 		# 6a
    InstructionInfo(InstructionType.ARR, MemMode.IMMEDIATE, 0, 2, 0), 			# 6b
    InstructionInfo(InstructionType.JMP, MemMode.INDIRECT, 3, 5, 0), 			# 6c
    InstructionInfo(InstructionType.ADC, MemMode.ABSOLUTE, 3, 4, 0), 			# 6d
    InstructionInfo(InstructionType.ROR, MemMode.ABSOLUTE, 3, 6, 0), 			# 6e
    InstructionInfo(InstructionType.RRA, MemMode.ABSOLUTE, 0, 6, 0), 			# 6f
    InstructionInfo(InstructionType.BVS, MemMode.RELATIVE, 2, 2, 1), 			# 70
    InstructionInfo(InstructionType.ADC, MemMode.INDIRECT_INDEXED, 2, 5, 1), 	# 71
    InstructionInfo(InstructionType.KIL, MemMode.IMPLIED, 0, 2, 0), 			# 72
    InstructionInfo(InstructionType.RRA, MemMode.INDIRECT_INDEXED, 0, 8, 0), 	# 73
    InstructionInfo(InstructionType.NOP, MemMode.ZEROPAGE_X, 2, 4, 0), 			# 74
    InstructionInfo(InstructionType.ADC, MemMode.ZEROPAGE_X, 2, 4, 0), 			# 75
    InstructionInfo(InstructionType.ROR, MemMode.ZEROPAGE_X, 2, 6, 0), 			# 76
    InstructionInfo(InstructionType.RRA, MemMode.ZEROPAGE_X, 0, 6, 0), 			# 77
    InstructionInfo(InstructionType.SEI, MemMode.IMPLIED, 1, 2, 0), 			# 78
    InstructionInfo(InstructionType.ADC, MemMode.ABSOLUTE_Y, 3, 4, 1), 			# 79
    InstructionInfo(InstructionType.NOP, MemMode.IMPLIED, 1, 2, 0), 			# 7a
    InstructionInfo(InstructionType.RRA, MemMode.ABSOLUTE_Y, 0, 7, 0), 			# 7b
    InstructionInfo(InstructionType.NOP, MemMode.ABSOLUTE_X, 3, 4, 1), 			# 7c
    InstructionInfo(InstructionType.ADC, MemMode.ABSOLUTE_X, 3, 4, 1), 			# 7d
    InstructionInfo(InstructionType.ROR, MemMode.ABSOLUTE_X, 3, 7, 0), 			# 7e
    InstructionInfo(InstructionType.RRA, MemMode.ABSOLUTE_X, 0, 7, 0), 			# 7f
    InstructionInfo(InstructionType.NOP, MemMode.IMMEDIATE, 2, 2, 0), 			# 80
    InstructionInfo(InstructionType.STA, MemMode.INDEXED_INDIRECT, 2, 6, 0), 	# 81
    InstructionInfo(InstructionType.NOP, MemMode.IMMEDIATE, 0, 2, 0), 			# 82
    InstructionInfo(InstructionType.SAX, MemMode.INDEXED_INDIRECT, 0, 6, 0), 	# 83
    InstructionInfo(InstructionType.STY, MemMode.ZEROPAGE, 2, 3, 0), 			# 84
    InstructionInfo(InstructionType.STA, MemMode.ZEROPAGE, 2, 3, 0), 			# 85
    InstructionInfo(InstructionType.STX, MemMode.ZEROPAGE, 2, 3, 0), 			# 86
    InstructionInfo(InstructionType.SAX, MemMode.ZEROPAGE, 0, 3, 0), 			# 87
    InstructionInfo(InstructionType.DEY, MemMode.IMPLIED, 1, 2, 0), 			# 88
    InstructionInfo(InstructionType.NOP, MemMode.IMMEDIATE, 0, 2, 0), 			# 89
    InstructionInfo(InstructionType.TXA, MemMode.IMPLIED, 1, 2, 0), 			# 8a
    InstructionInfo(InstructionType.XAA, MemMode.IMMEDIATE, 0, 2, 0), 			# 8b
    InstructionInfo(InstructionType.STY, MemMode.ABSOLUTE, 3, 4, 0), 			# 8c
    InstructionInfo(InstructionType.STA, MemMode.ABSOLUTE, 3, 4, 0), 			# 8d
    InstructionInfo(InstructionType.STX, MemMode.ABSOLUTE, 3, 4, 0), 			# 8e
    InstructionInfo(InstructionType.SAX, MemMode.ABSOLUTE, 0, 4, 0), 			# 8f
    InstructionInfo(InstructionType.BCC, MemMode.RELATIVE, 2, 2, 1), 			# 90
    InstructionInfo(InstructionType.STA, MemMode.INDIRECT_INDEXED, 2, 6, 0), 	# 91
    InstructionInfo(InstructionType.KIL, MemMode.IMPLIED, 0, 2, 0), 			# 92
    InstructionInfo(InstructionType.AHX, MemMode.INDIRECT_INDEXED, 0, 6, 0), 	# 93
    InstructionInfo(InstructionType.STY, MemMode.ZEROPAGE_X, 2, 4, 0), 			# 94
    InstructionInfo(InstructionType.STA, MemMode.ZEROPAGE_X, 2, 4, 0), 			# 95
    InstructionInfo(InstructionType.STX, MemMode.ZEROPAGE_Y, 2, 4, 0), 			# 96
    InstructionInfo(InstructionType.SAX, MemMode.ZEROPAGE_Y, 0, 4, 0), 			# 97
    InstructionInfo(InstructionType.TYA, MemMode.IMPLIED, 1, 2, 0), 			# 98
    InstructionInfo(InstructionType.STA, MemMode.ABSOLUTE_Y, 3, 5, 0), 			# 99
    InstructionInfo(InstructionType.TXS, MemMode.IMPLIED, 1, 2, 0), 			# 9a
    InstructionInfo(InstructionType.TAS, MemMode.ABSOLUTE_Y, 0, 5, 0), 			# 9b
    InstructionInfo(InstructionType.SHY, MemMode.ABSOLUTE_X, 0, 5, 0), 			# 9c
    InstructionInfo(InstructionType.STA, MemMode.ABSOLUTE_X, 3, 5, 0), 			# 9d
    InstructionInfo(InstructionType.SHX, MemMode.ABSOLUTE_Y, 0, 5, 0), 			# 9e
    InstructionInfo(InstructionType.AHX, MemMode.ABSOLUTE_Y, 0, 5, 0), 			# 9f
    InstructionInfo(InstructionType.LDY, MemMode.IMMEDIATE, 2, 2, 0), 			# a0
    InstructionInfo(InstructionType.LDA, MemMode.INDEXED_INDIRECT, 2, 6, 0), 	# a1
    InstructionInfo(InstructionType.LDX, MemMode.IMMEDIATE, 2, 2, 0), 			# a2
    InstructionInfo(InstructionType.LAX, MemMode.INDEXED_INDIRECT, 0, 6, 0), 	# a3
    InstructionInfo(InstructionType.LDY, MemMode.ZEROPAGE, 2, 3, 0), 			# a4
    InstructionInfo(InstructionType.LDA, MemMode.ZEROPAGE, 2, 3, 0), 			# a5
    InstructionInfo(InstructionType.LDX, MemMode.ZEROPAGE, 2, 3, 0), 			# a6
    InstructionInfo(InstructionType.LAX, MemMode.ZEROPAGE, 0, 3, 0), 			# a7
    InstructionInfo(InstructionType.TAY, MemMode.IMPLIED, 1, 2, 0), 			# a8
    InstructionInfo(InstructionType.LDA, MemMode.IMMEDIATE, 2, 2, 0), 			# a9
    InstructionInfo(InstructionType.TAX, MemMode.IMPLIED, 1, 2, 0), 			# aa
    InstructionInfo(InstructionType.LAX, MemMode.IMMEDIATE, 0, 2, 0), 			# ab
    InstructionInfo(InstructionType.LDY, MemMode.ABSOLUTE, 3, 4, 0), 			# ac
    InstructionInfo(InstructionType.LDA, MemMode.ABSOLUTE, 3, 4, 0), 			# ad
    InstructionInfo(InstructionType.LDX, MemMode.ABSOLUTE, 3, 4, 0), 			# ae
    InstructionInfo(InstructionType.LAX, MemMode.ABSOLUTE, 0, 4, 0), 			# af
    InstructionInfo(InstructionType.BCS, MemMode.RELATIVE, 2, 2, 1), 			# b0
    InstructionInfo(InstructionType.LDA, MemMode.INDIRECT_INDEXED, 2, 5, 1), 	# b1
    InstructionInfo(InstructionType.KIL, MemMode.IMPLIED, 0, 2, 0), 			# b2
    InstructionInfo(InstructionType.LAX, MemMode.INDIRECT_INDEXED, 0, 5, 1), 	# b3
    InstructionInfo(InstructionType.LDY, MemMode.ZEROPAGE_X, 2, 4, 0), 			# b4
    InstructionInfo(InstructionType.LDA, MemMode.ZEROPAGE_X, 2, 4, 0), 			# b5
    InstructionInfo(InstructionType.LDX, MemMode.ZEROPAGE_Y, 2, 4, 0), 			# b6
    InstructionInfo(InstructionType.LAX, MemMode.ZEROPAGE_Y, 0, 4, 0), 			# b7
    InstructionInfo(InstructionType.CLV, MemMode.IMPLIED, 1, 2, 0), 			# b8
    InstructionInfo(InstructionType.LDA, MemMode.ABSOLUTE_Y, 3, 4, 1), 			# b9
    InstructionInfo(InstructionType.TSX, MemMode.IMPLIED, 1, 2, 0), 			# ba
    InstructionInfo(InstructionType.LAS, MemMode.ABSOLUTE_Y, 0, 4, 1), 			# bb
    InstructionInfo(InstructionType.LDY, MemMode.ABSOLUTE_X, 3, 4, 1), 			# bc
    InstructionInfo(InstructionType.LDA, MemMode.ABSOLUTE_X, 3, 4, 1), 			# bd
    InstructionInfo(InstructionType.LDX, MemMode.ABSOLUTE_Y, 3, 4, 1), 			# be
    InstructionInfo(InstructionType.LAX, MemMode.ABSOLUTE_Y, 0, 4, 1), 			# bf
    InstructionInfo(InstructionType.CPY, MemMode.IMMEDIATE, 2, 2, 0), 			# c0
    InstructionInfo(InstructionType.CMP, MemMode.INDEXED_INDIRECT, 2, 6, 0), 	# c1
    InstructionInfo(InstructionType.NOP, MemMode.IMMEDIATE, 0, 2, 0), 			# c2
    InstructionInfo(InstructionType.DCP, MemMode.INDEXED_INDIRECT, 0, 8, 0), 	# c3
    InstructionInfo(InstructionType.CPY, MemMode.ZEROPAGE, 2, 3, 0), 			# c4
    InstructionInfo(InstructionType.CMP, MemMode.ZEROPAGE, 2, 3, 0), 			# c5
    InstructionInfo(InstructionType.DEC, MemMode.ZEROPAGE, 2, 5, 0), 			# c6
    InstructionInfo(InstructionType.DCP, MemMode.ZEROPAGE, 0, 5, 0), 			# c7
    InstructionInfo(InstructionType.INY, MemMode.IMPLIED, 1, 2, 0), 			# c8
    InstructionInfo(InstructionType.CMP, MemMode.IMMEDIATE, 2, 2, 0), 			# c9
    InstructionInfo(InstructionType.DEX, MemMode.IMPLIED, 1, 2, 0), 			# ca
    InstructionInfo(InstructionType.AXS, MemMode.IMMEDIATE, 0, 2, 0), 			# cb
    InstructionInfo(InstructionType.CPY, MemMode.ABSOLUTE, 3, 4, 0), 			# cc
    InstructionInfo(InstructionType.CMP, MemMode.ABSOLUTE, 3, 4, 0), 			# cd
    InstructionInfo(InstructionType.DEC, MemMode.ABSOLUTE, 3, 6, 0), 			# ce
    InstructionInfo(InstructionType.DCP, MemMode.ABSOLUTE, 0, 6, 0), 			# cf
    InstructionInfo(InstructionType.BNE, MemMode.RELATIVE, 2, 2, 1), 			# d0
    InstructionInfo(InstructionType.CMP, MemMode.INDIRECT_INDEXED, 2, 5, 1), 	# d1
    InstructionInfo(InstructionType.KIL, MemMode.IMPLIED, 0, 2, 0), 			# d2
    InstructionInfo(InstructionType.DCP, MemMode.INDIRECT_INDEXED, 0, 8, 0), 	# d3
    InstructionInfo(InstructionType.NOP, MemMode.ZEROPAGE_X, 2, 4, 0), 			# d4
    InstructionInfo(InstructionType.CMP, MemMode.ZEROPAGE_X, 2, 4, 0), 			# d5
    InstructionInfo(InstructionType.DEC, MemMode.ZEROPAGE_X, 2, 6, 0), 			# d6
    InstructionInfo(InstructionType.DCP, MemMode.ZEROPAGE_X, 0, 6, 0), 			# d7
    InstructionInfo(InstructionType.CLD, MemMode.IMPLIED, 1, 2, 0), 			# d8
    InstructionInfo(InstructionType.CMP, MemMode.ABSOLUTE_Y, 3, 4, 1), 			# d9
    InstructionInfo(InstructionType.NOP, MemMode.IMPLIED, 1, 2, 0), 			# da
    InstructionInfo(InstructionType.DCP, MemMode.ABSOLUTE_Y, 0, 7, 0), 			# db
    InstructionInfo(InstructionType.NOP, MemMode.ABSOLUTE_X, 3, 4, 1), 			# dc
    InstructionInfo(InstructionType.CMP, MemMode.ABSOLUTE_X, 3, 4, 1), 			# dd
    InstructionInfo(InstructionType.DEC, MemMode.ABSOLUTE_X, 3, 7, 0), 			# de
    InstructionInfo(InstructionType.DCP, MemMode.ABSOLUTE_X, 0, 7, 0), 			# df
    InstructionInfo(InstructionType.CPX, MemMode.IMMEDIATE, 2, 2, 0), 			# e0
    InstructionInfo(InstructionType.SBC, MemMode.INDEXED_INDIRECT, 2, 6, 0), 	# e1
    InstructionInfo(InstructionType.NOP, MemMode.IMMEDIATE, 0, 2, 0), 			# e2
    InstructionInfo(InstructionType.ISC, MemMode.INDEXED_INDIRECT, 0, 8, 0), 	# e3
    InstructionInfo(InstructionType.CPX, MemMode.ZEROPAGE, 2, 3, 0), 			# e4
    InstructionInfo(InstructionType.SBC, MemMode.ZEROPAGE, 2, 3, 0), 			# e5
    InstructionInfo(InstructionType.INC, MemMode.ZEROPAGE, 2, 5, 0), 			# e6
    InstructionInfo(InstructionType.ISC, MemMode.ZEROPAGE, 0, 5, 0), 			# e7
    InstructionInfo(InstructionType.INX, MemMode.IMPLIED, 1, 2, 0), 			# e8
    InstructionInfo(InstructionType.SBC, MemMode.IMMEDIATE, 2, 2, 0), 			# e9
    InstructionInfo(InstructionType.NOP, MemMode.IMPLIED, 1, 2, 0), 			# ea
    InstructionInfo(InstructionType.SBC, MemMode.IMMEDIATE, 0, 2, 0), 			# eb
    InstructionInfo(InstructionType.CPX, MemMode.ABSOLUTE, 3, 4, 0), 			# ec
    InstructionInfo(InstructionType.SBC, MemMode.ABSOLUTE, 3, 4, 0), 			# ed
    InstructionInfo(InstructionType.INC, MemMode.ABSOLUTE, 3, 6, 0), 			# ee
    InstructionInfo(InstructionType.ISC, MemMode.ABSOLUTE, 0, 6, 0), 			# ef
    InstructionInfo(InstructionType.BEQ, MemMode.RELATIVE, 2, 2, 1), 			# f0
    InstructionInfo(InstructionType.SBC, MemMode.INDIRECT_INDEXED, 2, 5, 1), 	# f1
    InstructionInfo(InstructionType.KIL, MemMode.IMPLIED, 0, 2, 0), 			# f2
    InstructionInfo(InstructionType.ISC, MemMode.INDIRECT_INDEXED, 0, 8, 0), 	# f3
    InstructionInfo(InstructionType.NOP, MemMode.ZEROPAGE_X, 2, 4, 0), 			# f4
    InstructionInfo(InstructionType.SBC, MemMode.ZEROPAGE_X, 2, 4, 0), 			# f5
    InstructionInfo(InstructionType.INC, MemMode.ZEROPAGE_X, 2, 6, 0), 			# f6
    InstructionInfo(InstructionType.ISC, MemMode.ZEROPAGE_X, 0, 6, 0), 			# f7
    InstructionInfo(InstructionType.SED, MemMode.IMPLIED, 1, 2, 0), 			# f8
    InstructionInfo(InstructionType.SBC, MemMode.ABSOLUTE_Y, 3, 4, 1), 			# f9
    InstructionInfo(InstructionType.NOP, MemMode.IMPLIED, 1, 2, 0), 			# fa
    InstructionInfo(InstructionType.ISC, MemMode.ABSOLUTE_Y, 0, 7, 0), 			# fb
    InstructionInfo(InstructionType.NOP, MemMode.ABSOLUTE_X, 3, 4, 1), 			# fc
    InstructionInfo(InstructionType.SBC, MemMode.ABSOLUTE_X, 3, 4, 1), 			# fd
    InstructionInfo(InstructionType.INC, MemMode.ABSOLUTE_X, 3, 7, 0), 			# fe
    InstructionInfo(InstructionType.ISC, MemMode.ABSOLUTE_X, 0, 7, 0), 			# ff
]


STACK_START = 0xFD
RESET_VECTOR = 0xFFFC
NMI_VECTOR = 0xFFFA
IRQ_BRK_VECTOR = 0xFFFE
MEM_SIZE = 2048


class CPU:
    def __init__(self, ppu: PPU, rom: ROM):
        # Memory on the CPU
        self.ram = array('B', [0] * MEM_SIZE)
        # Registers
        self.A: int = 0
        self.X: int = 0
        self.Y: int = 0
        self.SP: int = STACK_START
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
        self.instruction_count: int = 0
        # Connections to Other Parts of the Console
        self.ppu: PPU = ppu
        self.rom: ROM = rom


    def address_for_mode(self, data: int, mode: MemMode) -> int:
        def different_pages(address1: int, address2: int) -> bool:
            return ((address1 & 0xFF00) != (address2 & 0xFF00))
        address = 0
        if mode == MemMode.ABSOLUTE:
            address = data
        elif mode == MemMode.ABSOLUTE_X:
            address = data + self.X
            self.page_crossed = different_pages(address, address - self.X)
        elif mode == MemMode.ABSOLUTE_Y:
            address = data + self.Y
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
            address += self.Y
            self.page_crossed = different_pages(address, address - self.Y)
        elif mode == MemMode.RELATIVE:
            address = (self.PC + 2 + data) if (data < 0x80) else (self.PC + 2 + (data - 256)) # signed
        elif mode == MemMode.ZEROPAGE:
            address = data
        elif mode == MemMode.ZEROPAGE_X:
            address = data + self.X
        elif mode == MemMode.ZEROPAGE_Y:
            address = data + self.Y
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
        elif address == 0x4016: # Joypad status
            return 0 # Must enter here stuff from joypad
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
            self.ppu.write_register(temp)
        elif address == 0x4014:  # DMA Transfer of Sprite Data
            # Do transfer... call ppu.dma_transfer
            # stall for 512 cycles while this completes
            self.stall = 512
        elif address == 0x4016:
            # Joypad strobe and readcoutn change... see original source
            return
        elif address < 0x6000:
            return # Unimplemented other kinds of IO
        else:  # Addresses from 0x6000 to 0xFFFF are from the cartridge
            # We haven't implemented support for cartridge RAM
            return #self.rom.write_cartridge(address)



