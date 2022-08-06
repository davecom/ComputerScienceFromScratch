# RetroDither/macpaint.py
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
from array import array
from pathlib import Path
from datetime import datetime

MAX_WIDTH = 576
MAX_HEIGHT = 720
MACBINARY_LENGTH = 128
HEADER_LENGTH = 512


# Convert an array of bytes where each byte is 0 or 255
# to an array of bits where each byte that is 0 becomes a 1
# and each bit that is 255 becomes a 0
def bytes_to_bits(original: array) -> array:
    bits_array = array('B')

    for byte_index in range(0, len(original), 8):
        next_byte = 0
        for bit_index in range(8):
            next_bit = 1 - (original[byte_index + bit_index] & 1)
            next_byte = next_byte | (next_bit << (7 - bit_index))
            if (byte_index + bit_index + 1) >= len(original):
                break
        bits_array.append(next_byte)
    return bits_array


# Convert the array of bytes into bits using the helper function
# Pad any missing spots with white bits due to the original
# image having a smaller size than 576x720
def prepare(data: array, width: int, height: int) -> array:
    bits_array = array('B')
    for row in range(height):
        image_location = row * width
        image_bits = bytes_to_bits(data[image_location:(image_location + width)])
        bits_array += image_bits
        remaining_width = MAX_WIDTH - width
        white_width_bits = array('B', [0] * (remaining_width // 8))
        bits_array += white_width_bits
    remaining_height = MAX_HEIGHT - height
    white_height_bits = array('B', [0] * ((remaining_height * MAX_WIDTH) // 8))
    bits_array += white_height_bits
    return bits_array


# https://en.wikipedia.org/wiki/PackBits
# MacPaint expects RLE to happen on a per-line basis (MAX_WIDTH)
# In other words there are line boundaries
def run_length_encode(original_data: array) -> array:
    # Find how many of the same bytes are in a row from *start*
    def take_same(source: array, start: int) -> int:
        count = 0
        while start + count + 1 < len(source) and source[start + count] == source[start + count + 1]:
            count += 1
        return count + 1 if count > 0 else 0

    rle_data = array('B')
    # Divide data into MAX_WIDTH size boundaries by line
    for line_start in range(0, len(original_data), MAX_WIDTH // 8):
        data = original_data[line_start:(line_start + (MAX_WIDTH // 8))]
        index = 0
        while index < len(data):
            not_same = 0
            while ((same := take_same(data, index + not_same)) == 0) and (index + not_same < len(data)):
                not_same += 1
            if not_same > 0:
                rle_data.append(not_same - 1)
                rle_data += data[index:index + not_same]
                index += not_same
            if same > 0:
                rle_data.append(257 - same)
                rle_data.append(data[index])
                index += same
    return rle_data


def macbinary_header(outfile: str, data_size: int) -> array:
    macbinary = array('B', [0] * MACBINARY_LENGTH)
    filename = Path(outfile).stem
    filename = filename[:63] if len(filename) > 63 else filename  # limit to 63 characters maximum
    macbinary[1] = len(filename)  # file name length
    macbinary[2:(2 + len(filename))] = array("B", filename.encode("mac_roman"))  # file name
    macbinary[65:69] = array("B", "PNTG".encode("mac_roman"))  # file type
    macbinary[69:73] = array("B", "MPNT".encode("mac_roman"))  # file creator
    macbinary[83:87] = array("B", data_size.to_bytes(4, byteorder='big'))  # size of data fork
    timestamp = int((datetime.now() - datetime(1904, 1, 1)).total_seconds())  # Mac timestamps are seconds since 1904
    macbinary[91:95] = array("B", timestamp.to_bytes(4, byteorder='big'))  # creation stamp
    macbinary[95:99] = array("B", timestamp.to_bytes(4, byteorder='big'))  # modification stamp
    return macbinary


# Writes array *data* to *out_file*
def write_macpaint_file(data: array, out_file: str, width: int, height: int):
    bits_array = prepare(data, width, height)
    rle = run_length_encode(bits_array)
    data_size = len(rle) + HEADER_LENGTH  # header requires this
    output_array = macbinary_header(out_file, data_size) + array('B', [0] * HEADER_LENGTH) + rle
    output_array[MACBINARY_LENGTH + 3] = 2  # Data Fork Header Signature
    # macbinary format requires that there be padding of 0s up to a
    # multiple of 128 bytes for the data fork
    padding = 128 - (data_size % 128)
    if padding > 0:
        output_array += array('B', [0] * padding)
    with open(out_file + ".bin", "wb") as fp:
        output_array.tofile(fp)

# Alternative version of run_length_encode that doesn't use the helper function
# # https://en.wikipedia.org/wiki/PackBits
# # MacPaint expects RLE to happen on a per-line basis (MAX_WIDTH)
# # In other words there are line boundaries
# def run_length_encode(original_data: array) -> array:
#     rle_data = array('B')
#     # Divide data into MAX_WIDTH size boundaries
#     for line_start in range(0, len(original_data), MAX_WIDTH // 8):
#         data = original_data[line_start:(line_start + (MAX_WIDTH // 8))]
#         start_pointer = 0
#         reading_pointer = 0
#         while start_pointer < len(data):
#             reading_pointer = start_pointer
#             same = 0
#             not_same = 0
#             while reading_pointer < len(data):
#                 if (reading_pointer + 1) < len(data) and data[reading_pointer] == data[reading_pointer + 1]:
#                     if not_same > 0:
#                         break
#                     same += 1
#                 elif same > 0:
#                     break
#                 else:
#                     not_same += 1
#                 reading_pointer += 1
#             if same > 0:
#                 rle_data.append(255 - same + 1)
#                 rle_data.append(data[start_pointer])
#             elif not_same > 0:
#                 rle_data.append(not_same - 1)
#                 rle_data += data[start_pointer:(start_pointer + not_same)]
#             start_pointer += max(same + 1, not_same)
#     return rle_data