# KNN/digit.py
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
from dataclasses import dataclass
from math import dist
from typing import Self


@dataclass
class Digit:
    kind: str
    pixels: list[int]

    @classmethod
    def from_string_data(cls, data: list[str]) -> Self:
        return cls(kind=data[64], pixels=[int(x) for x in data[:64]])

    def distance(self, other: Self) -> float:
        return dist(self.pixels, other.pixels)