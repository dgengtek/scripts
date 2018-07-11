#!/usr/bin/env bash
usage() {
  cat >&2 << EOF
Usage: ${0##*/} <cmd>
  cmd     edit the specific command
EOF
}
main() {
  if [[ -z $1 ]]; then
    usage
    exit 1
  fi

  local -r cmd=$1
  local -r path=$(type "$cmd" | awk '{print $3}')

  if [[ -z $path ]]; then
    echo "$cmd not found." >&2 
    exit 1
  fi

  $EDITOR $path
}

main "$@"

