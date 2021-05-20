#!/usr/bin/env bash
main() {
  local dir
  if [[ -z $1 ]]; then
    dir="."
  else
    dir=$1
    shift
  fi
  if ! pushd "$dir" 2>&1 >/dev/null; then
    echo "Could not push to directory '$dir'" >&2 
    return 1
  fi
  while read -r -d $'\n' file ; do
    [[ -z "$file" ]] && continue
    realpath -e "$file"
  done < <(fzf --preview 'bat --color=always --style=numbers --line-range=:500 {}' --multi "$@")
  popd 2>&1 >/dev/null
}
main "$@"
