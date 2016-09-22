#!/bin/env bash
# use qemu bridge helper
# http://wiki.qemu.org/Features/HelperNetworking
function usage {
  cat << EOF
Usage:  ${0##*/} [Options] tapdev [bridge]

Options:
  tapdev		      tap device  name used for virtual network
  -b bridge		      bridge name used for virtual network
  -r			      remove tap device
  -h			      help
EOF
}
main() {
  local bridge_name="br$(genpw.sh -a 4)"
  local tap_dev_name="tap$(genpw.sh -a 4)"
  local -r optlist=":b:uhr"

  local -i remove_tap=0
  while getopts $optlist opt; do
    case $opt in
      b)
        bridge_name=$OPTARG
        ;;
      r)
        remove_tap=1
        ;;
      *)
        usage
        ;;
    esac
  done
  shift $((OPTIND -1))
  unset OPTIND
  if [[ $(id -u) != 0 ]] && [[ $# < 2 ]];then
    usage
    exit 2
  fi
  [[ -z $1 ]] && usage && exit 1
  tap_dev_name=$1
  [[ -n $2 ]] && bridge_name=$2

  if (($remove_tap == 1));then
    remove_tap_dev $tap_dev_name $bridge_name
    exit $?
  fi

  if ! net_bridge.sh "$bridge_name"; then
  fi

  local -r bridge_file_path="/tmp/virtual_network_$bridge_name"
  create_tap_dev 
}

function tap_dev_exists {
  local -r tapdev=$1
  [[ -e "/sys/devices/virtual/net/$tapdev" ]]
}
function tap_dev_up {
  local -r tap_path="/sys/class/net/$tap_dev_name/operstate"
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
  if ! tap_dev_exists "$tap_dev_up" &&
	ip tuntap add "$tap_dev_name" mode tap ;then 
    create_tap_dev_file
  fi
  ip link set dev "$tap_dev_name" master "$bridge_name" 
  ip link set dev "$tap_dev_name" up
}
function create_tap_dev_file {
  remove_tap_dev_file
  ! [[ -d "$bridge_file_path" ]] && exit 5
  echo "$bridge_name" > "$bridge_file_path/$tap_dev_name"
  echo "$tap_dev_name" >> "$bridge_file_path/$bridge_name"
}
function remove_tap_dev_file {
  if [[ -f "$bridge_file_path/$tap_dev_name" ]];then
    rm "$bridge_file_path/$tap_dev_name"
    sed -i "/^${tap_dev_name}\$/d" "$bridge_file_path/$bridge_name"
    return 0
  fi
  return 1
}
function remove_tap_dev {
  if [[ -n $1 ]] && [[ -n $2 ]];then
    tap_dev_name="$1"
    bridge_name="$2"
    bridge_file_path="/tmp/virtual_network_$bridge_name"
  fi
  if ! tap_dev_exists;then
    return $?
  fi
  if ip tuntap del "$tap_dev_name" mode tap &&
      remove_tap_dev_file;then
    net_bridge.sh -r $bridge_name
    return 0
  else 
    return 1
  fi
  return $?
}
main "$@"
