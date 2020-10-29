#!/usr/bin/env python3
import sys
import toml
import json

data_input = ""
if len(sys.argv) == 1:
    data_input = sys.stdin
else:
    data_input = open(sys.argv[1])

data = json.load(data_input)
print(toml.dump(data))
