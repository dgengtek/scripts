#!/usr/bin/env bash
readonly shell_name=${1:-alacritty}
readonly shell_bin=$(whereis "$shell_name" | awk '{print $2}')

if ! hash "$shell_name"; then
  echo "$shell_name does not exist" >&2
  exit 1
fi

forkexec() {
  exec "$shell_bin"
}

forkexec &
