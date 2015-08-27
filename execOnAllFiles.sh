#!/bin/bash
# execute specific command on a specific extension

cmd=$1
dest=$2
extension=""

function scriptinfo
{
	echo -e "\nUsage of $0"
	echo "$0 arg1 arg2"
	echo "arg1: command to use on
	with loop"
	echo "arg2: dest"
	exit 1

}

if [ -z $cmd ];then
	echo "no command specified"
	scriptinfo
fi	


OLDIFS=$IFS
IFS=$(echo -en "\n\b")
for file in $(ls -1 $dest)
do
	$cmd $file
done
IFS=$OLDIFS
