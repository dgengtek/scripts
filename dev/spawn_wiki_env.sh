#!/bin/bash

#start development Environment
sessionName="wikiEnv"
winName="win"

#create session,tabs and change to directory
if tmux has-session -t $sessionName; then
  echo "session already exists"
  exit 1
fi


cd /mnt/hdd/bigX/e-books/IT || exit
#set seperator to newlinebreaks for strings in ls-1
OLDIFS=$IFS
IFS=$(echo -en "\n\b")
PS3='select ebooks to work with...'
select selection in $(ls -1)
do
  if [ -n "$selection" ]
  then	
    #need to traverse through a next selection and open ebooks too
    cd "$selection" || exit
    break
  else
    echo "invalid selection"
  fi
done
IFS=$OLDIFS

#start tmux and configure windows and panes
tmux source ~/tmux/tmux_wiki_env.sh
