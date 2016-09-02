#!/bin/bash

#start development Environment
sessionName="devEnv"
winName="win"

#create session,tabs and change to directory
if tmux has-session -t $sessionName
then
	echo "session already exists"
	exit 1
fi


cd /mnt/hdd/bigX/a_Programmieren || exit

OLDIFS=$IFS
IFS=$(echo -en "\n\b")
PS3='select development environment to work in...'
select selection in $(ls -1)
do
	if [ -n "$selection" ]
	then	
		cd "$selection" || exit
		if [ -d workspace ] 
		then
			cd workspace || exit
		else
			echo "no workspace dir"
		fi
		break
	else
		echo "invalid selection"
	fi
done
IFS=$OLDIFS

#start tmux and configure windows and panes
tmux source /home/gd/bin/bash/tmux.devEnv.sh
