#!/bin/env bash
usage() {
  cat >&2 << EOF
Usage:	${0##*/} [OPTIONS] (FILENAME | URL...)

OPTIONS:
  -v
  -d
  -q
  -m,--media        download media with youtube-dl
EOF
}
main() {
  check_dependencies

  local -i enable_verbose=0
  local -i enable_quiet=0
  local -i enable_debug=0
  local -i download_media=0


  trap cleanup SIGINT SIGTERM
  prepare

  local -a options=
  local -a args=
  # parse input args 
  parse_options "$@"
  # set leftover options parsed local input args
  set -- ${args[@]}
  # remove args array
  unset -v args
  check_input_args "$@"


  local -r failed_links="failed_downloads_$RANDOM"
  local -i success=0
  local -i failures=0
  local downloader="curl -O -J -L -C -"

  setup
  run "$@"

}
check_dependencies() {
  :
}
check_input_args() {
  if [[ -z $1 ]]; then
    usage
    exit 1
  fi
}
prepare() {
  [[ -f ${MYLIBS}libutils.sh ]] && source "${MYLIBS}libutils.sh"

}
setup() {
  (($download_media)) && downloader="youtube-dl"
}
run() {
  if [[ -f $1 ]]; then
    process_file "$1"
  elif [[ -n $1 ]]; then
    process_urls "$@"
  fi
  cat << EOF
Processed from $@
  success: $success
  failures: $failures
  total: $(($success + $failures))
EOF
  (($failures)) && echo "Failures saved in $failed_links."
}
parse_options() {
  # exit if no options left
  [[ -z $1 ]] && return 0
  log "parse \$1: $1" 2>&$fddebug

  local do_shift=0
  case $1 in
      -)
        if ! (($singleton)); then
          singleton=1
          return 9
        fi
        error_exit 5 "stdin is not allowed inside config."
        ;;
      -v|--verbose)
	enable_verbose=1
	;;
      -q|--quiet)
        enable_quiet=1
        ;;
      -d|--debug)
        enable_debug=1
        ;;
      -m|--media)
        download_media=1
        ;;
      --)
        do_shift=3
        ;;
      -*)
        usage
        error_exit 5 "$1 is not allowed."
	;;
      *)
        do_shift=1
	;;
  esac
  if (($do_shift == 1)) ; then
    args+=("$1")
  elif (($do_shift == 2)) ; then
    # got option with argument
    shift
  elif (($do_shift == 3)) ; then
    # got --, use all arguments left for rsync to process
    shift
    options+=("$@")
    return
  fi
  shift
  parse_options "$@"
}
process() {
  local -r input=$1
  echo_e "${BLUE_BG}URL read - $input${COLOR_NONE}"
  $downloader "$input"
  if [[ $? == 0 ]]; then
    echo_e "${GREEN}Successfull download.${COLOR_NONE}"
    success=$(($success + 1))
  else
    echo_e "${RED}Failed download of ${input}${COLOR_NONE}" >&2
    echo "$input" >> "$failed_links"
    failures=$(($failures + 1))
  fi
}
process_file() {
  local -r file=$1
  while read -r line; do
    process "$line"
  done < "$file"
}
process_urls() {
  IFS=" "
  while [[ -n $1 ]]; do
    process "$1"
    shift
  done
}

cleanup() {
  trap - SIGINT SIGTERM
  exit 1
}
main "$@"
