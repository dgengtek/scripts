#!/bin/env bash
# start a session for ssh-agent inside a new shell
#lib=$(type select_ssh_id.py | cut -f 3 -d " ")
lib="select_ssh_id.py"
if ! hash $lib; then
  echo "lib not found"
  exit 1
fi
echo $lib
$lib && bash -i
