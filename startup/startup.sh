#!/bin/env bash
exec 2>1
exec 1>/dev/null
firefox &
keepassx &
urxvt -e bash --init-file <(cat ~/.bashrc;echo "tmuxp load wiki.yaml") &
