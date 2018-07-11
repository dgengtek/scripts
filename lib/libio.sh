#!/usr/bin/env bash
eat_pipe() {
  local -r pipe=$1
#  echo "eating pipe $pipe"
  if ! [[ -p "$pipe"]]; then
    return
  fi
  printf "" > $pipe &
  while read -r trash; do
    :
  done < $pipe
  rm -v "$pipe"
}
mutex() {
  local -r fifolock=$1
  local -r cmd=$2
  if [[ $cmd == "sync" ]]; then
    local -r input=$(cat "$fifolock")
    if [[ $input == "sync" ]]; then
      return 0
    else
      return 1
    fi
  fi
  echo "sync" > "$fifolock"
}
