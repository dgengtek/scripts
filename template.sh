#!/bin/env bash
usage() {
  cat << EOF
usage:	${0##*/} option1 option2 target destination
  
  options:
    -h			  help

  option1		  description
EOF
  exit 1
}
main() {
  echo "Script template"

  local -r optlist=":abcdefgh"
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

