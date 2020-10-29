#!/usr/bin/env python3
import sys
import toml
import json

data_input = ""
if len(sys.argv) == 1:
    data_input = sys.stdin
else:
    data_input = open(sys.argv[1])

data = toml.load(data_input)
json.dump(data, sys.stdout)
