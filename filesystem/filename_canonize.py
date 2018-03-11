#!/bin/env python3
"""
Use only legal characters from files or current directory

Usage:
    strip_filenames.py [options] [<filename> ...]
    strip_filenames.py [-a]

Options:
    -l, --lowercase  Only lowercase
    -a, --all  Include hidden files
    -h, --help  Show this screen and exit.
    -v, --verbose  be verbose
"""

import sys
import os
import click
import string

# docopt(doc, argv=None, help=True, version=None, options_first=False))

@click.command("strip_filename.py")
@click.argument("filename", nargs=-1, required=False)
@click.option('-g', '--graph', 'mode', flag_value='graph', default=True, help="mode: [default] All alnum characters with some valid printables")
@click.option('-a', '--alnum', 'mode', flag_value='alnum', help="mode: letters + digits only")
@click.option('-l', '--lowercase', is_flag=True, help="Allow lowercase letters in filename")
@click.option('-i', '--hidden', is_flag=True, help="Include hidden files")
@click.option('-n', '--dryrun', is_flag=True, help="Do not rename files")
@click.option('-v', '--verbose', is_flag=True, help="Output files")
def main(filename, mode, lowercase, hidden, dryrun, verbose):
    set_alpha = set(string.ascii_letters)
    set_digits = set(string.digits)
    set_printable = set(string.printable)
    set_whitespace = set(string.whitespace)

    set_etc = set(".-_~")
    charmap = {
            " ": "_",
            "ä": "ae",
            "ö": "oe",
            "ü": "ue",
            "Ä": "Ae",
            "Ö": "Oe",
            "Ü": "Ue",
            }

    character_pool = None
    if mode == "graph":
        character_pool = set_alpha.union(set_digits).union(set_etc)
    if mode == "alnum":
        character_pool = set_alpha.union(set_digits)

    if lowercase:
        character_pool = character_pool - string.ascii_uppercase

    if not filename:
        filename = os.listdir()
    directory = filename

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
            elif c in character_pool:
                newname += c
                previous_char = c
            else:
                continue

        # check for illegal characters in first char
        if newname[0] in set_etc:
            newname = newname[1:]

        if verbose and not dryrun:
            print("{} --> {}".format(directory[a],newname), file=sys.stderr)
        if dryrun:
            print("{}".format(newname))
        else:
            os.rename(directory[a], newname)

if __name__ == "__main__":
    main()
