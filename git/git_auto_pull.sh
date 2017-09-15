#!/bin/env bash
# ------------------------------------------------------------------------------
# description
# ------------------------------------------------------------------------------
# 
declare branch_active=

declare -r production_branches=(
"prod"
"release"
)

declare remote_id="origin"
declare branch_master="master"

usage() {
  cat >&2 << EOF
Usage:	${0##*/} [OPTIONS] [<path>] -- [GIT PUSH OPTIONS]

OPTIONS:
  -h			  help
  -v			  verbose
  -b <branch>		  branch master to pull to
  -a,--all		  all(TODO)
  -r <remote id>	  remote id
EOF
}

main() {

  # flags
  local -i enable_verbose=0
  local -i enable_quiet=0
  local -i enable_debug=0

  local -a options=
  local -a args=

  local enable_pull_all=0

  check_dependencies
  # parse input args 
  parse_options "$@"
  # set leftover options parsed local input args
  set -- ${args[@]}
  # remove args array
  unset -v args
  check_input_args "$@"

  prepare_env
  if [[ -z $1 ]]; then
    set -- "."
  fi
  for path in "$@"; do
    pushd "$path"
    setup
    run
    popd
  done
  trap - SIGINT SIGQUIT SIGABRT SIGTERM EXIT
}

run() {
  git checkout -q "$branch_master" || die "Could not checkout $branch_master"
  {
    if ((${#options[@]} == 0)); then
      git pull -q "${options[@]}" "$remote_id"
    else
      git pull -q "$remote_id"
    fi
  } || error "Pull from remote: $remote failed."

  git checkout -q "$branch_active"
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
  set -e
  source_libs
  set +e

  set_descriptors
}

source_libs() {
  source "${MYLIBS}libutils.sh"
  source "${MYLIBS}libcolors.sh"
  source "${MYLIBS}libgit.sh"
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
  branch_active=$(get_active_branch)
  trap "cleanup $branch_active" SIGINT SIGQUIT SIGABRT SIGTERM EXIT
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
      -b|--branch)
        branch_master=$2
        do_shift=2
        ;;
      -r|--remote)
        remote_id=$2
        do_shift=2
        ;;
      -a|--all)
        options+=("-a")
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
  local -r active=$1

  trap - SIGHUP SIGINT SIGTERM EXIT
  git checkout "$active"

  exit 0
}

prepare
main "$@"
