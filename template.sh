#!/bin/env bash
usage() {
  cat << EOF
Usage:	${0##*/} [OPTIONS] target destination
  
OPTIONS:
  -h			  help
  option1		  description
EOF
  exit 1
}
main() {
  echo "Script template"

  local -r optlist="abcdefgh"
  while getopts $optlist opt; do
    case $opt in
      a)
	;;
      b)
	;;
      *)
	usage
	;;
    esac
  done
  shift $((OPTIND - 1))
}

main "$@"
