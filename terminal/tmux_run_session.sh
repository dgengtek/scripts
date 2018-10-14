#!/usr/bin/env bash

usage() {
cat >&2 << EOF
Usage: ${0##*/}
use run.sh to run commands in specific tmux run session
EOF
}

main() {
  local -r session=run
  local -r window_name="window$RANDOM"
  if ! hash run.sh; then
    echo "Could not find run.sh in path." >&2
    exit 1
  fi
  if ! tmux has-session -t "$session" 2>/dev/null; then
    tmux new-session -d -s "$session" -n 0
  fi
  tmux send-keys -t "${session}:0" "tmux neww -d -n '$window_name' \"\
    run.sh -m -f -- '$*';\
    printf '[%s] exited, ^D to exit.\\n' '$*';\
    cat>/dev/null\"" ENTER

}

main "$@"
