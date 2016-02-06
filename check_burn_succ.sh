#!/bin/bash
if [ -z "$1" ];then
  echo "path to iso missing"
  exit 1
fi

isoPath=$1
isoChksum=$(md5sum isoimage.iso)
blocks=$(expr $(du -b "$isoPath" | awk "{print $1}") / 2048)
cdrChksum=$(dd if=/dev/sr0 bs=2048 count="$blocks" | md5sum)



isoChksum=$(echo "$isoChksum"|cut -f1 -d ' ')
cdrChksum=$(echo "$cdrChksum"|cut -f1 -d ' ')

echo "Sum $isoPath: $isoChksum"
echo "Sum cdr: $cdrChksum"

if [ "$isoChksum" == "$cdrChksum" ]; then
  echo "==> checksum is correct"
else
  echo "==> checksum is false"
  exit 1
fi

