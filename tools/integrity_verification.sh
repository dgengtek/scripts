#!/bin/bash

declare -ar cmds=(
md5sum
sha256sum
sha512sum
)
function usage {
echo "$0 cmd file digest"
echo -e "cmd\n\tcmd used for digest"
echo -e "file\n\tcmd used on file"
echo -e "digest\n\tdigest used for comparison"
echo -e "cmds available:"
for ((i= 0; i < ${#cmds[@]}; i++)); do
  echo -e "\t${cmds[$i]}"
done
exit 1
}


if [ -z "$1" ] || [ -z "$2" ] || [ -z "$3" ];then
  usage
fi
cmd=$1
file=$2
expectedSUM=$3

declare -i validCmd=0
for ((i= 0; i < ${#cmds[@]}; i++)); do
  if [[ ${cmds[$i]} == $cmd ]]; then
    let validCmd=1
  fi
done
if [[ $validCmd == 0 ]]; then
  echo -e "invalid cmd supplied\n"
  usage
fi


filesum=($($cmd "$file"))
if [ "$filesum" == "$expectedSUM" ]; then
  exit 0
fi
exit 1

