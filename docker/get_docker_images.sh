#!/bin/bash
declare -ar images
images=(
"alpine"
"python:alpine"
"centos"
"java:alpine"
)
for i in ${images[@]}; do
  echo "pull image $i"
  docker pull $i
done
