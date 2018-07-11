#!/usr/bin/env bash
usage() {
  cat >&2 << EOF
Usage:	${0##*/} [OPTIONS] <path of file>

remove file completly from git repository

OPTIONS:
  -r			  recursive
  -h			  help
  -v			  verbose
  -q			  quiet
  -d			  debug
EOF
}

main() {
  # flags
  local -i enable_verbose=0
  local -i enable_quiet=0
  local -i enable_debug=0

  local -a options
  local -a args

  local -i recursive=0

  check_dependencies
  # parse input args 
  parse_options "$@"
  # set leftover options parsed local input args
  set -- ${args[@]}
  # remove args array
  unset -v args
  check_input_args "$@"

  prepare_env
  set_signal_handlers
  setup
  run "$@"
  unset_signal_handlers
}

################################################################################
# script internal execution functions
################################################################################

run() {
  local -r path=$1
  shift 

  if (($recursive)); then
    cmd_git_rm="git -r rm --cached --ignore-unmatch" 
  else
    cmd_git_rm="git rm --cached --ignore-unmatch" 
  fi
  git filter-branch --force --index-filter \
    "$cmd_git_rm '$path'" \
    --prune-empty --tag-name-filter cat -- --all \
  git_garbage_collect.sh
}

check_dependencies() {
  if ! hash git_garbage_collect.sh >/dev/null 2>&1; then
    error 1 "git_garbage_collect.sh not found"
  fi
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

setup() {
  set_descriptors
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
      -r|--recursive)
        recursive=1
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
    if ps -p $p >/dev/null 2>&1; then
      kill -SIGINT $p >/dev/null 2>&1
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
