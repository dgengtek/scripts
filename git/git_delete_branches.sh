#!/usr/bin/env bash
# ------------------------------------------------------------------------------
# utility for removing branches easily
# ------------------------------------------------------------------------------
# 
set -u # error on unset variables or parameters
set -e # exit on unchecked errors
set -b # report status of background jobs
# set -m # monitor mode - enable job control
# set -n # read commands but do not execute
# set -p # privileged mode - constrained environment
# set -v # print shell input lines
# set -x # expand every command
set -o pipefail # fail on pipe errors
# set -C # bash does not overwrite with redirection operators

declare -i ENABLE_VERBOSE=0
declare -i ENABLE_QUIET=0
declare -i ENABLE_DEBUG=0
readonly GIT_TRUNK=${GIT_TRUNK:-"master"}

usage() {
  cat >&2 << EOF
Usage: ${0##*/} [OPTIONS] [branch name]

Delete branches except trunk(master)

OPTIONS:
  -h  help
  -v  verbose
  -q  quiet
  -r,--remove-remote  remove remote branch
  -l,--remove-local  remove local branch
  -a,--all  remove all(filter with -r or -l exclusive or all if no other flag)
  -d  debug
EOF
}



main() {
  local -a options
  local -a args
  local -i remove_all=0
  local -i remove_branch_remote=0
  local -i remove_branch_local=0

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
  local branch=${1:-""}
  local cmd_delete_branch=""

  set +u
  if (($branch_local)) && (($branch_remote)); then
    echo "ERROR: Cannot handle both flags" >&2
    usage
    exit 1
  elif (($branch_local)); then
    if (($remove_all)); then
      cmd_delete_branch=run_delete_all_local
    else
      cmd_delete_branch=run_delete_local_branch
    fi
  elif (($branch_remote)); then
    if (($remove_all)); then
      cmd_delete_branch=run_delete_all_remote
    else
      cmd_delete_branch=run_delete_remote_branch
    fi
  elif (($remove_all)); then
    run_delete_all_remote
    run_delete_all_local
    return
  fi
  set -u
  if [[ -z "$cmd_delete_branch" ]]; then
    echo "ERROR: No command set." >&2
    usage
    exit 1
  fi
  $cmd_delete_branch "$branch"
}


run_delete_all_local() {
  while read branch; do
    branch=$(echo "$branch" | tr -d '*\n ')
    if [[ $branch == "$GIT_TRUNK" ]]; then
      continue
    fi
    run_delete_local_branch "$branch"
  done < <(git branch -l)
}


run_delete_all_remote() {
  while read branch; do
    branch=$(echo "$branch" | tr -d '\n ')
    branch=${branch##*/}
    if [[ $branch == "$GIT_TRUNK" ]]; then
      continue
    fi
    run_delete_remote_branch "$branch"
  done < <(git branch -r)
}


run_delete_local_branch() {
  git branch -d "$1"
}


run_delete_remote_branch() {
  git push origin --delete "$1"
}


check_dependencies() {
  :
}


check_input_args() {
  :
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
  set -u
}


source_libs() {
  source "${PATH_USER_LIB}libutils.sh"
  source "${PATH_USER_LIB}libcolors.sh"
}


set_descriptors() {
  if (($ENABLE_VERBOSE)); then
    exec {fdverbose}>&2
  else
    exec {fdverbose}>/dev/null
  fi
  if (($ENABLE_DEBUG)); then
    set -xv
    exec {fddebug}>&2
  else
    exec {fddebug}>/dev/null
  fi
}


pre_run() {
  :
}


post_run() {
  :
}


parse_options() {
  # exit if no options left
  [[ -z ${1:-""} ]] && return 0
  log "parse \$1: $1" 2>&$fddebug

  local do_shift=0
  case $1 in
      -d|--debug)
        ENABLE_DEBUG=1
        ;;
      -v|--verbose)
	ENABLE_VERBOSE=1
	;;
      -q|--quiet)
        ENABLE_QUIET=1
        ;;
      -a|--all)
        remove_all=1
        ;;
      -r|--remove-remote)
        branch_remote=1
        ;;
      -l|--remove-local)
        branch_local=1
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


################################################################################
# signal handlers
#-------------------------------------------------------------------------------


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
