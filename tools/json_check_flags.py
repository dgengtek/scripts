#!/usr/bin/env python3
"""
output some git relevant states as json
"""
import logging
import json
import subprocess
import sys

logger = logging.getLogger(__name__)


def run_cmd(command, delimiter=" "):
    args = command.split(delimiter)
    p = subprocess.Popen(args, stdout=subprocess.PIPE, stdin=subprocess.PIPE)
    p.wait()
    return p


def main():
    args = parse_args()
    args = vars(args)
    all_flags = args.get("all")
    flags = args.get("flags")
    invert_result = args.get("invert")
    json_data = json.load(sys.stdin)

    flagtype = "any"
    result = False
    if all_flags:
        result = True
        flagtype = "all"

    comparison = generate_comparison(flagtype)
    for flag in flags:
        try:
            flag = bool(json_data.get(flag))
        except KeyError:
            print("Flag {} does not exist".format(flag), file=sys.stderr)
            sys.exit(1)
        result = comparison(result, flag)
    if invert_result:
        result = not result
    if result:
        result = 0
    else:
        result = 1
    sys.exit(result)


def generate_comparison(flagtype):
    def __c_any(a, b):
        return a or b

    def __c_all(a, b):
        return a and b

    flagmap = {
        "any": __c_any,
        "all": __c_all,
    }
    return flagmap.get(flagtype)


def usage():
    pass


def parse_args():
    import argparse

    parser = argparse.ArgumentParser(
        description="""\
Check flags from input and return result of lags as a returncode
""",
        epilog="",
        add_help=True,
    )
    # positional arguments
    # mutual exclusive, either foo or bar
    exclusive_group = parser.add_mutually_exclusive_group()
    exclusive_group.add_argument(
        "--any", help="any flag is true(default)", action="store_true"
    )
    exclusive_group.add_argument(
        "--all", help="all flags are true", action="store_true"
    )

    parser.add_argument("--invert", help="invert result", action="store_true")

    parser.add_argument("flags", nargs="+", help="target directory")
    parser.set_defaults(any=True)

    return parser.parse_args()


if __name__ == "__main__":
    main()
