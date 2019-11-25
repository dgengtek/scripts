#!/usr/bin/env bash
# use trunk based development instead! do not use this
# only commit to trunk
# short lived branches
# never break build on trunk
# ------------------------------------------------------------------------------

usage() {
  cat >&2 << EOF
Usage:	${0##*/} [OPTIONS] [<git repo path>] [-- [EXTRA]]

init branches
 * master is only merged by ci on successfull tests
 * only release will be merged to master and also to develop
 * development only onto develop branch, releases ready tags are merged into
   release branch and then merged into master if successfull
 * hotfixed are created from master tags and merged into dev and master

OPTIONS:
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
  local path
  local git_root
  if ! path=$(realpath ${1:-.}); then
    error 1 "$path is not valid."
  fi
  shift
  pushd "$path" >/dev/null 2>&1

  if ! git_root=$(get_root_directory); then
    error 1 "$path is not a git repository."
  fi
  git_init_workflow
  popd >/dev/null 2>&1
}

check_dependencies() {
  :
}

check_input_args() {
  :
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
  source "${PATH_USER_LIB}libgit.sh"
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

git_init_workflow() {
  local -r active_branch=$(get_active_branch)
  if [[ $active_branch != "master" ]]; then
    git checkout master
  fi
  # hotfix only from master branch tags, merged into dev and master
  git branch hotfix
  # develop
  git checkout -b dev || git checkout dev
  git branch stage
  git branch release
  # feature branches are created from dev
  git branch f1
  msg "Active branch: $(get_active_branch)"
}

#-------------------------------------------------------------------------------
# end custom functions
################################################################################

prepare
main "$@"
