#!/bin/env python
import sys
data_input = ""
if len(sys.argv) == 1:
    data_input = sys.stdin.readlines()
else:
    data_input = sys.argv[1:]

data = " ".join(data_input)
print(data.strip(), end='')
