#!/bin/bash
if [ -z $1 ];then
  echo "no command given for integrity calculation"
  exit 1
fi
if [ -z $2 ] || [ -z $3 ];then
  echo "no arguments (\$2, \$3) given for integrity calculation"
  exit 1
fi

cmd=$1

file1=$2
file2=$3

file1sum=$($cmd $file1)
file2sum=$($cmd $file2)

# filter out sum
file1sum=$(echo $file1sum|cut -f1 -d ' ')
file2sum=$(echo $file1sum|cut -f1 -d ' ')

echo "Sum $file1: $file1sum"
echo "Sum $file2: $file2um"

if [ $file1sum == $file2sum ]; then
  echo "==> checksum is correct"
else
  echo "==> checksum is false"
  exit 1
fi

