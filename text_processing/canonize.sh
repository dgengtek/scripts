#!/usr/bin/env bash
readonly script_name="filename_canonize.py"
if ! hash "$script_name"; then
  echo "$script_name not found in path." >&2
  exit 1
fi
$script_name -n "$@"
