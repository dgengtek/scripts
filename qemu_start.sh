#!/bin/bash
usage() {
  echo -e "Usage: ${0##*/} [-s] mem img [options]...\n"
  echo -e "  -s,\tcreate a snapshot and discard"
  echo -e "  -x,\tuse cpu arch x86_64"
  echo -e "  options,\tadd additional options to qemu"
  
}
main() {
local optlist=":shx"

local -i enable_snapshot=0

qemu_cmd="qemu-system-i386"
while getopts $optlist opt; do
  case $opt in
    s)
      let enable_snapshot=1
      ;;
    x)
      qemu_cmd="qemu-system-x86_64"
      ;;
    h)
      usage
      ;;
    *)
      usage
      ;;
  esac
done
shift $((OPTIND - 1))

local memory=""
local hda=""

if [ -z $2 ];then
  usage
  exit 1;
fi
if [ -z $1 ];then
  memory="256"
else
  memory="$1"
fi

hda="$2"
shift 2

local options="-enable-kvm -cpu host"

options+=" $@"

if ((enable_snapshot == 1)); then
  options+=" -snapshot"
fi

$qemu_cmd $options -m $memory -hda $hda

}





main "$@"
