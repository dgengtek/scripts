#!/bin/env bash
# add following to /etc/sysctl.conf
#
# net.ipv4.conf.all.rp_filter=1
# net.ipv4.conf.all.log_martians=1
# net.ipv4.conf.default.log_martians=1
# TODO add iptables.rules file for temporary storage of all rules
# TODO append all rules to file and use at the end iptables restore to active
# TODO allow debug mode where no rules are applied only sent to output

usage() {
  cat << EOF
Usage:	${0##*/} [OPTIONS] target destination
  
OPTIONS:
  -h			  help
  option1		  description
EOF
  exit 1
}
main() {
  INTERFACE_INC="eth1" # connected to internet 
  SERVER_IP="202.54.10.20" # server IP
  LAN_RANGE="192.168.1.0/24" # your LAN IP range 
  IPTABLES_BIN="/usr/bin/iptables" # path to iptables

  echo "Script template"

  local -r optlist="abcdefgh"
  while getopts $optlist opt; do
    case $opt in
      a)
	;;
      b)
	;;
      *)
	usage
	;;
    esac
  done
  shift $((OPTIND - 1))


}
block_spoof() {
   
  # Add your spoofed IP range/IPs here
  SPOOF_IPS="0.0.0.0/8 127.0.0.0/8 10.0.0.0/8 172.16.0.0/12 192.168.0.0/16 224.0.0.0/3"
   
   
  # default action, can be DROP or REJECT 
  ACTION="DROP"
   
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
main "$@"
