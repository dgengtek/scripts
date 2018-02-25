#!/bin/env bash
# ------------------------------------------------------------------------------
# select a file interactively from supplied directory
# ------------------------------------------------------------------------------
# 

usage() {
  cat >&2 << EOF
Usage:	${0##*/} [OPTIONS] <path> -- [EXTRA]
  
OPTIONS:
  -h			  help
  -v			  verbose
  -q			  quiet
  -d			  debug

arg1
  mandatory argument passed to script

EXTRA
  Additional options passed for other purposes
EOF
}

select_files() {
  local input=
  if [[ -z $1 ]] || ! [[ -d $1 ]]; then
    cat >&2 << EOF
Usage: $FUNCNAME <path>
EOF
    return
  fi
  input=$(find -L $1 -type f)
  local -r OLDPS3=$PS3
  PS3="Your selection > "
  select selection in $input; do
    if [[ -n $selection ]]; then
      if echo $input | grep $selection &>/dev/null; then
        echo "$selection"
        break
      else
        echo "Selection invalid." >&2
      fi
    fi
  done
  PS3=$OLDPS3
}

main() {
  # flags
  local -i enable_verbose=0
  local -i enable_quiet=0
  local -i enable_debug=0

  local -a options=
  local -a args=

  check_dependencies
  # parse input args 
  parse_options "$@"
  # set leftover options parsed local input args
  set -- ${args[@]}
  # remove args array
  unset -v args
  check_input_args "$@"

  select_files "$@"

  prepare_env
  setup
  run
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

prepare_env() {
  :
}

prepare() {
  export PATH_USER_LIB="$HOME/.local/lib/"
  source "${PATH_USER_LIB}libutils.sh"
  source "${PATH_USER_LIB}libcolors.sh"
  set_descriptors
}

set_descriptors() {
  if (($enable_verbose)); then
    exec {fdverbose}>&1
  else
    exec {fdverbose}>/dev/null
  fi
  if (($enable_debug)); then
    set -xv
    exec {fddebug}>&1
  else
    exec {fddebug}>/dev/null
  fi
}

setup() {
  trap cleanup SIGINT SIGQUIT SIGABRT SIGTERM EXIT
  set_descriptors
}

run() {
  :
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

  exit 0
}

prepare
main "$@"
