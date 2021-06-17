#!/usr/bin/env bash
# helper for rendering supplied variables for cloud init templates

readonly template=${1:?Template file required}
readonly environment_file=${2:?Environment file required}

set -a
source "$environment_file"
set +a

cat "$template" | envsubst
