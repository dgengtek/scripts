#!/usr/bin/env bash
# ------------------------------------------------------------------------------
# description
# ------------------------------------------------------------------------------
# 

usage() {
cat >&2 << EOF
Usage: ${0##*/}
spawn windows for python workspace
EOF
}

main() {
  local CWD=$PWD
  local tests_dir=$CWD
  local src_dir=$CWD
  if [[ -d $CWD/tests ]]; then
    tests_dir="$CWD/tests"
  elif [[ -d $CWD/test ]]; then
    tests_dir="$CWD/test"
  fi
  [[ -d $CWD/src ]] && src_dir="$CWD/src"
  tmux new-window -n sh \; \
    new-window -n src -c "$src_dir" \; \
    new-window -n tests -c "$tests_dir"
}

main "$@"
