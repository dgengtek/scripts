#!/bin/bash
if [ -z $1 ];then
  echo "usage: $0 dev"
  exit 1
fi
ip addr show dev $1|grep inet|awk '{FS= " ";print $2}'
