#!/bin/bash
#change extension name of files
oldext=$1
newext=$2
extension=""
rawfile=""

function scriptinfo
{
	echo -e "\nUsage of $0"
	echo "$0 {OLDEXTENSION|'*'} NEWEXTENSION"
	echo "star must be escaped or supplied with quotes to use all files"
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
	if [ "$oldext" = "*" ];then
	    mv "$file" "${file}.${newext}"
	elif [ "$oldext" = "$extension" ];then
	    rawfile=${file%.*}.$newext
	    mv "$file" "$rawfile"
	fi
done
