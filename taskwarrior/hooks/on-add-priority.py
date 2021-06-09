#!/bin/env python3
from tasklib import Task

def main():
    task = Task.from_input()
    task["priority"] = task["priority"].lower()
    print(task.export_data())

if __name__ == "__main__":
    main()
