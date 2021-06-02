# NESEmulator/ppu.py
# From Fun Computer Science Projects in Python
# Copyright 2021 David Kopec
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
# http:#www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
from array import array

SPR_RAM_SIZE = 256

class PPU:
    def __init__(self):
        self.spr = array('B', [0] * SPR_RAM_SIZE) # sprite ram

    def read_register(self, address: int) -> int:
        return 0 # Replace later

    def write_register(self, address: int, value: int):
        return