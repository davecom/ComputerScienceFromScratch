# NESEmulator/cpu.py
# From Computer Science from Scratch
# Copyright 2024 David Kopec
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
from __future__ import annotations
from enum import Enum
from dataclasses import dataclass
from array import array
from typing import Callable
from NESEmulator.ppu import PPU, SPR_RAM_SIZE
from NESEmulator.rom import ROM

MemMode = Enum("MemMode", "DUMMY ABSOLUTE ABSOLUTE_X ABSOLUTE_Y ACCUMULATOR "
                          "IMMEDIATE IMPLIED INDEXED_INDIRECT INDIRECT "
                          "INDIRECT_INDEXED RELATIVE ZEROPAGE ZEROPAGE_X "
                          "ZEROPAGE_Y")

InstructionType = Enum("InstructionType", "ADC AHX ALR ANC AND ARR ASL AXS "
                                          "BCC BCS BEQ BIT BMI BNE BPL BRK "
                                          "BVC BVS CLC CLD CLI CLV CMP CPX "
                                          "CPY DCP DEC DEX DEY EOR INC INX "
                                          "INY ISC JMP JSR KIL LAS LAX LDA "
                                          "LDX LDY LSR NOP ORA PHA PHP PLA "
                                          "PLP RLA ROL ROR RRA RTI RTS SAX "
                                          "SBC SEC SED SEI SHX SHY SLO SRE "
                                          "STA STX STY TAS TAX TAY TSX TXA "
                                          "TXS TYA XAA")


@dataclass(frozen=True)
class Instruction:
    type: InstructionType
    method: Callable[[Instruction, int], None]
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
                       (self.read_memory(RESET_VECTOR + 1,
                                         MemMode.ABSOLUTE) << 8)
        # Flags
        self.C: bool = False  # Carry
        self.Z: bool = False  # Zero
        self.I: bool = True  # Interrupt Disable
        self.D: bool = False  # Decimal Mode
        self.B: bool = False  # Break Command
        self.V: bool = False  # oVerflow
        self.N: bool = False  # Negative
        # Miscellaneous State
        self.jumped: bool = False
        self.page_crossed: bool = False
        self.cpu_ticks: int = 0
        self.stall: int = 0  # Number of cycles to stall
        self.joypad1 = Joypad()

        self.instructions = [
            Instruction(InstructionType.BRK, self.BRK, MemMode.IMPLIED, 1, 7, 0),  # 00
            Instruction(InstructionType.ORA, self.ORA, MemMode.INDEXED_INDIRECT, 2, 6, 0),
            Instruction(InstructionType.KIL, self.unimplemented, MemMode.IMPLIED, 0, 2, 0),
            Instruction(InstructionType.SLO, self.unimplemented, MemMode.INDEXED_INDIRECT, 0, 8, 0),
            Instruction(InstructionType.NOP, self.NOP, MemMode.ZEROPAGE, 2, 3, 0),  # 04
            Instruction(InstructionType.ORA, self.ORA, MemMode.ZEROPAGE, 2, 3, 0),  # 05
            Instruction(InstructionType.ASL, self.ASL, MemMode.ZEROPAGE, 2, 5, 0),  # 06
            Instruction(InstructionType.SLO, self.unimplemented, MemMode.ZEROPAGE, 0, 5, 0),
            Instruction(InstructionType.PHP, self.PHP, MemMode.IMPLIED, 1, 3, 0),  # 08
            Instruction(InstructionType.ORA, self.ORA, MemMode.IMMEDIATE, 2, 2, 0),  # 09
            Instruction(InstructionType.ASL, self.ASL, MemMode.ACCUMULATOR, 1, 2, 0),  # 0a
            Instruction(InstructionType.ANC, self.unimplemented, MemMode.IMMEDIATE, 0, 2, 0),
            Instruction(InstructionType.NOP, self.NOP, MemMode.ABSOLUTE, 3, 4, 0),  # 0c
            Instruction(InstructionType.ORA, self.ORA, MemMode.ABSOLUTE, 3, 4, 0),  # 0d
            Instruction(InstructionType.ASL, self.ASL, MemMode.ABSOLUTE, 3, 6, 0),  # 0e
            Instruction(InstructionType.SLO, self.unimplemented, MemMode.ABSOLUTE, 0, 6, 0),
            Instruction(InstructionType.BPL, self.BPL, MemMode.RELATIVE, 2, 2, 1),  # 10
            Instruction(InstructionType.ORA, self.ORA, MemMode.INDIRECT_INDEXED, 2, 5, 1),
            Instruction(InstructionType.KIL, self.unimplemented, MemMode.IMPLIED, 0, 2, 0),
            Instruction(InstructionType.SLO, self.unimplemented, MemMode.INDIRECT_INDEXED, 0, 8, 0),
            Instruction(InstructionType.NOP, self.NOP, MemMode.ZEROPAGE_X, 2, 4, 0),  # 14
            Instruction(InstructionType.ORA, self.ORA, MemMode.ZEROPAGE_X, 2, 4, 0),  # 15
            Instruction(InstructionType.ASL, self.ASL, MemMode.ZEROPAGE_X, 2, 6, 0),  # 16
            Instruction(InstructionType.SLO, self.unimplemented, MemMode.ZEROPAGE_X, 0, 6, 0),
            Instruction(InstructionType.CLC, self.CLC, MemMode.IMPLIED, 1, 2, 0),  # 18
            Instruction(InstructionType.ORA, self.ORA, MemMode.ABSOLUTE_Y, 3, 4, 1),  # 19
            Instruction(InstructionType.NOP, self.NOP, MemMode.IMPLIED, 1, 2, 0),  # 1a
            Instruction(InstructionType.SLO, self.unimplemented, MemMode.ABSOLUTE_Y, 0, 7, 0),
            Instruction(InstructionType.NOP, self.NOP, MemMode.ABSOLUTE_X, 3, 4, 1),  # 1c
            Instruction(InstructionType.ORA, self.ORA, MemMode.ABSOLUTE_X, 3, 4, 1),  # 1d
            Instruction(InstructionType.ASL, self.ASL, MemMode.ABSOLUTE_X, 3, 7, 0),  # 1e
            Instruction(InstructionType.SLO, self.unimplemented, MemMode.ABSOLUTE_X, 0, 7, 0),
            Instruction(InstructionType.JSR, self.JSR, MemMode.ABSOLUTE, 3, 6, 0),  # 20
            Instruction(InstructionType.AND, self.AND, MemMode.INDEXED_INDIRECT, 2, 6, 0),
            Instruction(InstructionType.KIL, self.unimplemented, MemMode.IMPLIED, 0, 2, 0),
            Instruction(InstructionType.RLA, self.unimplemented, MemMode.INDEXED_INDIRECT, 0, 8, 0),
            Instruction(InstructionType.BIT, self.BIT, MemMode.ZEROPAGE, 2, 3, 0),  # 24
            Instruction(InstructionType.AND, self.AND, MemMode.ZEROPAGE, 2, 3, 0),  # 25
            Instruction(InstructionType.ROL, self.ROL, MemMode.ZEROPAGE, 2, 5, 0),  # 26
            Instruction(InstructionType.RLA, self.unimplemented, MemMode.ZEROPAGE, 0, 5, 0),
            Instruction(InstructionType.PLP, self.PLP, MemMode.IMPLIED, 1, 4, 0),  # 28
            Instruction(InstructionType.AND, self.AND, MemMode.IMMEDIATE, 2, 2, 0),  # 29
            Instruction(InstructionType.ROL, self.ROL, MemMode.ACCUMULATOR, 1, 2, 0),  # 2a
            Instruction(InstructionType.ANC, self.unimplemented, MemMode.IMMEDIATE, 0, 2, 0),
            Instruction(InstructionType.BIT, self.BIT, MemMode.ABSOLUTE, 3, 4, 0),  # 2c
            Instruction(InstructionType.AND, self.AND, MemMode.ABSOLUTE, 3, 4, 0),  # 2d
            Instruction(InstructionType.ROL, self.ROL, MemMode.ABSOLUTE, 3, 6, 0),  # 2e
            Instruction(InstructionType.RLA, self.unimplemented, MemMode.ABSOLUTE, 0, 6, 0),
            Instruction(InstructionType.BMI, self.BMI, MemMode.RELATIVE, 2, 2, 1),  # 30
            Instruction(InstructionType.AND, self.AND, MemMode.INDIRECT_INDEXED, 2, 5, 1),
            Instruction(InstructionType.KIL, self.unimplemented, MemMode.IMPLIED, 0, 2, 0),
            Instruction(InstructionType.RLA, self.unimplemented, MemMode.INDIRECT_INDEXED, 0, 8, 0),
            Instruction(InstructionType.NOP, self.NOP, MemMode.ZEROPAGE_X, 2, 4, 0),  # 34
            Instruction(InstructionType.AND, self.AND, MemMode.ZEROPAGE_X, 2, 4, 0),  # 35
            Instruction(InstructionType.ROL, self.ROL, MemMode.ZEROPAGE_X, 2, 6, 0),  # 36
            Instruction(InstructionType.RLA, self.unimplemented, MemMode.ZEROPAGE_X, 0, 6, 0),
            Instruction(InstructionType.SEC, self.SEC, MemMode.IMPLIED, 1, 2, 0),  # 38
            Instruction(InstructionType.AND, self.AND, MemMode.ABSOLUTE_Y, 3, 4, 1),  # 39
            Instruction(InstructionType.NOP, self.NOP, MemMode.IMPLIED, 1, 2, 0),  # 3a
            Instruction(InstructionType.RLA, self.unimplemented, MemMode.ABSOLUTE_Y, 0, 7, 0),
            Instruction(InstructionType.NOP, self.NOP, MemMode.ABSOLUTE_X, 3, 4, 1),  # 3c
            Instruction(InstructionType.AND, self.AND, MemMode.ABSOLUTE_X, 3, 4, 1),  # 3d
            Instruction(InstructionType.ROL, self.ROL, MemMode.ABSOLUTE_X, 3, 7, 0),  # 3e
            Instruction(InstructionType.RLA, self.unimplemented, MemMode.ABSOLUTE_X, 0, 7, 0),
            Instruction(InstructionType.RTI, self.RTI, MemMode.IMPLIED, 1, 6, 0),  # 40
            Instruction(InstructionType.EOR, self.EOR, MemMode.INDEXED_INDIRECT, 2, 6, 0),
            Instruction(InstructionType.KIL, self.unimplemented, MemMode.IMPLIED, 0, 2, 0),
            Instruction(InstructionType.SRE, self.unimplemented, MemMode.INDEXED_INDIRECT, 0, 8, 0),
            Instruction(InstructionType.NOP, self.NOP, MemMode.ZEROPAGE, 2, 3, 0),  # 44
            Instruction(InstructionType.EOR, self.EOR, MemMode.ZEROPAGE, 2, 3, 0),  # 45
            Instruction(InstructionType.LSR, self.LSR, MemMode.ZEROPAGE, 2, 5, 0),  # 46
            Instruction(InstructionType.SRE, self.unimplemented, MemMode.ZEROPAGE, 0, 5, 0),
            Instruction(InstructionType.PHA, self.PHA, MemMode.IMPLIED, 1, 3, 0),  # 48
            Instruction(InstructionType.EOR, self.EOR, MemMode.IMMEDIATE, 2, 2, 0),  # 49
            Instruction(InstructionType.LSR, self.LSR, MemMode.ACCUMULATOR, 1, 2, 0),
            Instruction(InstructionType.ALR, self.unimplemented, MemMode.IMMEDIATE, 0, 2, 0),
            Instruction(InstructionType.JMP, self.JMP, MemMode.ABSOLUTE, 3, 3, 0),  # 4c
            Instruction(InstructionType.EOR, self.EOR, MemMode.ABSOLUTE, 3, 4, 0),  # 4d
            Instruction(InstructionType.LSR, self.LSR, MemMode.ABSOLUTE, 3, 6, 0),  # 4e
            Instruction(InstructionType.SRE, self.unimplemented, MemMode.ABSOLUTE, 0, 6, 0),
            Instruction(InstructionType.BVC, self.BVC, MemMode.RELATIVE, 2, 2, 1),  # 50
            Instruction(InstructionType.EOR, self.EOR, MemMode.INDIRECT_INDEXED, 2, 5, 1),
            Instruction(InstructionType.KIL, self.unimplemented, MemMode.IMPLIED, 0, 2, 0),
            Instruction(InstructionType.SRE, self.unimplemented, MemMode.INDIRECT_INDEXED, 0, 8, 0),
            Instruction(InstructionType.NOP, self.NOP, MemMode.ZEROPAGE_X, 2, 4, 0),  # 54
            Instruction(InstructionType.EOR, self.EOR, MemMode.ZEROPAGE_X, 2, 4, 0),  # 55
            Instruction(InstructionType.LSR, self.LSR, MemMode.ZEROPAGE_X, 2, 6, 0),  # 56
            Instruction(InstructionType.SRE, self.unimplemented, MemMode.ZEROPAGE_X, 0, 6, 0),
            Instruction(InstructionType.CLI, self.CLI, MemMode.IMPLIED, 1, 2, 0),  # 58
            Instruction(InstructionType.EOR, self.EOR, MemMode.ABSOLUTE_Y, 3, 4, 1),  # 59
            Instruction(InstructionType.NOP, self.NOP, MemMode.IMPLIED, 1, 2, 0),  # 5a
            Instruction(InstructionType.SRE, self.unimplemented, MemMode.ABSOLUTE_Y, 0, 7, 0),
            Instruction(InstructionType.NOP, self.NOP, MemMode.ABSOLUTE_X, 3, 4, 1),  # 5c
            Instruction(InstructionType.EOR, self.EOR, MemMode.ABSOLUTE_X, 3, 4, 1),  # 5d
            Instruction(InstructionType.LSR, self.LSR, MemMode.ABSOLUTE_X, 3, 7, 0),  # 5e
            Instruction(InstructionType.SRE, self.unimplemented, MemMode.ABSOLUTE_X, 0, 7, 0),
            Instruction(InstructionType.RTS, self.RTS, MemMode.IMPLIED, 1, 6, 0),  # 60
            Instruction(InstructionType.ADC, self.ADC, MemMode.INDEXED_INDIRECT, 2, 6, 0),
            Instruction(InstructionType.KIL, self.unimplemented, MemMode.IMPLIED, 0, 2, 0),
            Instruction(InstructionType.RRA, self.unimplemented, MemMode.INDEXED_INDIRECT, 0, 8, 0),
            Instruction(InstructionType.NOP, self.NOP, MemMode.ZEROPAGE, 2, 3, 0),  # 64
            Instruction(InstructionType.ADC, self.ADC, MemMode.ZEROPAGE, 2, 3, 0),  # 65
            Instruction(InstructionType.ROR, self.ROR, MemMode.ZEROPAGE, 2, 5, 0),  # 66
            Instruction(InstructionType.RRA, self.unimplemented, MemMode.ZEROPAGE, 0, 5, 0),
            Instruction(InstructionType.PLA, self.PLA, MemMode.IMPLIED, 1, 4, 0),  # 68
            Instruction(InstructionType.ADC, self.ADC, MemMode.IMMEDIATE, 2, 2, 0),  # 69
            Instruction(InstructionType.ROR, self.ROR, MemMode.ACCUMULATOR, 1, 2, 0),  # 6a
            Instruction(InstructionType.ARR, self.unimplemented, MemMode.IMMEDIATE, 0, 2, 0),
            Instruction(InstructionType.JMP, self.JMP, MemMode.INDIRECT, 3, 5, 0),  # 6c
            Instruction(InstructionType.ADC, self.ADC, MemMode.ABSOLUTE, 3, 4, 0),  # 6d
            Instruction(InstructionType.ROR, self.ROR, MemMode.ABSOLUTE, 3, 6, 0),  # 6e
            Instruction(InstructionType.RRA, self.unimplemented, MemMode.ABSOLUTE, 0, 6, 0),
            Instruction(InstructionType.BVS, self.BVS, MemMode.RELATIVE, 2, 2, 1),  # 70
            Instruction(InstructionType.ADC, self.ADC, MemMode.INDIRECT_INDEXED, 2, 5, 1),
            Instruction(InstructionType.KIL, self.unimplemented, MemMode.IMPLIED, 0, 2, 0),
            Instruction(InstructionType.RRA, self.unimplemented, MemMode.INDIRECT_INDEXED, 0, 8, 0),
            Instruction(InstructionType.NOP, self.NOP, MemMode.ZEROPAGE_X, 2, 4, 0),  # 74
            Instruction(InstructionType.ADC, self.ADC, MemMode.ZEROPAGE_X, 2, 4, 0),  # 75
            Instruction(InstructionType.ROR, self.ROR, MemMode.ZEROPAGE_X, 2, 6, 0),  # 76
            Instruction(InstructionType.RRA, self.unimplemented, MemMode.ZEROPAGE_X, 0, 6, 0),
            Instruction(InstructionType.SEI, self.SEI, MemMode.IMPLIED, 1, 2, 0),  # 78
            Instruction(InstructionType.ADC, self.ADC, MemMode.ABSOLUTE_Y, 3, 4, 1),  # 79
            Instruction(InstructionType.NOP, self.NOP, MemMode.IMPLIED, 1, 2, 0),  # 7a
            Instruction(InstructionType.RRA, self.unimplemented, MemMode.ABSOLUTE_Y, 0, 7, 0),
            Instruction(InstructionType.NOP, self.NOP, MemMode.ABSOLUTE_X, 3, 4, 1),  # 7c
            Instruction(InstructionType.ADC, self.ADC, MemMode.ABSOLUTE_X, 3, 4, 1),  # 7d
            Instruction(InstructionType.ROR, self.ROR, MemMode.ABSOLUTE_X, 3, 7, 0),  # 7e
            Instruction(InstructionType.RRA, self.unimplemented, MemMode.ABSOLUTE_X, 0, 7, 0),
            Instruction(InstructionType.NOP, self.NOP, MemMode.IMMEDIATE, 2, 2, 0),  # 80
            Instruction(InstructionType.STA, self.STA, MemMode.INDEXED_INDIRECT, 2, 6, 0),
            Instruction(InstructionType.NOP, self.NOP, MemMode.IMMEDIATE, 0, 2, 0),  # 82
            Instruction(InstructionType.SAX, self.unimplemented, MemMode.INDEXED_INDIRECT, 0, 6, 0),
            Instruction(InstructionType.STY, self.STY, MemMode.ZEROPAGE, 2, 3, 0),  # 84
            Instruction(InstructionType.STA, self.STA, MemMode.ZEROPAGE, 2, 3, 0),  # 85
            Instruction(InstructionType.STX, self.STX, MemMode.ZEROPAGE, 2, 3, 0),  # 86
            Instruction(InstructionType.SAX, self.unimplemented, MemMode.ZEROPAGE, 0, 3, 0),
            Instruction(InstructionType.DEY, self.DEY, MemMode.IMPLIED, 1, 2, 0),  # 88
            Instruction(InstructionType.NOP, self.NOP, MemMode.IMMEDIATE, 0, 2, 0),  # 89
            Instruction(InstructionType.TXA, self.TXA, MemMode.IMPLIED, 1, 2, 0),  # 8a
            Instruction(InstructionType.XAA, self.unimplemented, MemMode.IMMEDIATE, 0, 2, 0),
            Instruction(InstructionType.STY, self.STY, MemMode.ABSOLUTE, 3, 4, 0),  # 8c
            Instruction(InstructionType.STA, self.STA, MemMode.ABSOLUTE, 3, 4, 0),  # 8d
            Instruction(InstructionType.STX, self.STX, MemMode.ABSOLUTE, 3, 4, 0),  # 8e
            Instruction(InstructionType.SAX, self.unimplemented, MemMode.ABSOLUTE, 0, 4, 0),
            Instruction(InstructionType.BCC, self.BCC, MemMode.RELATIVE, 2, 2, 1),  # 90
            Instruction(InstructionType.STA, self.STA, MemMode.INDIRECT_INDEXED, 2, 6, 0),
            Instruction(InstructionType.KIL, self.unimplemented, MemMode.IMPLIED, 0, 2, 0),
            Instruction(InstructionType.AHX, self.unimplemented, MemMode.INDIRECT_INDEXED, 0, 6, 0),
            Instruction(InstructionType.STY, self.STY, MemMode.ZEROPAGE_X, 2, 4, 0),  # 94
            Instruction(InstructionType.STA, self.STA, MemMode.ZEROPAGE_X, 2, 4, 0),  # 95
            Instruction(InstructionType.STX, self.STX, MemMode.ZEROPAGE_Y, 2, 4, 0),  # 96
            Instruction(InstructionType.SAX, self.unimplemented, MemMode.ZEROPAGE_Y, 0, 4, 0),
            Instruction(InstructionType.TYA, self.TYA, MemMode.IMPLIED, 1, 2, 0),  # 98
            Instruction(InstructionType.STA, self.STA, MemMode.ABSOLUTE_Y, 3, 5, 0),  # 99
            Instruction(InstructionType.TXS, self.TXS, MemMode.IMPLIED, 1, 2, 0),  # 9a
            Instruction(InstructionType.TAS, self.unimplemented, MemMode.ABSOLUTE_Y, 0, 5, 0),
            Instruction(InstructionType.SHY, self.unimplemented, MemMode.ABSOLUTE_X, 0, 5, 0),
            Instruction(InstructionType.STA, self.STA, MemMode.ABSOLUTE_X, 3, 5, 0),  # 9d
            Instruction(InstructionType.SHX, self.unimplemented, MemMode.ABSOLUTE_Y, 0, 5, 0),
            Instruction(InstructionType.AHX, self.unimplemented, MemMode.ABSOLUTE_Y, 0, 5, 0),
            Instruction(InstructionType.LDY, self.LDY, MemMode.IMMEDIATE, 2, 2, 0),  # a0
            Instruction(InstructionType.LDA, self.LDA, MemMode.INDEXED_INDIRECT, 2, 6, 0),
            Instruction(InstructionType.LDX, self.LDX, MemMode.IMMEDIATE, 2, 2, 0),  # a2
            Instruction(InstructionType.LAX, self.unimplemented, MemMode.INDEXED_INDIRECT, 0, 6, 0),
            Instruction(InstructionType.LDY, self.LDY, MemMode.ZEROPAGE, 2, 3, 0),  # a4
            Instruction(InstructionType.LDA, self.LDA, MemMode.ZEROPAGE, 2, 3, 0),  # a5
            Instruction(InstructionType.LDX, self.LDX, MemMode.ZEROPAGE, 2, 3, 0),  # a6
            Instruction(InstructionType.LAX, self.unimplemented, MemMode.ZEROPAGE, 0, 3, 0),
            Instruction(InstructionType.TAY, self.TAY, MemMode.IMPLIED, 1, 2, 0),  # a8
            Instruction(InstructionType.LDA, self.LDA, MemMode.IMMEDIATE, 2, 2, 0),  # a9
            Instruction(InstructionType.TAX, self.TAX, MemMode.IMPLIED, 1, 2, 0),  # aa
            Instruction(InstructionType.LAX, self.unimplemented, MemMode.IMMEDIATE, 0, 2, 0),
            Instruction(InstructionType.LDY, self.LDY, MemMode.ABSOLUTE, 3, 4, 0),  # ac
            Instruction(InstructionType.LDA, self.LDA, MemMode.ABSOLUTE, 3, 4, 0),  # ad
            Instruction(InstructionType.LDX, self.LDX, MemMode.ABSOLUTE, 3, 4, 0),  # ae
            Instruction(InstructionType.LAX, self.unimplemented, MemMode.ABSOLUTE, 0, 4, 0),
            Instruction(InstructionType.BCS, self.BCS, MemMode.RELATIVE, 2, 2, 1),  # b0
            Instruction(InstructionType.LDA, self.LDA, MemMode.INDIRECT_INDEXED, 2, 5, 1),
            Instruction(InstructionType.KIL, self.unimplemented, MemMode.IMPLIED, 0, 2, 0),
            Instruction(InstructionType.LAX, self.unimplemented, MemMode.INDIRECT_INDEXED, 0, 5, 1),
            Instruction(InstructionType.LDY, self.LDY, MemMode.ZEROPAGE_X, 2, 4, 0),  # b4
            Instruction(InstructionType.LDA, self.LDA, MemMode.ZEROPAGE_X, 2, 4, 0),  # b5
            Instruction(InstructionType.LDX, self.LDX, MemMode.ZEROPAGE_Y, 2, 4, 0),  # b6
            Instruction(InstructionType.LAX, self.unimplemented, MemMode.ZEROPAGE_Y, 0, 4, 0),
            Instruction(InstructionType.CLV, self.CLV, MemMode.IMPLIED, 1, 2, 0),  # b8
            Instruction(InstructionType.LDA, self.LDA, MemMode.ABSOLUTE_Y, 3, 4, 1),  # b9
            Instruction(InstructionType.TSX, self.TSX, MemMode.IMPLIED, 1, 2, 0),  # ba
            Instruction(InstructionType.LAS, self.unimplemented, MemMode.ABSOLUTE_Y, 0, 4, 1),
            Instruction(InstructionType.LDY, self.LDY, MemMode.ABSOLUTE_X, 3, 4, 1),  # bc
            Instruction(InstructionType.LDA, self.LDA, MemMode.ABSOLUTE_X, 3, 4, 1),  # bd
            Instruction(InstructionType.LDX, self.LDX, MemMode.ABSOLUTE_Y, 3, 4, 1),  # be
            Instruction(InstructionType.LAX, self.unimplemented, MemMode.ABSOLUTE_Y, 0, 4, 1),
            Instruction(InstructionType.CPY, self.CPY, MemMode.IMMEDIATE, 2, 2, 0),  # c0
            Instruction(InstructionType.CMP, self.CMP, MemMode.INDEXED_INDIRECT, 2, 6, 0),
            Instruction(InstructionType.NOP, self.NOP, MemMode.IMMEDIATE, 0, 2, 0),  # c2
            Instruction(InstructionType.DCP, self.unimplemented, MemMode.INDEXED_INDIRECT, 0, 8, 0),
            Instruction(InstructionType.CPY, self.CPY, MemMode.ZEROPAGE, 2, 3, 0),  # c4
            Instruction(InstructionType.CMP, self.CMP, MemMode.ZEROPAGE, 2, 3, 0),  # c5
            Instruction(InstructionType.DEC, self.DEC, MemMode.ZEROPAGE, 2, 5, 0),  # c6
            Instruction(InstructionType.DCP, self.unimplemented, MemMode.ZEROPAGE, 0, 5, 0),
            Instruction(InstructionType.INY, self.INY, MemMode.IMPLIED, 1, 2, 0),  # c8
            Instruction(InstructionType.CMP, self.CMP, MemMode.IMMEDIATE, 2, 2, 0),  # c9
            Instruction(InstructionType.DEX, self.DEX, MemMode.IMPLIED, 1, 2, 0),  # ca
            Instruction(InstructionType.AXS, self.unimplemented, MemMode.IMMEDIATE, 0, 2, 0),
            Instruction(InstructionType.CPY, self.CPY, MemMode.ABSOLUTE, 3, 4, 0),  # cc
            Instruction(InstructionType.CMP, self.CMP, MemMode.ABSOLUTE, 3, 4, 0),  # cd
            Instruction(InstructionType.DEC, self.DEC, MemMode.ABSOLUTE, 3, 6, 0),  # ce
            Instruction(InstructionType.DCP, self.unimplemented, MemMode.ABSOLUTE, 0, 6, 0),
            Instruction(InstructionType.BNE, self.BNE, MemMode.RELATIVE, 2, 2, 1),  # d0
            Instruction(InstructionType.CMP, self.CMP, MemMode.INDIRECT_INDEXED, 2, 5, 1),
            Instruction(InstructionType.KIL, self.unimplemented, MemMode.IMPLIED, 0, 2, 0),
            Instruction(InstructionType.DCP, self.unimplemented, MemMode.INDIRECT_INDEXED, 0, 8, 0),
            Instruction(InstructionType.NOP, self.NOP, MemMode.ZEROPAGE_X, 2, 4, 0),  # d4
            Instruction(InstructionType.CMP, self.CMP, MemMode.ZEROPAGE_X, 2, 4, 0),  # d5
            Instruction(InstructionType.DEC, self.DEC, MemMode.ZEROPAGE_X, 2, 6, 0),  # d6
            Instruction(InstructionType.DCP, self.unimplemented, MemMode.ZEROPAGE_X, 0, 6, 0),
            Instruction(InstructionType.CLD, self.CLD, MemMode.IMPLIED, 1, 2, 0),  # d8
            Instruction(InstructionType.CMP, self.CMP, MemMode.ABSOLUTE_Y, 3, 4, 1),  # d9
            Instruction(InstructionType.NOP, self.NOP, MemMode.IMPLIED, 1, 2, 0),  # da
            Instruction(InstructionType.DCP, self.unimplemented, MemMode.ABSOLUTE_Y, 0, 7, 0),
            Instruction(InstructionType.NOP, self.NOP, MemMode.ABSOLUTE_X, 3, 4, 1),  # dc
            Instruction(InstructionType.CMP, self.CMP, MemMode.ABSOLUTE_X, 3, 4, 1),  # dd
            Instruction(InstructionType.DEC, self.DEC, MemMode.ABSOLUTE_X, 3, 7, 0),  # de
            Instruction(InstructionType.DCP, self.unimplemented, MemMode.ABSOLUTE_X, 0, 7, 0),
            Instruction(InstructionType.CPX, self.CPX, MemMode.IMMEDIATE, 2, 2, 0),  # e0
            Instruction(InstructionType.SBC, self.SBC, MemMode.INDEXED_INDIRECT, 2, 6, 0),
            Instruction(InstructionType.NOP, self.NOP, MemMode.IMMEDIATE, 0, 2, 0),  # e2
            Instruction(InstructionType.ISC, self.unimplemented, MemMode.INDEXED_INDIRECT, 0, 8, 0),
            Instruction(InstructionType.CPX, self.CPX, MemMode.ZEROPAGE, 2, 3, 0),  # e4
            Instruction(InstructionType.SBC, self.SBC, MemMode.ZEROPAGE, 2, 3, 0),  # e5
            Instruction(InstructionType.INC, self.INC, MemMode.ZEROPAGE, 2, 5, 0),  # e6
            Instruction(InstructionType.ISC, self.unimplemented, MemMode.ZEROPAGE, 0, 5, 0),
            Instruction(InstructionType.INX, self.INX, MemMode.IMPLIED, 1, 2, 0),  # e8
            Instruction(InstructionType.SBC, self.SBC, MemMode.IMMEDIATE, 2, 2, 0),  # e9
            Instruction(InstructionType.NOP, self.NOP, MemMode.IMPLIED, 1, 2, 0),  # ea
            Instruction(InstructionType.SBC, self.SBC, MemMode.IMMEDIATE, 0, 2, 0),  # eb
            Instruction(InstructionType.CPX, self.CPX, MemMode.ABSOLUTE, 3, 4, 0),  # ec
            Instruction(InstructionType.SBC, self.SBC, MemMode.ABSOLUTE, 3, 4, 0),  # ed
            Instruction(InstructionType.INC, self.INC, MemMode.ABSOLUTE, 3, 6, 0),  # ee
            Instruction(InstructionType.ISC, self.unimplemented, MemMode.ABSOLUTE, 0, 6, 0),
            Instruction(InstructionType.BEQ, self.BEQ, MemMode.RELATIVE, 2, 2, 1),  # f0
            Instruction(InstructionType.SBC, self.SBC, MemMode.INDIRECT_INDEXED, 2, 5, 1),
            Instruction(InstructionType.KIL, self.unimplemented, MemMode.IMPLIED, 0, 2, 0),
            Instruction(InstructionType.ISC, self.unimplemented, MemMode.INDIRECT_INDEXED, 0, 8, 0),
            Instruction(InstructionType.NOP, self.NOP, MemMode.ZEROPAGE_X, 2, 4, 0),  # f4
            Instruction(InstructionType.SBC, self.SBC, MemMode.ZEROPAGE_X, 2, 4, 0),  # f5
            Instruction(InstructionType.INC, self.INC, MemMode.ZEROPAGE_X, 2, 6, 0),  # f6
            Instruction(InstructionType.ISC, self.unimplemented, MemMode.ZEROPAGE_X, 0, 6, 0),
            Instruction(InstructionType.SED, self.SED, MemMode.IMPLIED, 1, 2, 0),  # f8
            Instruction(InstructionType.SBC, self.SBC, MemMode.ABSOLUTE_Y, 3, 4, 1),  # f9
            Instruction(InstructionType.NOP, self.NOP, MemMode.IMPLIED, 1, 2, 0),  # fa
            Instruction(InstructionType.ISC, self.unimplemented, MemMode.ABSOLUTE_Y, 0, 7, 0),
            Instruction(InstructionType.NOP, self.NOP, MemMode.ABSOLUTE_X, 3, 4, 1),  # fc
            Instruction(InstructionType.SBC, self.SBC, MemMode.ABSOLUTE_X, 3, 4, 1),  # fd
            Instruction(InstructionType.INC, self.INC, MemMode.ABSOLUTE_X, 3, 7, 0),  # fe
            Instruction(InstructionType.ISC, self.unimplemented, MemMode.ABSOLUTE_X, 0, 7, 0),
        ]

    # add memory to accumulator with carry
    def ADC(self, instruction: Instruction, data: int):
        src = self.read_memory(data, instruction.mode)
        signed_result = src + self.A + self.C
        self.V = bool(~(self.A ^ src) & (self.A ^ signed_result) & 0x80)
        self.A = (self.A + src + self.C) % 256
        self.C = signed_result > 0xFF
        self.setZN(self.A)

    # bitwise AND with accumulator
    def AND(self, instruction: Instruction, data: int):
        src = self.read_memory(data, instruction.mode)
        self.A = self.A & src
        self.setZN(self.A)

    # arithmetic shift left
    def ASL(self, instruction: Instruction, data: int):
        src = self.A if instruction.mode == MemMode.ACCUMULATOR else (
            self.read_memory(data, instruction.mode))
        self.C = bool(src >> 7)  # carry is set to 7th bit
        src = (src << 1) & 0xFF
        self.setZN(src)
        if instruction.mode == MemMode.ACCUMULATOR:
            self.A = src
        else:
            self.write_memory(data, instruction.mode, src)

    # branch if carry clear
    def BCC(self, instruction: Instruction, data: int):
        if not self.C:
            self.PC = self.address_for_mode(data, instruction.mode)
            self.jumped = True

    # branch if carry set
    def BCS(self, instruction: Instruction, data: int):
        if self.C:
            self.PC = self.address_for_mode(data, instruction.mode)
            self.jumped = True

    # branch on result zero
    def BEQ(self, instruction: Instruction, data: int):
        if self.Z:
            self.PC = self.address_for_mode(data, instruction.mode)
            self.jumped = True

    # bit test bits in memory with accumulator
    def BIT(self, instruction: Instruction, data: int):
        src = self.read_memory(data, instruction.mode)
        self.V = bool((src >> 6) & 1)
        self.Z = ((src & self.A) == 0)
        self.N = ((src >> 7) == 1)

    # branch on result minus
    def BMI(self, instruction: Instruction, data: int):
        if self.N:
            self.PC = self.address_for_mode(data, instruction.mode)
            self.jumped = True

    # branch on result not zero
    def BNE(self, instruction: Instruction, data: int):
        if not self.Z:
            self.PC = self.address_for_mode(data, instruction.mode)
            self.jumped = True

    # branch on result plus
    def BPL(self, instruction: Instruction, data: int):
        if not self.N:
            self.PC = self.address_for_mode(data, instruction.mode)
            self.jumped = True

    # force break
    def BRK(self, instruction: Instruction, data: int):
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
        self.jumped = True

    # branch on overflow clear
    def BVC(self, instruction: Instruction, data: int):
        if not self.V:
            self.PC = self.address_for_mode(data, instruction.mode)
            self.jumped = True

    # branch on overflow set
    def BVS(self, instruction: Instruction, data: int):
        if self.V:
            self.PC = self.address_for_mode(data, instruction.mode)
            self.jumped = True

    # clear carry
    def CLC(self, instruction: Instruction, data: int):
        self.C = False

    # clear decimal
    def CLD(self, instruction: Instruction, data: int):
        self.D = False

    # clear interrupt
    def CLI(self, instruction: Instruction, data: int):
        self.I = False

    # clear overflow
    def CLV(self, instruction: Instruction, data: int):
        self.V = False

    # compare accumulator
    def CMP(self, instruction: Instruction, data: int):
        src = self.read_memory(data, instruction.mode)
        self.C = self.A >= src
        self.setZN(self.A - src)

    # compare X register
    def CPX(self, instruction: Instruction, data: int):
        src = self.read_memory(data, instruction.mode)
        self.C = self.X >= src
        self.setZN(self.X - src)

    # compare Y register
    def CPY(self, instruction: Instruction, data: int):
        src = self.read_memory(data, instruction.mode)
        self.C = self.Y >= src
        self.setZN(self.Y - src)

    # decrement memory
    def DEC(self, instruction: Instruction, data: int):
        src = self.read_memory(data, instruction.mode)
        src = (src - 1) & 0xFF
        self.write_memory(data, instruction.mode, src)
        self.setZN(src)

    # decrement X
    def DEX(self, instruction: Instruction, data: int):
        self.X = (self.X - 1) & 0xFF
        self.setZN(self.X)

    # decrement Y
    def DEY(self, instruction: Instruction, data: int):
        self.Y = (self.Y - 1) & 0xFF
        self.setZN(self.Y)

    # exclusive or memory with accumulator
    def EOR(self, instruction: Instruction, data: int):
        self.A ^= self.read_memory(data, instruction.mode)
        self.setZN(self.A)

    # increment memory
    def INC(self, instruction: Instruction, data: int):
        src = self.read_memory(data, instruction.mode)
        src = (src + 1) & 0xFF
        self.write_memory(data, instruction.mode, src)
        self.setZN(src)

    # increment X
    def INX(self, instruction: Instruction, data: int):
        self.X = (self.X + 1) & 0xFF
        self.setZN(self.X)

    # increment Y
    def INY(self, instruction: Instruction, data: int):
        self.Y = (self.Y + 1) & 0xFF
        self.setZN(self.Y)

    # jump
    def JMP(self, instruction: Instruction, data: int):
        self.PC = self.address_for_mode(data, instruction.mode)
        self.jumped = True

    # jump to subroutine
    def JSR(self, instruction: Instruction, data: int):
        self.PC += 2
        # push pc to stack
        self.stack_push((self.PC >> 8) & 0xFF)
        self.stack_push(self.PC & 0xFF)
        # jump to subroutine
        self.PC = self.address_for_mode(data, instruction.mode)
        self.jumped = True

    # load accumulator with memory
    def LDA(self, instruction: Instruction, data: int):
        self.A = self.read_memory(data, instruction.mode)
        self.setZN(self.A)

    # load X with memory
    def LDX(self, instruction: Instruction, data: int):
        self.X = self.read_memory(data, instruction.mode)
        self.setZN(self.X)

    # load Y with memory
    def LDY(self, instruction: Instruction, data: int):
        self.Y = self.read_memory(data, instruction.mode)
        self.setZN(self.Y)

    # logical shift right
    def LSR(self, instruction: Instruction, data: int):
        src = self.A if instruction.mode == MemMode.ACCUMULATOR else (
            self.read_memory(data, instruction.mode))
        self.C = bool(src & 1)  # carry is set to 0th bit
        src >>= 1
        self.setZN(src)
        if instruction.mode == MemMode.ACCUMULATOR:
            self.A = src
        else:
            self.write_memory(data, instruction.mode, src)

    # no op
    def NOP(self, instruction: Instruction, data: int):
        pass

    # or memory with accumulator
    def ORA(self, instruction: Instruction, data: int):
        self.A |= self.read_memory(data, instruction.mode)
        self.setZN(self.A)

    # push accumulator
    def PHA(self, instruction: Instruction, data: int):
        self.stack_push(self.A)

    # push status
    def PHP(self, instruction: Instruction, data: int):
        # http://nesdev.com/the%20'B'%20flag%20&%20BRK%20instruction.txt
        self.B = True
        self.stack_push(self.status)
        self.B = False

    # pull accumulator
    def PLA(self, instruction: Instruction, data: int):
        self.A = self.stack_pop()
        self.setZN(self.A)

    # pull status
    def PLP(self, instruction: Instruction, data: int):
        self.set_status(self.stack_pop())

    # rotate one bit left
    def ROL(self, instruction: Instruction, data: int):
        src = self.A if instruction.mode == MemMode.ACCUMULATOR else (
            self.read_memory(data, instruction.mode))
        old_c = self.C
        self.C = bool((src >> 7) & 1)  # carry is set to 7th bit
        src = ((src << 1) | old_c) & 0xFF
        self.setZN(src)
        if instruction.mode == MemMode.ACCUMULATOR:
            self.A = src
        else:
            self.write_memory(data, instruction.mode, src)

    # rotate one bit right
    def ROR(self, instruction: Instruction, data: int):
        src = self.A if instruction.mode == MemMode.ACCUMULATOR else (
            self.read_memory(data, instruction.mode))
        old_c = self.C
        self.C = bool(src & 1)  # carry is set to 0th bit
        src = ((src >> 1) | (old_c << 7)) & 0xFF
        self.setZN(src)
        if instruction.mode == MemMode.ACCUMULATOR:
            self.A = src
        else:
            self.write_memory(data, instruction.mode, src)

    # return from interrupt
    def RTI(self, instruction: Instruction, data: int):
        # pull Status out
        self.set_status(self.stack_pop())
        # pull PC out
        lb = self.stack_pop()
        hb = self.stack_pop()
        self.PC = ((hb << 8) | lb)
        self.jumped = True

    # return from subroutine
    def RTS(self, instruction: Instruction, data: int):
        # pull PC out
        lb = self.stack_pop()
        hb = self.stack_pop()
        self.PC = ((hb << 8) | lb) + 1  # 1 past last instruction
        self.jumped = True

    # subtract with carry
    def SBC(self, instruction: Instruction, data: int):
        src = self.read_memory(data, instruction.mode)
        signed_result = self.A - src - (1 - self.C)
        # set overflow
        self.V = bool((self.A ^ src) & (self.A ^ signed_result) & 0x80)
        self.A = (self.A - src - (1 - self.C)) % 256
        self.C = not (signed_result < 0)  # set carry
        self.setZN(self.A)

    # set carry
    def SEC(self, instruction: Instruction, data: int):
        self.C = True

    # set decimal
    def SED(self, instruction: Instruction, data: int):
        self.D = True

    # set interrupt
    def SEI(self, instruction: Instruction, data: int):
        self.I = True

    # store accumulator
    def STA(self, instruction: Instruction, data: int):
        self.write_memory(data, instruction.mode, self.A)

    # store X register
    def STX(self, instruction: Instruction, data: int):
        self.write_memory(data, instruction.mode, self.X)

    # store Y register
    def STY(self, instruction: Instruction, data: int):
        self.write_memory(data, instruction.mode, self.Y)

    # transfer A to X
    def TAX(self, instruction: Instruction, data: int):
        self.X = self.A
        self.setZN(self.X)

    # transfer A to Y
    def TAY(self, instruction: Instruction, data: int):
        self.Y = self.A
        self.setZN(self.Y)

    # transfer stack pointer to X
    def TSX(self, instruction: Instruction, data: int):
        self.X = self.SP
        self.setZN(self.X)

    # transfer X to A
    def TXA(self, instruction: Instruction, data: int):
        self.A = self.X
        self.setZN(self.A)

    # transfer X to SP
    def TXS(self, instruction: Instruction, data: int):
        self.SP = self.X

    # transfer Y to A
    def TYA(self, instruction: Instruction, data: int):
        self.A = self.Y
        self.setZN(self.A)

    def unimplemented(self, instruction: Instruction, data: int):
        print(f"{instruction.type.name} is unimplemented.")

    def step(self):
        if self.stall > 0:
            self.stall -= 1
            self.cpu_ticks += 1
            return

        opcode = self.read_memory(self.PC, MemMode.ABSOLUTE)
        self.page_crossed = False
        self.jumped = False
        instruction = self.instructions[opcode]
        data = 0
        for i in range(1, instruction.length):
            data |= (self.read_memory(self.PC + i,
                                      MemMode.ABSOLUTE) << ((i - 1) * 8))

        instruction.method(instruction, data)

        if not self.jumped:
            self.PC += instruction.length
        elif instruction.type in {InstructionType.BCC, InstructionType.BCS,
                                  InstructionType.BEQ, InstructionType.BMI,
                                  InstructionType.BNE, InstructionType.BPL,
                                  InstructionType.BVC, InstructionType.BVS}:
            # branch instructions are +1 ticks if they succeeded
            self.cpu_ticks += 1
        self.cpu_ticks += instruction.ticks
        if self.page_crossed:
            self.cpu_ticks += instruction.page_ticks

    def address_for_mode(self, data: int, mode: MemMode) -> int:
        def different_pages(address1: int, address2: int) -> bool:
            return (address1 & 0xFF00) != (address2 & 0xFF00)

        address = 0
        match mode:
            case MemMode.ABSOLUTE:
                address = data
            case MemMode.ABSOLUTE_X:
                address = (data + self.X) & 0xFFFF
                self.page_crossed = different_pages(address, address - self.X)
            case MemMode.ABSOLUTE_Y:
                address = (data + self.Y) & 0xFFFF
                self.page_crossed = different_pages(address, address - self.Y)
            case MemMode.INDEXED_INDIRECT:
                # 0xFF for zero-page wrapping in next two lines
                ls = self.ram[(data + self.X) & 0xFF]
                ms = self.ram[(data + self.X + 1) & 0xFF]
                address = (ms << 8) | ls
            case MemMode.INDIRECT:
                ls = self.ram[data]
                ms = self.ram[data + 1]
                if (data & 0xFF) == 0xFF:
                    ms = self.ram[data & 0xFF00]
                address = (ms << 8) | ls
            case MemMode.INDIRECT_INDEXED:
                # 0xFF for zero-page wrapping in next two lines
                ls = self.ram[data & 0xFF]
                ms = self.ram[(data + 1) & 0xFF]
                address = (ms << 8) | ls
                address = (address + self.Y) & 0xFFFF
                self.page_crossed = different_pages(address, address - self.Y)
            case MemMode.RELATIVE:
                address = (self.PC + 2 + data) & 0xFFFF if (data < 0x80) \
                    else (self.PC + 2 + (data - 256)) & 0xFFFF  # signed
            case MemMode.ZEROPAGE:
                address = data
            case MemMode.ZEROPAGE_X:
                address = (data + self.X) & 0xFF
            case MemMode.ZEROPAGE_Y:
                address = (data + self.Y) & 0xFF
        return address

    def read_memory(self, location: int, mode: MemMode) -> int:
        if mode == MemMode.IMMEDIATE:
            return location  # location is actually data in this case
        address = self.address_for_mode(location, mode)

        # Memory map at http://wiki.nesdev.com/w/index.php/CPU_memory_map
        if address < 0x2000:  # main ram 2 KB goes up to 0x800
            return self.ram[address % 0x800]  # mirrors for next 6 KB
        elif address < 0x4000:  # 2000-2007 is PPU, mirrors every 8 bytes
            temp = ((address % 8) | 0x2000)  # get data from ppu register
            return self.ppu.read_register(temp)
        elif address == 0x4016:  # Joypad 1 status
            if self.joypad1.strobe:
                return self.joypad1.a
            self.joypad1.read_count += 1
            match self.joypad1.read_count:
                case 1:
                    return 0x40 | self.joypad1.a
                case 2:
                    return 0x40 | self.joypad1.b
                case 3:
                    return 0x40 | self.joypad1.select
                case 4:
                    return 0x40 | self.joypad1.start
                case 5:
                    return 0x40 | self.joypad1.up
                case 6:
                    return 0x40 | self.joypad1.down
                case 7:
                    return 0x40 | self.joypad1.left
                case 8:
                    return 0x40 | self.joypad1.right
                case _:
                    return 0x41
        elif address < 0x6000:
            return 0  # Unimplemented other kinds of IO
        else:  # Addresses from 0x6000 to 0xFFFF are from the cartridge
            return self.rom.read_cartridge(address)

    def write_memory(self, location: int, mode: MemMode, value: int):
        if mode == MemMode.IMMEDIATE:
            self.ram[location] = value
            return

        address = self.address_for_mode(location, mode)
        # Memory map at http://wiki.nesdev.com/w/index.php/CPU_memory_map
        if address < 0x2000:  # main ram 2 KB goes up to 0x800
            self.ram[address % 0x800] = value  # mirrors for next 6 KB
        elif address < 0x3FFF:  # 2000-2007 is PPU, mirrors every 8 bytes
            temp = ((address % 8) | 0x2000)  # write data to ppu register
            self.ppu.write_register(temp, value)
        elif address == 0x4014:  # DMA Transfer of Sprite Data
            from_address = value * 0x100  # address to start copying from
            for i in range(SPR_RAM_SIZE):  # copy all 256 bytes to sprite ram
                self.ppu.spr[i] = self.read_memory((from_address + i),
                                                   MemMode.ABSOLUTE)
            # stall for 512 cycles while this completes
            self.stall = 512
        elif address == 0x4016:  # Joypad 1
            if self.joypad1.strobe and (not bool(value & 1)):
                self.joypad1.read_count = 0
            self.joypad1.strobe = bool(value & 1)
            return
        elif address < 0x6000:
            return  # Unimplemented other kinds of IO
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
        # http://nesdev.com/the%20'B'%20flag%20&%20BRK%20instruction.txt
        self.B = False
        self.V = bool(temp & 0b01000000)
        self.N = bool(temp & 0b10000000)

    def trigger_NMI(self):
        self.stack_push((self.PC >> 8) & 0xFF)
        self.stack_push(self.PC & 0xFF)
        # http://nesdev.com/the%20'B'%20flag%20&%20BRK%20instruction.txt
        self.B = True
        self.stack_push(self.status)
        self.B = False
        self.I = True
        # set PC to NMI vector
        self.PC = (self.read_memory(NMI_VECTOR, MemMode.ABSOLUTE)) | \
                  (self.read_memory(NMI_VECTOR + 1, MemMode.ABSOLUTE) << 8)

    def log(self) -> str:
        opcode = self.read_memory(self.PC, MemMode.ABSOLUTE)
        instruction = self.instructions[opcode]
        data1 = "  " if instruction.length < 2 else f"{self.read_memory(self.PC + 1, 
                                                                        MemMode.ABSOLUTE):02X}"
        data2 = "  " if instruction.length < 3 else f"{self.read_memory(self.PC + 2, 
                                                                        MemMode.ABSOLUTE):02X}"
        return f"{self.PC:04X}  {opcode:02X} {data1} {data2}  {instruction.type.name}{29 * ' '}" \
               f"A:{self.A:02X} X:{self.X:02X} Y:{self.Y:02X} P:{self.status:02X} SP:{self.SP:02X}"
