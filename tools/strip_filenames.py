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
    -v, --verbose  be verbose
"""

import sys
import os
from docopt import docopt

# docopt(doc, argv=None, help=True, version=None, options_first=False))

def main():
    opt = docopt(__doc__, sys.argv[1:])
    enable_verbose = opt.get("--verbose")

    directory = opt.get("filename", os.listdir())
    legal_characters = set()
    set_N010 = { str(x) for x in range(10) }
    set_alpha = { chr(x+97) for x in range(26) }
    set_ALPHA = { chr(x+65) for x in range(26) }
    set_etc = ".-_~"
    charmap = {
            " ": "_",
            "ä": "ae",
            "ö": "oe",
            "ü": "ue",
            "Ä": "Ae",
            "Ö": "Oe",
            "Ü": "Ue",
            }

    legal_characters = legal_characters.union(set_N010)
    legal_characters = legal_characters.union(set_alpha)
    legal_characters = legal_characters.union(set_etc)

    if not opt.get("--lowercase", False):
        legal_characters = legal_characters.union(set_ALPHA)

    for a in range(len(directory)):
        newname = ""
        previous_char = directory[a][0]
        for c in directory[a]:
            mapped_char = charmap.get(c, "")

            # check if previous character matches current character
            if previous_char == mapped_char \
                    or (c == previous_char and c in set_etc):
                continue

            if mapped_char:
                newname += mapped_char
                previous_char = mapped_char
            elif c in legal_characters:
                newname += c
                previous_char = c
            else:
                continue

        # check for illegal characters in first char
        if newname[0] in set_etc:
            newname = newname[1:]

        if enable_verbose:
            print("convert {} to {}".format(directory[a],newname))
        os.rename(directory[a], newname)

if __name__ == "__main__":
    main()
