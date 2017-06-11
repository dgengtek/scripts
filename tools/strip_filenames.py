#!/bin/env python3
"""
Use only legal characters from files or current directory
Usage:
    strip_filenames.py [<filename>...]
Options:
    -l, --lowercase  Only lowercase
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
    list_N010 = list(range(size))
    list_alpha = [ chr(x+97) for x in range(26) ]
    list_ALPHA = [ chr(x+65) for x in range(26) ]

    legal_characters += "".join(list_N010)
    legal_characters += "".join(list_alpha)
    if not opt.get("--lowercase", False):
        legal_characters += "".join(list_N010)


    for a in range(len(directory)):
        newname=""
        for c in directory[a]:
            if c not in legal_characters:
                continue
            newname += c
        print("convert {} to {}".format(directory[a],newname))
        os.rename(directory[a], newname)

if __name__ == "__main__":
    main()
