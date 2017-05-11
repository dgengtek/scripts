#!/bin/env bash
# TODO: use coproc for buffering logs
usage() {
  cat >&2 << EOF
Usage: ${0##*/} [OPTIONS] CMD...

Run commands in background

OPTIONS:
  -l, --log           log command output
  -m, --mail          mail cmd output
  -n, --disable-notify        disable notifications
  -f, --foreground    run in foreground
  -p, --print-process print process regardless
  -h                  help
EOF
}
main() {
  cmd=("$@")
  local -i enable_logging=0
  local -i enable_mail=0
  local -i enable_foreground=0
  local -i enable_notifications=1
  local -i print_process=0

  # mail recipient
  local recipient="linux+admin"
  local logfile="/dev/null"
  local commands=
  parse_options "$@"
  set -- ${commands[@]}
  unset -v commands

  if [[ $# < 1 ]]; then
    usage
    error_exit 1 "No commands."
  fi

  trap handle_signal SIGINT SIGTERM 
  trap cleanup EXIT

  if (($enable_logging)) || (($enable_mail)); then
    logfile=$(mktemp -u log_runXXXXXX.out)
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
    (! (($enable_foreground)) || (($print_process)) ) && echo "$!" >&3
  fi
  # return 0 since bash uses last test return code
  return 0
}
run_commands() {
  eval "$@"
  local -r subject="$?[$USER@$HOSTNAME]$ run.sh $@"
  local -r message=$@
  if (($enable_notifications)); then
    [[ -n $BEEP ]] && mplayer "$BEEP" > /dev/null 2>&1
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
      -n|--disable-notify)
        enable_notifications=0
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

cleanup() {
  trap - EXIT
  (($enable_mail)) && [[ -e $logfile ]] && rm "$logfile"
}

handle_signal() {
  trap - SIGINT SIGTERM
  cleanup
  kill $$
  error_exit 1 "Signal received: stopping backup" 
}

main "$@"
