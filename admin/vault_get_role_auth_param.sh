#!/usr/bin/env bash
# ------------------------------------------------------------------------------
# get approle authentication as this string
# role_id:${role_id},secret_id:${secret_id}
# ------------------------------------------------------------------------------
# only use uppercase variables for environment variables 

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

declare -i enable_verbose=0
declare -i enable_quiet=0
declare -i enable_debug=0
readonly __script_name="${BASH_SOURCE[0]##*/}"


usage() {
  cat >&2 << EOF
Usage: ${0##*/} app [<login_token>]

generate tokens for apps

* login to vault and get approle tokens

EOF
}


main() {
  # flags

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
  run_approle "$@"
}


run_approle() {
  set +u
  local app=${1:?App name for approle require}
  shift
  if [[ -z "$VAULT_TOKEN" ]]; then
    if [[ -z "$1" ]]; then
      VAULT_TOKEN=$(systemd-ask-password "LOGIN token for vault")
    else
      VAULT_TOKEN="$1"
    fi
  fi

  if [[ -z "$VAULT_TOKEN" ]]; then
    usage
    exit 1
  fi
  set -u

  role_id=$(_get_role_id "$app")
  secret_id=$(_get_secret_id "$app")
  echo "role_id:${role_id},secret_id:${secret_id}"
}

_get_role_id() {
  local -r role_id=${1:?Role id missing as input}

  curl -s \
    --header "X-Vault-Token: ${VAULT_TOKEN}" \
    ${VAULT_ADDR}/v1/auth/approle/role/$role_id/role-id \
      | jq -r '.data.role_id'
}


_get_secret_id() {
  local -r role_id=${1:?Role id missing as input}

  data=$(jq -ns "{ \"metadata\": \"generated from pillar update script for role $role_id\" }" \
    | curl -s \
      --header "X-Vault-Token: ${VAULT_TOKEN}" \
      --request POST \
      ${VAULT_ADDR}/v1/auth/approle/role/$role_id/secret-id \
      | jq '.data')
  command echo "$role_id secret_id_accessor: $(command echo -n "$data" | jq -r '.secret_id_accessor')" >&2
  command echo -n "$data" | jq -r '.secret_id'
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


log() {
  logger -s -t "$__script_name" "$@"
}


# generate a logging function log_* for every level
for level in emerg err warning info debug; do
  printf -v functext -- 'log_%s() { log -p user.%s -- "$@" ; }' "$level" "$level"
  eval "$functext"
done


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


