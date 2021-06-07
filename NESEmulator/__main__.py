# NESEmulator/__main__.py
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
from argparse import ArgumentParser
from rom import ROM
from ppu import PPU
from cpu import CPU
from ui import UI

def run(rom: ROM):
    ui = UI()
    ppu = PPU(rom)
    cpu = CPU(ppu, rom)
    ticks = 0
    while True:
        cpu.step()
        new_ticks = cpu.cpu_ticks - ticks
        # 3 PPU cycles for every CPU tick
        for _ in range(new_ticks * 3):
            ppu.step()
            if (ppu.scanline == 241) and (ppu.cycle == 1) and ppu.generate_nmi:
                cpu.trigger_NMI()
        ticks += new_ticks



if __name__ == "__main__":
    # Parse the file argument
    file_parser = ArgumentParser("NESEmulator")
    file_parser.add_argument("rom_file", help="A file containing an NES game in iNES format.")
    arguments = file_parser.parse_args()
    game = ROM(arguments.rom_file)

