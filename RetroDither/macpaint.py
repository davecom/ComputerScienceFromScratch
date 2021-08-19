# RetroDither/macpaint.py
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
from array import array

MAX_WIDTH = 576
MAX_HEIGHT = 720
HEADER_LENGTH = 512

# Convert an array of bytes where each byte is 0 or 255
# to an array of bits where each byte that is 0 becomes a 0
# and each bit that is 255 becomes a 1
def bytes_to_bits(original: array) -> array:
    bits_array = array('B')

    for byte_index in range(0, len(original), 8):
        next_byte = 0
        for bit_index in range(8):
            next_bit = original[byte_index + bit_index] & 1
            next_byte = next_byte | (next_bit << (7 - bit_index))
            if (byte_index + bit_index + 1) >= len(original):
                break
        bits_array.append(next_byte)
    return bits_array


# Pad any missing spots with white bits due to the original
# image having a smaller size than 576x720
def prepare(data: array, width: int, height: int) -> array:
    bits_array = array('B')
    for row in range(height):
        image_location = row * width
        image_bits = bytes_to_bits(data[image_location:(image_location+width)])
        bits_array += image_bits
        remaining_width = MAX_WIDTH - width
        white_width_bits = array('B', [0] * (remaining_width // 8))
        bits_array += white_width_bits
    remaining_height = MAX_HEIGHT - height
    white_height_bits = array('B', [0] * ((remaining_height * MAX_WIDTH) // 8))
    bits_array += white_height_bits
    return bits_array


# https://en.wikipedia.org/wiki/PackBitsma
def run_length_encode(data: array) -> array:
    rle_data = array('B')
    start_pointer = 0
    reading_pointer = 0
    while start_pointer < len(data):
        reading_pointer = start_pointer
        same = 0
        not_same = 0
        while reading_pointer < len(data):
            if (reading_pointer + 1) < len(data) and data[reading_pointer] == data[reading_pointer + 1]:
                if not_same > 0:
                    break
                same += 1
            elif same > 0:
                break
            else:
                not_same += 1
            if same >= 127 or not_same >= 127:
                break
            reading_pointer += 1
        if same > 0:
            rle_data.append(same)
            rle_data.append(data[start_pointer])
        elif not_same > 0:
            rle_data.append(255 - not_same)
            rle_data += data[start_pointer:(start_pointer + not_same)]
        else: # last byte
            print("same and not_same both 0")
        start_pointer += max(same + 1, not_same)
    return rle_data


# Writes array *data* to *out_file*
def write_macpaint_file(data: array, out_file: str, width: int, height: int):
    bits_array = prepare(data, width, height)
    rle = run_length_encode(bits_array)
    output_array = array('B', [0] * HEADER_LENGTH) + rle
    output_array[3] = 2 # Header Signature
    with open(out_file, "wb") as fp:
        output_array.tofile(fp)

