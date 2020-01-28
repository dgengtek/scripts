#!/usr/bin/env bash
readonly SEARCH=${1:?Search string required}
readonly REPLACE=${2:?Replace string required}
shift 2
if [[ -z "$3" ]]; then
  readonly SEARCH_PATH="."
else
  readonly SEARCH_PATH=$3
  shift
fi

set -x
rg "$@" -0 -l "$SEARCH" "$SEARCH_PATH" | xargs -0 -I {} sed -i "s,$SEARCH,$REPLACE,g" {}
