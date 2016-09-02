#!/bin/bash
function usage {
>&2  echo "usage: $0 [-g] [-s] [-h] [-b bridge] [-n 'networkaddr/hostbits'] [-m macaddr]
[-t tapdev] image [options for qemu]"
>&2  echo "-g enable standard graphics"
>&2  echo "-s create temporary snapshots"
>&2  echo "-n set network address of virtual network"
>&2  echo "-m set mac address of virtual guest"
>&2  echo "-b bridge name used for virtual network"
>&2  echo "-t name of tap device the virtual machine should use"
>&2  echo "-h usage"
  exit 1
}
if (( $# < 3));then
  usage
fi
optlist=":gsn:b:m:t:h"



tapdev="tap$(gen_alpha 4)"
mem=256
network=""
declare -i enablegraphic=0
declare -i enablesnapshot=0
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
unset OPTIND

img_path=$1

shift 1

mac=""
options=""

function trap_interrupt {
  sh ./setup_tap_device.sh -r -b $bridge_id $tapdev
  sh ./setup_bridge.sh -r $bridge_id
  exit $?
}
trap trap_interrupt SIGINT SIGHUP SIGTERM

source ./setup_bridge.sh -h $network $bridge_name
unset OPTIND
source ./setup_tap_device.sh -b $bridge_name $tapdev

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
trap_interrupt
exit $?
