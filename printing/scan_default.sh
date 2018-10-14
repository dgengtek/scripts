#!/usr/bin/env bash
# ------------------------------------------------------------------------------
# description
# ------------------------------------------------------------------------------
# 

usage() {
  cat >&2 << EOF
Usage: ${0##*/} [<scan format>]

scan format - default:png
EOF
}

main() {
  local format=${1:-"png"}
  local -r scan_date=$(date +%y%m%d_%H%M%S_%N)
  scanimage -p "--format=$format" --resolution 300 -x 210 -y 297 > \
    "scanned_${scan_date}.${format}"
}

main "$@"
