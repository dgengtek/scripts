#!/bin/bash

#start development Environment
session_name="python"
session_fs="fs"
session_countdown="countdown"

#create session,tabs and change to directory
if tmux has-session -t $session_name ||
  tmux has-session -t $session_countdown ||
  tmux has-session -t $session_fs; then
exit 1
fi

run pycharm
run hamster
run firefox


#start tmux and configure windows and panes
cd ~ || exit
run urxvt -e tmux new-session -s $session_fs ranger 
run urxvt -e tmux new-session -s $session_countdown 
tmux new-window -t $session_countdown vimwiki

cd /mnt/hdd/bigX/programming/Python/workspace || exit
run urxvt -e tmux new-session -s $session_name ranger 
tmux new-window -t $session_name -n py python
