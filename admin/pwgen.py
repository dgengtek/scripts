#!/bin/env python3
"""
Generate passwords
Usage:
    genpw.py [options] [<length> [<count>]]
    genpw.py [(-a|-p|-l)] [<length> [<count>]]
    genpw.py (-h | --help)

Options:
    -a, --alnum  Only alphanumeric chars
    -f, --filter <characters>  Filter character_pool of characters
    -p, --pin  Only pin
    -l, --letters  Only alpha characters
    -h, --help  Show this screen and exit.
"""

import sys
from docopt import docopt
import random

set_all = { chr(x+32) for x in range(94) }
set_alpha = { chr(x+97) for x in range(26) }
set_alpha = set_alpha.union({ chr(x+65) for x in range(26) })
set_pin = { chr(x+48) for x in range(10) }

# docopt(doc, argv=None, help=True, version=None, options_first=False))

def main():
    opt = docopt(__doc__, sys.argv[1:], options_first=True)
    length = opt.get("<length>")
    count = opt.get("<count>")
    character_filter = opt.get("--filter")

    length = int(length) if length else 8
    count = int(count) if count else 30

    character_pool = set_all
    if opt.get("--alnum"):
        character_pool = set_alpha.union(set_pin)
    if opt.get("--letters"):
        character_pool = set_alpha
    if opt.get("--pin"):
        character_pool = set_pin
    if not character_filter:
        character_filter = set()
    else:
        character_filter = set(character_filter)
    character_pool = character_pool.difference(character_filter)
    character_pool = "".join(character_pool)

    for i in range(1, count+1):
        print(generate_password(character_pool, length), end="\t")
        if i % 3 == 0:
            print("\n")

def generate_password(pool, size):
    return "".join([ random.choice(pool) for x in range(size) ])

if __name__ == "__main__":
    main()
