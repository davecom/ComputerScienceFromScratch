# RetroDither/dither.py
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
from PIL import Image
from array import array

THRESHOLD = 127

# Assumes we are working with a grayscale image (Mode "L" in Pillow)
# Returns an array of dithered pixels (255 for white, 0 for black)
def atkinson_dither(image: Image) -> array:
    # Add *value* to the pixel at (*c*, *r*) in *image*
    def add_to_pixel(c: int, r: int, value: int):
        if c < 0 or c >= image.width or r >= image.height:
            return
        image.putpixel((c, r), image.getpixel((c, r)) + value)

    result = array('B', [0] * (image.width * image.height))
    for y in range(image.height):
        for x in range(image.width):
            old_pixel = image.getpixel((x, y))
            # Every new pixel is either solid black or solid white
            # since this is all that the original Macintosh supported
            new_pixel = 255 if old_pixel > THRESHOLD else 0
            result[y * image.width + x] = new_pixel
            # Error is an eighth of the difference between
            # the original pixel and how it ended up dithered
            error = (old_pixel - new_pixel) // 8
            # Disperse error amongst nearby upcoming pixels
            add_to_pixel(x + 1, y, error)
            add_to_pixel(x + 2, y, error)
            add_to_pixel(x - 1, y + 1, error)
            add_to_pixel(x, y + 1, error)
            add_to_pixel(x + 1, y + 1, error)
            add_to_pixel(x, y + 2, error)

    return result
