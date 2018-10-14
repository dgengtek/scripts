#!/usr/bin/env bash

usage() {
cat >&2 << EOF
Usage: ${0##*/}
run a command in a new window while remaining on exit
EOF
}

main() {
  if ! hash run.sh; then
    echo "Could not find run.sh in path." >&2
    exit 1
  fi
  local -r window_name="window$RANDOM"
  tmux neww -d -n "$window_name" "run.sh -m -f -- '$*'"
  tmux setw -t "$window_name" remain-on-exit on
}

main "$@"
