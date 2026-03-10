#!/usr/bin/env python3

import json
import os
import sys
from pathlib import Path

MY_DIR=os.path.dirname(os.path.abspath(__file__))

def concat_all_durations(colour):
  durations = {}
  entries = Path(f"{MY_DIR}/../data/").glob("*")
  for entry in entries:
    parts = str(entry).split('/')
    name = parts[-1] # eg java-junit
    filename = f"{MY_DIR}/../data/{name}/durations.json"
    with open(filename, 'r') as file:
      data = json.load(file)
      durations[name] = data[f"{colour}_duration"]

  sorted_durations = sorted(durations, key=durations.get)
  for r in reversed(sorted_durations):
    print(durations[r][:5], r)


if __name__ == "__main__":
  colour = sys.argv[1]
  concat_all_durations(colour)