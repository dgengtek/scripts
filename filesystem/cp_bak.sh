#!/usr/bin/env bash

usage() {
  cat >&2 << EOF
Usage: ${0##*/} [<options>] <files>...
create <file>.bak copies

options:
  -r,--restore  Inverse bak - use supplied filename with .bak suffix to restore file
EOF
}

main() {
  # flags
  local -i enable_verbose=0
  local -i enable_quiet=0
  local -i enable_debug=0
  local -i restore=0

  local -a options
  local -a args

  check_dependencies
  # parse input args 
  parse_options "$@"
  # set leftover options parsed local input args
  set -- "${args[@]}"
  # remove args array
  unset -v args
  check_input_args "$@"

  set_signal_handlers
  prepare_env
  pre_run
  run "$@"
  post_run 
  unset_signal_handlers
}

################################################################################
# script internal execution functions
################################################################################

run() {
  if (($restore)); then
    _restore "$@"
  else
    _bak "$@"
  fi
}

_bak() {
  local filename=
  local backup_file=
  while [[ -n $1 ]]; do
    filename=$1
    backup_file="${filename}.bak"
    mv "$filename" "$backup_file"
    cp -r "$backup_file" "$filename"
    shift
  done
}

_restore() {
  local filename=
  local backup_file=
  while [[ -n $1 ]]; do
    filename=$1
    backup_file="${filename}.bak"
    shift
    if ! [[ -f "$backup_file" ]]; then
      echo "Backup .bak of $filename does not exist." >&2
      continue
    fi
    cp -r "$backup_file" "$filename"
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
  set_descriptors
}

prepare() {
  export PATH_USER_LIB=${PATH_USER_LIB:-"$HOME/.local/lib/"}

  set -e
  source_libs
  set +e

  set_descriptors
}

source_libs() {
  source "${PATH_USER_LIB}libutils.sh"
  source "${PATH_USER_LIB}libcolors.sh"
}

set_descriptors() {
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

set_signal_handlers() {
  trap sigh_abort SIGABRT
  trap sigh_alarm SIGALRM
  trap sigh_hup SIGHUP
  trap sigh_cont SIGCONT
  trap sigh_usr1 SIGUSR1
  trap sigh_usr2 SIGUSR2
  trap sigh_cleanup SIGINT SIGQUIT SIGTERM EXIT
}

unset_signal_handlers() {
  trap - SIGABRT
  trap - SIGALRM
  trap - SIGHUP
  trap - SIGCONT
  trap - SIGUSR1
  trap - SIGUSR2
  trap - SIGINT SIGQUIT SIGTERM EXIT
}

pre_run() {
  :
}
post_run() {
  :
}

parse_options() {
  # exit if no options left
  [[ -z $1 ]] && return 0
  log "parse \$1: $1" 2>&$fddebug

  local do_shift=0
  case $1 in
      -d|--debug)
        enable_debug=1
        ;;
      -v|--verbose)
	enable_verbose=1
	;;
      -q|--quiet)
        enable_quiet=1
        ;;
      -h|--help)
        usage
        exit 0
        ;;
      -r|--restore)
        restore=1
        ;;
      -p|--path)
        path=$2
        do_shift=2
        ;;
      --)
        do_shift=3
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
    # got --, use all arguments left as options for other commands
    shift
    options+=("$@")
    return
  fi
  shift
  parse_options "$@"
}

sigh_abort() {
  trap - SIGABRT
}

sigh_alarm() {
  trap - SIGALRM
}

sigh_hup() {
  trap - SIGHUP
}

sigh_cont() {
  trap - SIGCONT
}

sigh_usr1() {
  trap - SIGUSR1
}

sigh_usr2() {
  trap - SIGUSR2
}

sigh_cleanup() {
  trap - SIGINT SIGQUIT SIGTERM EXIT
  local active_jobs=$(jobs -p)
  for p in $active_jobs; do
    if [[ -e "/proc/$p" ]]; then
      kill "$p" >/dev/null 2>&1
      wait "$p"
    fi
  done
}

################################################################################
# custom functions
#-------------------------------------------------------------------------------
# add here
example_function() {
  :
}
_example_command() {
  :
}

#-------------------------------------------------------------------------------
# end custom functions
################################################################################

prepare
main "$@"
