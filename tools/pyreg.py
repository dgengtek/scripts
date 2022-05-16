#!/usr/bin/env python3
import sys
import re


def usage():
    message = "usage: {} regex".format(sys.argv[0])
    print(message)


if len(sys.argv) is 2:
    regex = sys.argv[1]
else:
    usage()
    sys.exit(1)

intext = sys.stdin.readlines()

matcher = re.compile("(^{}$)".format(regex))

exitcode = 1
for i in intext:
    result = matcher.match(i)

    if result:
        (output,) = result.groups()
        print(output)
        exitcode = 0

sys.exit(exitcode)
