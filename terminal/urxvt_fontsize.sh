#!/usr/bin/env bash

usage() {
cat >&2 << EOF
Usage: ${0##*/} [<fontsize>]
set <fontsize> of urxvt

default of 18
EOF
}

main() {
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


  _update_fontsize "$fontsize"
  echo "$fontsize" > "/tmp/$file"
}

_update_fontsize() {
  #printf '\33]50;%s\007' xft:terminus:pixelsize=$1
  printf '\33]50;%s\007' xft:xos4 terminus:pixelsize=$1
}

main "$@"
