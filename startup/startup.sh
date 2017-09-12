#!/bin/env bash
exec 2>&1
exec 1>/dev/null
run.sh firefox
#run.sh keepassx 
tmux new -d -s "mutt" mutt
run.sh -q urxvtc -e 'tmuxp load ~/.tmuxp/wiki.yaml'
