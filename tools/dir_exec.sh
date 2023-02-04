#!/usr/bin/env bash
PATH_USER_LIB=${PATH_USER_LIB:-"$HOME/.local/lib"}
source "${PATH_USER_LIB}/libutils.sh"
source "${PATH_USER_LIB}/libcolors.sh"

usage() {
  cat >&2 << EOF
Usage: ${0##*/} [OPTIONS] <command>

Expects input of directories separated by the character '\0'

command
  Run a command in each directory
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
      printcbold $__CC_RED "{{${directory}}} is not a directory" >&2
      command echo >&2
      continue
    fi
    let i+=1
    pushd "$directory" >& /dev/null || continue
    output=$(bash -c "$*" 2>&1)
    rc=$?
    if (($rc == 0)); then
      printcbold $__CC_MAGENTA "# $i - " >&2
      command echo "$directory"
      [[ -n "$output" ]] && command echo "$output" >&2
      command echo >&2
    fi
    popd >& /dev/null
  done 
  trap - SIGTERM SIGQUIT SIGINT EXIT
  exec 3<&-
}
main "$@"
