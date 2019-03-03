#!/usr/bin/env bash
exec 2>&1
exec 1>/dev/null

main() {
  if ! hash run.sh; then
    echo "Could not find run.sh in path." >&2
    exit 1
  fi

  # decrypt smartcard first
  echo | gpg -d
  run.sh -n -q -- firefox
  #run.sh keepassx 
  run.sh -n -q -- urxvtc -e 'tmuxp load ~/.tmuxp/wiki.yaml'
  run.sh -n -q -- urxvtc -e 'tmux new -s mutt'
  run.sh -n -q -- urxvtc -e 'tmuxp load ~/.tmuxp/irc.yaml'
  run.sh -n -q -- urxvtc -e 'tmux new -s salt'
  run.sh -n -q -- urxvtc -e 'mosh baha'

  tmux send-keys -t mutt 'mutt' ENTER
  tmux send-keys -t salt 'lxc exec salt bash' ENTER
}

main "$@"
