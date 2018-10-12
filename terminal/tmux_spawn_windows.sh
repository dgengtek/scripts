#!/usr/bin/env bash
# ------------------------------------------------------------------------------
# description
# ------------------------------------------------------------------------------
# 

usage() {
cat >&2 << EOF
Usage: ${0##*/} <window count>
spawn # count of windows in current tmux session
EOF
}

main() {
  if [[ -z $1 ]]; then
    usage
    exit 1
  fi
  local -r count=$1
  shift
  local cmd=
  for i in $(seq $count); do
    tmux new-window -d &
  done
  wait
}

main "$@"
