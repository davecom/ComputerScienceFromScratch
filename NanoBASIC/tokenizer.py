# tokenizer.py
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
from typing import Optional


class Token(Enum):
    COMMENT = (r"rem.*", False)
    WHITESPACE = (r"[ \t\n\r]", False)
    PRINT = (r"print", False)
    IF_T = (r"if", False)
    THEN = (r"then", False)
    LET = (r"let", False)
    GOTO = (r"goto", False)
    GOSUB = (r"gosub", False)
    RETURN_T = (r"return", False)
    COMMA = (r",", False)
    EQUAL = (r"=", False)
    NOT_EQUAL = (r"<>|><", False)
    LESS = (r"<", False)
    LESS_EQUAL = (r"<=", False)
    GREATER = (r">", False)
    GREATER_EQUAL = (r">=", False)
    PLUS = (r"\+", False)
    MINUS = (r"-", False)
    MULTIPLY = (r"\*", False)
    DIVIDE = (r"/", False)
    OPEN_PAREN = (r"\(", False)
    CLOSE_PAREN = (r"\)", False)
    VARIABLE = (r"[A-Za-z_]*", True)
    NUMBER = (r"-?[0-9]+", True)
    STRING = (r"\"[a-zA-Z0-9 ]*\"", True)

    def __init__(self, pattern: str, has_associated_value: bool):
        self._pattern: str = pattern
        self._has_associated_value: bool = has_associated_value
        self.associated_value: Optional[str] = None

    @property
    def pattern(self) -> str:
        return self._pattern

    @property
    def has_associated_value(self) -> bool:
        return self._has_associated_value

