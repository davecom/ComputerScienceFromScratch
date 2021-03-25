# NanoBASIC/__main__.py
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
from argparse import ArgumentParser
from .tokenizer import tokenize
from .parser import Parser
from .interpreter import Interpreter
from typing import TextIO


def execute(text_file: TextIO):
    tokens = tokenize(text_file)
    print(tokens)
    ast = Parser(tokens).parse()
    Interpreter(ast).run()


if __name__ == "__main__":
    # Parse the file argument
    file_parser = ArgumentParser("NanoBASIC")
    file_parser.add_argument("basic_file", help="A text file containing NanoBASIC source code.")
    arguments = file_parser.parse_args()
    # Load the text file from the argument
    # Tokenize, parse, and execute it
    with open(arguments.basic_file, "r") as text_file:
        execute(text_file)