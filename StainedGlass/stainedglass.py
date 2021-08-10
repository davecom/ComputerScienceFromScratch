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
from enum import Enum
from PIL import Image, ImageDraw
from PIL import ImageChops, ImageStat
import random
from math import trunc
from timeit import default_timer as timer

Direction = Enum("Direction", "LEFT RIGHT UP DOWN")
Dimensions = tuple[tuple[int, int], tuple[int, int]]


def change_dimensions(old: Dimensions, direction: Direction, amount: int) -> Dimensions:
    if direction == Direction.LEFT:
        return (old[0][0] + amount, old[0][1]), (old[1][0], old[1][1])
    elif direction == Direction.RIGHT:
        return (old[0][0], old[0][1]), (old[1][0] + amount, old[1][1])
    elif direction == Direction.UP:
        return (old[0][0], old[0][1] + amount), (old[1][0], old[1][1])
    elif direction == Direction.DOWN:
        return (old[0][0], old[0][1]), (old[1][0], old[1][1] + amount)


def get_most_common_color(image: Image) -> tuple[int, int, int]:
    colors = image.getcolors(image.width * image.height)
    sorted_colors = sorted(colors, key=lambda item: item[0])
    return sorted_colors[-1][1]


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
            trials = 100000
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

    def random_dimensions(self) -> Dimensions:
        x1 = random.randint(0, self.original.width)
        y1 = random.randint(0, self.original.height)
        x2 = random.randint(0, self.original.width)
        y2 = random.randint(0, self.original.height)
        return (x1, y1), (x2, y2)

    def trial(self):
        while True:
            dimensions = self.random_dimensions()

            (x1, y1), (x2, y2) = dimensions
            region = self.original.crop((x1, y1, x2, y2))
            if region.width > 0 and region.height > 0:
                break
        try:
            #random color
            #color = tuple(random.choices(range(256), k=3))
            #average color
            color = tuple((round(n) for n in ImageStat.Stat(region).mean))
            #dominant color
            #color = get_most_common_color(region)
        except ZeroDivisionError:
            color = (0, 0, 0)
        original = self.glass

        def experiment() -> bool:
            new_image = original.copy()
            glass_draw = ImageDraw.Draw(new_image)
            glass_draw.ellipse(dimensions, fill=color)
            new_difference = self.difference(new_image)
            if new_difference < self.best_difference:
                self.best_difference = new_difference
                self.glass = new_image
                return True
            return False

        # print(dimensions, rand_color, new_difference)

        if experiment():
            # Try expanding every direction, keep expanding in any directions that are better
            for direction in Direction:
                for amount in (-1, 1):
                    while True:
                        old_dimensions = dimensions
                        dimensions = change_dimensions(dimensions, direction, amount)
                        if not experiment():
                            dimensions = old_dimensions
                            break

    def difference(self, other_image: Image) -> float:
        diff = ImageChops.difference(self.original, other_image)
        stat = ImageStat.Stat(diff)
        diff_ratio = sum(stat.mean) / (len(stat.mean) * 255)
        return diff_ratio
