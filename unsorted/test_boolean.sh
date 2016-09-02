#!/bin/bash
# useless
if [ -z $1 ] ||
    [ -z $2 ]; then
  echo "usage: $0 expr1 expr2"
else
  if [ $1 = $2 ]; then
    echo "True"
    exit 1
  else
    echo "False"
    exit 0
  fi
fi
