#!/bin/env bash
# todo: add supplied seconds to session database in file
usage() {
  cat << EOF
Usage: ${0##*/} [<seconds>]
EOF

}
main() {
  local time_seconds=
  local time_minutes=
  local time_hours=
  local -ri long_break=900
  local -ri short_break=300

  if [[ -z $1 ]];then
    pomodoro
  fi
  run "$1"

}
pomodoro() {
  echo "Run pomodoro."
  local -i counts=0
  while :; do
    run 1500
    counts=$((counts + 1))
    if ((counts >= 4 )); then
      counts=0
      echo "Long break."
      run $long_break
    else
      echo "Break."
      run $short_break
    fi
  done
}

run() {
  local -ir time_raw="$1"
  countdown_loop "$time_raw"
  update_time "$time_raw"
  local output="\rCountdown finished"
  output+=" - ${time_hours}h, ${time_minutes}m, ${time_seconds}s\n"
  echo -en "$output"
  notify-send "Countdown" "$output"
  run.sh -n mplayer $BEEP
}

countdown_loop() {
  local -i counter=$1
  local timer=""
  while [[ $counter -gt 0 ]]; do
    display_time "$counter"
    let --counter
    sleep 1
  done
}

display_time() {
  local -r input=$1
  update_time "$input"
  if [[ $time_hours == 0 ]]; then
    time_hours="00"
  fi
  if [[ $time_minutes == 0 ]]; then
    time_minutes="00"
  fi
  if [[ $time_seconds == 0 ]]; then
    time_seconds="00"
  fi
  printf "\r%02i:%02i:%02i" "${time_hours}" "${time_minutes}" "${time_seconds}"
}

update_time() {
  local input=$1

  time_hours=$(($input / 3600))
  input=$(($input % 3600))
  time_minutes=$(($input / 60))
  time_seconds=$(($input % 60))
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
