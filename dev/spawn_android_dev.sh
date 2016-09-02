#!/bin/bash

#start development Environment
sessionName="android_dev"
winName="win"

#create session,tabs and change to directory
if tmux has-session -t $sessionName; then
  echo "session already exists"
  exit 1
fi

cd /mnt/hdd/bigX/a_Programmieren/android/workspace || exit

run.sh android-studio

#start tmux and configure windows and panes
run.sh urxvt -e tmux source ~/tmux/tmux_dev_env.sh
run.sh urxvt -e tmux source ~/tmux/tmux_timer.sh
