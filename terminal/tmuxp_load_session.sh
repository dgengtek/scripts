#!/usr/bin/env bash

usage() {
cat >&2 << EOF
Usage: ${0##*/}
select tmupx file to load
EOF
}

main() {
  if ! hash fzf; then
    exit 1
  fi
  # can not start a new shell tmux session from inside a session
  # only able to replace the current one
  local spawnshell=
  if ! { [[ "$TERM" =~ "screen" ]] && [[ -n "$TMUX" ]]; } then
    spawnshell="n"
  fi
  local session=
  if [[ -n $1 ]]; then
    session=${TMUXP_PATH}/${1}
  elif ! session=$(find -L "$TMUXP_PATH" -type f -print0 | fzf --no-multi --select-1 --exit-0 --read0); then
    exit 1
  fi
  ! [[ -f $session ]] && exit 1
  local stop_repeat=0
  while ! (($stop_repeat)); do
    stop_repeat=1
    if [[ -z $spawnshell ]]; then
      read -n 1 -p "Start inside new shell?[y/n] >" spawnshell
      echo
    fi
    case $spawnshell in
      "y")
        run.sh urxvt -e bash --init-file <(cat ~/.bashrc;echo "tmuxp load $session";echo "exit 0")
        ;;
      "n")
        tmuxp load "$session"
        ;;
      "*")
        stop_repeat=0
        ;;
    esac
    spawnshell=
  done
}

main "$@"
