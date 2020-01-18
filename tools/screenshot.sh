#!/usr/bin/env bash
# ------------------------------------------------------------------------------
# wrapper script
# screenshot with maim for awesome wm
# ------------------------------------------------------------------------------

usage() {
  cat >&2 << EOF
Usage:	${0##*/}
  
OPTIONS:
  -h			  help
EOF
}

main() {
  check_dependencies

  # flags
  local -i enable_verbose=0
  local -i enable_quiet=0
  local -i enable_debug=0
  #
  local -i capture_window=0
  local -i move_screenshot=0

  local -a options
  local -a args
  # parse input args 
  parse_options "$@"
  # set leftover options parsed local input args
  set -- ${args[@]}
  # remove args array
  unset -v args
  check_input_args "$@"

  setup
  run "$@"
}

check_dependencies() {
  { 
    ! hash maim || ! hash slop 
  } && exit 1
}

check_input_args() {
  :
}

prepare() {
  export PATH_USER_LIB="$HOME/.local/lib/"
  [[ -f ${PATH_USER_LIB}libutils.sh ]] && source "${PATH_USER_LIB}libutils.sh"
}

setup() {
  trap cleanup SIGHUP SIGINT SIGTERM EXIT

  if (($enable_verbose)); then
    exec {fdverbose}>&2
  else
    exec {fdverbose}>/dev/null
  fi
  if (($enable_debug)); then
    set -xv
    exec {fddebug}>&2
  else
    exec {fddebug}>/dev/null
  fi
}

run() {
  local -a maim_args=("--format=png")
  (($capture_window)) && maim_args+=("-i $(xdotool getactivewindow)")
  if (($move_screenshot)); then
    maim_args+=("/mnt/nfs/homes/dgeng/screenshots/$(date +%Y%m%d_%H%M%S.png)")
  else
    maim_args+=("$HOME/$(date +%Y%m%d_%H%M%S.png)")
  fi
  maim "${maim_args[@]}"
}

parse_options() {
  # exit if no options left
  [[ -z $1 ]] && return 0
  #log "parse \$1: $1" 2>&$fddebug

  local do_shift=0
  case $1 in
      -)
        if ! (($singleton)); then
          singleton=1
          return 9
        fi
        error_exit 5 "stdin is not allowed inside config."
        ;;
      -w|--window)
	capture_window=1
	;;
      -m|--move)
        move_screenshot=1
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

cleanup() {
  trap - SIGHUP SIGINT SIGTERM EXIT

  exit 1
}

prepare
main "$@"
