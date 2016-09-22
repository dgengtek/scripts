#!/bin/env bash
# use qemu bridge helper
# http://wiki.qemu.org/Features/HelperNetworking
function usage {
  cat << EOF
Usage:  ${0##*/} [Options] bridge tapdev...

Options:
  tapdev		      tap device  name used for virtual network
  -r			      remove tap device
  -f                          remove bridge and tap device(implies -r)
  -h			      help
EOF
}
main() {
  if (($UID != 0 ));then
    usage
    error_exit 2 "Must be run as root."
  fi

  local -r optlist=":uhr"

  local -i remove_tap=0
  local -i remove_all_devices=0

  while getopts $optlist opt; do
    case $opt in
      r)
        remove_tap=1
        ;;
      f)
        remove_all_devices=1
        ;;
      *)
        usage
        ;;
    esac
  done
  shift $(($OPTIND - 1))

  local -r bridge_name=$1
  shift
  local -r bridge_file_path="/tmp/virtual_network_$bridge_name"

  [[ -z $bridge_name ]] && usage && exit 1
  [[ -z $1 ]] && usage && exit 1

  if (($remove_tap == 1));then
    loop_devices "remove_tap_dev" "$bridge_name" "$@"
    exit 0
  fi

  trap cleanup SIGINT SIGTERM SIGKILL

  prepare
  loop_devices "create_tap_dev" "$bridge_name" "$@"

}
loop_devices() {
  local -r func=$1
  local -r bridge_name=$2
  shift 2
  for dev in "$@"; do
    $func "$dev" "$bridge_name"
  done
}
prepare() {
  mkdir -p "$bridge_file_path" || exit 1
  ! bridge_exists "$bridge_name" && error_exit 1 "Bridge '$bridge_name' does not exist."
}
cleanup() {
  trap cleanup SIGINT SIGTERM SIGKILL
  rmdir "$bridge_file_path"
}
remove_all_attached() {
  local -r tap_dev_name=$1
  local -r attached_bridge=$(cat "$bridge_file_path/$tap_dev_name")
  if ! bridge_exists "$attached_bridge"; then
    error_exit 9 "Bridge '$bridge_name' does not exist."
  fi
  net_bridge.sh -r "$attached_bridge" \
    || error_exit 3 "Failed to remove bridge '$attached_bridge'."
}
bridge_exists() {
  local bridge_id=${1:?"No bridge id supplied to check if existing."}
  [[ -e "/sys/devices/virtual/net/$bridge_id" ]]
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
  local -r tap_dev_name=$1
  local -r bridge_name=$2
  if ! tap_dev_exists "$tap_dev_name" \
      && ip tuntap add "$tap_dev_name" mode tap ;then 
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
  local -r tap_dev_name=$1
  local -r bridge_name=$2

  if (($remove_all_devices)); then
    net_bridge.sh -r "$bridge_name"
    exit $?
  fi

  if ! tap_dev_exists "$tap_dev_name";then
    error_exit 1 "Tap device '$tap_dev_name' does not exist."
  fi
  if ip tuntap del "$tap_dev_name" mode tap \
    && remove_tap_dev_file;then
    return 0
  else 
    return 1
  fi
}
log() {
  echo -n "$@" | logger -s -t ${0##*/}
}
error_exit() {
  exit_code=${1:-0}
  shift
  log "$@"
  exit $error_code
}
main "$@"
