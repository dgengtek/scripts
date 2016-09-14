#!/bin/env bash
#change extension of files

oldext=$1
newext=$2
extension=""
rawfile=""

usage () {
  cat >&2 << EOF
Usage:  ${0##*/} {OLDEXTENSION|*} NEWEXTENSION
EOF
}

if [ -z "$oldext" ] \
  || [ -z "$newext" ];then
  usage
  exit 1
fi
# use newline as seperator

# get suffixes
oldext=${oldext##*.}
newext=${newext##*.}

if [[ $oldext != "*" ]];  then
  # grab with find
  oldext="*.$oldext"
fi

IFS=
while read -r -d $'\0' file; do
  raw=${file%.*}
  mv "$file" "${raw}.${newext}"
done < <(find . -maxdepth 1 -type f -name "$oldext" -print0)
IFS=$OLDIFS
