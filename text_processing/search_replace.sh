#!/usr/bin/env bash
readonly SEARCH=${1:?Search string required}
readonly REPLACE=${2:?Replace string required}
readonly PATH=${3:-.}
rg -0 -l "$SEARCH" "$PATH" | xargs -0 -I {} sed -i "s,$SEARCH,$REPLACE,g' {}
