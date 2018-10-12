#!/usr/bin/env bash

usage() {
  cat >&2 << EOF
Usage: ${0##*/} [OPTIONS] <command> [<arguments>] [-- [EXTRA]]
list available databases
EOF
}

main() {
  if [[ -z $1 ]]; then
    usage
    exit 1
  fi
  psql "$@" -q -A -t -c 'SELECT datname FROM pg_database'
}

main "$@"
