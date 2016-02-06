#!/bin/bash

#start development Environment
sessionName="android_dev"
winName="win"

#create session,tabs and change to directory
if tmux has-session -t $sessionName
then
	echo "session already exists"
	exit 1
fi


cd /mnt/hdd/bigX/a_Programmieren/android/workspace || exit


run android-studio

#start tmux and configure windows and panes
(eval "urxvt -e tmux source /home/gd/bin/bash/tmux_dev_env.sh") &
(eval "urxvt -e tmux source /home/gd/bin/bash/tmux_timer.sh") &
