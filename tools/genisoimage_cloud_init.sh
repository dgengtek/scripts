#!/usr/bin/env bash
# helper for rendering supplied variables for cloud init templates
# and creating a cloud init image

readonly cloud_init_template=${1:?Cloud init template file required}
readonly environment_file=${2:?Environment file required}
readonly template=$(realpath "$cloud_init_template")

set -a
source "$environment_file"
set +a

readonly CWD=$PWD
readonly tmp_dir=$(mktemp -d "/tmp/userdataXXXX")
cleanup() {
  rm -rf "$tmp_dir"
}

trap cleanup SIGINT SIGQUIT SIGTERM EXIT

pushd "$tmp_dir"
touch meta-data
cat "$template" | envsubst > user-data
genisoimage -output "${CWD}/seedci.iso" -volid cidata -joliet -rock user-data meta-data

popd
cleanup
trap - SIGINT SIGQUIT SIGTERM EXIT
