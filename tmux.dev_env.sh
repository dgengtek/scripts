#!/bin/bash

new-session -s devEnv -n vimMAIN vim
split-window -h vim
select-pane -t 0
new-window -n compiling 
split-window -h 
select-pane -t 0
select-window -t vimMAIN
