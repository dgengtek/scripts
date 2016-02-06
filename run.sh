#!/bin/bash
if [ -z "$1" ]
then
	echo "no arguments to start a command in background"
	exit 1
fi

cmd=("$@")
cmdstring=$(echo "$cmd" | cut -f1 -d ' ')

logfile="/dev/null"

("${cmd[@]}" &> $logfile) &
cmd_pid=$!
