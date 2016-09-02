#!/bin/env bash
if [ -z "$1" ]|| [ -z "$2" ];then
  echo "arguments empty"
  echo "\$1 - name of label"
  echo "\$2 - path iso to burn to disc"
  exit 1;
fi
extension=${2##*.}
if [ "$extension" != "iso" ]; then
  echo "supplied file is not an ISO"
  exit 1;
fi

label=$1
iso=$2
wodim -v dev=/dev/sr0 $iso
