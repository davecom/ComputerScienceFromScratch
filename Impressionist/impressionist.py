# Impressionist/impressionist.py
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
from enum import Enum
from PIL import Image, ImageDraw
from PIL import ImageChops, ImageStat
import random
from math import trunc
from timeit import default_timer as timer
from Impressionist.svg import SVG

ColorMethod = Enum("ColorMethod", "RANDOM AVERAGE COMMON")
ShapeType = Enum("ShapeType", "ELLIPSE TRIANGLE QUADRILATERAL LINE")
CoordList = list[int]
MAX_HEIGHT = 256


def get_most_common_color(image: Image.Image) -> tuple[int, int, int]:
    colors = image.getcolors(image.width * image.height)
    return max(colors, key=lambda item: item[0])[1]  # type: ignore


class Impressionist:
    def __init__(self, file_name: str, output_file: str, trials: int, method: ColorMethod,
                 shape_type: ShapeType, length: int, vector: bool, animation_length: int):
        self.method = method
        self.shape_type = shape_type
        self.shapes = []
        # Open image file and store in instance variable, execute algorithm
        with open(file_name, "rb") as fp:
            self.original = Image.open(fp).convert('RGB')
            # Scale down image so processing is faster, 256 max height pixel dimension
            width, height = self.original.size
            aspect_ratio = width / height
            new_size = (int(MAX_HEIGHT * aspect_ratio), MAX_HEIGHT)
            self.original.thumbnail(new_size, Image.Resampling.LANCZOS)
            # Start the generated image with a background that is the
            # average of all the original's pixels in color
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
            print(f"{end-start} seconds elapsed. {len(self.shapes)} shapes created.")
            self.create_output(output_file, length, vector, animation_length)

    def difference(self, other_image: Image.Image) -> float:
        diff = ImageChops.difference(self.original, other_image)
        stat = ImageStat.Stat(diff)
        diff_ratio = sum(stat.mean) / (len(stat.mean) * 255)
        return diff_ratio

    def random_coordinates(self) -> CoordList:
        num_coordinates = 4  # ellipse or line
        if self.shape_type == ShapeType.TRIANGLE:
            num_coordinates = 6
        elif self.shape_type == ShapeType.QUADRILATERAL:
            num_coordinates = 8
        coordinates = []
        for d in range(num_coordinates):
            if d % 2 == 0:  # x coordinates
                coordinates.append(random.randint(0, self.original.width))
            else:  # y coordinates
                coordinates.append(random.randint(0, self.original.height))
        return coordinates

    @staticmethod
    def bounding_box(coordinates: CoordList) -> tuple[int, int, int, int]:
        xcoords = coordinates[::2]
        ycoords = coordinates[1::2]
        x1 = min(xcoords)
        y1 = min(ycoords)
        x2 = max(xcoords)
        y2 = max(ycoords)
        return x1, y1, x2, y2

    def trial(self):
        while True:
            coordinates = self.random_coordinates()
            region = self.original.crop(self.bounding_box(coordinates))
            if region.width > 0 and region.height > 0:
                break

        if self.method == ColorMethod.AVERAGE:
            color = tuple((round(n) for n in ImageStat.Stat(region).mean))
        elif self.method == ColorMethod.COMMON:
            color = get_most_common_color(region)
        else:  # must be random
            color = tuple(random.choices(range(256), k=3))
        original = self.glass

        def experiment() -> bool:
            new_image = original.copy()
            glass_draw = ImageDraw.Draw(new_image)
            if self.shape_type == ShapeType.ELLIPSE:
                glass_draw.ellipse(self.bounding_box(coordinates), fill=color)
            else:  # must be triangle or quadrilateral or line
                glass_draw.polygon(coordinates, fill=color)
            new_difference = self.difference(new_image)
            if new_difference < self.best_difference:
                self.best_difference = new_difference
                self.glass = new_image
                return True
            return False

        if experiment():
            # Try expanding every direction, keep going in better directions
            for index in range(len(coordinates)):
                for amount in (-1, 1):
                    while True:
                        old_coordinates = coordinates.copy()
                        coordinates[index] = coordinates[index] + amount
                        if not experiment():
                            coordinates = old_coordinates
                            break
            self.shapes.append((coordinates, color))

    def create_output(self, out_file: str, height: int, vector: bool, animation_length: int):
        average_color = tuple((round(n) for n in ImageStat.Stat(self.original).mean))
        original_width, original_height = self.original.size
        ratio = height / original_height
        output_size = (int(original_width * ratio), int(original_height * ratio))
        output_image = Image.new("RGB", output_size, average_color)
        output_draw = ImageDraw.Draw(output_image)
        svg = SVG(*output_size, average_color) if vector else None
        animation_frames = [] if animation_length > 0 else None
        for coordinate_list, color in self.shapes:
            coordinates = [int(x * ratio) for x in coordinate_list]
            if self.shape_type == ShapeType.ELLIPSE:
                output_draw.ellipse(self.bounding_box(coordinates), fill=color)
                if svg:
                    svg.draw_ellipse(*coordinates, color)  # type: ignore
            else:  # must be triangle or quadrilateral or line
                output_draw.polygon(coordinates, fill=color)
                if svg:
                    if self.shape_type == ShapeType.LINE:
                        svg.draw_line(*coordinates, color)  # type: ignore
                    else:
                        svg.draw_polygon(coordinates, color)
            if animation_frames is not None:
                animation_frames.append(output_image.copy())
        output_image.save(out_file)
        if svg:
            svg.write(out_file + ".svg")
        if animation_frames is not None:
            animation_frames[0].save(out_file + ".gif", save_all=True,
                                     append_images=animation_frames[1:], optimize=False,
                                     duration=animation_length, loop=0, transparency=0, disposal=2)
