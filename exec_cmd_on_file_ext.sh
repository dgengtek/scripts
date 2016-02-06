#!/bin/bash
# execute specific command on a specific extension

fileext=$1
shift
cmd=("$@")
extension=""

function scriptinfo
{
	echo "$0 fileextension commandstring"
	echo "fileextension: filter files by extension to use command on"
	echo "commandstring: command with possible options,
	command has to able to use file inputs"
	exit 1

}

if [ -z "$fileext" ];then
	echo "no file extension specified, argument 1"
	scriptinfo
fi
if [ -z "$cmd" ];then
	echo "no command specified, to use on files 
	with extension $fileext"
	scriptinfo
fi	


OLDIFS=$IFS
IFS=$(echo -en "\n\b")

for file in $(ls -1)
do
	extension=${file##*.}
	if [ "$extension" = "$fileext" ];then
		eval "${cmd[@]}" "$file"
	fi
done
IFS=$OLDIFS
