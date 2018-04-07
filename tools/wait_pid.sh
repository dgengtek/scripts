#!/bin/env bash

usage() {
  cat >&2 << EOF
Usage: ${0##*/} <pid>...

Wait for <pid>... to finish execution.
EOF
}

main() {
  if [[ -z $@ ]];then 
    usage
    exit 1
  fi
  echo "PID's: $@" >&2

  local -a pids=()
  while [[ -n $1 ]]; do
    check_pid_exists "$1" &
    pids+=($!)
    shift
  done

  progress &
  rc=$!

  wait ${pids[@]}
  kill $rc

  echo -e "\nwait complete" >&2
}

progress_output() {
  case "$1" in
    "0")
      echo -ne "\rsleeping |"
      ;;

    "1")
      echo -ne "\rsleeping /"
      ;;

    "2")
      echo -ne "\rsleeping -"
      ;;

    "3")
      echo -ne "\rsleeping \\"
      ;;
    *)
      ;;
  esac
  sleep 1
}

progress() {
  declare -i cycle=0
  while :; do
    if (($cycle%4 == 0 ));then
      let cycle=0
    fi
    progress_output $cycle >&2
    let cycle++
  done
}

check_pid_exists() {
  while [[ -e "/proc/$1" ]]; do
    sleep 1
  done
}

main "$@"
