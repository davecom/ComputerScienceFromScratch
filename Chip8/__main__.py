# Chip8/__main__.py
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
from Chip8.vm import VM, SCREEN_WIDTH, SCREEN_HEIGHT
from Chip8.vm import TIMER_DELAY, FRAME_TIME_EXPECTED, ALLOWED_KEYS
import pygame
from timeit import default_timer as timer
import os


def run(program_data: bytes, name: str):
    # Startup Pygame, create the window, and load the sound
    pygame.init()
    screen = pygame.display.set_mode((SCREEN_WIDTH, SCREEN_HEIGHT),
                                     pygame.SCALED)
    pygame.display.set_caption(f"Chip8 - {os.path.basename(name)}")
    bee_sound = pygame.mixer.Sound(os.path.dirname(os.path.realpath(__file__))
                                   + "/bee.wav")
    currently_playing_sound = False
    vm = VM(program_data) # Load the virtual machine with the program data
    timer_accumulator = 0.0 # Used to limit the timer to 60 Hz
    # Main virtual machine loop
    while True:
        frame_start = timer()
        vm.step()
        if vm.needs_redraw:
            pygame.surfarray.blit_array(screen, vm.display_buffer)
            pygame.display.flip()

        # Handle keyboard events
        for event in pygame.event.get():
            if event.type == pygame.KEYDOWN:
                key_name = pygame.key.name(event.key)
                if key_name in ALLOWED_KEYS:
                    vm.keys[ALLOWED_KEYS.index(key_name)] = True
            elif event.type == pygame.KEYUP:
                key_name = pygame.key.name(event.key)
                if key_name in ALLOWED_KEYS:
                    vm.keys[ALLOWED_KEYS.index(key_name)] = False
            elif event.type == pygame.QUIT:
                sys.exit()

        # Sound
        if vm.play_sound:
            if not currently_playing_sound:
                bee_sound.play(-1)
                currently_playing_sound = True
        else:
            currently_playing_sound = False
            bee_sound.stop()

        # Handle timing
        frame_end = timer()
        frame_time = frame_end - frame_start # time it took in seconds
        timer_accumulator += frame_time
        # Every 1/60 of a second decrement the timers
        if timer_accumulator > TIMER_DELAY:
            vm.decrement_timers()
            timer_accumulator = 0
        # Limit the speed of the entire machine to 500 "frames" per second
        if frame_time < FRAME_TIME_EXPECTED:
            difference = FRAME_TIME_EXPECTED - frame_time
            pygame.time.delay(int(difference * 1000))
            timer_accumulator += difference


if __name__ == "__main__":
    # Parse the file argument
    file_parser = ArgumentParser("Chip8")
    file_parser.add_argument("rom_file",
                             help="A file containing a Chip-8 game.")
    arguments = file_parser.parse_args()
    with open(arguments.rom_file, "rb") as fp:
        file_data = fp.read()
        run(file_data, arguments.rom_file)
