#!/usr/bin/env bash

usage() {
cat >&2 << EOF
Usage: ${0##*/} [<bytesize>]
generate random base64 digits
EOF
}

main() { 
  # each base64 digit represents exactly 6 bits of data
  dd if=/dev/urandom count=1 bs="${1:-32}" 2>/dev/null | base64 -w 0
}

main "$@"
