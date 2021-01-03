#!/usr/bin/env bash
# exec 2>&1
# exec 1>/dev/null

main() {
  if ! hash run.sh; then
    echo "Could not find run.sh in path." >&2
    exit 1
  fi

  # TODO: 144hz not working out of box with x11 configuration?
  xrandr --output DisplayPort-2 --mode 1920x1080 --rate 144 --left-of DVI-D-0 --primary;
  xrandr --output DVI-D-0 --mode 1920x1080 --rate 60 --pos 1920x0

  systemctl --user start redshift dunst
  run.sh -n -- firefox
  run.sh -n -- freeplane
  run.sh -n -- alacritty -e 'tmuxp load ~/.tmuxp/wiki.yaml'
  run.sh -n -- alacritty -e 'tmuxp load ~/.tmuxp/private.yaml'
  run.sh -n -- alacritty -e 'tmuxp load ~/.tmuxp/monitor.yaml'
  run.sh -n -- alacritty -e 'tmuxp load ~/.tmuxp/mail.yaml'
  # run.sh -n -- alacritty -e 'tmuxp load ~/.tmuxp/irc.yaml'
  run.sh -n -- alacritty -e 'tmuxp load ~/.tmuxp/ci.yaml'
  run.sh -n -- alacritty -e 'tmux new -s admin'
  run.sh -n -- alacritty -e 'tmux new -s run'

  # wait until tmux server is up and sessions are running
  while ! tmux has-session >/dev/null 2>&1; do sleep 1; done
  while ! tmux has-session -t run >/dev/null 2>&1; do sleep 1; done
  while ! tmux has-session -t mail >/dev/null 2>&1; do sleep 1; done
  while ! tmux has-session -t ci >/dev/null 2>&1; do sleep 1; done
  while ! tmux has-session -t private >/dev/null 2>&1; do sleep 1; done
  while ! tmux has-session -t monitor >/dev/null 2>&1; do sleep 1; done
  while ! tmux has-session -t admin >/dev/null 2>&1; do sleep 1; done

  # run.sh -n -q -- urxvt -e 'ssh baha'
  # wait for gpg2 to close in other session
  while ! [[ -z "$(pgrep gpg2)" ]]; do
    sleep 1
  done
  run.sh -n -q -- alacritty -e 'mosh -p 60000 baha'
}

main "$@"
