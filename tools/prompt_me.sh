#!/usr/bin/env bash

prompt_me() {
  local input=
  if [[ -n $1 ]]; then
    echo "$@" >&2
  fi
  read -n 1 -p "Continue?[y/n] > " input
  input=$(echo -n "$input" | tr [a-z] [A-Z])
  echo
  case $input in
    "Y"|"YES"|"JA"|"J")
      return 0
      ;;
    "N"|"NO"|"NEIN")
      return 1
      ;;
    *)
      prompt_me "$@"
      ;;
  esac
}

prompt_me "$@"
