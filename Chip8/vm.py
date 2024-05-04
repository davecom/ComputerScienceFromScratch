# Chip8/vm.py
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
from array import array
from random import randint
import numpy as np
import pygame
import sys


RAM_SIZE = 4096  # in bytes, aka 4 kilobytes
SCREEN_WIDTH = 64
SCREEN_HEIGHT = 32
SPRITE_WIDTH = 8
WHITE = 0xFFFFFFFF
BLACK = 0
TIMER_DELAY = 1/60  # in seconds... about 60 hz
FRAME_TIME_EXPECTED = 1/500 # for limiting VM speed
ALLOWED_KEYS = ["0", "1", "2", "3", "4", "5", "6", "7", "8", "9",
                "a", "b", "c", "d", "e", "f"]

# The font set, hardcoded
FONT_SET = [
    0xF0, 0x90, 0x90, 0x90, 0xF0,  # 0
    0x20, 0x60, 0x20, 0x20, 0x70,  # 1
    0xF0, 0x10, 0xF0, 0x80, 0xF0,  # 2
    0xF0, 0x10, 0xF0, 0x10, 0xF0,  # 3
    0x90, 0x90, 0xF0, 0x10, 0x10,  # 4
    0xF0, 0x80, 0xF0, 0x10, 0xF0,  # 5
    0xF0, 0x80, 0xF0, 0x90, 0xF0,  # 6
    0xF0, 0x10, 0x20, 0x40, 0x40,  # 7
    0xF0, 0x90, 0xF0, 0x90, 0xF0,  # 8
    0xF0, 0x90, 0xF0, 0x10, 0xF0,  # 9
    0xF0, 0x90, 0xF0, 0x90, 0x90,  # A
    0xE0, 0x90, 0xE0, 0x90, 0xE0,  # B
    0xF0, 0x80, 0x80, 0x80, 0xF0,  # C
    0xE0, 0x90, 0x90, 0x90, 0xE0,  # D
    0xF0, 0x80, 0xF0, 0x80, 0xF0,  # E
    0xF0, 0x80, 0xF0, 0x80, 0x80   # F
]


def concat_nibbles(*args: int) -> int:
    result = 0
    for arg in args:
        result = (result << 4) | arg
    return result


class VM:
    def __init__(self, program_data: bytes):
        # Initialized registers & memory constructs
        # General Purpose Registers - CHIP-8 has 16 of these registers
        self.v = array('B', [0] * 16)
        # Index Register
        self.i = 0
        # Program Counter
        # starts at 0x200 because addresses below that were
        # used for the VM itself in the original CHIP-8 machines
        self.pc = 0x200
        # Memory - the standard 4k on the original CHIP-8 machines
        self.ram = array('B', [0] * RAM_SIZE)
        # load the font set into the first 80 bytes
        self.ram[0:len(FONT_SET)] = array('B', FONT_SET)
        # copy program into ram starting at byte 512 by convention
        self.ram[512:(512 + len(program_data))] = array('B', program_data)
        # Stack - in real hardware this is typically limited to
        # 12 or 16 PC addresses for jumps, but since we're on modern hardware,
        # ours can just be unlimited and expand/contract as needed
        self.stack = []
        # Graphics buffer for the screen - 64 x 32 pixels
        self.display_buffer = np.zeros((SCREEN_WIDTH, SCREEN_HEIGHT), dtype=np.uint32)
        self.needs_redraw = False
        # Timers - really simple registers that count down to 0 at 60 hertz
        self.delay_timer = 0
        self.sound_timer = 0
        # These hold the status of whether the keys are down
        # CHIP-8 has 16 keys
        self.keys = [False] * 16

    def decrement_timers(self):
        if self.delay_timer > 0:
            self.delay_timer -= 1
        if self.sound_timer > 0:
            self.sound_timer -= 1

    @property
    def play_sound(self) -> bool:
        return self.sound_timer > 0

    # Draw a sprite at *x*, *y* using data at *i* and with a height of *height*
    def draw_sprite(self, x: int, y: int, height: int):
        flipped_black = False  # were any pixels where this was drawn flipped from white to black?
        for row in range(0, height):
            row_bits = self.ram[self.i + row]
            for col in range(0, SPRITE_WIDTH):
                px = x + col
                py = y + row
                if px >= SCREEN_WIDTH or py >= SCREEN_HEIGHT:
                    continue  # Ignore off-screen pixels
                new_bit = (row_bits >> (7 - col)) & 1
                old_bit = self.display_buffer[px, py] & 1
                if new_bit & old_bit:  # If both are set, they will get flipped white -> black
                    flipped_black = True
                new_pixel = new_bit ^ old_bit  # Chip 8 draws by XORing, which flips everything
                self.display_buffer[px, py] = WHITE if new_pixel else BLACK
        self.v[0xF] = 1 if flipped_black else 0  # set flipped flag in register for collision detection

    def step(self):
        # we look at the opcode in terms of its nibbles (4 bit pieces)
        # opcode is 16 bits made up of next two bytes in memory
        first2 = self.ram[self.pc]
        last2 = self.ram[self.pc + 1]
        first = (first2 & 0xF0) >> 4
        second = first2 & 0xF
        third = (last2 & 0xF0) >> 4
        fourth = last2 & 0xF

        self.needs_redraw = False
        jumped = False

        match (first, second, third, fourth):
            case (0x0, 0x0, 0xE, 0x0):  # display clear
                self.display_buffer.fill(0)
                self.needs_redraw = True
            case (0x0, 0x0, 0xE, 0xE):  # return from subroutine
                self.pc = self.stack.pop()
                jumped = True
            case (0x0, n1, n2, n3):  # call program
                self.pc = concat_nibbles(n1, n2, n3)  # go to program start
                # clear registers
                self.delay_timer = 0
                self.sound_timer = 0
                self.v = array('B', [0] * 16)
                self.i = 0
                # clear screen
                self.display_buffer.fill(0)
                self.needs_redraw = True
                jumped = True
            case (0x1, n1, n2, n3):  # jump to address
                self.pc = concat_nibbles(n1, n2, n3)
                jumped = True
            case (0x2, n1, n2, n3):  # call subroutine
                self.stack.append(self.pc + 2)  # return location onto the stack
                self.pc = concat_nibbles(n1, n2, n3)  # goto subroutine
                jumped = True
            case (0x3, x, _, _):  # conditional skip v[x] equal last2
                if self.v[x] == last2:
                    self.pc += 4
                    jumped = True
            case (0x4, x, _, _):  # conditional skip v[x] not equal last2
                if self.v[x] != last2:
                    self.pc += 4
                    jumped = True
            case (0x5, x, y, _):  # conditional skip v[x] equal v[y]
                if self.v[x] == self.v[y]:
                    self.pc += 4
                    jumped = True
            case (0x6, x, _, _):  # set v[x] to last2
                self.v[x] = last2
            case (0x7, x, _, _):  # add last2 to v[x]
                self.v[x] = (self.v[x] + last2) % 256
            case (0x8, x, y, 0x0):  # set v[x] to v[y]
                self.v[x] = self.v[y]
            case (0x8, x, y, 0x1):  # set v[x] to v[x] | v[y]
                self.v[x] |= self.v[y]
            case (0x8, x, y, 0x2):  # set v[x] to v[x] & v[y]
                self.v[x] &= self.v[y]
            case (0x8, x, y, 0x3):  # set v[x] to v[x] ^ v[y]
                self.v[x] ^= self.v[y]
            case (0x8, x, y, 0x4):  # add with carry flag
                try:
                    self.v[x] += self.v[y]
                    self.v[0xF] = 0  # indicate no carry flag
                except OverflowError:
                    self.v[x] = (self.v[x] + self.v[y]) % 256
                    self.v[0xF] = 1  # set carry flag
            case (0x8, x, y, 0x5):  # subtract with borrow flag
                try:
                    self.v[x] -= self.v[y]
                    self.v[0xF] = 1  # indicate no borrow (yes weird it's 1)
                except OverflowError:
                    self.v[x] = (self.v[x] - self.v[y]) % 256
                    self.v[0xF] = 0  # indicates there was a borrow
            case (0x8, x, _, 0x6):  # v[x] >> 1 v[f] = least significant bit
                self.v[0xF] = self.v[x] & 0x1
                self.v[x] >>= 1
            case (0x8, x, y, 0x7):  # subtract with borrow flag (y - x in x)
                try:
                    self.v[x] = self.v[y] - self.v[x]
                    self.v[0xF] = 1  # indicate no borrow (yes weird it's 1)
                except OverflowError:
                    self.v[x] = (self.v[y] - self.v[x]) % 256
                    self.v[0xF] = 0  # indicates there was a borrow
            case (0x8, x, _, 0xE):  # v[x] << 1 v[f] = most significant bit
                self.v[0xF] = (self.v[x] & 0b10000000) >> 7
                self.v[x] = (self.v[x] << 1) & 0xFF
            case (0x9, x, y, 0x0):  # conditional skip if v[x] != v[y]
                if self.v[x] != self.v[y]:
                    self.pc += 4
                    jumped = True
            case (0xA, n1, n2, n3):  # set i to address n1n2n3
                self.i = concat_nibbles(n1, n2, n3)
            case (0xB, n1, n2, n3):  # jump to n1n2n3 + v[0]
                self.pc = concat_nibbles(n1, n2, n3) + self.v[0]
                jumped = True
            case (0xC, x, _, _):  # v[x] = random number (0-255) & last2
                self.v[x] = last2 & randint(0, 255)
            case (0xD, x, y, n):  # draw sprite at (vx, vy) that's n high
                self.draw_sprite(self.v[x], self.v[y], n)
                self.needs_redraw = True
            case (0xE, x, 0x9, 0xE):  # conditional skip if keys(v[x])
                if self.keys[self.v[x]]:
                    self.pc += 4
                    jumped = True
            case (0xE, x, 0xA, 0x1):  # conditional skip if not keys(v[x])
                if not self.keys[self.v[x]]:
                    self.pc += 4
                    jumped = True
            case (0xF, x, 0x0, 0x7):  # set v[x] to delay_timer
                self.v[x] = self.delay_timer
            case (0xF, x, 0x0, 0xA):  # wait until next key then store in v[x]
                # wait here for the next key then continue
                while True:
                    event = pygame.event.wait()
                    if event.type == pygame.QUIT:
                        sys.exit()
                    if event.type == pygame.KEYDOWN:
                        key_name = pygame.key.name(event.key)
                        if key_name in ALLOWED_KEYS:
                            self.v[x] = ALLOWED_KEYS.index(key_name)
                            break
            case (0xF, x, 0x1, 0x5):  # set delay_timer to v[x]
                self.delay_timer = self.v[x]
            case (0xF, x, 0x1, 0x8):  # set sound_timer to v[x]
                self.sound_timer = self.v[x]
            case (0xF, x, 0x1, 0xE):  # add vx to i
                self.i += self.v[x]
            case (0xF, x, 0x2, 0x9):  # set i to location of character v[x]
                self.i = self.v[x] * 5  # built-in fontset is 5 bytes apart
            case (0xF, x, 0x3, 0x3):  # store BCD at v[x] in i, i+1, i+2
                self.ram[self.i] = self.v[x] // 100  # 100s digit
                self.ram[self.i + 1] = (self.v[x] % 100) // 10  # 10s digit
                self.ram[self.i + 2] = (self.v[x] % 100) % 10  # 1s digit
            case (0xF, x, 0x5, 0x5):  # reg dump v0 to vx starting at i
                for r in range(0, x + 1):
                    self.ram[self.i + r] = self.v[r]
            case (0xF, x, 0x6, 0x5):  # store i through i+r in v0 through vr
                for r in range(0, x + 1):
                    self.v[r] = self.ram[self.i + r]
            case _:
                print(f"Unknown opcode {(hex(first), hex(second), hex(third), hex(fourth))}!")

        if not jumped:
            self.pc += 2  # increment program counter
