#!/bin/env bash
usage() {
  cat >&2 << EOF
Usage: ${0##*/} [OPTIONS] CMD...

Run commands in background

OPTIONS:
  -l, --log           log command output
  -s, --silent        disable notifications   
  -m, --mail <user>   mail user
  -h                  help
EOF
}
main() {
  cmd=("$@")
  local -i enable_logging=0
  local -i enable_mail=0
  local -i enable_notifications=1

  # mail recipient
  local recipient="admin"
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

  if (($enable_logging)); then
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
    local -r subject="Background process finished by $USER"
    local -r message=$@
    notify-send "$subject" "'$message'"
    echo "$message" | mail -s "$subject" "$recipient"
  fi
}
parse_options() {
  # exit if no options left
  [[ -z $1 ]] && return 0

  local do_shift=0
  case $1 in
      -l|--log)
        enable_logging=1
        ;;
      -m|--mail)
        enable_mail=1
        recipient=$2
        do_shift=2
        ;;
      -s|--silent)
        enable_notifications=0
        ;;
      *)
        do_shift=1
	;;
  esac
  if (($do_shift == 1)) ; then
    commands+=("$1")
  elif(($do_shift == 2)) ; then
    shift
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
