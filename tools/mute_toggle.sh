#!/bin/env bash
if hash pacmd 2>/dev/null; then
  answer=""
  if pacmd list-sinks 0|grep -q "muted: yes"; then
    answer="no"
  else
    answer="yes"

  fi
  pacmd set-sink-mute 0 $answer

  exit 1;
fi

amixer -D hw:0 -s -q << EOF
sset Master toggle 
sset Headphone toggle 
sset Front toggle 
EOF

