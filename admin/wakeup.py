#!/bin/env python3
from pathlib import Path
import subprocess
import logging
import sys
logger = logging.getLogger(__name__)

wol_path = "~/.config/wol.cfg"
# TODO query list from database when available

def main():
    global wol_path
    wol_path = Path(wol_path).expanduser()
    # iterate wake on lan list, wollist
    menu = generate_menulist(wol_path)
    while True:
        user_choice = ""
        display_menu(menu)
        try:
            choice = input("Your choice: ")
            user_choice = int(choice) - 1
            if check_in_bounds(user_choice, menu):
                break
            else:
                logger.info("Choose a number from the menu.")

        except (KeyboardInterrupt, EOFError):
            logger.error("\nbye")
            sys.exit(0)
        except (ValueError, TypeError):
            logger.error("Input is not a number.")


    hostname, hwadress = menu[user_choice]
    subprocess.run(["wol", "-p", "9", hwadress])

            
def display_menu(menu):
    for i, item in enumerate(menu):
        print("{} - {}".format((i+1),item))

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
