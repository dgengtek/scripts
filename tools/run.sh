#!/usr/bin/env bash
# TODO: use coproc for buffering logs

usage() {
  cat >&2 << EOF
Usage: ${0##*/} [OPTIONS] CMD...

Run commands in background

OPTIONS:
  -d, --debug
  -v, --verbose 
  -q, --quiet
  -c, --comment <comment>  comment for notification
  -l, --log           log command output
  -m, --mail          mail result
  -o, --output        mail cmd output
  -e, --exec          exec command
  -n, --silent        disable notifications
  -f, --foreground    run in foreground
  -p, --print-process print process regardless
  -r, --sudo          run with sudo
  -h                  help
EOF
}


main() {
  local -i enable_logging=0
  local -i enable_mail=0
  local -i enable_mail_cmd_output=0
  local -i enable_foreground=0
  local -i enable_notifications=1
  local -i run_as_sudo=0
  local -i print_process=0

  # flags
  local -i enable_verbose=0
  local -i enable_quiet=0
  local -i enable_debug=0
  local -i runexec=0

  # mail recipient
  local recipient="notification"
  local sender="runsh+script"
  local logfile="/dev/null"
  local comment=
  local -a commands=()
  parse_options "$@"
  set -- "${commands[@]}"
  unset -v commands

  if [[ $# -lt 1 ]]; then
    usage
    error_exit 1 "No commands."
  fi

  prepare_env
  set_signal_handlers
  run "$@"
  unset_signal_handlers

}


run() {
  if (($enable_logging)) || (($enable_mail)); then
    logfile=$(mktemp -u /tmp/runXXXXXX.log)
    echo "$*" > "$logfile"
    echo >> "$logfile"
  fi

  if (($run_as_sudo)); then
    command sudo -v
  fi 
  exec 3>&1
  if (($runexec)); then
    if (($enable_foreground)); then
      exec $*
    else
      exec $* &
    fi
  elif (($enable_foreground)); then
    local output_stream="/dev/null"
    (($enable_mail_cmd_output)) && output_stream=$logfile
    run_commands "$@" |& tee "$output_stream"
  else
    if (($enable_mail_cmd_output)); then
      exec 1>>"$logfile"
      exec 2>&1
    else
      exec 1>/dev/null
      exec 2>>"$logfile"
    fi
    run_commands "$@" &
  fi
  (($print_process)) && echo "$!" >&3
}


run_commands() {
  if (($run_as_sudo)); then
    time sudo setsid bash -c "$*"
  else
    time setsid bash -c "$*"
  fi

  local subject="$?[$USER@$HOSTNAME]$ run.sh"
  [[ -n $comment ]] && subject+=" # $comment"
  local -r message="$*"

  if (($enable_notifications)); then
    [[ -n $BEEP ]] && mplayer "$BEEP" > /dev/null 2>&1
    notify-send "$subject" "$message"
  fi

  if (($enable_mail)); then
    sendmail -f "$sender" "$recipient" << EOF
From: $sender
To: $recipient

Subject: $subject

$(cat "$logfile")
EOF
  fi
  cleanup
}


parse_options() {
  # exit if no options left
  [[ -z $1 ]] && return 0

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
      -l|--log)
        enable_logging=1
        ;;
      -m|--mail)
        enable_mail=1
        ;;
      -r|--sudo)
        run_as_sudo=1
        ;;
      -f|--foreground)
        enable_foreground=1
        ;;
      -n|--silent)
        enable_notifications=0
        ;;
      -e|--exec)
        runexec=1
        ;;
      -c|--comment)
        comment=$2
        do_shift=2
        ;;
      -o|--output)
        enable_mail_cmd_output=1
        ;;
      -p|--print-process)
        print_process=1
        ;;
      -h|--help)
        usage
        exit 0
        ;;
      --)
        do_shift=3
        ;;
      *)
        do_shift=1
	;;
  esac
  if (($do_shift == 1)) ; then
    commands+=("$1")
  elif(($do_shift == 2)) ; then
    shift
  elif (($do_shift == 3)) ; then
    # got --, use all arguments left as options for other commands
    shift
    commands+=("$@")
    return
  fi
  shift
  parse_options "$@"
}


error_exit() {
  local -r error_code=${1}
  shift
  log "$@"
  exit $error_code
}


prepare_env() {
  set_descriptors
}


prepare() {
  export PATH_USER_LIB=${PATH_USER_LIB:-"$HOME/.local/lib/"}

  set -e
  source_libs
  set +e

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
  cleanup
  local active_jobs=$(jobs -p)
  for p in $active_jobs; do
    if [[ -e "/proc/$p" ]]; then
      kill "$p" >/dev/null 2>&1
      wait "$p"
    fi
  done
}


cleanup() {
  [[ -f $logfile ]] && rm "$logfile"
}


prepare
main "$@"
