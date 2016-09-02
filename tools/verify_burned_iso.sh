#!/bin/env bash
if [ -z "$1" ];then
  echo "no iso given as argument"
  exit 1
fi

isoname=$1
echo "supplied iso: $isoname"
isosum=$(md5sum $"isoname")
echo -en "md5sum of iso:\n$isosum\n\n"

blocks=$(expr $(du -b "$isoname" | awk '{print $1}') / 2048)

checkdevsum=$(dd if=/dev/sr0 bs=2048 count="$blocks" | md5sum)

checkdevsum=${checkdevsum%-}
isosum=$(echo "$isosum"|cut -f1 -d ' ')
echo -en "\n\nSum of iso on dev: \n$checkdevsum\n"

if [ "$isosum" == "$checkdevsum" ]; then
  echo "==> Iso checksum is correct"
else
  echo "==> Iso checksum is false"
fi

