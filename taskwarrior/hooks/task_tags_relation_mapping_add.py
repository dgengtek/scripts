#!/bin/env python3
import task_utilities as tasku
from tasklib import Task
def main():
    task = Task.from_input()
    task = tasku.canonize_task(task)
    print(task.export_data())

if __name__ == "__main__":
    main()
