#!/bin/bash
if [ -z $1 || -z $2 ];then
  echo "arguments empty"
  echo "\$1 - name of label"
  echo "\$2 - path directory to burn to disc"
  exit 1;
fi
if ! [ -d $2 ]; then
  echo "supplied path is not a directory"
  exit 1;
fi

label=$1
burnpath=$2
genisoimage -V "$1" -J -r $2 | \
    wodim -v dev=/dev/sr0 -waiti -
