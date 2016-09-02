#!/bin/bash

#start development Environment
sessionName="java_dev"
winName="win"

#create session,tabs and change to directory
if tmux has-session -t $sessionName; then
  echo "session already exists"
  exit 1
fi

cd /mnt/hdd/bigX/programming/JAVA/workspace || exit

run.sh idea
run.sh hamster

#start tmux and configure windows and panes
run.sh urxvt -e tmux source ~/tmux/tmux.java_dev.sh
