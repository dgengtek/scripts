#!/bin/bash
# use this script as a support library to 
# start bridge mode for the virtual network

declare -i host_only=0
declare -i internal_only=1
declare -i bridged_network=0

declare -i flagged=0
declare -i remove_the_bridge=0
declare -i force_remove=0
network=""

function usage {
>&2  echo "usage: $0 [-h] (-i | -b netaddr | -h netaddr) [-r] [-f] [bridge]"
>&2  echo "only one flag can be active at a time"
>&2  echo "-b bridged network"
>&2  echo "-i internal network only"
>&2  echo "-h host only network (default)"
>&2  echo "-r remove named bridge"
>&2  echo "-f force remove named bridge"
>&2  echo "bridge  name of the bridge"
exit 1
}
function is_flagged {
  if ((flagged == 1)); then
    usage
  else
    let flagged=1
  fi
}

function create_bridge_file_id {
  if [ -z "$bridge_id" ];then
    bridge_id="br$(gen_alpha 2)"
  fi
  mkdir -p "$bridge_file_path"
  touch "$bridge_name_file"
}

function remove_bridge {
  if [ -z "$1" ];then
    >&2 echo "no bridge supplied to remove"
    return 1
  fi
  bridge_id="$1"

  if ! bridge_is_empty ||
    ((force_remove == 1));then
    tap_device_list=$(cat $bridge_name_file)
    for device in $tap_device_list;do
      sh ./setup_tap_device.sh -r -b $bridge_id $device
    done
  else
    return 1
  fi

  if (! [ -z $bridge_id ] && bridge_exists &&
	sudo ip link set dev $bridge_id down &&
	sudo ip link delete dev $bridge_id type bridge &&
	[ -e $bridge_name_file ]);then 
    rm $bridge_name_file
    rmdir $bridge_file_path
    return 0
  fi
  return 1
}



# bridge doesnt have any left over tap connections
function bridge_is_empty {
  local devices
  devices="$(cat $bridge_name_file)"
  if [[ $devices == "" ]]; then
    return 0
  fi
  return 1
}

function bridge_up {
  local path_to_bridge="/sys/class/net/$bridge_id/operstate"
  if [ -e $path_to_bridge ] && 
    [ $(cat $path_to_bridge) != "down" ];then 
      return 0
  fi
  return 1
}

function bridge_exists {
  [ -e /sys/devices/virtual/net/"$bridge_id" ]
}

function create_bridge {
  if ! bridge_exists "$bridge_id" &&
      sudo ip link add name "$bridge_id" type bridge;then 
  if ! [ -z $network ] && ! ((internal_only == 1));then
      sudo ip addr add "$network" dev "$bridge_id"
    fi
    return 0
  fi
  return 1
}

function start_bridge {
  if ! bridge_exists $bridge_id;then
    create_bridge
  fi
  create_bridge_file_id $bridge_id
  if ! bridge_up;then
    sudo ip link set dev "$bridge_id" up
    return $?
  else
    return 1
  fi
}

optlist=":b:ih:rf"
while getopts $optlist opt; do
  case $opt in
    b)
      is_flagged
      let internal_only=0
      let bridged_network=1
      network=$OPTARG
      ;;
    i)
      is_flagged
      ;;
    h)
      is_flagged
      let internal_only=0
      let host_only=1
      network=$OPTARG
      ;;
    r)
      let remove_the_bridge=1
      ;;
    f)
      let force_remove=1
      ;;
    *)
      usage
      ;;
  esac
done
shift $((OPTIND -1))
bridge_id="$1"
bridge_file_path="/tmp/virtual_network_$bridge_id"
bridge_name_file="$bridge_file_path/$bridge_id"

if ((remove_the_bridge == 1));then 
  remove_bridge $bridge_id
  exit $?
fi
start_bridge 
