#!/bin/bash
usage() {
  cat << EOF
Usage: ${0##*/} [OPTIONS] image [options for qemu]

OPTIONS:
  -g			    enable standard graphics
  -s			    create temporary snapshots
  -n CISR		    set network address/bits of virtual network
  -m macaddr		    set mac address of virtual guest
  -b bridge		    bridge name used for virtual network
  -t tapdev		    name of tap device the virtual machine should use
  -h			    usage
EOF
  exit 1
}
sanity_check() {
  local -i flagged=0
  if (($# < 3)) || !(hash net_bridge.sh && hash net_tuntap.sh); then
    let flagged=1
  else
    for i in $@; do
      if [ -z "$i" ]; then
	let flagged=1
	break
      fi
    done
  fi
  if ((flagged == 1)); then
    usage
  fi
}

main() {
  optlist=":gsn:b:m:t:h"

  local tapdev="tap$(gen_alpha.sh 4)"
  local mem=256
  local network=""
  local -i enablegraphic=0
  local -i enablesnapshot=0
  while getopts $optlist opt; do
    case $opt in
      g)
	let enablegraphic=1
	;;
      s)
	let enablesnapshot=1
	;;
      n)
	network=$OPTARG
	;;
      m)
	mac=$OPTARG
	;;
      b)
	bridge_name=$OPTARG
	;;
      t)
	tapdev=$OPTARG
	;;
      t)
	usage
	;;
    esac
  done
  shift $((OPTIND -1))

  local img_path=$1

  shift 1

  mac=""
  options=""


  net_bridge.sh -h $network $bridge_name
  net_tuntap.sh -b $bridge_name $tapdev

  mac=$(generate_mac -u)
  while grep -sq $mac $bridge_name_file; do
    mac=$(generate_mac)
  done
  if ((enablegraphic == 1)); then
    options="${options}-vga std "
  else
    options="${options}-nographic "
  fi
  if ((enablesnapshot== 1)); then
    options="${options}-snapshot "
  fi

  options="${options}-netdev tap,id=t0,ifname=$tapdev,script=no,downscript=no \
  -device e1000,netdev=t0,id=nic1,mac=$mac"
  qemu-system-i386 -enable-kvm -cpu host -m $mem -hda $img_path $options

}

trap_interrupt() {
  sh ./setup_tap_device.sh -r -b $bridge_id $tapdev
  sh ./setup_bridge.sh -r $bridge_id
  exit $?
}
trap trap_interrupt SIGINT SIGHUP SIGTERM
main "$@"
