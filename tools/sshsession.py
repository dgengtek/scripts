#!/bin/env python3
"""
Usage:
    sshsession.py [options] [SSHKEY...]

options:
    -h, --help  Show this screen and exit.
"""
import os
import sys
import re
import subprocess
from pathlib import Path
from docopt import docopt
# TODO check ssh path exists
# TODO add logging
# TODO add unit tests

def main():
    # parse docopt
    opt = docopt(__doc__, sys.argv[1:])

    home = os.environ["HOME"]
    main.ssh_path = Path(home, ".ssh")

    success = False
    ssh_keys = opt.get("SSHKEY", [])
    if len(ssh_keys) is 0:
        success = run_interactive(main.ssh_path)
    else:
        success = run_non_interactive(main.ssh_path, ssh_keys)
    if success:
        os.execl("/usr/bin/bash","bash", "-i")
    else:
        print_error("Failed sshsession.")
        sys.exit(1)

def run_non_interactive(path, ssh_keys):
    added_once = False
    for ssh_key in ssh_keys:
        key_path = path.joinpath(ssh_key)
        proc = add_ssh_key(key_path)
        if not added_once and proc.returncode is 0:
            added_once = True
    return added_once

def run_interactive(path):
    glob = r"id*.pub"
    ids = path.glob(glob)
    ids = list(ids)
    ids = sorted(ids)
    menu = create_interactive_menu(ids)
    choice=-1

    while True:
        print(menu)
        choice = interactive_input(ids)
        if choice is not None:
            proc = add_ssh_key(path.joinpath(ids[choice]))
            if proc.returncode is 0:
                return True
            else:
                return False
        else:
            print(choice)
            print_error("Invalid choice")

def interactive_input(ids):
    try:
        choice = input("Your choice: ")
        choice = int(choice) - 1
    except (KeyboardInterrupt, EOFError):
        print_error("bye")
        sys.exit(0)
    if is_in_bounds(choice, ids):
        return choice
    else:
        return None

def get_ids(items, matcher):
    ids = []
    found = False
    for i in items:
        result=matcher.match(i)
        if result:
            # get first item of groups match
            result,*s = result.groups()
            ids.append(result)
        elif len(ids) is 0:
            raise Exception("Items empty")
    return ids

def is_in_bounds(choice, items):
    length = len(items)
    if choice >= 0 and choice < length:
        return True
    else:
        return False

def create_interactive_menu(ids):
    output = "{:#^40}".format("Available ssh ids")
    output += "\nSelect an id:"
    for nr,key in enumerate(ids,1):
        output += "\n  {}\t{}".format(nr,key.name)
    return output

def add_ssh_key(key):
    # strip away .pub to get private key file
    if not key.is_file():
        print_error("Key {} does not exist.".format(str(key)))
        return False
    key = remove_suffix(str(key), ".pub")
    return subprocess.run(["/usr/bin/ssh-add", key])

def remove_suffix(string, suffix):
    if not string.endswith(suffix):
        return string
    position = string.find(suffix)
    return string[:position]

def print_error(text, fd=sys.stderr):
    print(text, file=fd)

if __name__ == "__main__":
    if os.name is not "posix":
        print_error("OS not supported.")
        sys.exit(1)
    main()


################################################################################
# Tests

