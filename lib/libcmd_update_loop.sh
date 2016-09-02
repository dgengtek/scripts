#!/bin/bash
loop_cmd() {
while : ; do
  /usr/bin/clear
  eval "$@"
  /usr/bin/sleep 1.5
done
}


