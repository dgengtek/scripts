#!/bin/env bash


function usage {
echo "$0 pid {pid}"
exit 1
}


args=("$@")
if [ -z $args ];then 
  usage
fi

echo "List of supplied PID's: ${args[@]}"

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
    if [[ $cycle == 4 ]];then
      let cycle=0
    fi
    progress_output $cycle
    let cycle++
  done
}
check_pid_exists() {
  while [ -e /proc/$1 ]; do
    sleep 1
  done
}
pids=()
for ((i=0; i < $#; i++)); do
	check_pid_exists ${args[$i]} &
	pids+=($!)
done


progress &
rc=$!

wait ${pids[@]}
kill $rc

echo "wait complete"
