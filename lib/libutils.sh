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
ord() { printf "%d" "'$1"; }
chr() { printf \\$(printf '%03o' $1); }

echo() ( 
  IFS=" " 
  printf '%s\n' "$*"
)

echo_n() (
  IFS=" "
  printf %s "$*"
)

echo_e() (
  IFS=" "
  printf '%b\n' "$*"
)
out() { echo "$1 $2" "${@:3}"; }
error() { out "==> ERROR:" "$@"; } >&2
msg() { out "==>" "$@"; }
msg2() { out "  ->" "$@";}
ignore_error() { log "$@" 2>/dev/null; }
log() { echo "$@" | logger -s -t ${0##*/}; }
error_exit() {
  error_code=$1
  shift
  log "$@"
  exit $error_code
}
die() { error_exit 1 "$@"; }
