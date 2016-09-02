#!/bin/bash
docker rmi $(docker images | grep none | \
  awk '{FS=" ";print $3}')
