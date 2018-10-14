#!/usr/bin/env bash
usage() {
cat >&2 << EOF
Usage: ${0##*/} <user> <channel> <msg>
send a message via irc
EOF
}

main() {
  local user=$1
  local channel=$2
  if [[ -z $user ]] || [[ -z $channel ]]; then
    usage
    exit 1
  fi

  exec 3>/dev/tcp/$SERVER_IRC/6667
  echo "NICK $user" >&3
  echo "USER $user 8 * : $user" >&3
#  echo "PASS $USER:$PASSWORD"
  echo "JOIN $channel" >&3
  sleep 1
  echo "PRIVMSG $channel $*" >&3
  echo "QUIT" >&3
  cat <&3
}

main "$@"
