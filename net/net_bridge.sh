#!/bin/env bash
# TODO add cleanup
# TODO add signal handler
usage() {
  cat << EOF
Usage: ${0##*/} [options] bridge

options:
    mode
    [-r [-f]]
    -r			    remove named bridge
    -f			    force remove named bridge
    bridge		    name of the bridge

mode:
    -b cidr,dev_eth	    bridged network,dev_eth to connect to 
    -i			    internal network only
    -h cidr		    host only network
EOF
  exit 1
}

main() {
  if (($UID != 0)); then
    error_exit 1 "Must be run with root permissions."
  fi
  local -i flag_host_only=0
  local -i flag_bridged_network=0
  local -i flag_internal_network=0
  local bridge_log_path="/tmp/virtual_network"

  # flag only once
  local -i flagged=0
  local -i flag_remove_bridge=0
  local -i force_remove=0
  local cidr="10.10.5.1/24"
  local dev_eth=""

  local -r optlist=":b:ih:rf"
  while getopts $optlist opt; do
    case $opt in
      b)
	is_flagged
	let flag_bridged_network=1
	cidr=$(echo $OPTARG | cut -f1 -d ",")
	dev_eth=$(echo $OPTARG | cut -f2 -d ",")
	;;
      i)
	is_flagged
	let flag_internal_network=1
	;;
      h)
	is_flagged
	let flag_host_only=1
	cidr=$OPTARG
	;;
      r)
	let flag_remove_bridge=1
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
  local bridge_id="br$(genpw.sh -a 4)"
  [[ -n $1 ]] && bridge_id=$1
  local -r bridge_log_path="${bridge_log_path}_$bridge_id"
  local -r bridge_log_file="${bridge_log_path}/$bridge_id"

  if (($flag_remove_bridge == 1));then 
    remove_bridge "$1"
  else
    sanity_check
    start_bridge "$bridge_id"
  fi
}
prepare() {
  mkdir -p "$bridge_log_path"
  touch "$bridge_log_file"
}
cleanup() {
  if ! bridge_exists "$bridge_id"; then
    rm "$bridge_log_file"
    rmdir "$bridge_log_path"
  fi
}

sanity_check() {
  # check if no flag was set
  if [[ $(id -u) != 0 ]] || [ -z "$bridge_id" ] || ((flagged == 0)); then
    usage
  fi
}

is_flagged() {
  if ((flagged == 1)); then
    usage
  else
    let flagged=1
  fi
}
remove_attached_devices() {
  local -r bridge_id=${1:?"No bridge id supplied to remove attached devices."}
  local -r bridge_log_file="${bridge_log_path}/$bridge_id"
  hash net_tuntap.sh || error_exit 1 "Net tuntap script not found in path."
  while read -r tapdev; do
    net_tuntap.sh -r "$bridge_id" "$tapdev"
  done < "$bridge_log_file"
}

remove_bridge() {
  set -e
  local -r bridge_id="${1:?"No bridge id supplied to remove."}"
  if [[ -z $bridge_id ]];then
    >&2 echo "no bridge supplied to remove"
    exit 1
  fi
  if ! bridge_exists "$bridge_id"; then
    error_exit 1 "Bridge '$bridge_id' does not exist."
  fi
  remove_attached_devices "$bridge_id"

  ip link set dev "$bridge_id" down
  ip link delete dev "$bridge_id" type bridge 
  cleanup
  set +e
}

bridge_is_up() {
  local -r path_to_bridge="/sys/class/net/$bridge_id/operstate"
  [ -e $path_to_bridge ] \
    && [ $(cat $path_to_bridge) != "down" ]
}

bridge_exists() {
  local -r bridge_id=$1
  [ ! -z $bridge_id ] \
    && [ -e /sys/devices/virtual/net/"$bridge_id" ]
}

create_bridge() {
  local -r bridge_id=$1
  (! bridge_exists "$bridge_id" \
    && ip link add name "$bridge_id" type bridge || exit 1)
  if ((flag_internal_network == 1)); then
    create_internal_networking
  else
    # theres no need to check for flag, since 
    # the bridge needs to get an addr with both modes
    create_host_only_networking "$bridge_id" "$cidr" 
    # attach to eth dev only if flagged
    if (($flag_bridged_network== 1)); then
      create_bridged_networking "$bridge_id" "$dev_eth" 
    fi
  fi
}

create_internal_networking() {
  # if iptables rules are set to accept need to add rule to reject packets
  # iptables -I FORWARD -m $bridge_id --physdev-is-bridged -j REJECT
  :
}

create_host_only_networking() {
  local -r bridge_id=$1
  local -r cidr=$2
  ip addr add "$cidr" dev "$bridge_id"
}

create_bridged_networking() {
  local -r bridge_id=$1
  local -r dev_eth=$2
  ip link set $dev_eth master $bridge_id
}

start_bridge() {
  local -r bridge_id=$1
  if ! bridge_exists "$bridge_id";then
    prepare
    create_bridge "$bridge_id"
  fi
  if ! bridge_is_up;then
    ip link set dev "$bridge_id" up
  fi
}
log() {
  echo -n "$@" | logger -s -t ${0##*/}
}
error_exit() {
  exit_code=${1:-0}
  shift
  log "$@"
  exit $exit_code
}
main "$@"
