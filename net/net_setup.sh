#!/bin/env bash
usage() {
  cat << EOF
Usage: ${0##*/} [OPTIONS] image [options for qemu]

OPTIONS:
  -g			    enable standard graphics
  -s			    create temporary snapshots
  -n CIDR		    set network address/bits of virtual network
  -m macaddr		    set mac address of virtual guest
  -b bridge		    bridge name used for virtual network
  -t tapdev		    name of tap device the virtual machine should use
  -h			    usage
EOF
  exit 1
}
sanity_check() {
  local -i flagged=0
  if [[ $(id -u) != 0 ]] || (($# < 3)) || !(hash net_bridge.sh && hash net_tuntap.sh); then
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
  local bridge_id=""
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
	bridge_id=$OPTARG
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

  sanity_check

  local img_path=$1
  shift 1

  local mac=""
  local options=""
  local -r bridge_file_path="/tmp/virtual_network_$bridge_id"
  local -r bridge_id_file="$bridge_file_path/$bridge_id"

  net_bridge.sh -h $network $bridge_id
  net_tuntap.sh -b $bridge_id $tapdev

  mac=$(generate_mac -u)
  while grep -sq $mac $bridge_id_file; do
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

create_bridge_file_id() {
  if [ -z "$bridge_id" ];then
    bridge_id="br$(gen_alpha.sh 2)"
  fi
  mkdir -p "$bridge_file_path"
  touch "$bridge_id_file"
}

remove_bridge() {
  bridge_id=$1
  if ! bridge_is_empty; then
    tap_device_list=$(cat $bridge_id_file)
    for device in $tap_device_list;do
      net_tuntap.sh -r -b $bridge_id $device
    done
  else
    logger --stderr --no-act "bridge has devices attached to it"
    return 1
  fi

}

# bridge doesnt have any left over tap connections
bridge_is_empty() {
  local devices
  devices="$(cat $bridge_id_file)"
  [[ $devices == "" ]]
}

trap_interrupt() {
  sh ./setup_tap_device.sh -r -b $bridge_id $tapdev
  sh ./setup_bridge.sh -r $bridge_id
  exit $?
}
trap trap_interrupt SIGINT SIGHUP SIGTERM
main "$@"
