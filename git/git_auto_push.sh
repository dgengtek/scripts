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

declare -r remote_id="origin"
declare -r branch_master="master"

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
}

run() {
  if ! check_branches_conflict "${production_branches[@]}"; then
    die "Conflicting branches found: ${production_branches[@]}"
  fi

  local branch_prod=$(get_valid_branch "$production_branches")
  [[ -z $branch_prod ]] && die "No production branch found."

  if check_merge_allowed "$branch_prod"; then
    {
    git checkout "$branch_master" && git merge --ff-only "$branch_prod"
    } 2>/dev/null || die "Merge of $branch_prod on $branch_master failed."
    msg "Merged $branch_prod to $branch_master"
  fi
  for remote in $(git remote); do
    {
    git pull "$remote_id"
    git push "$remote"
    } 2>/dev/null || error "Remote push to $remote failed."
  done

  git checkout "$branch_active"
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
