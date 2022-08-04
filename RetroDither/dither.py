# RetroDither/dither.py
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
from PIL import Image
from array import array
from typing import NamedTuple

THRESHOLD = 127


class PatternPart(NamedTuple):
    dx: int
    dy: int
    numerator: int
    denominator: int


ATKINSON = [PatternPart(1, 0, 1, 8), PatternPart(2, 0, 1, 8), PatternPart(-1, 1, 1, 8),
            PatternPart(0, 1, 1, 8), PatternPart(1, 1, 1, 8), PatternPart(0, 2, 1, 8)]


# Assumes we are working with a grayscale image (Mode "L" in Pillow)
# Returns an array of dithered pixels (255 for white, 0 for black)
def dither(image: Image.Image) -> array:

    def diffuse(x: int, y: int, error: int, pattern: list[PatternPart]):
        for part in pattern:
            col = x + part.dx
            row = y + part.dy
            if col < 0 or col >= image.width or row >= image.height:
                continue
            # Add *error_part* to the pixel at (*c*, *r*) in *image*
            error_part = (error * part.numerator) // part.denominator
            image.putpixel((col, row), image.getpixel((col, row)) + error_part)

    result = array('B', [0] * (image.width * image.height))
    for y in range(image.height):
        for x in range(image.width):
            old_pixel = image.getpixel((x, y))
            # Every new pixel is either solid white or solid black
            # since this is all that the original Macintosh supported
            new_pixel = 255 if old_pixel > THRESHOLD else 0
            result[y * image.width + x] = new_pixel
            difference = (old_pixel - new_pixel)
            # Disperse error amongst nearby upcoming pixels
            diffuse(x, y, difference, ATKINSON)

    return result
