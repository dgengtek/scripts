#!/bin/env bash
# todo: add supplied seconds to session database in file
usage() {
  cat << EOF
Usage: ${0##*/}
EOF

}
main() {
  local -ri long_break=15
  local -ri short_break=5
  local -ri work=25
  local -ri break_cycle=4

  if [[ -z $1 ]];then
    pomodoro
  fi
}
pomodoro() {
  echo "Starting pomodoro."
  local -i counts=0
  while :; do
    countdown "work" $work
    counts=$((counts + 1))
    if ((counts % $break_cycle == 0)); then
      counts=0
      countdown "break" $long_break
    else
      countdown "break" $short_break
    fi
  done
}

timew() {
  if ! hash command timew; then
    echo "Timewarrior could not be found in env." >&2
    return 1
  fi
  command timew "$@"
}

countdown() {
  local -r description=$1
  shift
  timew start "$description"
  if ! countdown.py -m "$@"; then
    echo "Stopping pomodoro."
    exit 0
  fi
  mplayer "$BEEP" >/dev/null 2>&1
  notify-send -u critical "Countdown finished" "$description"
  timew stop "$description"
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
