#!/bin/env bash
exec 2>&1
exec 1>/dev/null
run.sh firefox
run.sh keepassx 
run.sh urxvtc -e 'bash --init-file <(cat ~/.bashrc;echo "tmuxp load ~/.tmuxp/wiki.yaml")'
