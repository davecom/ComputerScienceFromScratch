# NESEmulator/tests.py
# From Fun Computer Science Projects in Python
# Copyright 2021 David Kopec
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
# http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#
# DESCRIPTION
# Tries running multiple different tests to verify the correctness of our emulator.
import unittest
import os
from cpu import CPU
from ppu import PPU
from rom import ROM


class CPUTestCase(unittest.TestCase):
    def setUp(self) -> None:
        # Change working directory to this file so we can easily access
        # the Tests directory where the test ROMs and logs reside
        os.chdir(os.path.dirname(os.path.abspath(__file__)))

    def test_nes_test(self):
        # Create machinery that we are testing
        rom = ROM("Tests/nestest/nestest.nes")
        ppu = PPU()
        cpu = CPU(ppu, rom)
        # Setup tests
        cpu.PC = 0xC000 # special starting location for tests
        with open("Tests/nestest/nestest.log") as f:
            correct_lines = f.readlines()
        log_line = 1
        # Check every line of the log against our own produced logs
        while log_line < 5260: # go until first unofficial opcode test
            our_line = cpu.log()
            correct_line = correct_lines[log_line - 1]
            self.assertEqual(correct_line[0:14], our_line[0:14], f"PC/Opcode don't match at line {log_line}")
            self.assertEqual(correct_line[48:73], our_line[48:73], f"Registers don't match at line {log_line}")
            cpu.cycle()
            log_line += 1

    def test_blargg_instr_test_v5_basics(self):
        # Create machinery that we are testing
        rom = ROM("Tests/instr_test-v5/rom_singles/01-basics.nes")
        ppu = PPU()
        cpu = CPU(ppu, rom)
        # Test keeps running as long as $6000 is 80, and then $6000 is result code; 0 means success
        rom.prg_ram[0] = 0x80
        while rom.prg_ram[0] == 0x80:  # go until first unofficial opcode test
            cpu.cycle()
        self.assertEqual(0, rom.prg_ram[0], f"Result code of basics test is {rom.prg_ram[0]} not 0")
        message = bytes(rom.prg_ram[4:]).decode("utf-8")
        print(message[0:message.index("\0")]) # Message ends with null terminator

    def test_blargg_instr_test_v5_implied(self):
        # Create machinery that we are testing
        rom = ROM("Tests/instr_test-v5/rom_singles/02-implied.nes")
        ppu = PPU()
        cpu = CPU(ppu, rom)
        # Test keeps running as long as $6000 is 80, and then $6000 is result code; 0 means success
        rom.prg_ram[0] = 0x80
        while rom.prg_ram[0] == 0x80:  # go until first unofficial opcode test
            cpu.cycle()
        self.assertEqual(0, rom.prg_ram[0], f"Result code of implied test is {rom.prg_ram[0]} not 0")
        message = bytes(rom.prg_ram[4:]).decode("utf-8")
        print(message[0:message.index("\0")]) # Message ends with null terminator

    def test_blargg_instr_test_v5_branches(self):
        # Create machinery that we are testing
        rom = ROM("Tests/instr_test-v5/rom_singles/10-branches.nes")
        ppu = PPU()
        cpu = CPU(ppu, rom)
        # Test keeps running as long as $6000 is 80, and then $6000 is result code; 0 means success
        rom.prg_ram[0] = 0x80
        while rom.prg_ram[0] == 0x80:  # go until first unofficial opcode test
            cpu.cycle()
        self.assertEqual(0, rom.prg_ram[0], f"Result code of braches test is {rom.prg_ram[0]} not 0")
        message = bytes(rom.prg_ram[4:]).decode("utf-8")
        print(message[0:message.index("\0")]) # Message ends with null terminator

    def test_blargg_instr_test_v5_stack(self):
        # Create machinery that we are testing
        rom = ROM("Tests/instr_test-v5/rom_singles/11-stack.nes")
        ppu = PPU()
        cpu = CPU(ppu, rom)
        # Test keeps running as long as $6000 is 80, and then $6000 is result code; 0 means success
        rom.prg_ram[0] = 0x80
        while rom.prg_ram[0] == 0x80:  # go until first unofficial opcode test
            cpu.cycle()
        self.assertEqual(0, rom.prg_ram[0], f"Result code of stack test is {rom.prg_ram[0]} not 0")
        message = bytes(rom.prg_ram[4:]).decode("utf-8")
        print(message[0:message.index("\0")]) # Message ends with null terminator

    def test_blargg_instr_test_v5_jmp_jsr(self):
        # Create machinery that we are testing
        rom = ROM("Tests/instr_test-v5/rom_singles/12-jmp_jsr.nes")
        ppu = PPU()
        cpu = CPU(ppu, rom)
        # Test keeps running as long as $6000 is 80, and then $6000 is result code; 0 means success
        rom.prg_ram[0] = 0x80
        while rom.prg_ram[0] == 0x80:  # go until first unofficial opcode test
            cpu.cycle()
        self.assertEqual(0, rom.prg_ram[0], f"Result code of jmp_jsr test is {rom.prg_ram[0]} not 0")
        message = bytes(rom.prg_ram[4:]).decode("utf-8")
        print(message[0:message.index("\0")]) # Message ends with null terminator

    def test_blargg_instr_test_v5_rts(self):
        # Create machinery that we are testing
        rom = ROM("Tests/instr_test-v5/rom_singles/13-rts.nes")
        ppu = PPU()
        cpu = CPU(ppu, rom)
        # Test keeps running as long as $6000 is 80, and then $6000 is result code; 0 means success
        rom.prg_ram[0] = 0x80
        while rom.prg_ram[0] == 0x80:  # go until first unofficial opcode test
            cpu.cycle()
        self.assertEqual(0, rom.prg_ram[0], f"Result code of rts test is {rom.prg_ram[0]} not 0")
        message = bytes(rom.prg_ram[4:]).decode("utf-8")
        print(message[0:message.index("\0")]) # Message ends with null terminator

    def test_blargg_instr_test_v5_rti(self):
        # Create machinery that we are testing
        rom = ROM("Tests/instr_test-v5/rom_singles/14-rti.nes")
        ppu = PPU()
        cpu = CPU(ppu, rom)
        # Test keeps running as long as $6000 is 80, and then $6000 is result code; 0 means success
        rom.prg_ram[0] = 0x80
        while rom.prg_ram[0] == 0x80:  # go until first unofficial opcode test
            cpu.cycle()
        self.assertEqual(0, rom.prg_ram[0], f"Result code of rti test is {rom.prg_ram[0]} not 0")
        message = bytes(rom.prg_ram[4:]).decode("utf-8")
        print(message[0:message.index("\0")]) # Message ends with null terminator

    def test_blargg_instr_test_v5_brk(self):
        # Create machinery that we are testing
        rom = ROM("Tests/instr_test-v5/rom_singles/15-brk.nes")
        ppu = PPU()
        cpu = CPU(ppu, rom)
        # Test keeps running as long as $6000 is 80, and then $6000 is result code; 0 means success
        rom.prg_ram[0] = 0x80
        while rom.prg_ram[0] == 0x80:  # go until first unofficial opcode test
            cpu.cycle()
        message = bytes(rom.prg_ram[4:]).decode("utf-8")
        print(message[0:message.index("\0")])  # Message ends with null terminator
        self.assertEqual(0, rom.prg_ram[0], f"Result code of brk test is {rom.prg_ram[0]} not 0")

    def test_blargg_instr_test_v5_special(self):
        # Create machinery that we are testing
        rom = ROM("Tests/instr_test-v5/rom_singles/16-special.nes")
        ppu = PPU()
        cpu = CPU(ppu, rom)
        # Test keeps running as long as $6000 is 80, and then $6000 is result code; 0 means success
        rom.prg_ram[0] = 0x80
        while rom.prg_ram[0] == 0x80:  # go until first unofficial opcode test
            cpu.cycle()
        message = bytes(rom.prg_ram[4:]).decode("utf-8")
        print(message[0:message.index("\0")])  # Message ends with null terminator
        self.assertEqual(0, rom.prg_ram[0], f"Result code of special test is {rom.prg_ram[0]} not 0")


if __name__ == "__main__":
    unittest.main()