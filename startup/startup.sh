#!/usr/bin/env bash
exec 2>&1
exec 1>/dev/null

main() {
  if ! hash run.sh; then
    echo "Could not find run.sh in path." >&2
    exit 1
  fi

  xrandr --output DisplayPort-2 --mode 1920x1080 --rate 144 --left-of DVI-D-0 --primary;
  xrandr --output DVI-D-0 --mode 1920x1080 --rate 60 --pos 1920x0

  systemctl --user start redshift dunst
  run.sh -n -q -- firefox
  run.sh -n -q -- freeplane
  run.sh -n -q -- alacritty -e 'tmuxp load ~/.tmuxp/wiki.yaml'
  run.sh -n -q -- alacritty -e 'tmuxp load ~/.tmuxp/private.yaml'
  run.sh -n -q -- alacritty -e 'tmuxp load ~/.tmuxp/monitor.yaml'
  run.sh -n -q -- alacritty -e 'tmux new -s mutt'
  # run.sh -n -q -- alacritty -e 'tmuxp load ~/.tmuxp/irc.yaml'
  run.sh -n -q -- alacritty -e 'tmux new -s ci'
  run.sh -n -q -- alacritty -e 'tmux new -s admin'
  run.sh -n -q -- alacritty -e 'tmux new -s run'

  # wait until tmux server is up
  while ! tmux has-session >/dev/null 2>&1; do sleep 1; done
  while ! tmux has-session -t run >/dev/null 2>&1; do sleep 1; done
  while ! tmux has-session -t mutt >/dev/null 2>&1; do sleep 1; done
  while ! tmux has-session -t ci >/dev/null 2>&1; do sleep 1; done
  while ! tmux has-session -t private >/dev/null 2>&1; do sleep 1; done
  while ! tmux has-session -t monitor >/dev/null 2>&1; do sleep 1; done
  while ! tmux has-session -t admin >/dev/null 2>&1; do sleep 1; done

  tmux send-keys -t mutt 'mutt' ENTER
  tmux send-keys -t ci 'fly -t intranet login && watch fly -t intranet builds' ENTER
  # TODO: wait for pinentry to successfully close
  # run.sh -n -q -- urxvt -e 'ssh baha'
  # run.sh -n -q -- alacritty -e 'mosh -p 60000 baha'
}

main "$@"
