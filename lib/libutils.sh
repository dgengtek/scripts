#!/bin/env bash
print_chars() {
  usage=$(cat << EOF
usage $0 char count
  default count of 10
EOF
  )
  if [[ -z $1 ]]; then
    echo "$usage"
    exit 1
  fi
  local -i count=10
  if [[ -n $2 ]]; then
    count=$2
  fi
  printf '=%.0s' {1..$count}
}

top_temperature() {
while : ; do
  /usr/bin/clear
  /usr/bin/sensors
  /usr/bin/sleep 1.5
done
}

loop_cmd() {
while : ; do
  /usr/bin/clear
  eval "$@"
  /usr/bin/sleep 1.5
done
}
