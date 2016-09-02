#!/bin/env bash
usage() {
    echo "no arguments to start a command in background" >&2
    exit 1
}
main() {
  if [ -z "$1" ]; then
    usage
  fi

  cmd=("$@")
  cmdstring=$(echo "$cmd" | cut -f1 -d ' ')

  logfile="/dev/null"

  $("${cmd[@]}" &> $logfile) &
  cmd_pid=$!
}

main "$@"
