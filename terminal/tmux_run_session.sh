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
  local -r cwd="$PWD"
  if ! hash run.sh; then
    echo "Could not find run.sh in path." >&2
    exit 1
  fi
  if ! tmux has-session -t "$session" 2>/dev/null; then
    tmux new-session -d -s "$session" -n 0
  fi
  local -r command=$(quotify.py "$*")
  local -a commands
  commands+=("cd '$cwd';")
  commands+=("run.sh -m -f -- '$command';")
  commands+=("echo -e '[$command] exited, ^D to exit.\\n' ;")
  commands+=("cat>/dev/null;")

  local -r command_string=$(quotify.py "${commands[*]}")
  tmux send-keys -t "${session}:0" "tmux neww -d -n '$window_name' $command_string" ENTER

}

main "$@"
