#!/bin/bash

declare -ar cmds=(
md5sum
sha256sum
sha512sum
)
function usage {
echo "$0 cmd file digest"
echo -e "cmd\tcmd used for digest"
echo -e "file\tcmd used on file"
echo -e "digest\tdigest used for comparison"
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


filesum=$($cmd < "$file")

echo "Sum $file: $filesum"
echo "Sum expected: $expectedSUM"

if [ "$filesum" == "$expectedSUM" ]; then
  echo "==> checksum is correct"
  exit 0
else
  echo "==> checksum is false"
  exit 1
fi

