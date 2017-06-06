#!/bin/env bash
pad_line() {
  usage=$(cat << EOF
Usage: $FUNCNAME [count]
  default count of 10
EOF
  )
  local -i count=${2:-10}
  printf '#%.0s' {1..$count}
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

log() { echo "$@" | logger -s -t ${0##*/}; }
out() { echo "$1 $2" "${@:3}"; }

error() { log "==> ERROR:" "$@"; } >&2
ignore_error() { log "$@" 2>/dev/null; }

msg() { log "==>" "$@"; }
msg2() { log "  ->" "$@";}

error_exit() {
  error_code=$1
  shift
  log "$@"
  exit $error_code
}
die() { error_exit 1 "$@"; }
