#!/usr/bin/env bash
set -e


main() {
  if ! hash pacmd 2>/dev/null; then
    echo asexit
    _alsa
    exit 1;
  fi
  _pulse
}


_pulse() {
  local output=$(pacmd list-sinks)
  local indexes=$(echo "$output"|grep "index"|awk -F':' '{print $2}')

  while read -d $'\n' index; do
    if [[ -z $index ]]; then
      echo "no index matched" >&2
      continue
    fi
    pacmd set-sink-mute $index "yes"
  done < <(echo "$indexes")

}


_alsa() {
  amixer -D hw:0 -s -q << EOF
sset Master mute
sset Headphone mute
sset Front mute
EOF
}


main
