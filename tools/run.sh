#!/bin/env bash
usage() {
  cat >&2 << EOF
Usage: ${0##*/} [OPTIONS] CMD...

Run commands in background

OPTIONS:
  -l, --log         log command output
  -s, --silent      disable notifications   
  -h                help
EOF
}
main() {
  cmd=("$@")
  local -i enable_verbose=0
  local -i enable_loggin=0
  local -i enable_notifications=1

  local logfile="/dev/null"
  local commands=
  parse_options "$@"
  set -- ${commands[@]}
  unset -v commands

  if [[ $# < 1 ]]; then
    usage
    error_exit 1 "No commands."
  fi

  #trap handle_signal SIGINT SIGTERM SIGKILL EXIT

  if (($enable_loggin)); then
    logfile="log_run.out"
    echo "$@" > "$logfile"
  fi

  exec 1>>"$logfile"
  exec 2>&1
  run_commands "$@" &
}
run_commands() {
  eval "$@"
  if (($enable_notifications)); then
    mplayer "$BEEP"
    local -r message=$@
    notify-send "Background process done" "'$message'"
  fi
}
parse_options() {
  # exit if no options left
  [[ -z $1 ]] && return 0

  local do_shift=0
  case $1 in
      -l|--log)
        enable_loggin=1
        ;;
      -s|--silent)
        enable_notifications=0
        ;;
      *)
        do_shift=1
	;;
  esac
  if (($do_shift)) ; then
    commands+=("$1")
  fi
  shift
  parse_options "$@"
}
log() {
  echo -n "$@" | logger -s -t ${0##*/}
}
error_exit() {
  error_code=${1:-0}
  shift
  log "$@"
  exit $error_code
}

handle_signal() {
  trap - SIGINT SIGTERM SIGKILL EXIT
  kill $$
  error_exit 1 "Signal received: stopping backup" 
}

main "$@"
