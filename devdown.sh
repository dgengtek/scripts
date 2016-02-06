#!/bin/sh
if [ -e "$1" ]
then 
  echo "no dev given as argument"
  exit 1

fi

sudo ip link set dev "$1" down
echo "Exit code of $0: $?"
