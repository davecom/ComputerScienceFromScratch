# NanoBASIC/tokenizer.py
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
#
# DESCRIPTION
# The tokenizer takes a string of source code (the contents of a source code
# file basically) and turns it into tokens. The tokens represent all of the
# smallest individual chunks of a program that can be processed. The valid
# tokens in a programming language are specified by a grammar. We have a grammar
# file in the repository as well. It is grammar.txt. Please keep it open as you
# read tokenizer.py and parser.py.
from enum import Enum
from typing import TextIO
import re
from dataclasses import dataclass


class TokenType(Enum):
    COMMENT = (r'rem.*', False)
    WHITESPACE = (r'[ \t\n\r]', False)
    PRINT = (r'print', False)
    IF_T = (r'if', False)
    THEN = (r'then', False)
    LET = (r'let', False)
    GOTO = (r'goto', False)
    GOSUB = (r'gosub', False)
    RETURN_T = (r'return', False)
    COMMA = (r',', False)
    EQUAL = (r'=', False)
    NOT_EQUAL = (r'<>|><', False)
    LESS_EQUAL = (r'<=', False)
    GREATER_EQUAL = (r'>=', False)
    LESS = (r'<', False)
    GREATER = (r'>', False)
    PLUS = (r'\+', False)
    MINUS = (r'-', False)
    MULTIPLY = (r'\*', False)
    DIVIDE = (r'/', False)
    OPEN_PAREN = (r'\(', False)
    CLOSE_PAREN = (r'\)', False)
    VARIABLE = (r'[A-Za-z_]+', True)
    NUMBER = (r'-?[0-9]+', True)
    STRING = (r'".*"', True)

    def __init__(self, pattern: str, has_associated_value: bool):
        self.pattern = pattern
        self.has_associated_value = has_associated_value

    def __repr__(self) -> str:
        return self.name


@dataclass(frozen=True)
class Token:
    kind: TokenType
    line_num: int
    col_start: int
    col_end: int
    associated_value: str | int | None


def tokenize(text_file: TextIO) -> list[Token]:
    tokens: list[Token] = []
    for line_num, line in enumerate(text_file.readlines(), start=1):
        col_start: int = 1
        while len(line) > 0:
            found: re.Match | None = None
            for possibility in TokenType:
                # Try each pattern from the beginning, case-insensitive
                # If it's found, store the match in *found*
                found = re.match(possibility.pattern, line, re.IGNORECASE)
                if found:
                    col_end: int = col_start + found.end() - 1
                    # Store tokens other than comments and whitespace
                    if (possibility is not TokenType.WHITESPACE
                            and possibility is not TokenType.COMMENT):
                        associated_value: str | int | None = None
                        if possibility.has_associated_value:
                            if possibility is TokenType.NUMBER:
                                associated_value = int(found.group(0))
                            elif possibility is TokenType.VARIABLE:
                                associated_value = found.group()
                            elif possibility is TokenType.STRING:
                                # Remove quote characters
                                associated_value = found.group(0)[1:-1]
                        tokens.append(Token(possibility, line_num, col_start,
                                            col_end, associated_value))
                    # Continue search from place in line after token
                    line = line[found.end():]
                    col_start = col_end + 1
                    break  # Go around again for next token
            # If we went through all the tokens and none of them were a match
            # then this must be an invalid token
            if not found:
                print(f"Syntax error on line {line_num} column {col_start}")
                break

    return tokens
