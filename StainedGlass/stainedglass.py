# StainedGlass/stainedglass.py
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
# Clamp an integer between 0 and 255, simulating a single byte
from PIL import Image, ImageDraw
from PIL import ImageChops, ImageStat
import random
from math import trunc
from timeit import default_timer as timer


class StainedGlass:
    def __init__(self, file_name: str):
        # Open image file and store in instance variable, execute algorithm
        with open(file_name, "rb") as fp:
            self.original = Image.open(fp)
            width, height = self.original.size
            aspect_ratio = width / height
            new_size = (int(256 * aspect_ratio), 256)
            self.original.thumbnail(new_size, Image.ANTIALIAS)
            average_color = tuple((round(n) for n in ImageStat.Stat(self.original).mean))
            self.glass = Image.new("RGB", new_size, average_color)
            self.best_difference = self.difference(self.glass)
            trials = 10000000
            last_percent = 0
            start = timer()
            for test in range(trials):
                self.trial()
                percent = trunc(test / trials * 100)
                if percent > last_percent:
                    last_percent = percent
                    print(f"{percent}% Done, Best Difference {self.best_difference}")
            end = timer()
            print(f"{end-start} seconds elapsed")
            self.glass.save("/Users/dave/Downloads/glass.png")

    def random_dimensions(self): #-> tuple[tuple[int, int], tuple[int, int]]:
        x1 = random.randint(0, self.original.width)
        y1 = random.randint(0, self.original.height)
        x2 = random.randint(0, self.original.width)
        y2 = random.randint(0, self.original.height)
        return (x1, y1), (x2, y2)

    def trial(self):
        new_image = self.glass.copy()
        glass_draw = ImageDraw.Draw(new_image)
        rand_color = tuple(random.choices(range(256), k=3))
        dimensions = self.random_dimensions()
        glass_draw.ellipse(dimensions, fill=rand_color)
        new_difference = self.difference(new_image)
        # print(dimensions, rand_color, new_difference)
        if new_difference < self.best_difference:
            self.best_difference = new_difference
            self.glass = new_image

    def difference(self, other_image: Image) -> float:
        diff = ImageChops.difference(self.original, other_image)
        stat = ImageStat.Stat(diff)
        diff_ratio = sum(stat.mean) / (len(stat.mean) * 255)
        return diff_ratio
