#!/bin/env python3
"""
Use only legal characters from files or current directory
"""

import sys
import os
import click
import string
import pathlib

# docopt(doc, argv=None, help=True, version=None, options_first=False))


@click.command("strip_filename.py")
@click.argument("filename", nargs=-1, required=False)
@click.option(
    '-g', '--graph', 'mode',
    flag_value='graph', default=True,
    help="mode: [default] All alnum characters with some valid printables")
@click.option(
    '-a', '--alnum', 'mode',
    flag_value='alnum',
    help="mode: letters + digits only")
@click.option(
    '-l', '--lowercase',
    is_flag=True,
    help="Return filename as lowercase")
@click.option('-i', '--hidden', is_flag=True, help="Include hidden files.")
@click.option(
    '-n', '--dryrun',
    is_flag=True,
    help="Do not rename files. Print only the new name")
@click.option(
    '-v', '--verbose',
    is_flag=True,
    help="Output filename changes.")
def main(filename, mode, lowercase, hidden, dryrun, verbose):
    """
    This script canonizes filenames. If no filename has been given it will
    only fetch names for the current directory
    but will not recurse into sub directories.

    FILENAME can also be a directory.
    """
    set_alpha = set(string.ascii_letters)
    set_digits = set(string.digits)

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

    if not filename:
        filename = os.listdir()
    elif len(filename) == 1 and filename[0] == "-":
        filenames = list()
        with click.open_file("-", "r") as f:
            for line in f.readlines():
                filenames.append(line.strip())
        filename = filenames

    for i, path in enumerate(filename):
        path_name = path
        path = pathlib.Path(path)
        newname = ""
        previous_char = path_name[0]
        for c in path_name:
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
        if lowercase:
            newname = newname.lower()

        changed = newname != path_name

        if verbose and not dryrun and changed:
            print("{} --> {}".format(path, newname), file=sys.stderr)
        if dryrun:
            print("{}".format(newname))
        else:
            path.rename(newname)


if __name__ == "__main__":
    main()
