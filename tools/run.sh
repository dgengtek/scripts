#!/bin/env bash
usage() {
  cat >&2 << EOF
Usage: ${0##*/} [OPTIONS] CMD...

Run commands in background

OPTIONS:
  -l, --log           log command output
  -m, --mail          mail cmd output
  -n, --notify        enable notifications
  -f, --foreground    run in foreground
  -p, --print-process print process
  -h                  help
EOF
}
main() {
  cmd=("$@")
  local -i enable_logging=0
  local -i enable_mail=0
  local -i enable_foreground=0
  local -i enable_notifications=0
  local -i print_process=0

  local -r fifo="/tmp/runfifo$RANDOM"

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

  trap cleanup SIGINT SIGTERM SIGKILL EXIT

  if (($enable_logging)) || (($enable_mail)); then
    logfile=$(mktemp -u /tmp/log_runXXXXXX.out)
    echo "$@" > "$logfile"
  fi

  if (($enable_foreground)); then
    (($print_process)) && echo "$$"
    run_commands "$@"
  else
    exec 3>&1
    exec 1>>"$logfile"
    exec 2>&1
    run_commands "$@" &
    (($print_process)) && echo "$!" >&3
  fi
}
run_commands() {
  eval "$@"
  local -r subject="Background process finished by $USER"
  local -r message=$@
  if (($enable_notifications)); then
    mplayer "$BEEP" > /dev/null 2>&1
    notify-send "$subject" "'$message'"
  fi
  if (($enable_mail)); then
    cat "$logfile" | mail -s "$subject" "$recipient"
  fi
  cleanup
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
        ;;
      -f|--foreground)
        enable_foreground=1
        ;;
      -n|--notify)
        enable_notifications=1
        ;;
      -p|--print-process)
        print_process=1
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
prepare() {
  mkfifo "$fifo"

}
cleanup() {
  [[ -e $fifo ]] && rm "$fifo"
  [[ -e $logfile ]] && rm "$logfile"
}

handle_signal() {
  trap - SIGINT SIGTERM SIGKILL EXIT
  kill $$
  error_exit 1 "Signal received: stopping backup" 
}

main "$@"
