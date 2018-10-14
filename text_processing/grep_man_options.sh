#!/usr/bin/env bash

usage() {
  cat >&2 << EOF
Usage: ${0##*/} [OPTIONS] <man command options>
grep for options of man result
EOF
}

main() {
  man "$@" | grep -A 4 -E "[ ]{2}+-.*"
}

main "$@"
