# KNN/__main__.py
# From Computer Science from Scratch
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
from KNN.knn import KNN
from KNN.digit import Digit
from pathlib import Path
import sys
import pygame
import numpy as np

PIXEL_WIDTH = 8
PIXEL_HEIGHT = 8
P_TO_D = 16 / 255  # pixel to digit scale factor
D_TO_P = 255 / 16  # digit to pixel scale factor
K = 9
WHITE = (255, 255, 255)


def run():
    # Create a 2D array of pixels to represent the digit
    digit_pixels = np.zeros((PIXEL_HEIGHT, PIXEL_WIDTH, 3),
                            dtype=np.uint32)
    # Load the training data
    digits_file = (Path(__file__).resolve().parent
                   / "datasets" / "digits" / "digits.csv")
    digits_knn = KNN(Digit, digits_file, has_header=False)
    # Startup Pygame, create the window
    pygame.init()
    screen = pygame.display.set_mode(size=(PIXEL_WIDTH, PIXEL_HEIGHT),
                                     flags=pygame.SCALED | pygame.RESIZABLE)
    pygame.display.set_caption("Digit Recognizer")
    while True:
        pygame.surfarray.blit_array(screen, digit_pixels)
        pygame.display.flip()

        # Handle keyboard events
        for event in pygame.event.get():
            if event.type == pygame.KEYDOWN:
                key_name = pygame.key.name(event.key)
                if key_name == "c":  # classify the digit
                    pixels = digit_pixels.transpose((1, 0, 2))[:, :, 0].flatten() * P_TO_D
                    classified_digit = digits_knn.classify(K, Digit("", pixels))
                    print(f"Classified as {classified_digit}")
                elif key_name == "e":  # erase the digit
                    digit_pixels.fill(0)
                elif key_name == "p":  # predict what the digit should look like
                    pixels = digit_pixels.transpose((1, 0, 2))[:, :, 0].flatten() * P_TO_D
                    predicted_pixels = digits_knn.predict_array(K, Digit("", pixels), "pixels")
                    predicted_pixels = predicted_pixels.reshape((PIXEL_HEIGHT, PIXEL_WIDTH)).transpose((1, 0)) * D_TO_P
                    digit_pixels = np.stack((predicted_pixels, predicted_pixels, predicted_pixels), axis=2)
            # Handle mouse events
            elif ((event.type == pygame.MOUSEBUTTONDOWN) or
                  (event.type == pygame.MOUSEMOTION and pygame.mouse.get_pressed()[0])):
                x, y = event.pos
                if x < PIXEL_WIDTH and y < PIXEL_HEIGHT:
                    digit_pixels[x][y] = WHITE
            elif event.type == pygame.QUIT:
                sys.exit()


if __name__ == "__main__":
    run()
