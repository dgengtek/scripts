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
    countdown "Working" $work
    counts=$((counts + 1))
    if ((counts % $break_cycle == 0)); then
      counts=0
      countdown "Long break" $long_break
    else
      countdown "Short break" $short_break
    fi
  done
}

countdown() {
  local -r description=$1
  shift
  if ! countdown.py -m "$@"; then
    echo "Stopping pomodoro."
    exit 0
  fi
  mplayer "$BEEP" >/dev/null 2>&1
  notify-send "Countdown finished" "$description"
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
