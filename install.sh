#!/bin/env bash
usage() {
  cat >&2 << EOF
Usage:	${0##*/} [OPTIONS] [<pystow path> [<configuration file>]]
  
OPTIONS:
  -h			  help
EOF
}
main() {
  echo "Install dotfiles"

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
  trap cleanup SIGINT SIGTERM SIGKILL
  local path_pystow="tools/pystow.py"
  local setup_config="setup.ini"
  [[ -n $1 ]] && path_pystow=$1 && [[ -n $2 ]] && setup_config=$2

  #setup_config="setup.yaml"
  if ! [[ -f $path_pystow ]]; then
    usage
    exit 1
  fi
  python "$path_pystow" "$setup_config"
}
cleanup() {
  trap - SIGINT SIGTERM SIGKILL
  exit 1
}

main "$@"
