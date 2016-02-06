#!/bin/bash
if [ -z "$1" ]; then
  echo "ssh target ip/domain"
fi
path="/home/gd/.ssh/id_rsa_home"
fingerprint=$(ssh-keygen -lf "$path"  | awk '{print $2}')
ssh-add -l |grep -q "$fingerprint" || ssh-add "$path"
ssh gd@"$1"
