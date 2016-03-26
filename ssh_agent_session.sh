#!/bin/bash
# start a session for ssh-agent inside a new shell
session_file=~/bin/python/select_ssh_id.py

if ! [ -e $session_file ]; then
  exit 1

fi
python $session_file && bash -i
