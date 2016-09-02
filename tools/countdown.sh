#!/bin/bash
# todo: add supplied seconds to session database in file
usage() {
  cat << EOF
Usage: ${0##*/} seconds sessionname
EOF

}
main() {
  local -r config_path="$HOME/.countdown"
  local session_name="$2"

  if [ -z "$1" ];then
    usage
    print_available_sessions
    exit 1;
  fi
  if [ -z "$session_name" ];then
    session_name="session"
  else
    session_name=${2}.session
  fi
  local -r session_path=$config_path/$session_name

  pushd ~
  if ! [ -e "$session_path" ];then
    mkdir -p "$config_path" || exit 1
    pushd "$config_path" || exit 1
    touch "$session_name"
    trap trap_SIG SIGHUP SIGKILL SIGINT
    popd
  fi
  local -ir countdown_raw="$1"
  countdown_loop "$countdown_raw"

  declare -ir time_minutes=$((countdown_raw/60))
  local output="\r--> Countdown of "
  local msg=""
  if [[ $time_minutes -lt 1 ]];then
    msg="$countdown_raw seconds"
  else
    msg="$time_minutes minutes"
  fi
  output="$output $msg, finished\n"
  echo -en "$output"
  notify-send "Timer finished" "$msg"
  run.sh mplayer $BEEP
  update_session
  popd
}

update_session() {
  current_date=$(date +%d_%m_%Y)
  pattern="([0-9]+) $current_date"
  grep -Eq "$pattern" $session_path
  result=$?
  if [[ $result == 0 ]];then
    # TODO: replace with better regexp
    sed -i -r "s/$pattern/echo \"\$((\\1+1)) $current_date\"/e" $session_path
  else
    echo "1 $current_date" >> $session_path
  fi
}
countdown_loop() {
  local -i counter=$1

  while [[ $counter -gt 0 ]]; do
    let --counter
    # clear line
    echo -ne "\r                                     "
    echo -ne "\rCountdown: $counter"
    sleep 1
  done
}
print_available_sessions() {
  if [ -e "$config_path" ];then
    echo -e "\nThese sessions are available:"
    find $config_path -type f | xargs -I {} basename -s ".session" {} | xargs -n 1 echo -e "\t"
  fi
}
trap_SIG() {
  is_empty=$(wc $session_path -c | cut -f1 -d ' ')
  if [[ $is_empty == 0 ]]; then
    rm "$session_path"
  fi
  exit 1
}
pushd() {
  command pushd "$@" > /dev/null
}

popd() {
  command popd "$@" > /dev/null
}

main "$@"
