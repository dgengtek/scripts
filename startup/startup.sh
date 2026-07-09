#!/usr/bin/env bash
# exec 2>&1
# exec 1>/dev/null

# lock created from mail session during startup
readonly STARTUP_GPG_LOCK="/tmp/startup_gpg2_lock"

set -x
main() {
  if ! hash run.sh; then
    echo "Could not find run.sh in path." >&2
    exit 1
  fi

  session_exists admin || run.sh -e -- alacritty -e tmux new -s admin
  sleep 1
  session_exists ci || run.sh -e -- alacritty -e bash -c "tmuxp load $HOME/.tmuxp/ci.yaml"
  sleep 1
  pgrep firefox || swaymsg 'workspace "2:1+2 surf"; exec firefox'
  sleep 1
  session_exists privat || swaymsg 'workspace "3:1+3 priv"; exec alacritty -e bash -c "tmuxp load privat"'
  sleep 1
  # run.sh -e -- alacritty -e 'tmuxp load ~/.tmuxp/irc.yaml'

  # move all to container and scratchpad later
  session_exists run || swaymsg 'workspace "7:1+7 0"; exec alacritty -e bash -c "tmuxp load run"'
  session_exists notizen || swaymsg 'workspace "7:1+7 0"; exec alacritty -e bash -c "tmuxp load notizen"'
  session_exists medien || swaymsg 'workspace "7:1+7 0"; exec alacritty -e bash -c "tmuxp load medien"'

  # wait until tmux server is up and sessions are running
  while ! tmux has-session >/dev/null 2>&1; do sleep 1; done
  while ! session_exists run; do sleep 1; done
  while ! session_exists ci; do sleep 1; done
  while ! session_exists privat; do sleep 1; done
  while ! session_exists admin; do sleep 1; done
  while ! session_exists notizen; do sleep 1; done
  while ! session_exists medien; do sleep 1; done
  swaymsg "workspace 7:1+7 0; focus parent; move scratchpad"
  swaymsg 'workspace "1:1+1 shells"; scratchpad show; focus parent; resize grow height 50 px; resize grow width 200 px; move position center; focus child'
}

session_exists() {
  tmux has-session -t "${1:?Session required}" >/dev/null 2>&1
}

main "$@"
