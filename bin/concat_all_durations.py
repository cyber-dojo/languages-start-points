#!/usr/bin/env python3

import json
import os
import sys
from pathlib import Path

MY_DIR=os.path.dirname(os.path.abspath(__file__))

def concat_all_durations(colour):
  """Print each start-point's duration for colour, slowest first."""
  durations = {}
  entries = Path(f"{MY_DIR}/../data/").glob("*")
  for entry in entries:
    parts = str(entry).split('/')
    name = parts[-1] # eg java-junit
    filename = f"{MY_DIR}/../data/{name}/durations.json"
    with open(filename, 'r') as file:
      data = json.load(file)
      # float() so the ordering is numeric. Comparing the JSON strings puts
      # '11.115' between '2.018' and '1.852', hiding the slowest start-points.
      durations[name] = float(data[f"{colour}_duration"])

  for name in sorted(durations, key=durations.get, reverse=True):
    print(f"{durations[name]:.3f}", name)


if __name__ == "__main__":
  colour = sys.argv[1]
  concat_all_durations(colour)