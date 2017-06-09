#!/bin/env python3
"""
Reevaluate old task entry uda values. Use a default age range to select from.

This example uses docopt with the built in cmd module to demonstrate an
interactive command application.
Usage:
    my_program tcp <host> <port> [--timeout=<seconds>]
    my_program serial <port> [--baud=<n>] [--timeout=<seconds>]
    my_program (-i | --interactive)
    my_program (-h | --help | --version)
Options:
    -i, --interactive  Interactive Mode
    -h, --help  Show this screen and exit.
    --baud=<n>  Baudrate [default: 9600]
"""

"""
<arguements>, ARGUMENTS -> list
--options, words with dash(-) , or --input=FILE or -i FILE
commands, dont follow above

Pattern constructs:
    [](brackets) optional elements
    ()(parentheses) required elements, everything not put in [] also required
    |(pipe) mutually exclusive elements. Group with () or []
    ...(ellipsis) one or more elements, e.g. my_program.py FILE ..., one ore
        more FILE s accepted, for zero or more use [FILE ...]
    [options](case sensitive) shortcut for options, defined in options below
    "[--]" used by convention to separate positional arguements
    "[-]" by conevntion signify stdin is used instead of a file
    [-v | -vv | -vv] countable flags, args["-v"] will be nr of occ

    Options:
      --verbose   # GOOD
      -o FILE     # GOOD
    Other: --bad  # BAD, line does not start with dash "-"

    -o FILE --output=FILE       # without comma, with "=" sign
    -i <file>, --input <file>   # with comma, without "=" sing

    Use two spaces to separate options with their informal description
	--verbose More text.   # BAD, will be treated as if verbose option had
			       # an argument "More", so use 2 spaces instead
	-q        Quit.        # GOOD
	-o FILE   Output file. # GOOD
	--stdout  Use stdout.  # GOOD, 2 spaces

    If you want to set a default value for an option with an argument, 
    put it into the option-description, in form [default: <my-default-value>]:
	--coefficient=K  The K coefficient [default: 2.95]
	--output=FILE    Output file [default: test.txt]
	--directory=DIR  Some directory [default: ./]

    for git like sub commands use, options_first parameter 

     args = docopt(__doc__,
                  version='git version 1.7.4.4',
                  options_first=True)
    print('global arguments:')
    print(args)
    print('command arguments:')

    argv = [args['<command>']] + args['<args>']
    if args['<command>'] == 'add':
        # In case subcommand is implemented as python module:
        import git_add
    print(docopt(git_add.__doc__, argv=argv))

"""


import sys
from docopt import docopt
from taskw import TaskWarrior
from prompt_toolkit.validation import Validator, ValidationError
from prompt_toolkit import prompt
from prompt_toolkit.history import InMemoryHistory
from prompt_toolkit.auto_suggest import AutoSuggestFromHistory
from prompt_toolkit.interface import AbortAction
import pprint
from datetime import datetime

# docopt(doc, argv=None, help=True, version=None, options_first=False))

history = InMemoryHistory()

def main():
    tw = TaskWarrior()
    #opt = docopt(__doc__, sys.argv[1:])
    #print(opt)
    config = tw.config



    pending_tasks = tw.load_tasks()["pending"]

    udas = config.get("uda")
    udas_map = config.get_udas()

    for task in pending_tasks:
        if not review_required(task):
            continue

        udas_new_map = dict()
        print("""
################################################################################
Updating task: 
 id: {}
 description: {}
 project: {}
 tags: {}
""".format(
    task.get("id"),
    task.get("description"),
    task.get("project"),
    task.get("tags"),
    ))

        for uda, values in udas.items():
            menu = create_interactive_menu(values)
            menu += "\n[latest := {}]".format(task.get(uda))
            validator = SelectMenuValidator(udas_map.get(uda))
            generate_udas(menu, uda ,values, validator, udas_new_map)

        print("The new task:")
        pp = pprint.PrettyPrinter(indent=4)
        pp.pprint(udas_new_map)
        if prompt_confirm():
            task.update(udas_new_map)
            task["review"] = format_datetime_iso(datetime.now())
            new_task = tw.task_update(task)
        else:
            print("Did not add task.")

def review_required(task):
    now = datetime.now().date()

    modified = task.get("modified")
    review = task.get("review", "")

    result = True

    if modified:
        modified = datetime.strptime(modified, "%Y%m%dT%H%M%SZ").date()
        result = result and now > modified
    if review:
        review = datetime.strptime(review, "%Y%m%dT%H%M%S.%f").date()
        result = result and now > review and now.day > review.day 

    return result

def format_datetime_iso(date):
    """
    return iso string
    """
    return date.isoformat().replace("-","").replace(":","")


def generate_udas(menu, uda, values, validator, udas_new_map):
    defaults = values.get("default")

    if defaults and defaults.find(",") != -1:
        defaults = defaults.split(",")
    else:
        return

    while True:
        try:
            print(menu)
            choice = ""
            choice = prompt("> ",
                validator=validator, 
                history=history,
                on_abort=AbortAction.RETRY,
                auto_suggest=AutoSuggestFromHistory())
        except InputError:
            choice = "?"
        except (KeyboardInterrupt, EOFError):
            print("bye")
            sys.exit(0)
        print("---")
        if choice:
            break
    udas_new_map.update({str(uda):str(choice)})


class SelectMenuValidator(Validator):
    def __init__(self, uda):
        self.uda = uda

    def validate(self, document):
        text = document.text

        if text == "":
            raise InputError("Input is empty")
        elif not self.uda.is_valid_choice(text):
            raise ValidationError(message="Choice is not a valid uda.")

class InputError(Exception):
    pass


def run_menu(menu, validator,  default="?"):

    if choice == "":
        return default
    elif choice is False:
        return False

def prompt_confirm(string=""):
    print(string)
    try:
        user_input = prompt("Do you want to continue?[yn]",
                history=history,
                on_abort=AbortAction.RETRY,
                auto_suggest=AutoSuggestFromHistory())
    except (KeyboardInterrupt, EOFError):
        print("bye")
        sys.exit(0)
    if user_input.lower() in ["y","yes","ye","j","ja"]:
        return True
    else:
        return False

def prompt_value(string, exit_if_empty=False):
    try:
        user_input = prompt("{}> ".format(string),
                history=history,
                on_abort=AbortAction.RETRY,
                erase_when_done=True,
                auto_suggest=AutoSuggestFromHistory())
    except (KeyboardInterrupt, EOFError):
        print("bye")
        sys.exit(0)
    if not user_input and exit_if_empty:
        print("No input.")
        sys.exit(1)
    return user_input

def create_interactive_menu(values):
    output = "{:#^40}".format(" {} ".format(values.get("label")))
    output += "\nSelect from defaults: \n\t{}".format(values.get("default"))
    return output

def usage():
    pass

if __name__ == "__main__":
    main()
