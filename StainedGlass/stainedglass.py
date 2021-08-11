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

ColorMethod = Enum("ColorMethod", "RANDOM AVERAGE COMMON")
ShapeType = Enum("ShapeType", "ELLIPSE TRIANGLE QUADRILATERAL LINE")
Dimensions = list[int]
MAX_HEIGHT = 256


def get_most_common_color(image: Image) -> tuple[int, int, int]:
    colors = image.getcolors(image.width * image.height)
    sorted_colors = sorted(colors, key=lambda item: item[0])
    return sorted_colors[-1][1]


class StainedGlass:
    def __init__(self, file_name: str, output_file: str, trials: int, method: ColorMethod, shape_type: ShapeType, length: int, vector: bool):
        self.method = method
        self.shape_type = shape_type
        self.shapes = []
        # Open image file and store in instance variable, execute algorithm
        with open(file_name, "rb") as fp:
            self.original = Image.open(fp)
            # Scale down image so processing is faster, 256 max height pixel dimension
            width, height = self.original.size
            aspect_ratio = width / height
            new_size = (int(MAX_HEIGHT * aspect_ratio), MAX_HEIGHT)
            self.original.thumbnail(new_size, Image.ANTIALIAS)
            # Start the generated image with a background that is the
            # average of all of the original's pixels in color
            average_color = tuple((round(n) for n in ImageStat.Stat(self.original).mean))
            self.glass = Image.new("RGB", new_size, average_color)
            # Keep track of how far along we are, our best result so far, and
            # how much time elapses as the processing takes place
            self.best_difference = self.difference(self.glass)
            last_percent = 0
            start = timer()
            for test in range(trials):
                self.trial()
                percent = trunc(test / trials * 100)
                if percent > last_percent:
                    last_percent = percent
                    print(f"{percent}% Done, Best Difference {self.best_difference}")
            end = timer()
            print(f"{end-start} seconds elapsed. Outputting image...")
            self.create_output(output_file, length, vector)

    def create_output(self, output_file: str, height: int, vector: bool):
        average_color = tuple((round(n) for n in ImageStat.Stat(self.original).mean))
        original_width, original_height = self.original.size
        ratio = height / original_height
        output_size = (int(original_width * ratio), int(original_height * ratio))
        output_image = Image.new("RGB", output_size, average_color)
        output_draw = ImageDraw.Draw(output_image)
        for coordinates, color in self.shapes:
            dimensions = [int(x * ratio) for x in coordinates]
            if self.shape_type == ShapeType.ELLIPSE:
                output_draw.ellipse(dimensions, fill=color)
            else: # must be triangle or quadrilateral or line
                output_draw.polygon(dimensions, fill=color)
        output_image.save(output_file)

    def random_dimensions(self) -> Dimensions:
        num_dimensions = 4 # ellipse or line
        if self.shape_type == ShapeType.TRIANGLE:
            num_dimensions = 6
        elif self.shape_type == ShapeType.QUADRILATERAL:
            num_dimensions = 8
        dimensions = []
        for d in range(num_dimensions):
            if d % 2 == 0: # x coordinates
                dimensions.append(random.randint(0, self.original.width))
            else: # y coordinates
                dimensions.append(random.randint(0, self.original.height))
        return dimensions

    def bounding_box(self, dimensions: Dimensions):
        if self.shape_type == ShapeType.ELLIPSE or self.shape_type == ShapeType.LINE:
            return dimensions
        else: # Triangle or would work for any Polygon
            xcoords = dimensions[::2]
            ycoords = dimensions[1::2]
            x1 = min(xcoords)
            y1 = min(ycoords)
            x2 = max(xcoords)
            y2 = max(ycoords)
            return [x1, y1, x2, y2]

    def trial(self):
        while True:
            dimensions = self.random_dimensions()
            region = self.original.crop(self.bounding_box(dimensions))
            if region.width > 0 and region.height > 0:
                break

        if self.method == ColorMethod.AVERAGE:
            color = tuple((round(n) for n in ImageStat.Stat(region).mean))
        elif self.method == ColorMethod.COMMON:
            color = get_most_common_color(region)
        else: # must be random
            color = tuple(random.choices(range(256), k=3))
        #try:
        #except ZeroDivisionError:
        #    color = (0, 0, 0)
        original = self.glass

        def experiment() -> bool:
            new_image = original.copy()
            glass_draw = ImageDraw.Draw(new_image)
            if self.shape_type == ShapeType.ELLIPSE:
                glass_draw.ellipse(dimensions, fill=color)
            else: # must be triangle or quadrilateral or line
                glass_draw.polygon(dimensions, fill=color)
            new_difference = self.difference(new_image)
            if new_difference < self.best_difference:
                self.best_difference = new_difference
                self.glass = new_image
                self.shapes.append((dimensions, color))
                return True
            return False

        # print(dimensions, rand_color, new_difference)

        if experiment():
            # Try expanding every direction, keep expanding in any directions that are better
            for index in range(len(dimensions)):
                for amount in (-1, 1):
                    while True:
                        old_dimensions = dimensions.copy()
                        dimensions[index] = dimensions[index] + amount
                        if not experiment():
                            dimensions = old_dimensions
                            break

    def difference(self, other_image: Image) -> float:
        diff = ImageChops.difference(self.original, other_image)
        stat = ImageStat.Stat(diff)
        diff_ratio = sum(stat.mean) / (len(stat.mean) * 255)
        return diff_ratio
