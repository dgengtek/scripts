#!/bin/env bash
# ------------------------------------------------------------------------------
# track time via pomodoro
# use taskwarrior for flagging task
# use timewarrior for recording total time used for tasks
# ------------------------------------------------------------------------------

usage() {
  cat >&2 << EOF
Usage: ${0##*/} [<task filter>]
EOF
}

main() {
  # flags
  local -i enable_verbose=0
  local -i enable_quiet=0
  local -i enable_debug=0
  local -i enable_mail_notification=0

  local -a options=
  local -a args=

  local -ri long_break=15
  local -ri short_break=5
  local -ri work=25
  local -ri break_cycle=4

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

run() {
  pomodoro "$@"
}

check_dependencies() {
  if ! hash command timew; then
    echo "Timewarrior could not be found in env." >&2
    exit 1
  fi
  if ! hash command task; then
    echo "Taskwarrior shell script could not be found in env." >&2
    exit 1
  fi
}

check_input_args() {
  :
}

prepare_env() {
  :
}

prepare() {
  #export MYLIBS="$HOME/.local/lib/"

  set -e
  source_libs
  set +e

  set_descriptors
}

source_libs() {
  source "${MYLIBS}libutils.sh"
  source "${MYLIBS}libcolors.sh"
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
      -)
        if ! (($singleton)); then
          singleton=1
          return 9
        fi
        error_exit 5 "stdin is not allowed inside config."
        ;;
      -d|--debug)
        enable_debug=1
        ;;
      -v|--verbose)
	enable_verbose=1
	;;
      -m|--mail)
	enable_mail_notification=1
	;;
      -q|--quiet)
        enable_quiet=1
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
  mplayer "$BEEP" >/dev/null 2>&1
  timew stop
  local active_jobs=$(jobs -p)
  for p in $active_jobs; do
    if ps -p $p >/dev/null 2>&1; then
      kill -SIGINT $p >/dev/null 2>&1
    fi
  done
  exit 0
}

################################################################################
# custom functions
#-------------------------------------------------------------------------------

pomodoro() {
  echo "Starting pomodoro."
  local -i counts=0
  while :; do
    countdown $work "work" "$@"
    counts=$((counts + 1))
    if ((counts % $break_cycle == 0)); then
      counts=0
      countdown $long_break "break" 
    else
      countdown $short_break "break" 
    fi
  done
}

taskwarrior() {
  local -r cmd=$1
  local -r description=$2
  shift 2
  if [[ -z $1 ]]; then
    command timew "$cmd" "$description"
  else
    command task "$@" "$cmd"
  fi
}

countdown() {
  local -r time_unit=$1
  local -r description=$2
  shift 2
  notify-send -t 10000 -u critical "Starting countdown" "$description"
  mplayer "$BEEP" >/dev/null 2>&1
  if (($enable_mail_notification)); then
    echo "Starting countdown" | mail -s "pomodoro: $description" notification
  fi
  taskwarrior start "$description" "$@"
  if ! countdown.py -m "$time_unit"; then
    echo "Stopping pomodoro."
    taskwarrior stop "$description" "$@"
    exit 0
  fi
  mplayer "$BEEP" >/dev/null 2>&1
  taskwarrior stop "$description" "$@"
}

print_available_sessions() {
  if [ -e "$config_path" ];then
    echo -e "\nThese sessions are available:"
    find $config_path -type f | xargs -I {} basename -s ".session" {} | xargs -n 1 echo -e "\t"
  fi
}
#-------------------------------------------------------------------------------
# end custom functions
################################################################################

prepare
main "$@"
