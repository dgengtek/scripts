#!/bin/env bash
usage() {
  cat << EOF
usage:  ${0##*/} [options] [length]
  
  generate password

options:
  -a        
      alphanumeric
  -g  
      (used by default)      
      all printable characters, excluding space

EOF
  exit 1
}
main() {
  local -r optslist="agh"
  local charset="graph"
  while getopts $optlist opt; do
    case $opt in
      a)
        charset="alnum"
	;;
      g)
        charset="graph"
	;;
      h)
        echo "$usage"
        exit 1
	;;
    esac
  done

  length=$1
  if [ -z "$length" ];then
    length=8
  fi

  tr -cd [:"$charset":] < /dev/urandom | head -c "$length" | xargs -0
}

main "$@"

