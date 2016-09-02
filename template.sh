#!/bin/bash
usage() {
  echo -e "usage:\n\t${0##*/} \
   option1 option2 target destination"
  echo -e "\toption1,\tdescription"
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

