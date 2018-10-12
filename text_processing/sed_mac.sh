#!/usr/bin/env bash
# ------------------------------------------------------------------------------
# replace 
# ------------------------------------------------------------------------------
# 

usage() {
  cat >&2 << EOF
Usage: ${0##*/} <mac> [<mac separator>] [<mac separator replacement>]

<mac separator> default is :
<mac separator replacement> default is ''
EOF
}

main() {
  if [[ -z $1 ]]; then
    usage
    exit 1
  fi
  local separator=${2:-:}
  local replace=${3:-''}
  echo "$1" | sed "s/$separator/$replace/g"
}

main "$@"
