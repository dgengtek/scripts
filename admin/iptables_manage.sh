#!/bin/env bash
# ------------------------------------------------------------------------------
# description
# ------------------------------------------------------------------------------
# 
# add following to /etc/sysctl.conf
#
# net.ipv4.conf.all.rp_filter=1
# net.ipv4.conf.all.log_martians=1
# net.ipv4.conf.default.log_martians=1
# TODO add iptables.rules file for temporary storage of all rules
# TODO append all rules to file and use at the end iptables restore to active
# TODO allow debug mode where no rules are applied only sent to output
usage() {
  cat >&2 << EOF
Usage:	${0##*/} [OPTIONS] arg1 -- [EXTRA]
  
OPTIONS:
  -h			  help
  -v			  verbose
  -f, --flush		  flush
  -q			  quiet
  -d			  debug

arg1
  mandatory argument passed to script

EXTRA
  Additional options passed for other purposes
EOF
}

main() {
  local -r INTERFACE_INC="eth1" # connected to internet 
  local -r SERVER_IP="202.54.10.20" # server IP
  local -r LAN_RANGE="192.168.1.0/24" # your LAN IP range 
  local -r IPTABLES_BIN="/usr/bin/iptables" # path to iptables
  # Add your spoofed IP range/IPs here
  SPOOF_IPS=(
  "0.0.0.0/8"
  "127.0.0.0/8"
  "10.0.0.0/8"
  "172.16.0.0/12"
  "192.168.0.0/16"
  "224.0.0.0/3"
  )
   
  # default action, can be DROP or REJECT 
  ACTION="DROP"


  # flags
  local -i enable_verbose=0
  local -i enable_quiet=0
  local -i enable_debug=0

  local -a options=
  local -a args=

  check_dependencies
  # parse input args 
  parse_options "$@"
  # set leftover options parsed local input args
  set -- ${args[@]}
  # remove args array
  unset -v args
  check_input_args "$@"

  prepare_env
  setup
  run
}

defaults() {
  # Reject spoofed packets
  $IPTABLES_BIN -A INPUT -s 10.0.0.0/8 -j DROP
  $IPTABLES_BIN -A INPUT -s 169.254.0.0/16 -j DROP
  $IPTABLES_BIN -A INPUT -s 172.16.0.0/12 -j DROP
  $IPTABLES_BIN -A INPUT -s 127.0.0.0/8 -j DROP

  $IPTABLES_BIN -A INPUT -s 224.0.0.0/4 -j DROP
  $IPTABLES_BIN -A INPUT -d 224.0.0.0/4 -j DROP
  $IPTABLES_BIN -A INPUT -s 240.0.0.0/5 -j DROP
  $IPTABLES_BIN -A INPUT -d 240.0.0.0/5 -j DROP
  $IPTABLES_BIN -A INPUT -s 0.0.0.0/8 -j DROP
  $IPTABLES_BIN -A INPUT -d 0.0.0.0/8 -j DROP
  $IPTABLES_BIN -A INPUT -d 239.255.255.0/24 -j DROP
  $IPTABLES_BIN -A INPUT -d 255.255.255.255 -j DROP

# Stop smurf attacks
  $IPTABLES_BIN -A INPUT -p icmp -m icmp --icmp-type address-mask-request -j DROP
  $IPTABLES_BIN -A INPUT -p icmp -m icmp --icmp-type timestamp-request -j DROP
  $IPTABLES_BIN -A INPUT -p icmp -m icmp -j DROP

# Drop all invalid packets
  $IPTABLES_BIN -A INPUT -m state --state INVALID -j DROP
  $IPTABLES_BIN -A FORWARD -m state --state INVALID -j DROP
  $IPTABLES_BIN -A OUTPUT -m state --state INVALID -j DROP

# Drop excessive RST packets to avoid smurf attacks
  $IPTABLES_BIN -A INPUT -p tcp -m tcp --tcp-flags RST RST -m limit --limit 2/second --limit-burst 2 -j ACCEPT

# Attempt to block portscans
# Anyone who tried to portscan us is locked out for an entire day.
  $IPTABLES_BIN -A INPUT   -m recent --name portscan --rcheck --seconds 86400 -j DROP
  $IPTABLES_BIN -A FORWARD -m recent --name portscan --rcheck --seconds 86400 -j DROP

# Once the day has passed, remove them from the portscan list
  $IPTABLES_BIN -A INPUT   -m recent --name portscan --remove
  $IPTABLES_BIN -A FORWARD -m recent --name portscan --remove

# These rules add scanners to the portscan list, and log the attempt.
  $IPTABLES_BIN -A INPUT   -p tcp -m tcp --dport 139 -m recent --name portscan --set -j LOG --log-prefix "Portscan:"
  $IPTABLES_BIN -A INPUT   -p tcp -m tcp --dport 139 -m recent --name portscan --set -j DROP

  $IPTABLES_BIN -A FORWARD -p tcp -m tcp --dport 139 -m recent --name portscan --set -j LOG --log-prefix "Portscan:"
  $IPTABLES_BIN -A FORWARD -p tcp -m tcp --dport 139 -m recent --name portscan --set -j DROP

}

check_dependencies() {
  :
}

check_input_args() {
  if [[ -z $1 ]]; then
    usage
    exit 1
  fi
}

prepare_env() {
  :
}

prepare() {
  export MYLIBS="$HOME/.local/lib/"
  source "${MYLIBS}libutils.sh"
  source "${MYLIBS}libcolors.sh"
  set_descriptors
}

set_descriptors() {
  if (($enable_verbose)); then
    exec {fdverbose}>&1
  else
    exec {fdverbose}>/dev/null
  fi
  if (($enable_debug)); then
    set -xv
    exec {fddebug}>&1
  else
    exec {fddebug}>/dev/null
  fi
}

setup() {
  trap cleanup SIGHUP SIGINT SIGTERM EXIT
  set_descriptors
}

run() {
  :
}

parse_options() {
  # exit if no options left
  [[ -z $1 ]] && return 0
  log "parse \$1: $1" 2>&$fddebug

  local do_shift=0
  case $1 in
      -)
        if ! (($singleton)); then
          singleton=1
          return 9
        fi
        error_exit 5 "stdin is not allowed inside config."
        ;;
      -f|--flush)
        flush_all
        exit 0
	;;
      -v|--verbose)
	enable_verbose=1
	;;
      -q|--quiet)
        enable_quiet=1
        ;;
      -d|--debug)
        enable_debug=1
        ;;
      --)
        do_shift=3
        ;;
      -*)
        usage
        error_exit 5 "$1 is not allowed."
	;;
      *)
        do_shift=1
	;;
  esac
  if (($do_shift == 1)) ; then
    args+=("$1")
  elif (($do_shift == 2)) ; then
    # got option with argument
    shift
  elif (($do_shift == 3)) ; then
    # got --, use all arguments left for rsync to process
    shift
    options+=("$@")
    return
  fi
  shift
  parse_options "$@"
}

cleanup() {
  trap - SIGHUP SIGINT SIGTERM EXIT

  exit 0
}

block_spoof() {
  # Drop packet that claiming from our own server on WAN port
  $IPTABLES_BIN -A INPUT -i $INTERFACE_INC -s $SERVER_IP -j $ACTION
  $IPTABLES_BIN -A OUTPUT -o $INTERFACE_INC -s $SERVER_IP -j $ACTION
   
  # Drop packet that claiming from our own internal LAN on WAN port
  $IPTABLES_BIN -A INPUT -i $INTERFACE_INC -s $LAN_RANGE -j $ACTION
  $IPTABLES_BIN -A OUTPUT -o $INTERFACE_INC -s $LAN_RANGE -j $ACTION
   
  ## Drop all spoofed 
  for ip in $SPOOF_IPS; do
    $IPTABLES_BIN -A INPUT -i $INTERFACE_INC -s $ip -j $ACTION
    $IPTABLES_BIN -A OUTPUT -o $INTERFACE_INC -s $ip -j $ACTION
  done
}

flush_all() {
  $IPTABLES_BIN -P INPUT ACCEPT
  $IPTABLES_BIN -P FORWARD ACCEPT
  $IPTABLES_BIN -P OUTPUT ACCEPT
  $IPTABLES_BIN -F
  $IPTABLES_BIN -X
  $IPTABLES_BIN -t nat -F
  $IPTABLES_BIN -t nat -X
  $IPTABLES_BIN -t mangle -F
  $IPTABLES_BIN -t mangle -X
  $IPTABLES_BIN iptables -t raw -F
  $IPTABLES_BIN -t raw -X
}

prepare
main "$@"
