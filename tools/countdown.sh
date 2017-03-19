#!/bin/env bash
# todo: add supplied seconds to session database in file
usage() {
  cat << EOF
Usage: ${0##*/} SECONDS [ SESSIONNAME ]
EOF

}
main() {
  local session_name="$2"

  local time_seconds=
  local time_minutes=
  local time_hours=

  if [[ -z $1 ]];then
    usage
    print_available_sessions
    exit 1;
  fi
  if [[ -z $session_name ]];then
    session_name="session"
  else
    session_name=${2}.session
  fi

  pushd ~
  local -ir time_raw="$1"
  countdown_loop "$time_raw"
  update_time "$time_raw"
  local output="\rCountdown session '$session_name' finished - "
  output+="${time_hours}h${time_minutes}m${time_seconds}s\n"
  echo -en "$output"
  notify-send "Countdown" "$output"
  run.sh mplayer $BEEP
  popd
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
pushd() {
  command pushd "$@" > /dev/null
}

popd() {
  command popd "$@" > /dev/null
}

main "$@"
