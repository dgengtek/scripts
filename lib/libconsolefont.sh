#!/bin/env bash
# set fontsize of urxvt
fontsize_set() {
  local -r file="system_fontsize"
  if ! [[ -f $file ]]; then
    echo "18" > /tmp/$file
  fi
  local -i fontsize=$(cat /tmp/$file)
  if [[ -z $1 ]]; then
    fontsize=18
  elif [[ $1 == "+" ]]; then
    fontsize=$((fontsize + 2))
  elif [[ $1 == "-" ]]; then
    fontsize=$((fontsize - 2))
  elif (($1 > 12)); then
    fontsize=$1
  fi
  __5XBnCcVj_fontsize_update $fontsize
  echo "$fontsize" > /tmp/$file
}

__5XBnCcVj_fontsize_update() {
  printf '\33]50;%s\007' xft:terminus:pixelsize=$1
}
