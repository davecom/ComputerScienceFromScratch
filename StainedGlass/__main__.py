# StainedGlass/__main__.py
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
from argparse import ArgumentParser
from StainedGlass.stainedglass import StainedGlass, ColorMethod, ShapeType

if __name__ == "__main__":
    # Parse the file argument
    argument_parser = ArgumentParser("StainedGlass")
    argument_parser.add_argument("image_file", help="An image file to paint a stained glass equivalent of.")
    argument_parser.add_argument("output_file", help="The final resulting abstract art image.")
    argument_parser.add_argument('-t', '--trials', type=int, default=10000,
                                 help='The number of trials to run (default 10000).')
    argument_parser.add_argument('-m', '--method', choices=['random', 'average', 'common'], default='average',
                                 help='The method for determining shape colors (default average).')
    argument_parser.add_argument('-s', '--shape', choices=['ellipse', 'triangle', 'quadrilateral', 'line'],
                                 default='ellipse',
                                 help='The shape type to use (default ellipse).')
    argument_parser.add_argument('-l', '--length', type=int, default=256,
                                 help='The length (height) of the final image in pixels (default 256).')
    argument_parser.add_argument('-v', '--vector', default=False, action='store_true',
                                 help='Create vector output. A SVG file will also be output.')
    argument_parser.add_argument('-a', '--animate', type=int, default=0,
                                 help='If a number greater than 0 is provided, will create an animated '
                                      'GIF with the number of milliseconds per frame provided.')
    arguments = argument_parser.parse_args()
    method = ColorMethod[arguments.method.upper()]
    shape_type = ShapeType[arguments.shape.upper()]
    StainedGlass(arguments.image_file, arguments.output_file, arguments.trials, method, shape_type, arguments.length,
                 arguments.vector, arguments.animate)
