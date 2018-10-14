#!/usr/bin/env bash

usage() {
cat >&2 << EOF
Usage: ${0##*/}
update pip packages
EOF
}

main() { 
  pip install --user -U $(pip list | awk '{print $1;}')
}

main "$@"
