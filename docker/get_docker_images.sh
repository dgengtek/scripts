#!/bin/env bash
main() {
  local -ar images
  images=(
  "alpine"
  "python:alpine"
  "centos"
  "java:alpine"
  "debian"
  )
  for i in ${images[@]}; do
    echo "pull image $i"
    docker pull $i
  done
}
main 
