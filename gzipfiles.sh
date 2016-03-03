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

sigINT() {
  echo -en "\n\nSIGINT\n"
  echo "cleanup...rm $gzDir/$rawFilename.gz"
  rm "$gzDir/$file.gz"
  exit 1
}
trap sigINT SIGINT SIGTERM 

scriptinfo() {
	echo "usage: $0 fileextension"
	echo "filextension to select from files to gzip"
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
