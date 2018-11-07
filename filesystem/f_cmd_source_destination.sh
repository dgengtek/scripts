#!/usr/bin/env bash
# ------------------------------------------------------------------------------
# utility for selecting files to easily cp or mv
# ------------------------------------------------------------------------------
# 

usage() {
  cat >&2 << EOF
Usage: ${0##*/} <cmd> <destination> [<source path>] [-- [cmd args...]]

Works only with commands which use SOURCE and DESTINATION as arguments, like cp, mv

Does not work with interactive commands since the command will run in the background.

cmd  A command like cp, mv
destination  destination path to move selections to
source path  source path to get selections from[default: .]
cmd args  Arguments to pass to the cmd
EOF
}

main() {
  # flags
  local -i enable_verbose=0
  local -i enable_quiet=0
  local -i enable_debug=0

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
  local -r CMD=$1
  if ! hash $CMD; then
    echo "The cmd $CMD could not be found." >&2
    exit 1
  fi
  local -r destination_path=$2
  local -r source_path=${3:-"."}
  if ! [[ -d $destination_path ]]; then
    echo "Destination path is not a directory or does not exist." >&2
    exit 1
  fi
  if ! [[ -d $source_path ]]; then
    echo "Source path is not a directory or does not exist." >&2
    exit 1
  fi
  shift 3
  cat >&2 << EOF
Running with inputs:
  CMD [OPTIONS] SOURCE DESTINATION
  $CMD ${options[@]} $source_path $destination_path
EOF
  f_cmd_run "$@"
  wait
  echo "Done." >&2
}

f_cmd_run() {
  local -i counts=0
  while read -d $'\0' result; do
    let counts+=1
    echo "$CMD ${options[*]} $result $destination_path/" >&2
    ($CMD "${options[@]}" "$result" "$destination_path/" &)
  done < <(find "$source_path" -print0 2>/dev/null | fzf-tmux --height 50% --read0 --print0 --multi)
  if (($counts >= 1)); then
    f_cmd_run "$destination_path" "$source_path"
  fi
  wait
}

check_dependencies() {
  :
}

check_input_args() {
  if [[ -z $1 ]] || [[ -z $2 ]]; then
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
