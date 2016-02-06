#!/bin/bash
#run with output logging
if [ -z "$1" ]
then
	echo "no arguments to start a command in background"
	exit 1
fi

cmd=("$@")
cmdstring=$(echo "${cmd[@]}" | cut -f1 -d ' ')
logfile="run_${cmdstring}_log"
logfn="empty"


function checklogfile {
	declare -i zaehler=0
	logfn=${logfile}
	while [ -e "$logfn" ]
	do
		logfn=${logfile}${zaehler}
		let zaehler+=1
	done
	return 0 

}


checklogfile
logfile=$logfn
echo -e "Saving output to $logfile"

("${cmd[@]}" &> "$logfile") &
cmd_pid=$!
echo -e "PID - $cmd_pid \nrunning in background..."
