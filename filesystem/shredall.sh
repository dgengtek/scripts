#!/usr/bin/env bash
set -eu
main() {
  shredall "$@"
}

shredall() {
  #shred all files recursively inside directory
  local -r path=$1
  if ! [[ -d $path ]]; then
    echo "No path supplied or is not a directory." >&2
    return 1
  fi
  echo "Shredding all of $path." >&2
  find "$path" -type f -print0 | parallel -0 shred -uvz
  rm -I -rf "${path}"
}
main "$@"
