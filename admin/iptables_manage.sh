#!/bin/env bash
# ------------------------------------------------------------------------------
# description
# ------------------------------------------------------------------------------
# 
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
  -p, --panic             panic mode, only ssh
  -q			  quiet
  -d			  debug
EOF
}

main() {
  local -r INTERFACE_INC="eth1" # connected to internet 
  local -r SERVER_IP="202.54.10.20" # server IP
  local -r LAN_RANGE="192.168.1.0/24" # your LAN IP range 
  local -r IPTABLES_BIN="/usr/bin/iptables" # path to iptables

  local -r sysctl_file="90-firewall.conf"

  # Add your spoofed IP range/IPs here
  # RFC 1918
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
  DEFAULT_CHAIN_ACTION="DROP"


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
default_CHAINS() {
  $IPTABLES_BIN -N TCP
  $IPTABLES_BIN -N UDP

}
default_POLICY() {
  $IPTABLES_BIN -P INPUT "$DEFAULT_CHAIN_ACTION"
  $IPTABLES_BIN -P FORWARD "$DEFAULT_CHAIN_ACTION"
  $IPTABLES_BIN -P OUTPUT ACCEPT
}

add_kernel_parameters() {
  local -ar kernel_options=(
  "net.ipv4.conf.all.log_martians=1"
  "net.ipv4.conf.default.log_martians=1"
  )
  if [[ -f "/etc/sysctl.d/$sysctl_file" ]]; then
    :
  fi
}

default_BLOCKS() {

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
default_ACCEPT() {
  $IPTABLES_BIN -A INPUT -m conntrack --ctstate RELATED,ESTABLISHED -j ACCEPT
  $IPTABLES_BIN -A INPUT -i lo -j ACCEPT
  $IPTABLES_BIN -A INPUT -p udp -m conntrack --ctstate NEW -j UDP
  $IPTABLES_BIN -A INPUT -p tcp --syn -m conntrack --ctstate NEW -j TCP

  $IPTABLES_BIN -A INPUT -p udp -j REJECT --reject-with icmp-port-unreachable
  $IPTABLES_BIN -A INPUT -p tcp -j REJECT --reject-with tcp-reset


  $IPTABLES_BIN -A TCP -p tcp --dport 80 -j ACCEPT
  $IPTABLES_BIN -A TCP -p tcp --dport 443 -j ACCEPT
  $IPTABLES_BIN -A TCP -p tcp --dport 22 -j ACCEPT
  $IPTABLES_BIN -A TCP -p tcp --dport 53 -j ACCEPT
  $IPTABLES_BIN -A UDP -p udp --dport 53 -j ACCEPT

  $IPTABLES_BIN -t raw -I PREROUTING -m rpfilter --invert -j DROP

# syn scans
  $IPTABLES_BIN -I TCP -p tcp -m recent --update --seconds 60 --name TCP-PORTSCAN -j REJECT --reject-with tcp-reset
  $IPTABLES_BIN -D INPUT -p tcp -j REJECT --reject-with tcp-reset
  $IPTABLES_BIN -A INPUT -p tcp -m recent --set --name TCP-PORTSCAN -j REJECT --reject-with tcp-reset

# udp scans
  $IPTABLES_BIN -I UDP -p udp -m recent --update --seconds 60 --name UDP-PORTSCAN -j REJECT --reject-with icmp-port-unreachable
  $IPTABLES_BIN -D INPUT -p udp -j REJECT --reject-with icmp-port-unreachable
  $IPTABLES_BIN -A INPUT -p udp -m recent --set --name UDP-PORTSCAN -j REJECT --reject-with icmp-port-unreachable

  $IPTABLES_BIN -A INPUT -j REJECT --reject-with icmp-proto-unreachable
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
  flush_all
  block_spoof
  default_POLICY
  default_CHAINS
  default_BLOCKS
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
      -p|--panic)
        panic
        exit 0
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
  # TODO add to only wan interface
  return 0
  # Reject spoofed packets
  $IPTABLES_BIN -A INPUT -s 10.0.0.0/8 -j DROP
  $IPTABLES_BIN -A INPUT -s 169.254.0.0/16 -j DROP
  $IPTABLES_BIN -A INPUT -s 172.16.0.0/12 -j DROP
  $IPTABLES_BIN -A INPUT -s 127.0.0.0/8 -j DROP

  $IPTABLES_BIN -A INPUT -s 224.0.0.0/4 -j DROP
  $IPTABLES_BIN -A INPUT -d 224.0.0.0/4 -j DROP
  $IPTABLES_BIN -A INPUT -s 240.0.0.0/4 -j DROP
  $IPTABLES_BIN -A INPUT -d 240.0.0.0/4 -j DROP
  $IPTABLES_BIN -A INPUT -s 0.0.0.0/8 -j DROP
  $IPTABLES_BIN -A INPUT -d 0.0.0.0/8 -j DROP
  $IPTABLES_BIN -A INPUT -d 239.255.255.0/24 -j DROP
  $IPTABLES_BIN -A INPUT -d 255.255.255.255 -j DROP
}

flush_all() {
  $IPTABLES_BIN -P INPUT ACCEPT
  $IPTABLES_BIN -P FORWARD ACCEPT
  $IPTABLES_BIN -P OUTPUT ACCEPT

  $IPTABLES -t nat -P PREROUTING ACCEPT
  $IPTABLES -t nat -P POSTROUTING ACCEPT
  $IPTABLES -t nat -P OUTPUT ACCEPT

  $IPTABLES -t mangle -P PREROUTING ACCEPT
  $IPTABLES -t mangle -P POSTROUTING ACCEPT
  $IPTABLES -t mangle -P INPUT ACCEPT
  $IPTABLES -t mangle -P OUTPUT ACCEPT
  $IPTABLES -t mangle -P FORWARD ACCEPT

  $IPTABLES_BIN -F
  $IPTABLES_BIN -t nat -F
  $IPTABLES_BIN -t mangle -F
  $IPTABLES_BIN -t raw -F

  $IPTABLES_BIN -X
  $IPTABLES_BIN -t nat -X
  $IPTABLES_BIN -t mangle -X
  $IPTABLES_BIN -t raw -X
}
panic() {
  flush_all
  $IPTABLES_BIN -A INPUT -p tcp --dport 22 --syn -m conntrack --ctstate NEW -j ACCEPT
  $IPTABLES_BIN -A OUTPUT -p tcp --sport 22 -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT
  $IPTABLES_BIN -P INPUT DROP
  $IPTABLES_BIN -P FORWARD DROP
  $IPTABLES_BIN -P OUTPUT DROP
}

prepare
main "$@"
