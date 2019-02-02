#!/usr/bin/env bash


usage() {
  echo "usage: ${0##*/}"
  exit 1
}


main() {
  local protocol_log="$HOME/.var/log/vimwiki_protocol_log_"
  local -i entry_count=0
  local -i editor_pid
  if [ -e $protocol_log ]; then
    entry_count="$(sed 1!d $protocol_log)"
    editor_pid="$(sed 2!d $protocol_log)"
  fi
  local protocol_dir="protocol_admin"
  local protocol_path="$HOME/vimwiki/$protocol_dir"

  year="$(date +%Y)"
  month="$(date +%m_%b)"
  day="$(date +%V_%d_%a)"

  protocol_path+="/${year}/${month}/${day}.wiki"

  check_entry_running "$protocol_path" $editor_pid

  prepare_entry "$protocol_path"

  urxvt -e vim $protocol_path &
  editor_pid=$!
  update_tmp

  # wait in background and handle tmp file
  #wait_for_finish "$protocol_log" "$editor_pid" &

}


wait_for_finish() {
  local file="$1"
  local pid="$2"
  while [ -e /proc/$pid ]; do
    sleep 1
  done
  # todo change this entry
  sleep 20
  sed -i 2d $file
}


update_tmp() {
  echo "$entry_count" > "$protocol_log"
  echo "$editor_pid" >> "$protocol_log"
}


check_entry_running() {
  local file="$1"
  local pid=$2
  # if editor is stil open with the entry
  # kill editor since possibly afk
  echo "pid:$pid"
  if [ -e /proc/$pid ] &&
    [[ $pid != 0 ]]; then
    echo "kill:$pid"
    kill $pid
    sed -i '2i afk' $file
  fi
}


prepare_entry() {
  # log entry filename
  local file="$1"
  local file_path="${1%/*}"
  local message="$2"
  local tmp="$(mktemp /tmp/protocol.XXXXXX)"
  local log_path="$HOME/.var/log"
  mkdir -p $log_path
  # if dir doesnt exist, new day
  if ! [ -e $file ];then
    mkdir -p "$file_path"
    let entry_count=1
  else
    let entry_count+=1
  fi
  # prepare new headers
entry=$(cat <<EOF
= Entry $entry_count $(date +%H:%M)=

$message
EOF
)

  # copy temporary buffer
  cp "$file" "$tmp"
  # paste to beginning
  echo "$entry" > "$file"
  # add leftovers
  cat "$tmp" >> "$file"
  rm "$tmp"
}


main "$@"
