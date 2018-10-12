#!/usr/bin/env bash

usage() {
cat >&2 << EOF
Usage: ${0##*/}
remove all timestamps for all users
EOF
}


main() {
  local -r sudo_timestamp_path="/run/sudo/ts"
  [[ -d $sudo_timestamp_path ]] || return 1
  while read -r line; do
    sudo rm -v "$line"
  done < <(sudo find "$sudo_timestamp_path" -type f)
}

main "$@"
