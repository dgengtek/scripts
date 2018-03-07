#!/bin/env bash
# ------------------------------------------------------------------------------
# ansible-role wrapper script for testing single roles
# ------------------------------------------------------------------------------
# 

usage() {
  cat >&2 << EOF
Wrapper script for ansible-playbook to apply single role.
Needs to be in same directory as role.

Usage:	${0##*/} <host-pattern> <role-name> [ansible-playbook options]

OPTIONS:
  -h			  help
  -v			  verbose
  -q			  quiet
  -d			  debug
  -c <directory>, --change <directory>	  change to directory before applying roles path

Examples:
  $0 dest_host my_role
  $0 custom_host my_role -i 'custom_host,' -vv --check
EOF
}

main() {
  # flags
  local -i enable_verbose=0
  local -i enable_quiet=0
  local -i enable_debug=0

  local -a options=
  local -a args=

  local role_directory=$(pwd)

  check_dependencies
  # parse input args 
  parse_options "$@"
  # set leftover options parsed local input args
  set -- ${args[@]}
  # remove args array
  unset -v args
  check_input_args "$@"

  local -r HOST_PATTERN=$1
  local -r ROLE=$2
  shift 2

  prepare_env
  setup
  run ${options[@]} $@
}

run() {
  echo "Trying to apply role \"$ROLE\" to host/group \"$HOST_PATTERN\"..."

  export ANSIBLE_ROLES_PATH="$role_directory"
  export ANSIBLE_RETRY_FILES_ENABLED="False"
  ansible-playbook "$@" /dev/stdin <<END
---
- hosts: $HOST_PATTERN
  roles:
    - $ROLE
END
}

check_dependencies() {
  :
}

check_input_args() {
  if [[ $# < 2 ]]; then
    usage
    exit
  fi
}

prepare_env() {
  :
}

prepare() {
  #export PATH_USER_LIB="$HOME/.local/lib/"
  source_libs
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
      -c|--change)
        role_directory="$(pwd)/$2"
        do_shift=2
        ;;
      --)
        do_shift=3
        ;;
      -*)
        usage
        error_exit 5 "$1 is not allowed. Pass -- if you want to pass options to ansible-playbook."
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
    # got --
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
