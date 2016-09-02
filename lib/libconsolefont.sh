#!/bin/bash
_set_fontsize() {
  local -r file="system_fontsize"
  if ! [ -f "$file" ]; then
    echo "18" > /tmp/$file
  fi
  local -i fontsize=$(cat /tmp/$file)
  if [ $1 == "+" ]; then
    fontsize=$((fontsize + 2))
  elif [ $1 == "-" ]; then
    fontsize=$((fontsize - 2))
  else 
    fontsize=18
  fi
  _update_fontsize $fontsize
  echo "$fontsize" > /tmp/$file
}

_update_fontsize() {
  printf '\33]50;%s\007' xft:terminus:pixelsize=$1
}
