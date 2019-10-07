#!/usr/bin/env bash
exec 2>&1
exec 1>/dev/null

main() {
  if ! hash run.sh; then
    echo "Could not find run.sh in path." >&2
    exit 1
  fi

  run.sh -n -q -- firefox
  #run.sh keepassx 
  run.sh -n -q -- alacritty -e 'tmuxp load ~/.tmuxp/wiki.yaml'
  run.sh -n -q -- alacritty -e 'tmux new -s mutt'
  run.sh -n -q -- alacritty -e 'tmuxp load ~/.tmuxp/irc.yaml'
  run.sh -n -q -- alacritty -e 'tmux new -s salt'
  run.sh -n -q -- alacritty -e 'tmux new -s ci'
  run.sh -n -q -- alacritty -e 'mosh -p 60000 baha -- sudo -u admin -i'

  # wait until tmux server is up
  while ! tmux has-session >/dev/null 2>&1; do sleep 1; done
  while ! tmux has-session -t mutt >/dev/null 2>&1; do sleep 1; done
  while ! tmux has-session -t salt >/dev/null 2>&1; do sleep 1; done
  while ! tmux has-session -t ci >/dev/null 2>&1; do sleep 1; done
  tmux send-keys -t mutt 'mutt' ENTER
  tmux send-keys -t salt 'lxc exec salt bash' ENTER
  tmux send-keys -t ci 'fly -t intranet login && watch fly -t intranet builds' ENTER
}

main "$@"
