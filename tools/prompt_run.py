#!/usr/bin/env python3
"""
run the input args as a prefix command in a prompt which uses the user input as
args for the prefix command for execution
"""
import logging
import sys
import argparse
import atexit
import signal
import subprocess
import os
import shlex
logger = logging.getLogger(__name__)


def main():
    """
    main method
    """

    atexit.register(cleanup, "Cleanup before exit")
    signal.signal(signal.SIGALRM, handler)

    args = parse_args().args
    if not args:
        die("Arguments for the prefix to execute are required")

    while True:
        try:
            user_input = input("{} > ".format(" ".join(args)))
        except EOFError:
            sys.exit(0)
        except KeyboardInterrupt:
            print()
            continue

        call_args = list(args)
        call_args.extend(shlex.split(user_input))
        subprocess.call(call_args)


def usage():
    """
    usage method for help
    """


def parse_args():
    """
    parse arguments and return result
    """
    parser = argparse.ArgumentParser(
            description="Program description.",
            epilog="Epilog of program.",
            add_help=True
            )

    parser.add_argument(
        'args',
        nargs=argparse.REMAINDER)

    return parser.parse_args()


def cleanup(description):
    # prerr(description)
    pass


def handler(signum, frame):
    print('Signal handler called with signal', signum, file=sys.stderr)


def prerr(msg):
    print(msg, file=sys.stderr)


def die(msg, exit_code=1):
    print(msg, file=sys.stderr)
    sys.exit(exit_code)


def check_env(var):
    res = os.environ.get(var)
    if res is None:
        prerr("env '{}' is not set".format(var))
    elif res == "":
        prerr("env '{}' is empty".format(var))
    else:
        return True
    return False


if __name__ == "__main__":
    main()
