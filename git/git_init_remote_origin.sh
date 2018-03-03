#!/bin/env bash
# ------------------------------------------------------------------------------
# set remote origin from environment
# ------------------------------------------------------------------------------
# 

usage() {
  cat >&2 << EOF
Usage: ${0##*/} [OPTIONS] [<git repository path> [<git remote url>]]

* Remote name defaults to environment variable \$REPOSITORY_USER or the userid if not set
* Remote url defaults to \$REPOSITORY_REMOTE_URL else must be passed to the script

OPTIONS:
  -h    help
  -v    verbose
  -q    quiet
  -d    debug
  -n,--name <repository name>  Name of the git remote repository
  -p,--push  Push the repository and set master branch as upstream
EOF
}

main() {
  # flags
  local -i enable_verbose=0
  local -i enable_quiet=0
  local -i enable_debug=0

  local -a options=
  local -a args=

  local remote_path=""
  local path="."
  local remote_name="${REPOSITORY_USER:-$(id -un)}"
  local enable_push=0

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
  local git_root=
  if ! path=$(realpath ${1:-$path}); then
    error 1 "$path is not valid."
  fi
  shift
  pushd "$path" >/dev/null 2>&1

  if ! git_root=$(get_root_directory); then
    error 1 "$path is not a git repository."
  fi
  local remote_path=$2
  local git_basename=$(basename "$git_root")

  if [[ -z $remote_path ]] && [[ -z $REPOSITORY_REMOTE_URL ]]; then
    error 1 "Cannot set remote repository url. Pass the url to the script manually."
  elif [[ -z $remote_path ]]; then
    remote_path="$REPOSITORY_REMOTE_URL/$git_basename"
  fi

  git_init_remote_origin "$@"
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
      -p|--push)
        enable_push=1
        ;;
      -n|--name)
        remote_name=$2
        shift
        ;;
      -h|--help)
        usage
        exit 0
        ;;
      --)
        do_shift=2
        ;;
      *)
        do_shift=1
	;;
  esac
  if (($do_shift == 1)) ; then
    args+=("$1")
  elif (($do_shift == 2)) ; then
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

git_init_remote_origin() {
  # add default remotes to repository
  local -r active_branch=$(get_active_branch)
  if [[ $active_branch != "master" ]]; then
    git checkout master
  fi
  git remote add "$remote_name" "$remote_path"
  (($enable_push)) && git push --set-upstream "$remote_name" master
  git checkout "$active_branch"
}

#-------------------------------------------------------------------------------
# end custom functions
################################################################################

prepare
main "$@"
