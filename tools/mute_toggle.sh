#!/usr/bin/env bash


main() {
  if ! hash pacmd 2>/dev/null; then
    echo asexit
    alsa_toggle
    exit 1;
  fi
  pulse_toggle
}


pulse_toggle() {
  local output=$(pacmd list-sinks)
  local indexes=$(echo "$output"|grep "index"|awk -F':' '{print $2}')

  while read -d $'\n' index; do
    if [[ -z $index ]]; then
      echo "no index matched" >&2
      continue
    fi
    local answer=$(echo "$output"|grep -A 20 "index: $index"|awk '/mute/ {print $2}')
    if [[ -z $answer ]]; then
      echo "$index: no match in answer" >&2
      continue
    elif [[ $answer == "yes" ]]; then
      answer="no"
    else
      answer="yes"
    fi
    pacmd set-sink-mute $index $answer
  done < <(echo "$indexes")

}


select_index() {
  local index=$1
  local -i valid_selection=0
  while [[ $valid_selection == 0 ]]; do
    local -i counter=0
    for i in $index; do
      echo "${counter}. Index: $i"
      let counter++
    done
    echo "Your selection: "
    read input
    if (($input < $counter)) && (($input >= 0)); then
      selected_index=$input
      break
    fi
  done
}


alsa_toggle() {
  amixer -D hw:0 -s -q << EOF
sset Master toggle 
sset Headphone toggle 
sset Front toggle 
EOF
}


main
