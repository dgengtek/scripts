#!/bin/python
import os
directory = os.listdir()
illegal_characters = "%?_'*+$!\""
tolowercase=True

for a in range(len(directory)):
    newname=""
    for c in directory[a]:
        if c in illegal_characters:
            continue
        if c.isalnum() or c == '.':
            newname=newname+c.lower()
    print("convert {} to {}".format(directory[a],newname))
    os.rename(directory[a], newname)

