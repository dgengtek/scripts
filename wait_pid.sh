#!/bin/bash



args=("$@")
echo "List of supplied PID's: $@"

function progress {
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


for ((i=0; i < $#; i++)) 
{
	echo "waiting for PID: ${args[$i]}"
	declare -i cycle=0
	while [ -e "/proc/${args[$i]}" ]
	do
	  if [[ $cycle == 4 ]];then
	    let cycle=0
	  fi
	  progress $cycle
	  let cycle++
	done
	echo -e "\ndone waiting for PID: ${args[$i]}"

}
echo "wait complete"
