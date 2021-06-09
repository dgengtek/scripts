#!/usr/bin/env python3

from tasklib import Task
import os
import time

def main():
    task = Task.from_input(modify=True)
    print(task.export_data())
    old = task.original
    new = task

    tags = []
    if new["project"]:
        tags.append(new["project"])
    if new["tags"]:
        tags.extend(new["tags"])
    tags = " ".join(tags)

    suffix = "{} :yes :adjust".format(tags)
    cmd = ""
    if new.active and not "start" in old:
        cmd = "timew start {}".format(suffix)
    else:
        cmd = "timew stop {}".format(suffix)
    os.system(cmd)

if __name__ == "__main__":
    main()
