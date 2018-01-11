#!/bin/env bash
# TODO: use coproc for buffering logs
usage() {
  cat >&2 << EOF
Usage: ${0##*/} [OPTIONS] CMD...

Run commands in background

OPTIONS:
  -l, --log           log command output
  -m, --mail          mail result
  -o, --output        mail cmd output
  -n, --disable-notify        disable notifications
  -f, --foreground    run in foreground
  -p, --print-process print process regardless
  -s, --sudo          run with sudo
  -q, --quiet  quiet run
  -h                  help
EOF
}
main() {
  cmd=("$@")
  local -i enable_logging=0
  local -i enable_mail=0
  local -i enable_mail_cmd_output=0
  local -i enable_foreground=0
  local -i enable_notifications=1
  local -i run_as_sudo=0
  local -i print_process=0

  # mail recipient
  local recipient="notification"
  local sender="runsh+script"
  local logfile="/dev/null"
  local -a commands=
  parse_options "$@"
  set -- ${commands[@]}
  unset -v commands

  if [[ $# < 1 ]]; then
    usage
    error_exit 1 "No commands."
  fi

  trap signal_handler SIGINT SIGTERM 
  trap cleanup EXIT

  if (($enable_logging)) || (($enable_mail)); then
    logfile=$(mktemp -u /tmp/runXXXXXX.log)
    echo -e "$@\n" > "$logfile"
  fi

  if (($run_as_sudo)); then
    set -- sudo $@
    command sudo -v
  fi 
  exec 3>&1
  if (($enable_foreground)); then
    local output_stream="/dev/null"
    (($enable_mail_cmd_output)) && output_stream=$logfile
    run_commands "$@" |& tee "$output_stream"
    (($print_process)) && echo "$!"
  else
    if (($enable_mail_cmd_output)); then
      exec 1>>"$logfile"
      exec 2>&1
    else
      exec 1>/dev/null
      exec 2>>"$logfile"
    fi
    run_commands "$@" &
    (! (($enable_foreground)) || (($print_process)) ) && echo "$!" >&3
  fi
  # return 0 since bash uses last test return code
  return 0
}
run_commands() {
  time $@

  local -r subject="$?[$USER@$HOSTNAME]$ run.sh"
  local -r message=$@
  if (($enable_notifications)); then
    [[ -n $BEEP ]] && mplayer "$BEEP" > /dev/null 2>&1
    notify-send "$subject" "'$message'"
  fi

  if (($enable_mail)); then
    sendmail -f "$sender" "$recipient" << EOF_HEADER
From: $sender
To: $recipient

Subject: $subject

$(cat $logfile)
EOF_HEADER
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
      -s|--sudo)
        run_as_sudo=1
        ;;
      -f|--foreground)
        enable_foreground=1
        ;;
      -n|--disable-notify)
        enable_notifications=0
        ;;
      -o|--output)
        enable_mail_cmd_output=1
        ;;
      -p|--print-process)
        print_process=1
        ;;
      -q|--quiet)
        exec 1>/dev/null
        ;;
      -h|--help)
        usage
        exit 0
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
  [[ -f $logfile ]] && rm "$logfile"
}

signal_handler() {
  trap - SIGINT SIGTERM
  cleanup
  local active_jobs=$(jobs -p)
  [[ -n $active_jobs ]] && kill -SIGINT $active_jobs
  error_exit 1 "Signal received: stopping backup" 
}

main "$@"
