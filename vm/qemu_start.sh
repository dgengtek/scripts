#!/bin/bash
usage() {
  cat << EOF
Usage: ${0##*/} [options] img [addoptions]

options:
  -s			  create a snapshot and discard
  -x			  use cpu arch x86_64
  -m mem		  memory
  -w port		  create monitor on port, default is 7100
  -p 'sport:dport'	  open ports from host,sport -> guest,dport
  addoptions		  add additional options to qemu
EOF
  exit 1
}
main() {
local optlist=":shxm:w:p:"

local -i enable_snapshot=0
local -i enable_monitor=0
local -i enable_ports=0

local memory="256"
local hda=""
local -a ports

local qemu_cmd="qemu-system-i386"
while getopts $optlist opt; do
  case $opt in
    s)
      let enable_snapshot=1
      ;;
    x)
      qemu_cmd="qemu-system-x86_64"
      ;;
    m)
      memory=$OPTARG
      ;;
    w)
      let enable_monitor=1
      if [[ $OPTARG == "" ]];then
	monitor_port=7100
      else
	monitor_port=$OPTARG
      fi
      ;;
    p)
      let enable_ports=1
      ports+=("$OPTARG")
      ;;
    *)
      usage
      ;;
  esac
done
shift $((OPTIND - 1))


if [ -z $1 ];then
  usage
  exit 1;
fi
hda="$1"
shift 1

local options="-enable-kvm -cpu host -vga qxl" 

options+=" $@"

if ((enable_snapshot == 1)); then
  options+=" -snapshot"
fi

if ((enable_monitor == 1)); then
  options+=" -monitor \
    telnet:localhost:$monitor_port,server,nowait,nodelay"
fi

if ((enable_ports == 1)); then
  local sport=""
  local dport=""
  options+=" -device e1000,netdev=net0 \
    -netdev user,id=net0"
  for p in ${ports[@]}; do
    sport=${p%%:*}
    dport=${p##*:}
    options+=",hostfwd=tcp::$sport-:$dport"
  done
fi
$qemu_cmd $options -m $memory -hda $hda

}

main "$@"
