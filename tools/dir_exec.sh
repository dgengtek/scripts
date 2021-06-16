#!/usr/bin/env bash

usage() {
  cat >&2 << EOF
Usage: ${0##*/} [OPTIONS] <command>

Expects input of directories separated by the character '\0'

command
  Run a command in each directory

OPTIONS:
  -h  help
  -v  verbose
  -q  quiet
  -d  debug
  -p,--path <directory>  some directory
EOF
}


main() {
  if [[ -z "$1" ]]; then
    usage
    exit 1
  fi

  local -r cwd=$PWD
  local -i i=0

  exec 3<&0
  trap "builtin cd $cwd;exec 3<&-;exit" SIGTERM SIGQUIT SIGINT EXIT
  local output=
  local rc=
  cat >&2 << EOF
Expects input list to be separated by newlines '\n'

Capture output to receive a list of directories 
which succeeded at running the supplied command. -- '$@'

EOF

  while IFS= read -r -u 3 -d $'\n' directory; do
    if ! [[ -d "$directory" ]]; then
      echo "{{${directory}}} is not a directory" >&2
      continue
    fi
    let i+=1
    pushd "$directory" >& /dev/null || continue
    output=$(bash -c "$*" 2>&1)
    rc=$?
    if (($rc == 0)); then
      echo -n "# $i - " >&2
      echo "$directory"
      [[ -n "$output" ]] && echo "$output" >&2
      echo >&2
    fi
    popd >& /dev/null
  done 
  trap - SIGTERM SIGQUIT SIGINT EXIT
  exec 3<&-
}
main "$@"
