#!/usr/bin/env bash
PATH_USER_LIB=${PATH_USER_LIB:-"$HOME/.local/lib"}
source "${PATH_USER_LIB}/libutils.sh"
source "${PATH_USER_LIB}/libcolors.sh"


usage() {
  cat >&2 << EOF
Usage: ${0##*/} [OPTIONS] <filename> [<conditional command> ...]

filename
  input filename which contains a list of directories separated by newlines

conditional command
  skips entering a shell for a directory if the command fails
EOF
}

main() {
  # input lines must be terminated with newlines
  # supply file with directories and enter into an interactive shell if
  #   the command after the first argument succeeds in that directory
  local file_input=$1
  shift
  if ! [[ -f "$file_input" ]]; then
    printcbold $__CC_RED "{{$file_input}} is not a file" >&2
    command echo >&2
    usage
    exit 1
  fi

  local cwd=$PWD
  local -r CPID=$$
  local -a directories=()

  while IFS= read -r -d $'\n' directory; do
    if ! [[ -d "$directory" ]]; then
      printcbold $__CC_RED "{{$directory}} is not a directory" >&2
      command echo >&2
      continue
    fi
    directories+=("$directory")
  done < "$file_input"

  local -r count=${#directories[@]}
  trap "trap - SIGTERM SIGQUIT SIGINT EXIT; builtin cd $cwd; printcbold $__CC_GREEN "Done." >&2; exit" SIGTERM SIGQUIT SIGINT EXIT
  printc $__CC_YELLOW "running interactive subshells for $count directories.
$ byebye # to stop function
"

  for i in $(seq "$count"); do
    pushd "${directories[$i-1]}" >& /dev/null || continue
    if ! bash -c "$*"; then
      printcbold $__CC_RED "==> Condition failed: skipping subshell $i of $count - $PWD" >&2
      command echo >&2
      popd >& /dev/null
      continue
    fi

  bash --init-file <(cat << EOF
source ~/.bashrc
source "${PATH_USER_LIB}/libcolors.sh"
byebye() { kill -SIGTERM \$\$; }
trap "trap - SIGTERM SIGQUIT; kill -SIGTERM $CPID; exit" SIGTERM SIGQUIT
printcbold $__CC_MAGENTA "Enter subshell $i of $count - ">&2;pwd
EOF
)
    popd >& /dev/null
  done
  trap - SIGTERM SIGQUIT SIGINT EXIT
  printcbold $__CC_GREEN "Done." >&2
  command echo >&2
}
main "$@"
