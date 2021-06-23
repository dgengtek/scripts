#!/usr/bin/env bash
# exec 2>&1
# exec 1>/dev/null

# lock created from mail session during startup
readonly STARTUP_GPG_LOCK="/tmp/startup_gpg2_lock"

main() {
  if ! hash run.sh; then
    echo "Could not find run.sh in path." >&2
    exit 1
  fi

  # TODO: 144hz not working out of box with x11 configuration?
  xrandr --output DisplayPort-2 --mode 1920x1080 --rate 144 --left-of DVI-D-0 --primary;
  xrandr --output DVI-D-0 --mode 1920x1080 --rate 60 --pos 1920x0

  run.sh -e -- freeplane
  run.sh -e -- alacritty -e 'tmux new -s admin'
  i3-msg 'workspace "2:surf"; exec firefox'
  i3-msg 'workspace "3:priv"; exec alacritty -e bash -c "tmuxp load $HOME/.tmuxp/private.yaml"'
  # run.sh -e -- alacritty -e 'tmuxp load ~/.tmuxp/irc.yaml'

  # move all to container and scratchpad later
  i3-msg 'workspace "8:0"; exec alacritty -e bash -c "tmuxp load $HOME/.tmuxp/ci.yaml"'
  i3-msg 'workspace "8:0"; exec alacritty -e bash -c "tmuxp load $HOME/.tmuxp/run.yaml"'
  i3-msg 'workspace "8:0"; exec alacritty -e bash -c "tmuxp load $HOME/.tmuxp/scratchpad.yaml"'
  i3-msg 'workspace "8:0"; exec alacritty -e bash -c "tmuxp load $HOME/.tmuxp/wiki.yaml"'

  # wait until tmux server is up and sessions are running
  while ! tmux has-session >/dev/null 2>&1; do sleep 1; done
  while ! tmux has-session -t run >/dev/null 2>&1; do sleep 1; done
  while ! tmux has-session -t ci >/dev/null 2>&1; do sleep 1; done
  while ! tmux has-session -t private >/dev/null 2>&1; do sleep 1; done
  while ! tmux has-session -t admin >/dev/null 2>&1; do sleep 1; done
  while ! tmux has-session -t wiki >/dev/null 2>&1; do sleep 1; done
  while ! tmux has-session -t scratchpad >/dev/null 2>&1; do sleep 1; done

  # run.sh -e -- urxvt -e 'ssh baha'
  sleep 10 # wait for startup of other sessions to create lock file
  # wait for lock to release
  while [[ -d "$STARTUP_GPG_LOCK" ]]; do
    echo "waiting for lock($STARTUP_GPG_LOCK) to release" >&2
    sleep 1
  done
  run.sh -e -- alacritty -e 'mosh -p 60000 baha'
  systemctl --user start redshift dunst
  i3-msg 'workspace "8:0"; focus parent; move scratchpad'
  i3-msg 'workspace "1:shells"'
}

main "$@"
