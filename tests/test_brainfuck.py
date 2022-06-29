# tests/test_brainfuck.py
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
#
# DESCRIPTION
# Tries running all of the example Brainfuck programs and checks their
# output against the expected output.
import unittest
import sys
import os
from io import StringIO
from Brainfuck.brainfuck import Brainfuck


# Tokenizes, parses, and interprets a Brainfuck
# program; stores the output in a string and returns it
def run(file_name: str) -> str:
    output_holder = StringIO()
    sys.stdout = output_holder
    Brainfuck(file_name).execute()
    return output_holder.getvalue()


class BrainfuckTestCase(unittest.TestCase):
    def setUp(self) -> None:
        # Change working directory to this file so we can easily access
        # the Examples directory where the test Brainfuck code resides
        os.chdir(os.path.dirname(os.path.abspath(__file__)))

    def test_hello_world(self):
        program_output = run("../Brainfuck/Examples/hello_world_verbose.bf")
        expected = "Hello World!\n"
        self.assertEqual(program_output, expected)

    def test_fibonacci(self):
        program_output = run("../Brainfuck/Examples/fibonacci.bf")
        expected = "1, 1, 2, 3, 5, 8, 13, 21, 34, 55, 89"
        self.assertEqual(program_output, expected)

    def test_cell_size(self):
        program_output = run("../Brainfuck/Examples/cell_size.bf")
        expected = "8 bit cells\n"
        self.assertEqual(program_output, expected)

    def test_beer(self):
        program_output = run("../Brainfuck/Examples/beer.bf")
        with open("../Brainfuck/Examples/beer.out", "r") as text_file:
            expected = text_file.read()
            self.assertEqual(program_output, expected)


if __name__ == "__main__":
    unittest.main()
