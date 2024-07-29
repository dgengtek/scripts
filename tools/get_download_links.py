#!/usr/bin/env python3
"""
get any download links found in the html document with the download id
"""

import logging
import sys
import argparse
import atexit
import signal
import subprocess
import os
from pathlib import Path
import shlex

import requests
from bs4 import BeautifulSoup

logger = logging.getLogger(__name__)


def main():
    # atexit.register(cleanup, "Cleanup before exit")
    # signal.signal(signal.SIGALRM, handler)

    args = parse_args()

    website = requests.get(args.url)
    results = BeautifulSoup(website.content, "html.parser")

    for r in results.find_all("div", id="download"):
        found = r.find("a")["href"]
        if found:
            print(found)


def usage():
    """
    usage method for help
    """


def parse_args():
    """
    parse arguments and return result
    """
    parser = argparse.ArgumentParser(
        description="get download links from url.", epilog="", add_help=True
    )
    # positional arguments
    parser.add_argument("url", help="url to get download links froms")

    return parser.parse_args()


def cleanup(description):
    prerr(description)


def handler(signum, frame):
    print("Signal handler called with signal", signum, file=sys.stderr)


def prerr(msg):
    print(msg, file=sys.stderr)


def die(msg, exit_code=1):
    print(msg, file=sys.stderr)
    sys.exit(exit_code)


def run(*args):
    return subprocess.run(args)


def call(*args):
    return subprocess.call(args)


def run_cmd(cmd, args):
    if isinstance(cmd, Path):
        cmd = str(cmd)
    logger.debug("Running: {} {}".format(cmd, " ".join(args)))
    proc = subprocess.Popen(
        [cmd] + args, stderr=subprocess.PIPE, stdout=subprocess.PIPE
    )
    proc.wait()
    if proc.stdout.peek():
        out = [x.decode("UTF-8") for x in proc.stdout.readlines()]
        logger.info("\n".join(proc.stdout.readlines()))
    if proc.returncode > 0:
        out = [x.decode("UTF-8") for x in proc.stderr.readlines()]
        logger.error("\n".join(out))
    return proc


def run_string(command):
    args = shlex.split(command)
    p = subprocess.Popen(args, stdout=subprocess.PIPE, stdin=subprocess.PIPE)
    p.wait()
    return p


def run_process(*args):
    p = subprocess.Popen(args, stdout=subprocess.PIPE, stdin=subprocess.PIPE)
    p.wait()
    return p


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
