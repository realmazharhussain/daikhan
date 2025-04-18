#!/usr/bin/env python3

import json
import sys

if '-h' in sys.argv or '--help' in sys.argv:
    print(f"Usage: {sys.argv[0]} FILE1 FILE2")
    print("NOTE: This only works on files generated by `daikhan-content-id` tool with `--batch --json` options.")
    exit(0)

if len(sys.argv) != 3:
    print("Must provide exactly 2 files to compare", file=sys.stderr)
    exit(1)

with open(sys.argv[1]) as f:
    first = json.loads(f.read())

with open(sys.argv[2]) as f:
    second = json.loads(f.read())

print(f"Files not in {sys.argv[1]}:")
for filename in second.keys():
    if filename not in first:
        print("  " + filename)

print()
print(f"Files not in {sys.argv[2]}:")
for filename in first.keys():
    if filename not in second:
        print("  " + filename)

print()
print(f"Files that differ in content:")
for filename in first.keys():
    if filename in second and first[filename]['content_id'] != second[filename]['content_id']:
        print("  " + filename)
