#!/bin/env bash
main() {
  docker rmi $(docker images | grep none | \
    awk '{FS=" ";print $3}')
}
main
