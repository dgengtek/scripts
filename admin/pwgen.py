#!/bin/env python3
"""
Generate passwords
Usage:
    genpw.py [options] [<length> [<count>]]
    genpw.py (-h | --help)

Options:
    -a, --alpha  Only alphanumeric chars
    -f, --filter <characters>  Filter string of characters
    -p, --printable  Only printable chars
    -h, --help  Show this screen and exit.
"""

import sys
from docopt import docopt
import random

string_all = "".join([ chr(x+32) for x in range(94) ])
string_printable = "".join([ chr(x+97) for x in range(26) ])
string_printable += "".join([ chr(x+65) for x in range(26) ])
string_alpha = "{}{}".format(string_printable, 
        "".join([ chr(x+48) for x in range(10) ]))

# docopt(doc, argv=None, help=True, version=None, options_first=False))

def main():
    opt = docopt(__doc__, sys.argv[1:], options_first=True)
    length = opt.get("<length>")
    count = opt.get("<count>")
    character_filter = opt.get("--filter")

    length = int(length) if length else 8
    count = int(count) if count else 30

    string = string_all
    if opt.get("--alpha"):
        string = string_alpha
    if opt.get("--printable"):
        string = string_printable
    if not character_filter:
        character_filter = ""
    for character in character_filter:
        string = string.replace(character, "")

    for i in range(1, count+1):
        print(generate_password(string, length), end="\t")
        if i % 3 == 0:
            print("\n")

def generate_password(string, size):
    return "".join([ random.choice(string) for x in range(size) ])

if __name__ == "__main__":
    main()
