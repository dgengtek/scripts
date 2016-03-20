#!/bin/bash
# TODO: add option to set log filename and log path
#	duplicate script of run, move all logic to run
#run with output logging

if [ -z "$1" ]; then
	echo "no arguments to start a command in background"
	exit 1
fi
log_path="/tmp/log"
cmd=("$@")
cmdstring=$(echo "${cmd[@]}" | cut -f1 -d ' ')
logfile="run_${cmdstring}_log"
logfn="empty"


checklogfile() {
	declare -i zaehler=0
	logfn=${logfile}
	while [ -e "$logfn" ]
	do
		logfn=${logfile}${zaehler}
		let zaehler+=1
	done
	return 0 

}

if ! [ -e $log_path ];then
  mkdir -p $log_path
fi

checklogfile
logfile=$logfn
echo -e "Saving output to $logfile"

$("${cmd[@]}" &> "$log_path/$logfile") &
cmd_pid=$!
echo -e "PID - $cmd_pid \nrunning in background..."
