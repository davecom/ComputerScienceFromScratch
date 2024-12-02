# NESEmulator/__main__.py
# From Fun Computer Science Projects in Python
# Copyright 2024 David Kopec
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
from NESEmulator.rom import ROM
from NESEmulator.ppu import PPU, NES_WIDTH, NES_HEIGHT
from NESEmulator.cpu import CPU
import pygame
from timeit import default_timer as timer
import os


def run(rom: ROM, name: str):
    pygame.init()
    screen = pygame.display.set_mode((NES_WIDTH, NES_HEIGHT), 0, 24)
    pygame.display.set_caption(f"NES Emulator - {os.path.basename(name)}")
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
                end = timer()
                if start is not None:
                    print(end - start)
                start = timer()
            if (ppu.scanline == 241) and (ppu.cycle == 2) and ppu.generate_nmi:
                cpu.trigger_NMI()
        ticks += new_ticks

        for event in pygame.event.get():
            if event.type == pygame.QUIT:
                sys.exit()
            # Handle keyboard events as joypad changes
            if event.type not in {pygame.KEYDOWN, pygame.KEYUP}:
                continue
            is_keydown = event.type == pygame.KEYDOWN
            match event.key:
                case pygame.K_LEFT:
                    cpu.joypad1.left = is_keydown
                case pygame.K_RIGHT:
                    cpu.joypad1.right = is_keydown
                case pygame.K_UP:
                    cpu.joypad1.up = is_keydown
                case pygame.K_DOWN:
                    cpu.joypad1.down = is_keydown
                case pygame.K_x:
                    cpu.joypad1.a = is_keydown
                case pygame.K_z:
                    cpu.joypad1.b = is_keydown
                case pygame.K_s:
                    cpu.joypad1.start = is_keydown
                case pygame.K_a:
                    cpu.joypad1.select = is_keydown


if __name__ == "__main__":
    # Parse the file argument
    file_parser = ArgumentParser("NESEmulator")
    file_parser.add_argument("rom_file",
                             help="An NES game file in iNES format.")
    arguments = file_parser.parse_args()
    game = ROM(arguments.rom_file)
    run(game, arguments.rom_file)
