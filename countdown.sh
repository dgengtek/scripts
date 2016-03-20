#!/bin/bash
# todo: add supplied seconds to session database in file

function pushd {
  command pushd "$@" > /dev/null
}

function popd {
  command popd "$@" > /dev/null
}



time_seconds=$1
session_name=${2}.session
config_path=".countdown"
session_path=$config_path/$session_name

function print_available_sessions {
  if [ -e $config_path ];then
    echo -e "\n\nThese sessions are available:\n"
    ls -1 $config_path/*.session
  fi
}

function trapping_SIG {
  rm "$session_path"
  exit 1
}

if [ -z "$time_seconds" ];then
  cd ~
  echo "specify countdown time in seconds"
  print_available_sessions
  exit 1;
fi
if [ -z "$session_name" ];then
  session_name="session"
  session_path="$config_path/$session_name"
fi


pushd ~
if ! [ -e "$session_path" ];then
  mkdir -p "$config_path"
  pushd "$config_path" || exit
  echo "create session"
  touch $session_name
  trap trapping_SIG SIGHUP SIGKILL SIGINT
  popd
fi


function update_session {
  current_date=$(date +%d_%m_%Y)
  pattern="([0-9]+) $current_date"
  grep -Eq "$pattern" $session_path
  result=$?
  if [ $result == 0 ];then
    sed -i -r "s/$pattern/echo \"\$((\\1+1)) $current_date\"/e" $session_path
  else
    echo "1 $current_date" >> $session_path
  fi

}


function counter_loop {
  declare -i counter=$1

  while [[ $counter -gt 0 ]]
  do
    echo -ne "\r                                     "
    echo -ne "\rCountdown: $counter"
    let --counter
    sleep 1
  done

}

counter_loop "$time_seconds"

declare -i time_minutes=$time_seconds/60
output="\r--> Countdown of "
msgsend=""
if [[ $time_minutes -lt 1 ]];then
  output="$output$time_seconds seconds"
  msgsend="$time_seconds seconds"
else
  output="$output$time_minutes minutes"
  msgsend="$time_minutes minutes"
fi
output="$output, finished\n"
echo -en "$output"
notify-send "Timer finished" "$msgsend"
run mplayer $BEEP
update_session
popd
