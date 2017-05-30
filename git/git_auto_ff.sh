#!/bin/env bash
# ------------------------------------------------------------------------------
# description
# ------------------------------------------------------------------------------
# 
# Use as post-commit or post-merge script for development
# Automatically merges dev branch into master branch with fast forward only.
# If possible, will try to push updates from master branch to remotes mentioned
#   in variable $remote_id
declare branch_active
declare -r development_branches=(
"dev"
"development"
)
declare -r production_branches=(
"prod"
"release"
)
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
  setup
  run
}


run() {
  if ! check_branches_conflict "${development_branches[@]}"; then
    die "Conflicting branches found: ${development_branches[@]}"
  fi
  if ! check_branches_conflict "${production_branches[@]}"; then
    die "Conflicting branches found: ${production_branches[@]}"
  fi

  local branch_dev=$(get_valid_branch "$development_branches")
  local branch_prod=$(get_valid_branch "$production_branches")
  [[ -z $branch_dev ]] && die "No development branch found."
  [[ -z $branch_prod ]] && die "No production branch found."

  pushd $(get_root_directory) >/dev/null
  if ! git commit -v -a 2>/dev/null; then
    die "Could not commit to current branch. Stash your items or commit them."
  fi
  
  if check_merge_allowed "$branch_dev" "$branch_prod"; then
    {
      git checkout "$branch_dev" && git merge --ff-only "$branch_active"
    } 2>/dev/null || die "Merge to $branch_dev failed for $branch_active."
  fi

  {
    git checkout "$branch_prod" && git merge --ff-only "$branch_dev"
  } 2>/dev/null || die "Merge to $branch_prod failed for $branch_dev."

  git checkout "$branch_active"
  popd >/dev/null
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
  source "libgit.sh"
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
