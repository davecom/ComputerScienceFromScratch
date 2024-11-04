# tests/test_nesemulator.py
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
# Tries running multiple different tests to verify the correctness of our KNN implementation.
import unittest
import os
import csv
from pathlib import Path
from KNN.knn import KNN
from KNN.fish import Fish
from KNN.digit import Digit


class FishTestCase(unittest.TestCase):
    def setUp(self) -> None:
        # Change working directory to this file to get datasets
        os.chdir(Path(__file__).resolve().parent)

    def test_nearest(self):
        k: int = 3
        fish_knn = KNN(Fish, '../KNN/datasets/fish/fish.csv')
        test_fish: Fish = Fish("", 0.0, 30.0, 32.5, 38.0, 12.0, 5.0)
        nearest_fish: list[Fish] = fish_knn.nearest(k, test_fish)
        self.assertEqual(len(nearest_fish), k)
        expected_fish = [Fish('Bream', 340.0, 29.5, 32.0, 37.3, 13.9129, 5.0728),
                         Fish('Bream', 500.0, 29.1, 31.5, 36.4, 13.7592, 4.368),
                         Fish('Bream', 700.0, 30.4, 33.0, 38.3, 14.8604, 5.2854)]
        self.assertEqual(nearest_fish, expected_fish)

    def test_classify(self):
        k: int = 5
        fish_knn = KNN(Fish, '../KNN/datasets/fish/fish.csv')
        test_fish: Fish = Fish("", 0.0, 20.0, 23.5, 24.0, 10.0, 4.0)
        classify_fish: str = fish_knn.classify(k, test_fish)
        self.assertEqual(classify_fish, "Parkki")

    def test_predict(self):
        k: int = 5
        fish_knn = KNN(Fish, '../KNN/datasets/fish/fish.csv')
        test_fish: Fish = Fish("", 0.0, 20.0, 23.5, 24.0, 10.0, 4.0)
        predict_fish: float = fish_knn.predict(k, test_fish, "weight")
        self.assertEqual(predict_fish, 165.0)


class DigitsTestCase(unittest.TestCase):
    def setUp(self) -> None:
        # Change working directory to this file to get datasets
        os.chdir(os.path.dirname(os.path.abspath(__file__)))

    def test_digits_test_set(self):
        k: int = 1
        digits_knn = KNN(Digit, '../KNN/datasets/digits/digits.csv',
                         has_header=False)
        test_data_points: list[Digit] = []
        with open('../KNN/datasets/digits/digits_test.csv', 'r') as f:
            reader = csv.reader(f)
            for row in reader:
                test_data_points.append(Digit.from_string_data(row))
        correct_classifications = 0
        for test_data_point in test_data_points:
            predicted_digit: str = digits_knn.classify(k, test_data_point)
            if predicted_digit == test_data_point.kind:
                correct_classifications += 1
        correct_percentage = (correct_classifications
                              / len(test_data_points) * 100)
        print(f"Correct Classifications: "
              f"{correct_classifications} of {len(test_data_points)} "
              f"or {correct_percentage}%")
        self.assertGreater(correct_percentage, 97.0)


if __name__ == "__main__":
    unittest.main()