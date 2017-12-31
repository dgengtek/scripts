#!/bin/env bash
exec 2>&1
exec 1>/dev/null
run.sh firefox
#run.sh keepassx 
run.sh -q urxvtc -e 'tmuxp load ~/.tmuxp/wiki.yaml'
run.sh -q urxvtc -e 'tmux new -s mutt'
run.sh -q urxvtc -e 'tmuxp load ~/.tmuxp/irc.yaml'
