#!/bin/bash
# execute specific command on a specific extension

fileext=$1
cmd=$2
extension=""

function scriptinfo
{
	echo -e "\nUsage of $0"
	echo "$0 arg1 arg2"
	echo "arg1: filextension to select"
	echo "arg2: command to use on 
	fileextension"
	exit 1

}

if [ -z $fileext ];then
	echo "no file extension specified, argument 1"
	scriptinfo
fi
if [ -z $cmd ];then
	echo "no command specified, to use on files 
	with extension $fileext"
	scriptinfo
fi	


OLDIFS=$IFS
IFS=$(echo -en "\n\b")

for file in $(ls -1)
do
	extension=${file##*.}
	if [ $extension = $fileext ];then
		$cmd $file
	fi
done
IFS=$OLDIFS
