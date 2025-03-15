# KNN/knn.py
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
from pathlib import Path
import csv
from typing import Protocol, Self
from collections import Counter
import numpy as np


class DataPoint(Protocol):
    kind: str

    @classmethod
    def from_string_data(cls, data: list[str]) -> Self: ...

    def distance(self, other: Self) -> float: ...


class KNN[DP: DataPoint]:
    def __init__(self, data_point_type: type[DP], file_path: str | Path,
                 has_header: bool = True) -> None:
        self.data_point_type = data_point_type
        self.data_points = []
        self._read_csv(file_path, has_header)

    # Read a CSV file and return a list of data points
    def _read_csv(self, file_path: str | Path, has_header: bool) -> None:
        with open(file_path, 'r') as f:
            reader = csv.reader(f)
            if has_header:
                _ = next(reader)
            for row in reader:
                self.data_points.append(
                    self.data_point_type.from_string_data(row))

    # Find the k nearest neighbors of a given data point
    def nearest(self, k: int, data_point: DP) -> list[DP]:
        return sorted(self.data_points, key=data_point.distance)[:k]

    # Classify a data point based on the k nearest neighbors
    # Choose the kind with the most neighbors and return it
    def classify(self, k: int, data_point: DP) -> str:
        neighbors = self.nearest(k, data_point)
        return Counter(neighbor.kind for neighbor in neighbors).most_common(1)[0][0]

    # Predict a numeric property of a data point based on the k-nearest neighbors.
    # Find the average of that property from the neighbors and return it.
    def predict(self, k: int, data_point: DP, property_name: str) -> float:
        neighbors = self.nearest(k, data_point)
        return (sum([getattr(neighbor, property_name) for neighbor in neighbors])
                / len(neighbors))

    # Predict a NumPy array property of a data point based on the k-nearest neighbors.
    # Find the average of that property from the neighbors and return it.
    def predict_array(self, k: int, data_point: DP, property_name: str) -> np.ndarray:
        neighbors = self.nearest(k, data_point)
        return (np.sum([getattr(neighbor, property_name) for neighbor in neighbors], axis=0)
                / len(neighbors))
