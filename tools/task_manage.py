#!/bin/env python3
"""
Manage tasks interactively

Usage:
    task_manage.py add
    task_manage.py note <subcommand> [<filter>]
    task_manage.py search [-t|-p]
    task_manage.py dep [-r] [<id>]
    task_manage.py review [<filter>]
    task_manage.py review [-a | -n <count>]

Options:
    -h, --help  Show this screen and exit.

Commands overview:
    add             Add new task
    search          Fuzzy search for task(+annotations) and retrieve id
    review          Review tasks, by default will review the top 20 tasks
    dep             Add dependencies to supplied id. Blocking it until selected
                        tasks are done
    note            Add a note to a task

Note subcommands:
    add|edit        Create and edit note with $EDITOR
    rm              Remove a note
    cat             Display to stdout
    ls              Show path to note
    cleanup         Cleanup notes in notes directory if task has been deleted

dep:
    -r, --reverse  Reverse dependency. Supplied task id will be parent of all
                    selected tasks
search:
    -p, --projects  Search for projects
    -t, --tags  Search for tags

review:
    -n <count>, --number <count>  Number of top tasks to review[default: 20]
    -a, --all  Review all tasks which are flagged for review

"""

from docopt import docopt
from tasklib import TaskWarrior,Task
from prompt_toolkit.validation import Validator, ValidationError
from prompt_toolkit import prompt
from prompt_toolkit.history import InMemoryHistory
from prompt_toolkit.auto_suggest import AutoSuggestFromHistory
from prompt_toolkit.interface import AbortAction
from iterfzf import iterfzf
from functools import partial
import pprint
from datetime import datetime,timedelta
import random
import logging
from itertools import tee
import re
from pathlib import Path
import sys, tempfile, os
from subprocess import call

EDITOR = os.environ.get('EDITOR','vim')


logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

# docopt(doc, argv=None, help=True, version=None, options_first=False))
# TODO generate singleton for taskwarrior global

history = InMemoryHistory()

valid_search_attributes = ["project", "tag"]
tw = None

uda_values_filter = [
        "label",
        "type",
        "values",
        "default",
        "description",
        ]

__notes_dir = Path("~/.task/notes/").expanduser()


def main():
    opt = docopt(__doc__, sys.argv[1:])
    
    command = generate_command(opt,  **opt)
    if not command:
        logger.info("Command not legal.")
        sys.exit(1)

    command()


def generate_command(opts, *args, **kwargs):
    global tw
    tw = TaskWarrior()

    def generate_review():
        task_filter = kwargs.get("<filter>", "")
        review_all = kwargs.get("--all")
        top_count = kwargs.get("--number")

        if review_all:
            review_task("")
        elif task_filter:
            review_task(task_filter, force=True)
        else:
            for task_id in get_top_tasks(top_count):
                review_task(task_id, force=True)

    def generate_dependency():
        task_filter = kwargs.get("<id>", "")
        reverse_dependency = kwargs.get("--reverse")
        add_dependencies(task_filter, reverse_dependency)

    def generate_search():
        tasks = tw.tasks.pending()

        if kwargs.get("--projects"):
            search_attribute(tasks, "project")
        elif kwargs.get("--tags"):
            search_attribute(tasks, "tag")
        else:
            search_task(tasks)

    def generate_note():
        task_filter = kwargs.get("<filter>", "")
        subcommand = kwargs.get("<subcommand>")
        if subcommand == "cleanup":
            cleanup_notes()
        else:
            command_note(task_filter, subcommand)


    commands = {
            "add": add_task,
            "review": generate_review,
            "dep": generate_dependency,
            "search": generate_search,
            "note": generate_note,
            }

    command = ""
    for cmd in commands.keys():
        if opts.get(cmd):
            command = cmd

    return commands.get(command, "")

def get_top_tasks(count):
    import subprocess
    cmd = ["task", "limit:{}".format(count), "top"]
    p = subprocess.Popen(cmd, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
    valid_pattern = "^([0-9]+$)"
    for line in p.stdout:
        s = canonize_string(str(line,"UTF-8"))
        if string_match(valid_pattern, s):
            yield s


def search_task(tasks):
    tasks_mapping = ( to_string_task_simple(x, annotations=True) for x in tasks )
    task = iterfzf(tasks_mapping)
    if not task:
        return
    task_id = task.split()[0]
    task = tasks.get(id=task_id)
    print(to_string_task_full(task))
    return task

def select_tasks(tasks):
    available_tasks = ( to_string_task_simple(x, annotations=True) for x in tasks )
    while True:
        available_tasks, taskgencopy = tee(available_tasks)
        taskgencopy = ( to_string_task_simple(x) for x in taskgencopy )
        task = iterfzf(taskgencopy)
        if task:
            yield task 
        else:
            return
        available_tasks = filter_task(task, available_tasks)

def search_attribute(tasks, attribute):
    """
    search for specific attribute - either
        'tag'
        'project'
    """
    global valid_search_attributes
    if attribute not in valid_search_attributes:
        logger.info("Supplied attribute {} is not valid(or implemented) for search".format(attribute))
        sys.exit(1)

    import subprocess
    cmd = [ "task", "{}s".format(attribute) ]
    process = subprocess.Popen(cmd, stdout=subprocess.PIPE,
            stderr=subprocess.PIPE)

    items = []
    invalid_pattern = "^([0-9- ()]|Project|Tag)"
    for line in process.stdout:
        line = str(line.strip(), "utf-8")
        if string_match(invalid_pattern, line) or line == "":
            continue
        items.append(line)
    items = iterfzf(items, multi=True)
    items = [ item.strip().split()[0] for item in items ]

    if attribute == "project":
        filter_string = [ "project:{}".format(x) for x in items ]
    elif attribute == "tag":
        filter_string = [ "+{}".format(x) for x in items ]

    if len(items) > 1:
        tasks = tasks.filter(" or ".join(filter_string))
    else:
        tasks = tasks.filter("".join(filter_string))

    for task in tasks:
        print(to_string_task_simple(task))



def string_match(pattern, string):
    match = re.match(pattern, string)
    if match:
        return True
    else:
        return False


def add_dependencies(child_task, reverse_dependency=False, status="pending"):
    """
    add dependencies to a parent task
    """
    from copy import deepcopy

    global tw
    tasks = tw.tasks.pending()

    if not child_task:
        child_task = search_task(tasks)
    else:
        try:
            child_task = tasks.get(id=child_task)
        except Task.DoesNotExist as e:
            logger.error("Could not find parent task to apply dependencies for.", exc_info=True)
            sys.exit(1)

    if not child_task:
        logger.error("Task not valid. Abort.")
        sys.exit(1)

    available_tasks = filter_task(child_task, tasks)

    dependencies = []
    while True:
        available_tasks, taskgencopy = tee(available_tasks)
        taskgencopy = ( to_string_task_simple(x) for x in taskgencopy )
        parent_dependency = iterfzf(taskgencopy)
        if not parent_dependency:
            break
        try:
            parent_dependency = parent_dependency.split()[0]
            parent_dependency = tasks.get(id=parent_dependency)
        except Task.DoesNotExist as e:
            logger.error(e)
            logger.error("Task with id {} could not be found.".format(parent_dependency))

        dependencies.append(parent_dependency)
        available_tasks = filter_task(parent_dependency, available_tasks)

    task_dependencies = child_task["depends"]
    for dependency in dependencies:
        # add dependency to child - blocking it until dependency is done
        if not reverse_dependency:
            task_dependencies.add(dependency)
        # add dependency to selected task blocking them until 'child_task'(the
        #   parent now) is done
        else:
            dependency["depends"].add(child_task)
            dependency.save()

    child_task["depends"] = task_dependencies
    child_task.save()


def filter_task(task, tasks):
    for t in tasks:
        if t["id"] == task["id"]:
            continue
        yield t


def to_string_task_simple(task, annotations=False):
    description = canonize_string(task["description"])
    if annotations:
        description += " - {}".format(task["annotations"])
    task_id = task["id"]
    return "{}  {}".format(task_id, description)

def to_string_task_full(task):
    output = "[{}]  {}".format(task["id"], task["description"])
    projects = task["projects"]
    output += "\nProjects: "
    if projects:
        output += "{}".format(", ".join(projects))
    else:
        output += "{}".format(projects)

    tags = task["tags"]
    output += "\nTags: "
    if tags:
        output += "{}".format(", ".join(tags))
    else:
        output += "{}".format(tags)

    output += "\nDependencies: {}".format(task["depends"])

    annotations = task["annotations"]
    output += "\nAnnotations: "
    if tags:
        for ann in annotations:
            output += "\n - {}".format(ann)
    else:
        output += "{}".format(annotations)

    return output


def canonize_string(string):
    return string.strip().replace("\n"," ")

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
    
    global uda_values_filter
    config_udas = parse_udas(config, uda_values_filter)
    config_udas, udas = tee(config_udas)
    for uda in udas:
        uda, values = uda
        menu = create_interactive_menu(uda, values)
        validator = SelectMenuValidator(uda, values)
        default = values.get("default")

        while True:
            print(menu)
            value = prompt_value(validator=validator, default=default)
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
            logger.info("Task has not been saved.")
    else:
        logger.info("Did not add task.")

def prompt_items(string):
    while True:
        tag = prompt_value(string)
        if not tag:
            break
        yield tag

def command_note(task_filter, subcommand, status="pending"):
    global tw
    if task_filter:
        pending_tasks = tw.tasks.filter(task_filter, status=status)
    else:
        pending_tasks = tw.tasks.pending()
        pending_tasks = select_tasks(pending_tasks)

    def build_command(command):
        global __notes_dir
        notes_dir = __notes_dir

        add = partial(create_note, notes_dir=notes_dir)
        rm = partial(rm_note, notes_dir=notes_dir)
        def display(task):
            print("{} | {}".format(task["id"], task["uuid"]))
            display_note(task, notes_dir)
        def ls(task):
            note_path = get_note_path(task, notes_dir)
            if not note_path.exists():
                return

            print("{} | {}".format(task["id"], note_path))

        commands = {
                "add": add,
                "edit": add,
                "rm": rm,
                "cat": display,
                "ls": ls,
                }
        return commands.get(subcommand, "")

    cmd = build_command(subcommand)
    if not cmd:
        raise NotImplementedError("Subcommand is not available.")
    for task in pending_tasks:
        cmd(task)
    


def create_note(task, notes_dir):
    def create_note_dir(note_dir):
        note_dir = Path(note_dir).expanduser()
        if not note_dir.exists():
            note_dir.mkdir(parents=True)
            logger.info("Created notes directory at {}".format(note_dir))
        return note_dir

    notes_dir = create_note_dir(notes_dir)
    add_note(task, notes_dir)

def add_note(task, notes_dir):
    task_note = get_note_path(task, notes_dir)
    message = """ 
Add some notes for this task
{}
""".format(task)
    content = ""
    is_empty = os.stat(task_note).st_size == 0
    with task_note.open(mode="a") as tmpfile:
        if is_empty:
            tmpfile.write(message)
            tmpfile.flush()
        # TODO check if changed
        call([EDITOR, tmpfile.name])
        task["note"] = "y"
        task.save()

def rm_note(task, notes_dir):
    task_note = get_note_path(task, notes_dir)
    if task_note.exists():
        os.remove(task_note)
        task["note"] = "n"
        task.save()
        logger.info("Removed note for task: {}".format(task))

def get_note_path(task, notes_dir):
    uuid = task["uuid"]
    task_note = notes_dir.joinpath(uuid)
    return task_note

def display_note(task, notes_dir):
    task_note = get_note_path(task, notes_dir)

    if not task_note.exists():
        logger.info("Task note does not exist.")
        return
    with task_note.open() as f:
        for line in f:
            print(line,end="")

def cleanup_notes(notes_dir):
    global tw
    for uuid in os.listdir(notes_dir):
        task = tw.tasks.get(uuid=uuid)
        if not task.deleted:
            continue
        os.remove(notes_dir.joinpath(uuid))


def review_task(taskfilter, status="pending", force=False):
    global tw
    config = tw.config.items()
    global uda_values_filter
    config_udas = parse_udas(config, uda_values_filter)

    if taskfilter:
        pending_tasks = tw.tasks.filter(taskfilter, status=status)
    else:
        pending_tasks = tw.tasks.pending()

    if not pending_tasks:
        logger.info("No tasks found with status '{}'.".format(status))
        sys.exit(2)

    for task in pending_tasks:
        if not (force or review_required(task)):
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
            uda, values = uda
            menu = create_interactive_menu(uda, values)
            validator = SelectMenuValidator(uda, values)

            while True:
                print(menu)
                default = values.get("default")
                value = prompt_value(validator=validator,
                    default=default)
                if value:
                    break
            udas_new_map.update({uda: value})

        print("The new task:")
        pp = pprint.PrettyPrinter(indent=4)
        pp.pprint(udas_new_map)
        if prompt_confirm():
            update_task(task, **udas_new_map)
        else:
            logger.info("Did not continue updating task.")


def update_task(task, **kwargs):
    for k, v in kwargs.items():
        task[k] = v

    review_day = timedelta(days=random.randint(21,28))
    date = datetime.now() + review_day
    task["review"] = format_datetime_iso(date)
    task.save()

    if task.saved:
        logger.info("Updated task: {}".format(task["id"]))
    else:
        logger.info("Task has not been updated.")

def prompt_value(string="", validator=None, default="", exit_if_empty=False):
    if not default:
        default = ""
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
        logger.error("No input. Exiting now.")
        sys.exit(1)
    return user_input

def review_required(task):
    now = datetime.now().date() 
    day90old = now - timedelta(days=90)

    modified = task["modified"]
    review = task["review"]

    review_task = False

    if not review:
        return True


    if modified:
        modified = modified.date()
        review_task = day90old > modified

    if review_task:
        try:
            review = datetime.strptime(review, "%Y%m%dT%H%M%S.%f").date()
        except ValueError:
            logger.error("Could not parse review date of task with id {}".format(task["id"]))
            sys.exit(1)

        review_task = now > review

    return review_task

def format_datetime_iso(date):
    """
    return iso string
    """
    return date.isoformat().replace("-","").replace(":","")

class SelectMenuValidator(Validator):
    def __init__(self, uda, values):
        self.uda = uda
        self.values = values.get("values")

    def validate(self, document):
        text = document.text

        if text == "" or not text:
            raise InputError("Input is empty")
        elif text not in self.values:
            raise ValidationError(message="Choice is not a valid uda.")

class InputError(Exception):
    pass

def parse_udas(config, values_filter):
    """
    Get uda default values from strings filter
    """
    filters = []
    uda_filter = build_filter(["^uda."])
    values_filter = build_filter(values_filter)

    filters.append(uda_filter)
    filters.append(values_filter)

    def get_uda(key):
        return key.split(".")[1]

    def get_option(key):
        return key.split(".")[2]

    def update_uda(uda, values, orig_config):
        new_values = orig_config.get(uda, "")
        if not new_values:
            new_values = dict()
        new_values.update(values)
        orig_config.update({uda: new_values})

    new_config = dict()
    for item in config:
        is_valid = (f(item) for f in filters)
        is_valid = all(is_valid)
        if not is_valid:
            continue
        k, v = item
        uda = get_uda(k)
        option = get_option(k)
        values = {option:v}
        update_uda(uda, values, new_config)
    return sorted(new_config.items())

def build_filter(patterns, negate=False):
    """
    Build a filter from a list of strings
    """
    import re
    def filter_search(item):
        k,v = item
        for pattern in patterns:
            pattern = re.compile(pattern)
            match = re.search(pattern, k)
            if bool(match) ^ bool(negate):
                return True
        return False
    return filter_search

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
    user_input = user_input.lower().strip()
    if user_input in ["y","yes","ye","j","ja"]:
        return True
    elif user_input in ["n","no","nein"]:
        return False
    else:
        # repeat if invalid
        return prompt_confirm(string)


def create_interactive_menu(uda, values):
    output = "{:#^40}".format(" {} ".format(uda))
    output += "\n{}".format(values.get("description", ""))
    output += "\nSelect from: \t{}".format(values.get("values"))
    return output

################################################################################
import pytest

@pytest.fixture(scope="module")
def config_sample():
    return {
            "uda.test.label":"Test",
            "uda.test.type":"string",
            "uda.test.values":"t,n,y,?",
            "uda.test.default":"t",
            "uda.test.description":"Description of test",
            "uda.test2.label":"Test2",
            "uda.test2.type":"string",
            "uda.test2.values":"t2,n2,y2,?2",
            "uda.test2.default":"t2",
            "uda.test2.description":"Description of test2",
            "urgency.uda.test.t":"0",
            "urgency.uda.test.y":"2",
            "urgency.uda.test.n":"1",
            "urgency.uda.test.?":"0",
            "color.uda.test.h":"color255",
            "color.uda.test.l":"color245",
            "color.uda.test.m":"color250",
            }

@pytest.fixture(scope="module")
def config_sample_expected():
    return {
            "uda.test.label":"Test",
            "uda.test.type":"string",
            "uda.test.values":"t,n,y,?",
            "uda.test.default":"t",
            "uda.test.description":"Description of test",
            "uda.test2.label":"Test2",
            "uda.test2.type":"string",
            "uda.test2.values":"t2,n2,y2,?2",
            "uda.test2.default":"t2",
            "uda.test2.description":"Description of test2",
            }

@pytest.fixture(scope="module")
def filter_sample(): 
    return [
            "label",
            "type",
            "values",
            "default",
            "description",
            ]

def test_config_filter(config_sample, config_sample_expected, filter_sample):
    std_filter = build_filter(filter_sample)
    config = filter(std_filter, config_sample.items())
    assert dict(config) == config_sample_expected

def test_uda_parsing(config_sample, filter_sample):
    config = parse_udas(config_sample.items(), filter_sample)
    config = dict(config)
    assert "test" in config and "test2" in config


if __name__ == "__main__":
    main()
