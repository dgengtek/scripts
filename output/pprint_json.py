#!/bin/env python3
import json
import pprint
import sys
json_string = ""
for line in sys.stdin.readlines():
    json_string = "{}{}".format(json_string, line.strip())
item = json.loads(json_string)
pprint.pprint(item)
