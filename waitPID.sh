#!/bin/bash



args=("$@")
statefile="pidstate"
echo 0 > $statefile

echo "List of supplied PID's: $@"

function cleanup {
  rm $statefile
  exit 1
}

trap cleanup SIGINT SIGTERM

function progress {

  cycle="$(cat $1)"

  case "$cycle" in
    "0")
      echo -ne "\rsleeping |"
      echo 1 > $1
      ;;

    "1")
      echo -ne "\rsleeping /"
      echo 2 > $1
      ;;

    "2")
      echo -ne "\rsleeping -"
      echo 3 > $1
      ;;

    "3")
      echo -ne "\rsleeping \\"
      echo 0 > $1
      ;;
    *)
      echo 0 > $1
      ;;
  esac

  sleep 1

}



for ((i=0; i < $#; i++)) 
{
	echo "waiting for PID: ${args[$i]}"
	while [ -e /proc/${args[$i]} ]
	do
	  progress $statefile
	done
	echo -e "\ndone waiting for PID: ${args[$i]}"

}
echo "wait complete"
rm $statefile
