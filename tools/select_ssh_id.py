#!/bin/env python3
import os
import sys
import re
import subprocess
# TODO add arguments to pass ssh_path and a list of keys to add
# TODO check ssh path exists
# TODO add logging
# TODO add unit tests


def main():
    main.ssh_path="{}/.ssh".format(os.environ["HOME"])  
    items = os.listdir(main.ssh_path)
    if len(sys.argv) is 2:
        add_ssh_key(main.ssh_path + "/" + sys.argv[1])

    regex = r"id(?!.*[.]pub).*"
    # group regex
    matcher = re.compile("({})".format(regex))
    ids = get_ids(items, matcher)
    output = create_interactive_menu(ids)

    choice=-1
    while True:
        print(output)
        try:
            choice = input("Your choice: ")
            choice = int(choice)
        except KeyboardInterrupt:
            print()
            sys.exit(2)
        if is_in_bounds(choice, ids):
            add_ssh_key(main.ssh_path+"/"+ids[choice-1])
        else:
            print("Invalid choice")

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

def is_in_bounds(choice, l):
    length = len(l)
    if choice <= length and choice > 0:
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
    print("Add key from location: ",key)
    os.execl("/usr/bin/ssh-add","ssh-add", key)



if __name__ == "__main__":
    main()
