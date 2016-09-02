#!/bin/env bash
# deprecated, use command basename
#change extension name of files

oldext=$1
newext=$2
extension=""
rawfile=""

scriptinfo() {
  echo -e "\nUsage of $0"
  echo "$0 {OLDEXTENSION|'*'} NEWEXTENSION"
  echo "star must be escaped or supplied with quotes to use all files"
  exit 1

}

if [ -z "$oldext" ] \
  || [ -z "$newext" ];then
  usage
fi
# use newline as seperator
OLDIFS=$IFS
IFS=$(echo -en "\n\b")
list=$(ls -1)
IFS=$OLDIFS

# get suffixes
oldext=${oldext##*.}
newext=${newext##*.}

for file in $list; do
  extension=${file##*.}
  if [ "$oldext" = "*" ];then
    mv "$file" "${file}.${newext}"
  elif [ "$oldext" = "$extension" ];then
    rawfile=${file%.*}.$newext
    mv "$file" "$rawfile"
  fi
done
