#!/usr/bin/env bash
# ------------------------------------------------------------------------------
# wrapper script
# screenshot with maim
# ------------------------------------------------------------------------------

usage() {
  cat >&2 << EOF
Usage:	${0##*/}
  
OPTIONS:
  -h			  help
  -m,--move  move screenshot to directory
  -s,--select  selection region to screenshot
  -w,--window  select window to screenshot
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
  local -i select_region=0

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
  trap - SIGHUP SIGINT SIGTERM EXIT
}

check_dependencies() {
  { 
    ! hash maim || ! hash slop 
  } && exit 1
}

check_input_args() {
  if (($select_region)) && (($capture_window)); then
    echo "Cannot select region and window." >&2
    exit 1
  fi
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
  local -r date_iso="date +%Y%m%dT%H%M%S%z"
  local -a maim_args=("--format=png")
  if (($select_region)); then
    maim_args+=("-s")
  else
    # sleep if no manually selection
    sleep 1
  fi
  if (($capture_window)); then
    maim_args+=("--window=$(xdotool getactivewindow)")
  fi

  if (($move_screenshot)); then
    maim_args+=("/mnt/nfs/homes/dgeng/screenshots/$($date_iso).png")
  else
    maim_args+=("$HOME/$($date_iso).png")
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
      -s|--select)
	select_region=1
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
