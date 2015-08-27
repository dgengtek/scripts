#!/bin/bash
# need to change scriptinfo and use select for option
# catch INT TERM with trap and cleanup code
# tarAll.sh
# add options for compression flags
# z gz
# j bz2
# J xz


fileext=$1
# name of tar file
name=$2
extension=""
#should it only run on files with extension?
declare -i extOption=1


function scriptinfo
{
	echo -e "\nUsage of $0"
	echo "$0 arg1 arg2"
	echo "arg1: filextension to select"
	echo "arg2: name of tar"
	exit 1

}
if [ -z $name ]; then
  "no name for tar file"
  scriptinfo
fi

if [ -z $fileext ];then
	echo "no file extension specified, argument 1"
	read -p "Proceed on all files? yn:" yn
	if [ $yn = "n" ]
	then
		scriptinfo
	else
		let extOption=0	
	fi
fi


OLDIFS=$IFS
IFS=$(echo -en "\n\b")

files=()

for file in $(ls -1)
do
  extension=${file##*.}
  rawFilename=${file%.*}
  if (( $extOption == 1)) && 
   [ $extension != $fileext ];then
   continue
  fi
  files+=($file)
done
IFS=$OLDIFS

function sigINT {
  echo -en "\n\ncatched SIGINT\n"
  echo "cleanup...rm $tarDir/$name.tar.gz"

  rm "$tarDir/$name.tar.gz"
  exit 1
}

trap sigINT INT

if [ -e $tarDir/$name.tar.gz ]; then
  tar -zvc $files > "$tarDir/$name.tar.gz"
  exit $?
else
  echo "File at: $tarDir/$name.tar.gz"
  exit 1
fi

