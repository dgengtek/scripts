#!/bin/bash
usage() {
  cat << EOF
Usage: ${0##*/} [options] {devices} img [addoptions]

options:
  -s			  create a snapshot and discard
  -x			  use cpu arch x86_64
  -m mem		  memory
  -w port		  create monitor on port, default is 7100
  -p 'sport:dport'	  open ports from host,sport -> guest,dport
  addoptions		  add additional options to qemu

devices: [-b bridge | -t tapdev]
only one type possible
  -b bridge		  bridge to connect to via bridge helper
  -t tapdev		  tapdev to connect to
EOF
  exit 1
}
main() {
  local optlist=":shxm:w:p:b:t:"

  local -i enable_snapshot=0
  local -i enable_monitor=0
  local -i enable_ports=0
  local -i connect_bridges=0
  local -i connect_tapdevs=0
  local -i flagged=0

  local memory="256"
  local hda=""
  local -a ports
  local -a bridges
  local -a tapdevs

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
      b)
	let connect_bridges=1
	bridges+=("$OPTARG")
	;;
      t)
	let connect_tapdevs=1
	tapdevs+=("$OPTARG")
	;;
      *)
	usage
	;;
    esac
  done
  shift $((OPTIND - 1))


  if [ -z $1 ] \
    || ( ((connect_bridges == 1)) && ((connect_tapdevs == 1)) );then
    usage
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

  local devices=""
  local function=""
  if ((connect_bridge == 1)); then
    devices=${bridges[@]}
    function=connect_bridges
  elif ((connect_tapdevs== 1)); then
    devices=${bridges[@]}
    function=connect_bridges
  fi
  connect_netdevs $function $devices

  if ((enable_ports == 1)); then
    open_ports ${ports[@]}
  fi

  $qemu_cmd $options -m $memory -hda $hda

}

connect_netdevs() {
  local -i count=0
  func=$1
  shift 1
  if [ -z "$func" ]; then
    return 1
  fi

  for n in $@; do
    func $count $n
    let count+=1
  done
}


# with bridge helper of qemu
connect_bridges() {
  local id=$1
  local bridge=$2
  options+="-net nic,vlan=$id -net bridge,vlan=$id,br=$bridge"
}

connect_tapdevs() {
  local id=$1
  local tapdev=$2
  options+="-netdev tap,id=t$id,ifname=$tapdev,script=no,downscript=no \
  -device e1000,netdev=t$id,id=nic$id"
  #options+=",mac=$mac"
}

open_ports() {
  local sport=""
  local dport=""
  options+=" -device e1000,netdev=net0 \
    -netdev user,id=net0"
  for p in $@; do
    sport=${p%%:*}
    dport=${p##*:}
    options+=",hostfwd=tcp::$sport-:$dport"
  done

}

main "$@"
