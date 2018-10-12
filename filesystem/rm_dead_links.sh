#!/usr/bin/env bash

usage() {
  cat >&2 << EOF
Usage: ${0##*/} <path>
remove all dead links in <path>
EOF
}

main() {
  find "${1:?No path supplied}" -xtype l -exec rm -vI {} +; 
}

main "$@"
