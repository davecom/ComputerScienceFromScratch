# RetroDither/dither.py
# From Computer Science from Scratch
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
from PIL import Image
from array import array
from typing import NamedTuple

THRESHOLD = 127


class PatternPart(NamedTuple):
    dc: int  # change in column
    dr: int  # change in row
    numerator: int
    denominator: int


ATKINSON = [PatternPart(1, 0, 1, 8), PatternPart(2, 0, 1, 8),
            PatternPart(-1, 1, 1, 8), PatternPart(0, 1, 1, 8),
            PatternPart(1, 1, 1, 8), PatternPart(0, 2, 1, 8)]


# Assumes we are working with a grayscale image (Mode "L" in Pillow)
# Returns an array of dithered pixels (255 for white, 0 for black)
def dither(image: Image.Image) -> array:
    # Distribute error among nearby pixels
    def diffuse(c: int, r: int, error: int, pattern: list[PatternPart]):
        for part in pattern:
            col = c + part.dc
            row = r + part.dr
            if col < 0 or col >= image.width or row >= image.height:
                continue
            current_pixel: float = image.getpixel((col, row))  # type: ignore
            # Add *error_part* to the pixel at (*col*, *row*) in *image*
            error_part = (error * part.numerator) // part.denominator
            image.putpixel((col, row), current_pixel + error_part)

    result = array('B', [0] * (image.width * image.height))
    for y in range(image.height):
        for x in range(image.width):
            old_pixel: float = image.getpixel((x, y))  # type: ignore
            # Every new pixel is either solid white or solid black
            # since this is all that the original Macintosh supported
            new_pixel = 255 if old_pixel > THRESHOLD else 0
            result[y * image.width + x] = new_pixel
            difference = int(old_pixel - new_pixel)
            # Disperse error amongst nearby upcoming pixels
            diffuse(x, y, difference, ATKINSON)

    return result
