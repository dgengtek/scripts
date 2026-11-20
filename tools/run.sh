#!/usr/bin/env bash
# TODO: use coproc for buffering logs
# run.sh - run commands in background with optional logging/mail/notifications

usage() {
  cat >&2 <<EOF
Usage: ${0##*/} [OPTIONS] CMD...

Run commands in background

OPTIONS:
  -d, --debug
  -v, --verbose
  -q, --quiet
  -c, --comment <comment>  comment for notification
  -l, --log                log command output
  -m, --mail               mail result
  -o, --output             mail cmd output
  -e, --exec               exec command
  -n, --silent             disable notifications
  -f, --foreground         run in foreground
  -p, --print-process      print process regardless
  -r, --sudo               run with sudo
  -h, --help               help
EOF
}

error_exit() {
  local -r error_code=${1:-1}
  shift
  # Prefer log if available, otherwise fall back to stderr
  if declare -F log >/dev/null 2>&1; then
    log "$@"
  else
    printf '%s\n' "$@" >&2
  fi
  exit "$error_code"
}

source_libs() {
  # PATH_USER_SCRIPTS must be set by the environment
  if [[ -z ${PATH_USER_SCRIPTS:-} ]]; then
    error_exit 1 "PATH_USER_SCRIPTS is not set"
  fi
  # shellcheck source=/dev/null
  source "${PATH_USER_SCRIPTS}/libutils.sh"
  # shellcheck source=/dev/null
  source "${PATH_USER_SCRIPTS}/libcolors.sh"
}

set_descriptors() {
  if ((enable_verbose)); then
    exec {fdverbose}>&2
  else
    exec {fdverbose}>/dev/null
  fi
  if ((enable_debug)); then
    set -xv
    exec {fddebug}>&2
  else
    exec {fddebug}>/dev/null
  fi
}

prepare_env() {
  set_descriptors
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
  trap - SIGABRT SIGALRM SIGHUP SIGCONT SIGUSR1 SIGUSR2
  trap - SIGINT SIGQUIT SIGTERM EXIT
}

sigh_abort() { trap - SIGABRT; }
sigh_alarm() { trap - SIGALRM; }
sigh_hup() { trap - SIGHUP; }
sigh_cont() { trap - SIGCONT; }
sigh_usr1() { trap - SIGUSR1; }
sigh_usr2() { trap - SIGUSR2; }

sigh_cleanup() {
  trap - SIGINT SIGQUIT SIGTERM EXIT
  cleanup
  local p
  for p in $(jobs -p); do
    if [[ -e "/proc/$p" ]]; then
      kill "$p" >/dev/null 2>&1 || true
      wait "$p" 2>/dev/null || true
    fi
  done
}

cleanup() {
  # Only remove real temp files we created
  if [[ -n ${logfile:-} && $logfile != /dev/null && -f $logfile ]]; then
    rm -f -- "$logfile"
  fi
}

parse_options() {
  while (($# > 0)); do
    case $1 in
      -d | --debug) enable_debug=1 ;;
      -v | --verbose) enable_verbose=1 ;;
      -q | --quiet) enable_quiet=1 ;;
      -l | --log) enable_logging=1 ;;
      -m | --mail) enable_mail=1 ;;
      -r | --sudo) run_as_sudo=1 ;;
      -f | --foreground) enable_foreground=1 ;;
      -n | --silent) enable_notifications=0 ;;
      -e | --exec) runexec=1 ;;
      -o | --output) enable_mail_cmd_output=1 ;;
      -p | --print-process) print_process=1 ;;
      -c | --comment)
        if (($# < 2)); then
          error_exit 1 "--comment requires an argument"
        fi
        comment=$2
        shift
        ;;
      -h | --help)
        usage
        exit 0
        ;;
      --)
        shift
        commands+=("$@")
        break
        ;;
      -*)
        error_exit 1 "Unknown option: $1"
        ;;
      *)
        commands+=("$1")
        ;;
    esac
    shift
  done
}

run_commands() {
  log_info "running '$*'"

  local status=0
  if ((run_as_sudo)); then
    time sudo setsid "$@" || status=$?
  else
    time setsid "$@" || status=$?
  fi

  local subject="${status}[${USER}@${HOSTNAME}]$ ${0##*/}"
  [[ -n $comment ]] && subject+=" # $comment"
  local message="$*"

  if ((enable_notifications)); then
    [[ -n ${BEEP:-} ]] && mplayer "$BEEP" >/dev/null 2>&1 || true
    notify-send "$subject" "$message" || true
  fi

  if ((enable_mail)); then
    # Proper headers: no blank line before Subject
    sendmail -f "$sender" "$recipient" <<EOF
From: $sender
To: $recipient
Subject: $subject

$(cat "$logfile" 2>/dev/null || true)
EOF
  fi

  # Do not clean up here if we are still in a background job that the
  # parent may want to inspect; leave cleanup to EXIT / explicit call.
  return "$status"
}

run() {
  # Create a real temp file when logging or mailing is requested
  if ((enable_logging || enable_mail)); then
    logfile=$(mktemp /tmp/runXXXXXX.log) || error_exit 1 "mktemp failed"
    printf '%s\n\n' "$*" >"$logfile"
  fi

  if ((run_as_sudo)); then
    command sudo -v || error_exit 1 "sudo -v failed"
  fi

  # Preserve original stdout for -p
  exec 3>&1

  if ((runexec)); then
    log_info "exec '$*'"
    if ((enable_foreground)); then
      exec "$@"
    else
      # Background + exec: the & is the only thing that keeps the parent alive
      # long enough to print $! if requested
      exec "$@" &
      ((print_process)) && echo "$!" >&3
      # Parent exits; the exec'ed process is already running
      exit 0
    fi
  elif ((enable_foreground)); then
    local output_stream=/dev/null
    ((enable_mail_cmd_output)) && output_stream=$logfile
    run_commands "$@" |& tee "$output_stream"
  else
    if ((enable_mail_cmd_output)); then
      exec 1>>"$logfile"
      exec 2>&1
    else
      exec 1>/dev/null
      exec 2>>"$logfile"
    fi
    run_commands "$@" &
    ((print_process)) && echo "$!" >&3
  fi
}

main() {
  local -i enable_logging=0
  local -i enable_mail=0
  local -i enable_mail_cmd_output=0
  local -i enable_foreground=0
  local -i enable_notifications=1
  local -i run_as_sudo=0
  local -i print_process=0
  local -i enable_verbose=0
  local -i enable_quiet=0
  local -i enable_debug=0
  local -i runexec=0

  local recipient=notification
  local sender=runsh+script
  local logfile=/dev/null
  local comment=
  local -a commands=()

  parse_options "$@"
  set -- "${commands[@]}"
  unset -v commands

  if (($# < 1)); then
    usage
    error_exit 1 "No commands."
  fi

  prepare_env
  set_signal_handlers
  run "$@"
  # When the command was backgrounded, the traps stay until the
  # background job finishes or the shell exits.
  # For foreground / exec we can clear them.
  if ((enable_foreground || runexec)); then
    unset_signal_handlers
  fi
}

# ---------------------------------------------------------------------------
# Entry point
# ---------------------------------------------------------------------------
# Source libraries first (they define log / log_info etc.)
set -e
source_libs
set +e

# Descriptors will be configured after flags are parsed (inside main)
main "$@"
