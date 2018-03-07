#!/bin/env bash

declare -ar cmds=(
md5sum
sha256sum
sha512sum
sha1sum
)
usage() {
  cat << EOF
Usage: ${0##*/} cmd (digest|file) filename
cmd         cmd used for creating digest
file        cmd used on file
digest      digest used for comparison

cmds:       ${cmds[@]}
EOF
  exit 1
}


if [ -z "$1" ] || [ -z "$2" ] || [ -z "$3" ];then
  usage
fi
cmd=$1
digest=$2
file=$3

declare -i cmd_exists=0
for ((i= 0; i < ${#cmds[@]}; i++)); do
  if [[ ${cmds[$i]} == $cmd ]]; then
    let cmd_exists=1
  fi
done
if [[ $cmd_exists == 0 ]]; then
  echo "invalid cmd supplied"
  usage
fi

if [[ -f $digest ]]; then
  digest=$($cmd $digest | awk '{$0=$1;print}')
fi

digest2=$($cmd "$file" | awk '{$0=$1;print}')
if [[ "$digest" == "$digest2" ]]; then
  exit 0
fi
echo "$digest != $digest2" >&2
exit 1
