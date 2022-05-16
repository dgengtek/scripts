#!/usr/bin/env python3
"""
print a random line from the given file or stdin
"""
import logging
import sys
import argparse
from random import randint

logger = logging.getLogger(__name__)


def main():
    """
    main method
    """
    args = parse_args()

    file_lines = args.filename.readlines()
    random_line = randint(0, len(file_lines))
    print(file_lines[random_line])


def parse_args():
    """
    parse arguments and return result
    """
    parser = argparse.ArgumentParser(
        description="print random line.", epilog="Epilog of program.", add_help=True
    )

    # optional input
    parser.add_argument(
        "filename",
        nargs="?",
        help="filename to print random line from",
        type=argparse.FileType("r"),
        default=sys.stdin,
    )

    return parser.parse_args()


if __name__ == "__main__":
    main()
