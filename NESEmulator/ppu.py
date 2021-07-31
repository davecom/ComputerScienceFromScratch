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
from rom import ROM
try:
    import numpy as np
except ImportError as error:
    print("Couldn't import numpy, trying _numpypy")
    import _numpypy as np # for pypy

SPR_RAM_SIZE = 256
NAMETABLE_SIZE = 2048
PALETTE_SIZE = 32
NES_WIDTH = 256
NES_HEIGHT = 240
NES_PALETTE = [0x7C7C7C, 0x0000FC, 0x0000BC, 0x4428BC, 0x940084, 0xA80020, 0xA81000, 0x881400,
               0x503000, 0x007800, 0x006800, 0x005800, 0x004058, 0x000000, 0x000000, 0x000000,
               0xBCBCBC, 0x0078F8, 0x0058F8, 0x6844FC, 0xD800CC, 0xE40058, 0xF83800, 0xE45C10,
               0xAC7C00, 0x00B800, 0x00A800, 0x00A844, 0x008888, 0x000000, 0x000000, 0x000000,
               0xF8F8F8, 0x3CBCFC, 0x6888FC, 0x9878F8, 0xF878F8, 0xF85898, 0xF87858, 0xFCA044,
               0xF8B800, 0xB8F818, 0x58D854, 0x58F898, 0x00E8D8, 0x787878, 0x000000, 0x000000,
               0xFCFCFC, 0xA4E4FC, 0xB8B8F8, 0xD8B8F8, 0xF8B8F8, 0xF8A4C0, 0xF0D0B0, 0xFCE0A8,
               0xF8D878, 0xD8F878, 0xB8F8B8, 0xB8F8D8, 0x00FCFC, 0xF8D8F8, 0x000000, 0x000000]

class PPU:
    def __init__(self, rom: ROM):
        self.rom = rom
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
        self.scanline = 0
        self.cycle = 0
        self.display_buffer = np.zeros((NES_WIDTH, NES_HEIGHT), dtype=np.uint32)  # pixels for screen

    # rendering reference https://wiki.nesdev.com/w/index.php/PPU_rendering
    # status reference http://wiki.nesdev.com/w/index.php/PPU_registers#PPUSTATUS
    def step(self):
        # our simplified PPU draws just once per frame
        if (self.scanline == 240) and (self.cycle == 256):
            if self.show_background:
                self.draw_background()
            if self.show_sprites:
                self.draw_sprites(False)
        if (self.scanline == 241) and (self.cycle == 1):
            self.status |= 0b10000000 # set vblank
        if (self.scanline == 261) and (self.cycle == 1):
            self.status |= 0b00011111 # vblank off, clear sprite zero, clear sprite overflow

        self.cycle += 1
        if self.cycle > 340:
            self.cycle = 0
            self.scanline += 1
            if self.scanline > 261:
                self.scanline = 0

    def draw_background(self):
        attribute_table_address = self.nametable_address + 0x3C0
        # 30 tiles in width and 32 tiles in height
        for y in range(30):
            for x in range(32):
                tile_address = self.nametable_address + y * 0x20 + x
                nametable_entry = self.read_memory(tile_address)
                attrx = x // 4
                attry = y // 4
                attribute_address = attribute_table_address + attry * 8 + attrx
                attribute_entry = self.read_memory(attribute_address)
                block = (y & 0x02) | ((x & 0x02) >> 1) # https://forums.nesdev.com/viewtopic.php?f=10&t=13315
                attribute_bits = 0
                if block == 0:
                    attribute_bits = (attribute_entry & 0b00000011) << 2
                elif block == 1:
                    attribute_bits = (attribute_entry & 0b00001100)
                elif block == 2:
                    attribute_bits = (attribute_entry & 0b00110000) >> 2
                elif block == 3:
                    attribute_bits = (attribute_entry & 0b11000000) >> 4
                else:
                    print("Invalid block")
                for fine_y in range(8):
                    low_order = self.read_memory(self.background_pattern_table_address + nametable_entry * 16 + fine_y)
                    high_order = self.read_memory(self.background_pattern_table_address + nametable_entry * 16 + 8 + fine_y)
                    for fine_x in range(8):
                        pixel = ((low_order >> (7 - fine_x)) & 1) | (((high_order >> (7 - fine_x)) & 1) << 1) | attribute_bits
                        x_screen_loc = x * 8 + fine_x
                        y_screen_loc = y * 8 + fine_y
                        transparent_background = ((pixel & 3) == 0)
                        # if the background is transparent, we use the first color in the palette
                        color = self.palette[0] if transparent_background else self.palette[pixel]
                        # self.display_buffer[x_screen_loc, y_screen_loc] = NES_PALETTE[color]
                        self.display_buffer[x_screen_loc, y_screen_loc] = NES_PALETTE[color]
                        # plot pixel here draw_pixel(x_screen_loc, y_screen_loc, transparent_background ? palette[0] : palette[pixel]);

    def draw_sprites(self, background_transparent: bool):
        for i in range(SPR_RAM_SIZE - 4, -4, -4):
            y_position = self.spr[i]
            if y_position == 0xFF: # 0xFF is a marker for no sprite data
                continue
            # we actually draw sprites shifted one pixel down
            background_sprite = bool((self.spr[i + 2] >> 5) & 1)
            x_position = self.spr[i + 3]

            for x in range(x_position, x_position + 8):
                if x >= NES_WIDTH:
                    break
                for y in range(y_position, y_position + 8):
                    if y >= NES_HEIGHT:
                        break
                    flip_y = bool((self.spr[i + 2] >> 7) & 1)
                    sprite_line = y - y_position
                    if flip_y:
                        sprite_line = 7 - sprite_line
                    index = self.spr[i + 1]
                    bit0s_address = self.spr_pattern_table_address + (index * 16) + sprite_line
                    bit1s_address = self.spr_pattern_table_address + (index * 16) + sprite_line + 8
                    bit0s = self.read_memory(bit0s_address)
                    bit1s = self.read_memory(bit1s_address)
                    bit3and2 = ((self.spr[i + 2]) & 3) << 2
                    # draw the 8 pixels on this scanline
                    flip_x = bool((self.spr[i + 2] >> 6) & 1)

                    x_loc = x - x_position # position within sprite
                    if not flip_x:
                        x_loc = 7 - x_loc

                    bit1and0 = (((bit1s >> x_loc) & 1) << 1) | (((bit0s >> x_loc) & 1) << 0)
                    if bit1and0 == 0: # transparent pixel... skip
                        continue

                    # this is not transparent, is it a sprite zero hit therefore?
                    # check left 8 pixel clipping is not off
                    if (i == 0) and (not background_transparent) and (not (x < 8 and (not self.left_8_sprite_show or not self.left_8_background_show)) and self.show_background and self.show_sprites):
                        self.status |= 0b01000000
                    # need to do this after sprite zero checking so we still count background
                    # sprites for sprite zero checks
                    if background_sprite and not background_transparent:
                        continue # don't draw over opaque background pixels if this is backround sprite

                    color = bit3and2 | bit1and0
                    color = self.read_memory(0x3F10 + color) # pull from palette
                    self.display_buffer[x, y] = NES_PALETTE[color]
                    # draw_pixel(x, y, color)



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
        address = address % 0x4000 # mirror >0x4000
        if address < 0x2000: # pattern tables
            return self.rom.read_cartridge(address)
        elif address < 0x3F00: # nametables
            address = (address - 0x2000) % 0x1000 # 3000-3EFF is a mirror
            if self.rom.vertical_mirroring:
                address = address % 0x0800
            else: # horizontal mirroring
                if (address >= 0x400) and (address < 0xC00):
                    address = address - 0x400
                elif address >= 0xC00:
                    address = address - 0x800
            return self.nametables[address]
        elif address < 0x4000: # palette memory
            address = (address - 0x3F00) % 0x20
            if (address > 0x0F) and ((address % 0x04) == 0):
                address = address - 0x10
            return self.palette[address]
        else:
            print(f"Error: Unrecognized PPU address read at {address:X}")

    def write_memory(self, address: int, value: int):
        address = address % 0x4000  # mirror >0x4000
        if address < 0x2000:  # pattern tables
            return self.rom.write_cartridge(address, value)
        elif address < 0x3F00:  # nametables
            address = (address - 0x2000) % 0x1000  # 3000-3EFF is a mirror
            if self.rom.vertical_mirroring:
                address = address % 0x0800
            else:  # horizontal mirroring
                if (address >= 0x400) and (address < 0xC00):
                    address = address - 0x400
                elif address >= 0xC00:
                    address = address - 0x800
            self.nametables[address] = value
        elif address < 0x4000:  # palette memory
            address = (address - 0x3F00) % 0x20
            if (address > 0x0F) and ((address % 0x04) == 0):
                address = address - 0x10
            self.palette[address] = value
        else:
            print(f"Error: Unrecognized PPU address read at {address:X}")