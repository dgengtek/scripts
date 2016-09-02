#!/bin/bash
usage() {
  cat << EOF
Usage: ${0##*/} [mode] [options] [bridge]

mode:
    -b cidr,dev_eth	    bridged network,dev_eth to connect to 
    -i			    internal network only
    -h cidr		    host only network (default)

options:
    [-r [-f]]
    -r			    remove named bridge
    -f			    force remove named bridge
    bridge		    name of the bridge
EOF
  exit 1
}

main() {
  local -i flag_host_only=0
  local -i flag_bridged_network=0
  local -i flag_internal_network=0

  # flag only once
  local -i flagged=0
  local -i flag_remove_bridge=0
  local -i force_remove=0
  local cidr=""
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
  local bridge_id="$1"


  local -r bridge_file_path="/tmp/virtual_network_$bridge_id"
  local -r bridge_name_file="$bridge_file_path/$bridge_id"

  if ((flag_remove_bridge == 1));then 
    remove_bridge $bridge_id
  else
    sanity_check
    start_bridge $bridge_id
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

create_bridge_file_id() {
  if [ -z "$bridge_id" ];then
    bridge_id="br$(gen_alpha.sh 2)"
  fi
  mkdir -p "$bridge_file_path"
  touch "$bridge_name_file"
}

remove_bridge() {
  if [ -z "$1" ];then
    >&2 echo "no bridge supplied to remove"
    return 1
  fi
  bridge_id="$1"

  if ! bridge_is_empty ||
    ((force_remove == 1));then
    tap_device_list=$(cat $bridge_name_file)
    for device in $tap_device_list;do
      net_tuntap.sh -r -b $bridge_id $device
    done
  else
    logger --stderr --no-act "bridge has devices attached to it"
    return 1
  fi

  if (bridge_exists $bridge_id &&
	ip link set dev $bridge_id down &&
	ip link delete dev $bridge_id type bridge &&
	[ -e $bridge_name_file ]);then 
    rm $bridge_name_file
    rmdir $bridge_file_path
  fi
}



# bridge doesnt have any left over tap connections
bridge_is_empty() {
  local devices
  devices="$(cat $bridge_name_file)"
  [[ $devices == "" ]]
}

bridge_is_up() {
  local path_to_bridge="/sys/class/net/$bridge_id/operstate"
  [ -e $path_to_bridge ] && 
    [ $(cat $path_to_bridge) != "down" ]
}

bridge_exists() {
  local bridge_id=$1
  [ ! -z $bridge_id ] && \
  [ -e /sys/devices/virtual/net/"$bridge_id" ]
}

create_bridge() {
  local bridge_id=$1
  (! bridge_exists "$bridge_id" && \
    ip link add name "$bridge_id" type bridge || exit 1)
  if ((flag_internal_network == 1)); then
    create_internal_networking
  else
    # theres no need to check for flag, since 
    # the bridge needs to get an addr with both modes
    create_host_only_networking $cidr $bridge_id
    # attach to eth dev only if flagged
    if ((flag_bridged_network== 1)); then
      create_bridged_networking $dev_eth $bridge_id
    fi
  fi
}

create_internal_networking() {
  # if iptables rules are set to accept need to add rule to reject packets
  # iptables -I FORWARD -m $bridge_id --physdev-is-bridged -j REJECT
  :
}

create_host_only_networking() {
  local cidr=$1
  local bridge_id=$2
  ip addr add "$cidr" dev "$bridge_id"
}

create_bridged_networking() {
  local dev_eth=$1
  local bridge_id=$2
  ip link set $dev_eth master $bridge_id
}

start_bridge() {
  local bridge_id=$1
  if ! bridge_exists $bridge_id;then
    create_bridge $bridge_id
  fi
  create_bridge_file_id $bridge_id
  if ! bridge_is_up;then
    ip link set dev "$bridge_id" up
  fi
}
main "$@"
