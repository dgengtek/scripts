#!/bin/env bash
exec 2>&1
exec 1>/dev/null
run.sh firefox
run.sh keepassx 
run.sh urxvtc -e tmux new ssh-agent sshsession.py
run.sh urxvtc -e bash --init-file <(cat ~/.bashrc;echo "tmuxp_start wiki.yaml")
