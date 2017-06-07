#!/bin/env python3
"""
Generate new tasks by prompting user defined attributes

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
from tasklib import TaskWarrior,task

# docopt(doc, argv=None, help=True, version=None, options_first=False))

udas = None

def main():
    tw = TaskWarrior()
    #opt = docopt(__doc__, sys.argv[1:])
    #print(opt)
    config = tw.config.items()

    new_task = task.Task(tw)

    description = prompt_value("Task description: ", exit_if_empty=True)
    new_task["description"] = description
    project = prompt_value("Project: ")
    new_task["project"] = project

    tags = []
    while True:
        tag = prompt_value("Add tag (leave with empty input on enter): ")
        if not tag:
            break
        tags.append(tag)
    new_task["tags"] = tags

    udas = parse_udas(config)

    for uda in udas:
        uda, defaults = canonize_uda(uda)
        menu = create_interactive_menu(uda,defaults)
        result = ""
        while True:
            result = run_menu(menu, defaults)
            print("---")
            if result:
                break
            else:
                print("==> ERROR: Please repeat your input.")
        new_task[uda] = result
    new_task.save()
    if new_task.saved:
        print("Task, {} - '{}', has been saved.".format(new_task["id"],new_task))


def run_menu(menu, values, default="?"):
    print(menu)
    choice = interactive_input()

    if choice == "":
        if not prompt_confirm("Using default: {}".format(default)):
            return False
        return default
    elif choice is False:
        return False

    try:
        return values[choice]
    except IndexError:
        return False

def prompt_confirm(string=""):
    print(string)
    try:
        user_input = input("Do you want to continue?[yn]")
    except (KeyboardInterrupt, EOFError):
        print("bye")
        sys.exit(0)
    if user_input.lower() in ["y","yes","ye","j","ja"]:
        return True
    else:
        return False

def prompt_value(string, exit_if_empty=False):
    try:
        user_input = input(string)
    except (KeyboardInterrupt, EOFError):
        print("bye")
        sys.exit(0)
    if not user_input and exit_if_empty:
        print("No input.")
        sys.exit(1)
    return user_input

def interactive_input():
    try:
        choice = input("Your choice: ")
        choice = int(choice) - 1
    except (KeyboardInterrupt, EOFError):
        print("bye")
        sys.exit(0)
    except ValueError:
        return ""

    if choice >= 0:
        return choice
    else:
        return False

def create_interactive_menu(uda, defaults):
    output = "{:#^40}".format(" {} ".format(uda))
    output += "\nSelect your value from highest(1) to lowest(n) weighting points:"
    for i,value in enumerate(defaults,1):
        output += "\n({})  {}".format(i, value)
    return output

def canonize_uda(uda):
    uda, default = uda
    # uda.name.default
    uda = uda.split(".")[1]
    # 0,1,2,3,...
    default = default.split(",")

    return uda,default

def parse_udas(config):
    uda_filter = build_filter("uda")
    default_filter = build_filter("default")

    config = filter(uda_filter, config)
    config = filter(default_filter, config )

    return config


def build_filter(string, negate=False):
    def filter_search(item):
        k,v = item
        if string in k and not negate:
            return True
        else:
            return False
    return filter_search

def usage():
    pass

if __name__ == "__main__":
    main()
