#!/bin/env bash

usage() {
  cat << EOF
Usage:  ${0##*/} [options] [length]
  
generate password

options:
  -a            alphanumeric
  -g            (default)all printable characters, excluding space
  -p            pin

EOF
}

main() {
  local -r optlist=":agp"
  local charset="graph"
  while getopts $optlist opt; do
    case $opt in
      a)
        charset="alnum"
	;;
      g)
        charset="graph"
	;;
      p)
        charset="digit"
	;;
      *)
        usage
        exit 1
	;;
    esac
  done
  shift $(($OPTIND - 1))
  length=${1:-8}

  display $length
}
display() {
  local length=${1:?"Length not set."}
  local columns=${2:-6}
  local rows=${3:-10}
  for i in $(seq $rows); do
    for j in $(seq $columns); do
      genpw $length
    done
    echo
  done

}
genpw() {
  local length=${1:?"Length not set."}
  pw=$(head -c "$length" /dev/urandom | tr -cd [:"$charset":] | xargs -0)
  printf "%b" "$pw"
  printf "    "
}

main "$@"
