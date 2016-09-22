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
log() {
  echo -n "$@" | logger -s -t ${0##*/}
}
error_exit() {
  exit_code=${1:-0}
  shift
  log "$@"
  exit $error_code
}
ord() {
  printf "%d" "'$1"
}
chr() {
  printf \\$(printf '%03o' $1)
}
