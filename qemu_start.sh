#!/bin/bash
function usage {
  echo "usage: $0 mem img"
}
if [ -z $1 ] ||
  [ -z $2 ];then
  usage
  exit 1;
fi
qemu-system-i386 -enable-kvm -cpu host -m $1 -hda $2
