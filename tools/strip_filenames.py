#!/bin/env python3
"""
Use only legal characters from files or current directory

Usage:
    strip_filenames.py [-a]
    strip_filenames.py [options] [<filename> ...]

Options:
    -l, --lowercase  Only lowercase
    -a, --all  Include hidden files
    -h, --help  Show this screen and exit.
"""

import sys
import os
from docopt import docopt

# docopt(doc, argv=None, help=True, version=None, options_first=False))

def main():
    opt = docopt(__doc__, sys.argv[1:])
    directory = opt.get("filename", os.listdir())
    legal_characters = ""
    list_N010 = [ str(x) for x in range(10) ]
    list_alpha = [ chr(x+97) for x in range(26) ]
    list_ALPHA = [ chr(x+65) for x in range(26) ]

    legal_characters += "".join(list_N010)
    legal_characters += "".join(list_alpha)
    legal_characters += ".-_~"

    if not opt.get("--lowercase", False):
        legal_characters += "".join(list_ALPHA)


    consecutive_char = ""
    for a in range(len(directory)):
        newname = ""
        for c in directory[a]:
            if consecutive_char and c == consecutive_char:
                continue
            else:
                consecutive_char = c

            if c == " ":
                newname += "_"
            elif c in legal_characters:
                newname += c

            else:
                continue
        print("convert {} to {}".format(directory[a],newname))
        os.rename(directory[a], newname)

def is_consecutive_char(char_consec, char):


if __name__ == "__main__":
    main()
