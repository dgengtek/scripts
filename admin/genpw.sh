#!/bin/env bash
usage() {
  cat << EOF
Usage:  ${0##*/} [options] [length]
  
generate password

options:
  -a            alphanumeric
  -g            (default)all printable characters, excluding space
EOF
}
main() {
  local -r optlist=":ag"
  local charset="graph"
  while getopts $optlist opt; do
    case $opt in
      a)
        charset="alnum"
	;;
      g)
        charset="graph"
	;;
      *)
        usage
        exit 1
	;;
    esac
  done
  length=${1:-8}
  tr -cd [:"$charset":] < /dev/urandom | head -c "$length" | xargs -0
}

main "$@"
