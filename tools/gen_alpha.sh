#!/bin/bash
length=$1
if [ -z "$length" ];then
  length=8
fi
tr -cd [:alnum:] < /dev/urandom | head -c "$length" | xargs -0
