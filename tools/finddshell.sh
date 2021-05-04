#!/usr/bin/env bash

usage() {
  cat >&2 << EOF
Usage: ${0##*/} [OPTIONS] <filename> [<conditional command> ...]

filename
  input filename which contains a list of directories separated by newlines

conditional command
  skips entering a shell for a directory if the command fails

OPTIONS:
  -h  help
  -v  verbose
  -q  quiet
  -d  debug
  -p,--path <directory>  some directory
EOF
}

main() {
  # input lines must be terminated with newlines
  # supply file with directories and enter into an interactive shell if
  #   the command after the first argument succeeds in that directory
  local file_input=$1
  shift
  if ! [[ -f "$file_input" ]]; then
    echo "{{$file_input}} is not a file" >&2
    usage
    exit 1
  fi

  local cwd=$PWD
  local -r CPID=$$
  local -a directories=()

  while IFS= read -r -d $'\n' directory; do
    if ! [[ -d "$directory" ]]; then
      echo "{{$directory}} is not a directory" >&2
      continue
    fi
    directories+=("$directory")
  done < "$file_input"

  local -r count=${#directories[@]}
  trap "trap - SIGTERM SIGQUIT; builtin cd $cwd; echo 'we are done with interactivity'>&2; exit" SIGTERM SIGQUIT SIGINT EXIT
  cat << EOF
running interactive subshells for $count directories.
$ byebye # to stop function
EOF

  for i in $(seq "$count"); do
    pushd "${directories[$i-1]}" >& /dev/null || continue
    if ! bash -c "$*"; then
      echo "==> Condition failed: skipping subshell $i of $count - $PWD" >&2
      popd >& /dev/null
      continue
    fi

  bash --init-file <(cat << EOF
source ~/.bashrc
byebye() { kill -SIGTERM \$\$; }
trap "trap - SIGTERM SIGQUIT; kill -SIGTERM $CPID; exit" SIGTERM SIGQUIT
echo -n "Enter subshell $i of $count - ">&2;pwd
EOF
)
    popd >& /dev/null
  done
  trap - SIGTERM SIGQUIT SIGINT EXIT
  echo "Done." >&2
}
main "$@"
