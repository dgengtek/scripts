#!/usr/bin/env bash

usage() {
  cat >&2 << EOF
Usage: ${0##*/} <path>
count inodes in <path>
EOF
}

main() {
  find "${1:?No path supplied.}" -xdev -printf '%h\n' | sort | uniq -c | sort -k 1 -n
}

main "$@"
