#!/bin/env python3
"""
Usage:
    sshsession.py [options] [SSHKEY...]

options:
    -h, --help  Show this screen and exit.
"""
import os
import re
import subprocess
import sys

from pathlib import Path
from docopt import docopt

# TODO check ssh path exists
# TODO add logging
# TODO add unit tests
# TODO add bash prompt coloring
#       research: import PS1 from current invoked interactive bash session?

used_keys = []

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
        print()
        run_sshsession()

    else:
        print_error("Failed sshsession.")
        sys.exit(1)

def run_sshsession(custom_prompt=True):
    import tempfile
    global used_keys

    with tempfile.NamedTemporaryFile(delete=True) as f:
        prompt = ""
        if custom_prompt:
            COLOR = "\033[0;33m"
            COLOR_NONE = "\033[0m"
            prompt= r"""
PS1="({1}SSHSESSION{2} {0})
$(__set_custom_bash_prompt "$?" "\u" "@\h#\W]$ ")"
""".format(used_keys, COLOR, COLOR_NONE)
        bash_cmd = r"""
source ~/.bashrc
{0}
        """.format(prompt)
        with open(f.name, "w") as fo:
            fo.write(bash_cmd)

        command = [
                "/usr/bin/bash",
                "--rcfile",
                f.name,
                "-i",
                ]
        subprocess.call(command) 
        #os.execl("/usr/bin/bash","bash", "-i")


def run_non_interactive(path, ssh_keys):
    global used_keys
    added_once = False

    for ssh_key in ssh_keys:
        key_path = path.joinpath(ssh_key)
        used_keys.append(os.basename(str(key_path)))
        proc = add_ssh_key(key_path)
        if not added_once and proc.returncode is 0:
            added_once = True
    return added_once

def run_interactive(path):
    global used_keys
    cwd = os.getcwd()

    os.chdir(str(path))
    ids = os.listdir(".")
    ids = get_ids(ids)
    os.chdir(cwd)

    ids = sorted(ids)
    menu = create_interactive_menu(ids)
    choice=-1

    while True:
        print(menu)
        choice = interactive_input(ids)
        if choice is not None:
            key = ids[choice]
            used_keys.append(os.path.basename(str(key)))
            proc = add_ssh_key(path.joinpath(key))
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

def get_ids(items):
    import subprocess
    ids = []
    found = False
    valid_keyfiletype = "PEM RSA private key"
    for item in items:
        command = ["file", item]
        result = subprocess.Popen(command, 
                stderr=subprocess.DEVNULL,
                stdout=subprocess.PIPE)
        result = result.stdout.read().decode("UTF-8").split(":")
        f, filetype = result
        f = f.strip()
        filetype = filetype.strip()

        if filetype == valid_keyfiletype:
            ids.append(item)

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
        output += "\n  {}\t{}".format(nr,key)
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
    try:
        main()
    except KeyboardInterrupt:
        print_error("\nbye")
        sys.exit(0)



################################################################################
# Tests

