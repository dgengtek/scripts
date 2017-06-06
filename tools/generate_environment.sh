#!/bin/env bash
# ------------------------------------------------------------------------------
# description
# ------------------------------------------------------------------------------
# 
usage() {
  cat >&2 << EOF
Usage:	${0##*/} [OPTIONS] <arg1> -- [EXTRA]

arg1
  mandatory argument passed to script
  
OPTIONS:
  -h			  help
  -v			  verbose
  -q			  quiet
  -d			  debug


EXTRA
  Additional options passed for other purposes
EOF
}

main() {
  # flags
  local -i enable_verbose=0
  local -i enable_quiet=0
  local -i enable_debug=0

  local -a options=
  local -a args=
  local path=

  check_dependencies
  # parse input args 
  parse_options "$@"
  # set leftover options parsed local input args
  set -- ${args[@]}
  # remove args array
  unset -v args
  check_input_args "$@"

  path=$1


  prepare_env
  setup
  pushd "$path"
  run
  popd
}

generate_files() {
  local line_count=
  local filename=
  local -r root_path=$1
  local -ir count=$2
  for c in $(seq $count); do
    filename=$(mktemp -u "$root_path/tmp.XXXXXXXXXX")
    line_count=$(shuf -i 10-100 -n 1)
    head -n "$line_count" /dev/urandom | tr -cd [:graph:] > "$filename"
  done
}

run() {
  local files_count=
  local -r DIR_COUNT=$(shuf -i 10-100 -n 1)
  local selected_random_dir=
  for d in $(seq $DIR_COUNT); do
    selected_random_dir=$(find . -not -path '*/\.*' -type d | shuf -n 1)
    mktemp -d "$selected_random_dir/dirXXXXXXXXXX"
    files_count=$(shuf -i 5-100 -n 1)
    generate_files "$selected_random_dir" "$files_count"
  done
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
  mkdir -p "$path"
}

prepare() {
  #export MYLIBS="$HOME/.local/lib/"

  set -e
  source_libs
  set +e

  set_descriptors
}

source_libs() {
  source "${MYLIBS}libutils.sh"
  source "${MYLIBS}libcolors.sh"
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
