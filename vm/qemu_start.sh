#!/usr/bin/env bash

usage() {
  cat << EOF
Usage: ${0##*/} [options] [{devices}] img [addoptions]

Simple wrapper around qemu. Aliasing commands for reference and easier access

options:
  -s			  create a snapshot and discard
  -x			  use cpu arch x86_64
  -q                      debug
  -d			  daemonize
  -v			  enable vga
  -m mem		  memory
  -k mac                  use mac address
  -c                      boot from network first
  -n                      enable netdev passthrough 
  -w [port]               enable monitor
  -w port		  create monitor on port, default is 7100
  -p 'sport:dport'	  open ports from host,sport -> guest,dport
  addoptions		  add additional options to qemu

devices: [-b bridge | -t tapdev]
only one type possible
  -b bridge		  bridge to connect to via bridge helper
  -t tapdev		  tapdev to connect to
EOF
}
main() {
  local optlist="qvdshk:xm:cw:p:b:t:n"
  local debug=

  local -i enable_graphic=0
  local -i enable_ports=0
  local -i connect_bridges=0
  local -i connect_tapdevs=0
  local -i flagged=0
  local -i daemonize=0

  local mac=
  local memory="256"
  local hda=""
  local -a ports
  local -a bridges
  local -a tapdevs

  local -a options=(
  "-enable-kvm" 
  "-cpu host" 
  )

  local qemu_cmd="qemu-system-i386"
  while getopts $optlist opt; do
    case $opt in
      q)
        debug=echo
        set -x
	;;
      s)
        options+=("-snapshot")
	;;
      x)
	qemu_cmd="qemu-system-x86_64"
	;;
      m)
	memory=$OPTARG
	;;
      k)
	mac=$OPTARG
	;;
      d)
        options+=("-daemonize")
	;;
      v)
        let enable_graphic=1
	;;
      n)
        options+=("-netdev user,id=vmnic -device virtio-net,netdev=vmnic")
	;;
      c)
        options+=("-boot order=nc")
	;;
      w)
	if [[ $OPTARG == "" ]];then
	  monitor_port=7100
	else
	  monitor_port=$OPTARG
	fi
        options+=("-monitor \
          telnet:localhost:$monitor_port,server,nowait,nodelay")
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
        exit 1
	;;
    esac
  done
  shift $(($OPTIND - 1))


  if [[ -z $1 ]] \
    || ( (($connect_bridges == 1)) && (($connect_tapdevs == 1)) );then
    usage
    exit 1
  fi
  hda="$1"
  shift 1

  if (($enable_graphic)); then
    options+=("-vga qxl")
  else
    options+=("-nographic")
  fi


  local devices=""
  local function=""
  if ((connect_bridge == 1)); then
    devices=${bridges[@]}
    function=connect_bridges
  elif ((connect_tapdevs== 1)); then
    devices=${tapdevs[@]}
    function=connect_tapdevs
  fi
  connect_netdevs $function $devices

  if ((enable_ports == 1)); then
    open_ports ${ports[@]}
  fi
  options+=( "$@" )

  $debug $qemu_cmd ${options[@]} -m "$memory" -hda "$hda"
}
restrict() {
# -netdev type=user,id=mynet0,restrict=yes 
:
}

connect_netdevs() {
  local -i count=0
  local -r func=$1
  shift 1
  if [[ -z $func ]]; then
    return 1
  fi

  for n in "$@"; do
    $func "$count" "$n"
    let count+=1
  done
}
smb() {
#  -net nic -net
#  user,smb="/mnt/nfs/os/windows/win10/Activator",smbserver=10.0.2.4
:
}
no_network() {
  # options+=("-net none")
  :
}


# with bridge helper of qemu
connect_bridges() {
  local -r id=$1
  local -r bridge=$2
  options+=("-net nic,vlan=$id -net bridge,vlan=$id,br=$bridge")
}

connect_tapdevs() {
  local -r id=$1
  local -r tapdev=$2
  local -r mac=${mac:-$(generate_mac.py -u)}

  options+=("-netdev tap,id=t$id,ifname=$tapdev,script=no,downscript=no \
    -device e1000,netdev=t$id,id=nic$id,mac=$mac")
}

open_ports() {
  local sport=""
  local dport=""
  local option+="-device e1000,netdev=net0 \
    -netdev user,id=net0"
  for p in $@; do
    sport=${p%%:*}
    dport=${p##*:}
    option+=",hostfwd=tcp::$sport-:$dport"
  done
  options+=("$option")

}
# example commands to maybe integrate
# terminal on socket with monitor
# -chardev socket,host=127.0.0.1,port=4556,id=gnc0,server,nowait -device isa-serial,chardev=gnc0 -monitor tcp:127.0.0.1:4555,server,nodelay

main "$@"
