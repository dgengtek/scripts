#!/bin/env python3
"""
Manage tasks interactively

Usage:
    task_manage.py add
    task_manage.py review [<filter>]

Options:
    -h, --help  Show this screen and exit.

Commands:
    add  Add new task
    review  Review tasks
"""

import sys
from docopt import docopt
from tasklib import TaskWarrior,Task
from prompt_toolkit.validation import Validator, ValidationError
from prompt_toolkit import prompt
from prompt_toolkit.history import InMemoryHistory
from prompt_toolkit.auto_suggest import AutoSuggestFromHistory
from prompt_toolkit.interface import AbortAction
import pprint
from datetime import datetime,timedelta
import random
import logging
from itertools import tee

# docopt(doc, argv=None, help=True, version=None, options_first=False))

history = InMemoryHistory()

tw = None

def get_command(opts):
    commands = ["add", "review"]
    for command in commands:
        if opts.get(command):
            return command
    return ""

def main():
    opt = docopt(__doc__, sys.argv[1:])
    
    command = get_command(opt)
    command = generate_command(command,  **opt)
    if not command:
        logging.info("Command not legal.")
        sys.exit(1)

    global tw
    tw = TaskWarrior()
    #opt = docopt(__doc__, sys.argv[1:])
    #print(opt)

    command()

def generate_command(command, *args, **kwargs):
    def generate_review():
        task_filter = kwargs.get("<filter>", "")
        review_task(task_filter)

    commands = {
            "add": add_task,
            "review": generate_review,
            }

    return commands.get(command, "")


def add_task():
    global tw
    config = tw.config.items()

    udas_new_map = dict()

    description = prompt_value("Task description", exit_if_empty=True)
    udas_new_map.update({"description":description})


    project = prompt_value("Project")
    udas_new_map.update({"project":project})

    tags = []
    for tag in prompt_items("Add a tag."):
        tags.append(tag)
    udas_new_map.update({"tags": tags})

    annotations = []
    for annotation in prompt_items("Add an annotation."):
        annotations.append(annotation)
    
    config_udas = parse_udas(config)
    config_udas, udas = tee(config_udas)
    for uda in udas:
        uda, defaults = canonize_uda(uda)
        menu = create_interactive_menu(uda, defaults)
        validator = SelectMenuValidator(uda, defaults)

        while True:
            print(menu)
            value = prompt_value(validator=validator)
            if value:
                break
        udas_new_map.update({uda: value})

    print("The new task:")
    pp = pprint.PrettyPrinter(indent=4)
    pp.pprint(udas_new_map)
    if prompt_confirm():
        new_task = Task(tw, **udas_new_map)
        new_task.save()
        if new_task.saved:
            for annotation in annotations:
                new_task.add_annotation(annotation)
            print(new_task["id"])
        else:
            logging.info("Task has not been saved.")
    else:
        logging.info("Did not add task.")

def prompt_items(string):
    while True:
        tag = prompt_value(string)
        if not tag:
            break
        yield tag


def review_task(taskfilter, status="pending"):
    global tw
    config = tw.config.items()
    config_udas = parse_udas(config)
    force_review = False

    if taskfilter:
        pending_tasks = tw.tasks.filter(taskfilter, status=status)
        force_review = True
    else:
        pending_tasks = tw.tasks.pending()

    if not pending_tasks:
        logging.info("No tasks found.")
        return

    for task in pending_tasks:
        if not (force_review or review_required(task)):
            continue

        udas_new_map = dict()
        print("""
################################################################################
Updating task: 
 id: {}
 description: {}
 annotations: 
    {}
 project: {}
 tags: {}
""".format(
    task["id"],
    task["description"],
    task["annotations"],
    task["project"],
    task["tags"],
    ))

        config_udas, udas = tee(config_udas)
        for uda in udas:
            uda, defaults = canonize_uda(uda)
            menu = create_interactive_menu(uda, defaults)
            validator = SelectMenuValidator(uda, defaults)

            while True:
                print(menu)
                value = prompt_value(validator=validator,
                    default=task[uda])
                if value:
                    break
            udas_new_map.update({uda: value})

        print("The new task:")
        pp = pprint.PrettyPrinter(indent=4)
        pp.pprint(udas_new_map)
        if prompt_confirm():
            update_task(task, **udas_new_map)
        else:
            logging.info("Did not continue updating task.")


def update_task(task, **kwargs):
    for k, v in kwargs.items():
        task[k] = v

    review_day = timedelta(days=random.randint(7,28))
    date = datetime.now() + review_day
    task["review"] = format_datetime_iso(date)
    task.save()

    if task.saved:
        logging.info(task["id"])
    else:
        logging.info("Task has not been updated.")

def prompt_value(string="", validator=None, default="", exit_if_empty=False):
    try:
        user_input = prompt("{}> ".format(string),
                history=history,
                validator=validator,
                default=default,
                on_abort=AbortAction.RETRY,
                erase_when_done=True,
                auto_suggest=AutoSuggestFromHistory())
    except InputError:
        user_input = "?"
    except (KeyboardInterrupt, EOFError):
        print("bye")
        sys.exit(0)
    if not user_input and exit_if_empty:
        logging.error("No input. Exiting now.")
        sys.exit(1)
    return user_input

def review_required(task):
    now = datetime.now().date() 
    day28old = now - timedelta(days=28)

    modified = task["modified"]
    review = task["review"]

    review_task = False

    if modified:
        modified = modified.date()
        review_task = review_task or day28old > modified

    if review:
        try:
            review = datetime.strptime(review, "%Y%m%dT%H%M%S.%f").date()
        except ValueError:
            logging.error("Could not parse review date of task with id {}".format(task["id"]))
            sys.exit(1)

        review_task = review_task or now > review
    else:
        return True

    return review_task

def format_datetime_iso(date):
    """
    return iso string
    """
    return date.isoformat().replace("-","").replace(":","")

class SelectMenuValidator(Validator):
    def __init__(self, uda, defaults):
        self.uda = uda
        self.defaults = defaults

    def validate(self, document):
        text = document.text

        if text == "":
            raise InputError("Input is empty")
        elif text not in self.defaults:
            raise ValidationError(message="Choice is not a valid uda.")

class InputError(Exception):
    pass

def canonize_uda(uda):
    uda, defaults = uda
    # uda.name.default
    uda = uda.split(".")[1]
    # 0,1,2,3,...
    defaults = defaults.split(",")

    return uda,defaults

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


def create_interactive_menu(uda, values):
    output = "{:#^40}".format(" {} ".format(uda))
    output += "\nSelect from defaults: \n\t{}".format(values)
    return output

if __name__ == "__main__":
    main()
