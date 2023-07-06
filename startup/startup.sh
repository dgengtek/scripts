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

  # TODO: 144hz not working out of box with x11 configuration?
  xrandr --output DisplayPort-2 --mode 1920x1080 --rate 144 --left-of DVI-D-0 --primary;
  xrandr --output DVI-D-0 --mode 1920x1080 --rate 60 --pos 1920x0

  session_exists admin || run.sh -e -- alacritty -e tmux new -s admin
  sleep 1
  session_exists ci || run.sh -e -- alacritty -e bash -c "tmuxp load $HOME/.tmuxp/ci.yaml"
  sleep 1
  pgrep firefox || i3-msg 'workspace "2:1+2:surf"; exec firefox'
  sleep 1
  session_exists private || i3-msg 'workspace "3:1+3:priv"; exec alacritty -e bash -c "tmuxp load $HOME/.tmuxp/private.yaml"'
  sleep 1
  # run.sh -e -- alacritty -e 'tmuxp load ~/.tmuxp/irc.yaml'

  # move all to container and scratchpad later
  session_exists run || i3-msg 'workspace "1:1+7:0"; exec alacritty -e bash -c "tmuxp load $HOME/.tmuxp/run.yaml"'
  session_exists wiki || i3-msg 'workspace "1:1+7:0"; exec alacritty -e bash -c "tmuxp load $HOME/.tmuxp/wiki.yaml"'
  session_exists scratchpad || i3-msg 'workspace "1:1+7:0"; exec alacritty -e bash -c "tmuxp load $HOME/.tmuxp/scratchpad.yaml"'

  # wait until tmux server is up and sessions are running
  while ! tmux has-session >/dev/null 2>&1; do sleep 1; done
  while ! session_exists run; do sleep 1; done
  while ! session_exists ci; do sleep 1; done
  while ! session_exists private; do sleep 1; done
  while ! session_exists admin; do sleep 1; done
  while ! session_exists wiki; do sleep 1; done
  while ! session_exists scratchpad; do sleep 1; done

  # run.sh -e -- urxvt -e 'ssh baha'
  sleep 10 # wait for startup of other sessions to create lock file
  # wait for lock to release
  while [[ -d "$STARTUP_GPG_LOCK" ]]; do
    echo "waiting for lock($STARTUP_GPG_LOCK) to release" >&2
    sleep 1
  done
  # create scratchpad
  pgrep mosh || i3-msg 'workspace "2:3+2:ssh"; exec alacritty -e mosh -p 60000 baha'

  # finish
  sleep 1
  i3-msg 'workspace "1:1+1:shells"'
  systemctl --user start redshift dunst
}

session_exists() {
  tmux has-session -t "${1:?Session required}" >/dev/null 2>&1
}

main "$@"
