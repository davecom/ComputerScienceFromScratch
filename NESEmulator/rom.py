# NESEmulator/rom.py
# From Fun Computer Science Projects in Python
# Copyright 2021-2022 David Kopec
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
from struct import unpack
from collections import namedtuple
from array import array

Header = namedtuple("Header", "signature prg_rom_size chr_rom_size flags6 flags7 flags8 flags9 flags10 unused")
HEADER_SIZE = 16
TRAINER_SIZE = 512
PRG_ROM_BASE_UNIT_SIZE = 16384
CHR_ROM_BASE_UNIT_SIZE = 8192
PRG_RAM_SIZE = 8192


class ROM:
    def __init__(self, filename: str):
        with open(filename, "rb") as file:
            # Read Header and Check Signature "NES"
            self.header = Header._make(unpack("!LBBBBBBB5s", file.read(HEADER_SIZE)))
            if self.header.signature != 0x4E45531A:
                print("Invalid ROM Header Signature")
            else:
                print("Valid ROM Header Signature")
            # Untangle Mapper - one nybble in flags6 and one nybble in flags7
            self.mapper = (self.header.flags7 & 0xF0) | ((self.header.flags6 & 0xF0) >> 4)
            print(f"Mapper {self.mapper}")
            if self.mapper != 0:
                print("Invalid Mapper: Only Mapper 0 is Implemented")
            self.read_cartridge = self.read_mapper0
            self.write_cartridge = self.write_mapper0
            # Check if there's a trainer (4th bit flags6) and read it
            self.has_trainer = bool(self.header.flags6 & 4)
            if self.has_trainer:
                self.trainer_data = file.read(TRAINER_SIZE)
            # Check mirroring from flags6 bit 0
            self.vertical_mirroring = bool(self.header.flags6 & 1)
            print(f"Has vertical mirroring {self.vertical_mirroring}")
            # Read PRG_ROM and CHR_ROM, these are in multiples of 16K and 8K respectively
            self.prg_rom = file.read(PRG_ROM_BASE_UNIT_SIZE * self.header.prg_rom_size)
            self.chr_rom = file.read(CHR_ROM_BASE_UNIT_SIZE * self.header.chr_rom_size)
            self.prg_ram = array('B', [0] * PRG_RAM_SIZE) # sprite ram

    def read_mapper0(self, address: int) -> int:
        if address < 0x2000:
            return self.chr_rom[address]
        elif 0x6000 <= address < 0x8000:
            return self.prg_ram[address % PRG_RAM_SIZE]
        elif address >= 0x8000:
            if self.header.prg_rom_size > 1:
                return self.prg_rom[address - 0x8000]
            else:
                return self.prg_rom[(address - 0x8000) % PRG_ROM_BASE_UNIT_SIZE]
        else:
            raise LookupError(f"Tried to read from cartridge at invalid address {address:X}")

    def write_mapper0(self, address: int, value: int):
        if address >= 0x6000:
            self.prg_ram[address % PRG_RAM_SIZE] = value