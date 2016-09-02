#!/bin/env python3
from pathlib import Path
import subprocess

def main():
    main.path = Path(".config/wol.cfg")
    main.path = main.path.home().joinpath(main.path)
    # iterate wake on lan list, wollist
    menu = generate_menulist(main.path)
    if display_menu(menu):
        hostname, hwadress = menu[main.user_choice]
        subprocess.run(["wol", hwadress])

            
def display_menu(menu):
    for i, item in enumerate(menu):
        print("{} - {}".format((i+1),item))
    try:
        choice = input("Your choice: ")
        main.user_choice = int(choice) - 1
    except KeyboardInterrupt:
        print()
        return False
    if check_in_bounds(main.user_choice, menu):
        return True
    else:
        print("{:-^80}".format("Invalid choice"))
        display_menu(menu)
    

def check_in_bounds(choice, l):
    length = len(l)
    if choice < length and choice >= 0:
        return True
    else:
        return False
            
def generate_menulist(path):
    menu = list()
    with path.open() as wollist:
        for record in wollist:
           menu.append(tuple(record.strip().split(" "))) 
    return menu
            
def usage():
  pass

if __name__ == "__main__":
  main()
