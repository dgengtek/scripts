#!/bin/bash
# need to change scriptinfo and use select for option
# catch INT TERM with trap and cleanup code


fileext=$1
extension=""
#should it only run on files with extension?
declare -i extOption=1
gzDir="gz"
rawFilename=""
file=""

function sigINT {
  echo -en "\n\ncatched SIGINT\n"
  echo "cleanup...rm $gzDir/$rawFilename.gz"
  rm "$gzDir/$file.gz"
  exit 1
}
trap sigINT INT

function scriptinfo
{
	echo -e "\nUsage of $0"
	echo "$0 arg1"
	echo "arg1: filextension to select"
	exit 1

}

if [ -z "$fileext" ];then
	echo "no file extension specified, argument 1"
	read -rp "Proceed on all files? yn:" yn
	if [ "$yn" = "n" ]
	then
		scriptinfo
	else
		let extOption=0	
	fi
fi

if ! [ -d $gzDir ]
then
	mkdir $gzDir
fi

OLDIFS=$IFS
IFS=$(echo -en "\n\b")

for file in $(ls -1)
do
  extension=${file##*.}
  if ((extOption == 1)) && 
   [ "$extension" != "$fileext" ];then
   continue
  fi

  if ! [ -e "${gzDir}/${file}.gz" ]; then
    gzip -vc "$file" > "${gzDir}/${file}.gz"
  else
    echo "File: ${file}.gz, already exists"
  fi
done
IFS=$OLDIFS
