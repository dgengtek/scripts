#!/usr/bin/env bash

usage() {
cat >&2 << EOF
Usage: ${0##*/}
display host information
EOF
}

main() {
  printf "CPU: "
  grep "model name" /proc/cpuinfo | head -1 | awk '{ for (i = 4; i <= NF;i++) printf "%s ", $i }'
  echo
  cat /etc/issue
  uname -a | awk '{ printf "Kernel: %s " , $3 }'
  uname -m | awk '{ printf "%s | " , $1 }'
  echo
  uptime | awk '{ printf "Uptime: %s %s %s", $3, $4, $5 }' | sed 's/,//g'
  echo
  who -b
  who -q
  who | head -n 2
  sensors | grep Core | head -1 | awk '{ printf "%s %s %s\n", $1, $2, $3 }'
  sensors | grep Core | tail -1 | awk '{ printf "%s %s %s\n", $1, $2, $3 }'
  #cputemp | awk '{ printf "%s %s", $1 $2 }'

}

main "$@"
