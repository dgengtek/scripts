#!/usr/bin/env bash
usage() {
  cat << EOF
Usage: ${0##*/} iso [device]

iso         iso to check
device      optional device to check against(default:/dev/sr0)
EOF
  exit 1

}
isoname=$1
device=${2:-/dev/sr0}
if [[ -z $1 ]] && ! [[ -e $device ]]; then
  usage
fi

echo "supplied iso: $isoname"
isosum=$(md5sum $"isoname")
echo -en "md5sum of iso:\n$isosum\n\n"

blocks=$(expr $(du -b "$isoname" | awk '{print $1}') / 2048)

checkdevsum=$(dd if="$device" bs=2048 count="$blocks" | md5sum)

checkdevsum=${checkdevsum%-}
isosum=$(echo "$isosum"|cut -f1 -d ' ')
echo -en "\n\nSum of iso on dev: \n$checkdevsum\n"

if [[ "$isosum" == "$checkdevsum" ]]; then
  echo "==> Iso checksum is correct"
  return 0
else
  echo "==> Iso checksum is false"
  return 1
fi
