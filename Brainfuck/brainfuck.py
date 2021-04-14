# Brainfuck/brainfuck.py
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
class Brainfuck:
    def __init__(self, file_name: str):
        # Open text file and store in instance variable, execute
        with open(file_name, "r") as text_file:
            self.source_code: str = text_file.read()

    # Find the location of the corresponding matching bracket to the one at start
    # If forward is true go to the right looking for a matching "]"
    # Otherwise do the reverse
    def find_bracket_match(self, start: int, forward: bool) -> int:
        in_between_brackets: int = 0
        direction: int = 1 if forward else -1
        location: int = start + direction
        start_bracket: str = "[" if forward else "]"
        end_bracket: str = "]" if forward else "["
        while location < len(self.source_code) and location >= 0:
            if self.source_code[location] == end_bracket:
                if in_between_brackets == 0:
                    return location
                in_between_brackets -= 1
            elif self.source_code[location] == start_bracket:
                in_between_brackets += 1
            location += direction
        # Didn't find a match
        print(f"Error: could not find matching bracket for {start_bracket} at {start}.")
        return start

    def execute(self):
        # Setup state
        cells: list[int] = [0] * 30000
        instruction_pointer: int = 0
        data_pointer: int = 0
        # Change to match statement in Python 3.10
        while instruction_pointer < len(self.source_code):
            instruction = self.source_code[instruction_pointer]
            if instruction == ">":
                data_pointer += 1
            elif instruction == "<":
                data_pointer -= 1
            elif instruction == "+":
                cells[data_pointer] += 1
            elif instruction == "-":
                cells[data_pointer] -= 1
            elif instruction == ".":
                print(chr(cells[data_pointer]), end='', flush=True)
            elif instruction == ",":
                cells[data_pointer] = int(input())
            elif instruction == "[":
                if cells[data_pointer] == 0:
                    instruction_pointer = self.find_bracket_match(instruction_pointer, True)
            elif instruction == "]":
                if cells[data_pointer] != 0:
                    instruction_pointer = self.find_bracket_match(instruction_pointer, False)
            instruction_pointer += 1

