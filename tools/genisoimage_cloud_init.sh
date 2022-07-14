#!/usr/bin/env bash
# helper for rendering supplied variables for cloud init templates
# and creating a cloud init image

readonly cloud_init_template=$(realpath ${1:?Cloud init template file required})
readonly cloud_init_image=${2:-seedci.iso}
readonly environment_file=$3

set -a
test -f "$environment_file" && source "$environment_file"
set +a

readonly CWD=$PWD
readonly tmp_dir=$(mktemp -d "/tmp/userdataXXXX")
cleanup() {
  rm -rf "$tmp_dir"
}

trap cleanup SIGINT SIGQUIT SIGTERM EXIT

pushd "$tmp_dir"
touch meta-data
cat "$cloud_init_template" | envsubst > user-data
genisoimage -output "${CWD}/${cloud_init_image}" -volid cidata -joliet -rock user-data meta-data

popd
cleanup
trap - SIGINT SIGQUIT SIGTERM EXIT
