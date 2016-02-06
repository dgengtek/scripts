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


cd /mnt/hdd/bigX/a_Programmieren/Python/workspace || exit


run pycharm
run hamster

#start tmux and configure windows and panes
(eval "urxvt -e tmux source /home/gd/bin/bash/tmux.python_dev.sh") &
