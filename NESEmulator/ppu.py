# NESEmulator/ppu.py
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
from array import array

SPR_RAM_SIZE = 256
NAMETABLE_SIZE = 2048
PALETTE_SIZE = 32


class PPU:
    def __init__(self):
        # PPU Memory
        self.spr = array('B', [0] * SPR_RAM_SIZE) # sprite ram
        self.nametables = array('B', [0] * NAMETABLE_SIZE) # nametable ram
        self.palette = array('B', [0] * PALETTE_SIZE)  # pallete ram
        # Registers
        self.addr = 0 # main PPU address register
        self.addr_write_latch = False
        self.status = 0
        self.spr_address = 0
        # Variables controlled by PPU Control Registers
        self.nametable_address = 0
        self.address_increment = 1
        self.spr_pattern_table_address = 0
        self.background_pattern_table_address = 0
        self.generate_nmi = False
        self.show_background = False
        self.show_sprites = False
        self.left_8_sprite_show = False
        self.left_8_background_show = False
        # Internal helper variables
        self.buffer2007 = 0

    def read_register(self, address: int) -> int:
        if address == 0x2002:
            self.addr_write_latch = False
            current = self.status
            self.status &= 0b01111111 # clear vblank on read to $2002
            return current
        elif address == 0x2004:
            return self.spr[self.spr_address]
        elif address == 0x2007:
            if (self.addr % 0x4000) < 0x3F00:
                value = self.buffer2007
                self.buffer2007 = self.read_memory(self.addr)
            else:
                value = self.read_memory(self.addr)
                self.buffer2007 = self.read_memory(self.addr - 0x1000)
            self.addr += self.address_increment # every read to $2007 there is an increment of 1 or 32
            return value
        else:
            print(f"Error: Unrecognized PPU register read {address:X}")

    def write_register(self, address: int, value: int):
        if address == 0x2000: # Control1
            self.nametable_address = (0x2000 + (value & 0b00000011) * 0x400)
            self.address_increment = 32 if (value & 0b00000100) else 1
            self.spr_pattern_table_address = (((value & 0b00001000) >> 3) * 0x1000)
            self.background_pattern_table_address = (((value & 0b00010000) >> 4) * 0x1000)
            self.generate_nmi = bool(value & 0b10000000)
        elif address == 0x2001: # Control2
            self.show_background = bool(value & 0b00001000)
            self.show_sprites = bool(value & 0b00010000)
            self.left_8_background_show = bool(value & 0b00000010)
            self.left_8_sprite_show = bool(value & 0b00000100)
        elif address == 0x2003:
            self.spr_address = value
        elif address == 0x2004:
            self.spr[self.spr_address] = value
            self.spr_address += 1
        elif address == 0x2005: # scroll
            pass
        elif address == 0x2006: # based on http://wiki.nesdev.com/w/index.php/PPU_scrolling
            if not self.addr_write_latch: # first write
                self.addr = (self.addr & 0x00FF) | ((value & 0xFF) << 8)
            else: # second write
                self.addr = (self.addr & 0xFF00) | (value & 0xFF)
            self.addr_write_latch = not self.addr_write_latch
        elif address == 0x2007:
            self.write_memory(self.addr, value)
            self.addr += self.address_increment
        else:
            print(f"Error: Unrecognized PPU register write {address:X}")



    def read_memory(self, address: int) -> int:
        pass

    def write_memory(self, address: int, value: int):
        pass