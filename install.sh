#!/bin/env bash
usage() {
  cat >&2 << EOF
Usage:	${0##*/} [OPTIONS] [<configuration file>]]
  
OPTIONS:
  -h			  help
EOF
}
main() {
  echo "Install scripts"

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
  trap cleanup SIGINT SIGTERM
  local installer="tools/install.py"
  ! hash "$installer" && echo "Could not find $installer in PATH." && exit 1

  local setup_config="setup.ini"
  [[ -n $1 ]] && setup_config=$1

  python3 "$installer" "$setup_config"
}
cleanup() {
  trap - SIGINT SIGTERM
  exit 1
}
prepare() {
  mkdir -p .local/{bin,lib}
}
mkdir() {
  ! [[ -e $1 ]] && command mkdir "$@"
}

main "$@"

