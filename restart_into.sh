#!/bin/bash
if [ -z $1 ]; then
  echo "$0 menuid"
  echo "menuid  menuid in grub menu"
  exit 1
fi
sudo grub-set-default $1
shutdown -r now
