#!/bin/bash
#change extension name of files
oldext=$1
newext=$2
extension=""
rawfile=""

function scriptinfo
{
	echo -e "\nUsage of $0"
	echo "$0 arg1 arg2"
	echo "arg1: oldextension to select from"
	echo "arg2: newextension to select from"
	exit 1

}

if [ -z "$oldext" ];then
	echo "no oldextension specified for arg1"
	scriptinfo
fi
if [ -z "$newext" ];then
	echo "no newextension specified for arg2"
	scriptinfo
fi
list=$(ls -1)

#strip of .
oldext=${oldext##*.}
newext=${newext##*.}


for file in $list
do
	extension=${file##*.}
	if [ $oldext = "0" ]
	then
		mv $file "$file.$newext"
		continue
	fi
	if [ $oldext = $extension ]
	then
		rawfile=${file%.*}.$newext
		mv $file $rawfile
	fi
done
