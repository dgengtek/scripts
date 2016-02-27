#!/bin/bash
function usage {
>&2  echo "usage: $0 [-r] [-h] [-b bridge] [-u user] tapdev"
>&2  echo "-b bridge name used for virtual network"
>&2  echo "tap device  name used for virtual network"
>&2  echo "-u user used to create tap device"
>&2  echo "-r remove tap device"
>&2  echo "-h help"

  exit 1
}
if (( $# < 2));then
  usage
fi
usr="$USER"
bridge_name="br$(gen_alpha 4)"
tap_dev_name=""

function tap_dev_exists {
  if [ -e /sys/devices/virtual/net/"$tap_dev_name" ];then
    return 0
  else
    return 1
  fi
}
function tap_dev_up {
  local tap_path="/sys/class/net/$tap_dev_name/operstate"
  if [ -e "$tap_path" ];then
    local is_up
    is_up="$(cat $tap_path)"
    if [ "$is_up" != "down" ];then
      return 0
    fi
  fi
  return 1
}
function create_tap_dev {
  if ! tap_dev_exists &&
	sudo ip tuntap add "$tap_dev_name" mode tap user "$usr";then 
    create_tap_dev_file
  fi
  sudo ip link set dev "$tap_dev_name" master "$bridge_name" 
  sudo ip link set dev "$tap_dev_name" up
}
function create_tap_dev_file {
  remove_tap_dev_file
  echo "$bridge_name" > "$bridge_file_path/$tap_dev_name"
  echo "$tap_dev_name" >> "$bridge_file_path/$bridge_name"
}
function remove_tap_dev_file {
  if [ -e "$bridge_file_path/$tap_dev_name" ];then
    rm "$bridge_file_path/$tap_dev_name"
    sed -i "/^${tap_dev_name}\$/d" "$bridge_file_path/$bridge_name"
    return 0
  fi
  return 1
}
function remove_tap_dev {
  if ! [ -z "$1" ] && ! [ -z "$2" ];then
    tap_dev_name="$1"
    bridge_name="$2"
    bridge_file_path="/tmp/virtual_network_$bridge_name"
  fi
  if ! tap_dev_exists;then
    return $?
  fi
  if sudo ip tuntap del "$tap_dev_name" mode tap &&
      remove_tap_dev_file;then
    sh ./setup_bridge.sh -r $bridge_name
    return 0
  else 
    return 1
  fi
  return $?
}


optlist=":b:uhr"

declare -i remove_tap=0
while getopts $optlist opt; do
  case $opt in
    b)
      bridge_name=$OPTARG
      ;;
    u)
      usr=$OPTARG
      ;;
    r)
      let remove_tap=1
      ;;
    *)
      usage
      ;;
  esac
done
shift $((OPTIND -1))
unset OPTIND
tap_dev_name=$1

if ((remove_tap == 1));then
  remove_tap_dev $tap_dev_name $bridge_name
  exit $?
fi

source ./setup_bridge.sh "$bridge_name"
if ! [ -z "$bridge_id" ];then
  bridge_name="$bridge_id"
fi

bridge_file_path="/tmp/virtual_network_$bridge_name"
create_tap_dev 
