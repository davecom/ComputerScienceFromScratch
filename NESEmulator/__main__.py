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
import sys
from argparse import ArgumentParser
from .rom import ROM
from .ppu import PPU, NES_WIDTH, NES_HEIGHT
from .cpu import CPU
import pygame
from timeit import default_timer as timer

def run(rom: ROM):
    pygame.init()
    screen = pygame.display.set_mode((NES_WIDTH, NES_HEIGHT), 0 , 32)
    ppu = PPU(rom)
    cpu = CPU(ppu, rom)
    ticks = 0
    start = None
    while True:
        cpu.step()
        new_ticks = cpu.cpu_ticks - ticks
        # 3 PPU cycles for every CPU tick
        for _ in range(new_ticks * 3):
            ppu.step()
            # Draw, once per frame, everything onto the screen
            if (ppu.scanline == 240) and (ppu.cycle == 257):
                pygame.surfarray.blit_array(screen, ppu.display_buffer)
                pygame.display.flip()
                end=timer()
                if start is not None:
                    print(end-start)
                start=timer()
            if (ppu.scanline == 241) and (ppu.cycle == 2) and ppu.generate_nmi:
                cpu.trigger_NMI()
        ticks += new_ticks
        # Handle keyboard events as joypad changes
        for event in pygame.event.get():
            if event.type == pygame.KEYDOWN:
                if event.key == pygame.K_LEFT:
                    cpu.joypad1.left = True
                if event.key == pygame.K_RIGHT:
                    cpu.joypad1.right = True
                if event.key == pygame.K_UP:
                    cpu.joypad1.up = True
                if event.key == pygame.K_DOWN:
                    cpu.joypad1.down = True
                if event.key == pygame.K_x:
                    cpu.joypad1.a = True
                if event.key == pygame.K_z:
                    cpu.joypad1.b = True
                if event.key == pygame.K_s:
                    cpu.joypad1.start = True
                if event.key == pygame.K_a:
                    cpu.joypad1.select = True
            elif event.type == pygame.KEYUP:
                if event.key == pygame.K_LEFT:
                    cpu.joypad1.left = False
                if event.key == pygame.K_RIGHT:
                    cpu.joypad1.right = False
                if event.key == pygame.K_UP:
                    cpu.joypad1.up = False
                if event.key == pygame.K_DOWN:
                    cpu.joypad1.down = False
                if event.key == pygame.K_x:
                    cpu.joypad1.a = False
                if event.key == pygame.K_z:
                    cpu.joypad1.b = False
                if event.key == pygame.K_s:
                    cpu.joypad1.start = False
                if event.key == pygame.K_a:
                    cpu.joypad1.select = False
            elif event.type == pygame.QUIT:
                sys.exit()



if __name__ == "__main__":
    # Parse the file argument
    file_parser = ArgumentParser("NESEmulator")
    file_parser.add_argument("rom_file", help="A file containing an NES game in iNES format.")
    arguments = file_parser.parse_args()
    game = ROM(arguments.rom_file)
    run(game)

