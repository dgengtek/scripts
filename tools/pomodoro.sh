#!/bin/env bash
# track time via pomodoro
# use taskwarrior for flagging task
# use timewarrior for recording total time used for tasks
usage() {
  cat << EOF
Usage: ${0##*/} [<task filter>]
EOF

}
main() {
  local -ri long_break=15
  local -ri short_break=5
  local -ri work=25
  local -ri break_cycle=4

  pomodoro "$@"
}
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
  if ! hash command timew; then
    echo "Timewarrior could not be found in env." >&2
    return 1
  fi
  if ! hash command task; then
    echo "Taskwarrior shell script could not be found in env." >&2
    return 1
  fi
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

cleanup() {
  trap - SIGHUP SIGKILL SIGINT
  exit 1
}

main "$@"
