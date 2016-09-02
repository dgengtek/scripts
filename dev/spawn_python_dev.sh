#!/bin/bash

#start development Environment
sessionName="python_dev"
winName="win"

#create session,tabs and change to directory
if tmux has-session -t $sessionName
then
  echo "session already exists"
  exit 1
fi


cd /mnt/hdd/bigX/programming/Python/workspace || exit


run pycharm
run hamster

#start tmux and configure windows and panes
run urxvt -e tmux source /home/gd/bin/bash/tmux.python_dev.sh
