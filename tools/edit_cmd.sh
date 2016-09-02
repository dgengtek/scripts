#!/bin/bash
usage() {
  echo -e "usage:\n\t${0##*/} \
   cmd"
  echo -e "\tcmd,\tedit the specific command"
}
main() {
  if [ -z $1 ]; then
    usage;
  fi

  cmd=$1
  path=$(type $cmd | cut -f 3 -d " ")

  if [[ $path == "" ]]; then
    echo "$cmd not found" >&2 
    exit 1
  fi

  vim $path
}

main "$@"

