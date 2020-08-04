#!/usr/bin/env bash
readonly path=${1:?File required}
readonly filename=$(basename "$path" | tr A-Z a-z)
readonly directory=$(dirname "$path")

mv "$path" "${directory}/${filename}"
