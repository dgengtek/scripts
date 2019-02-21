#!/usr/bin/env bash
main() {
  if (($#!=0)); then
    echo s
    git diff "$@"
    return "$?"
  fi
    echo ss
  local git_pager=$(git config --get core.pager)
  (
    git diff --color
    git ls-files --others --exclude-standard |
      while read -r file; do
        git diff --color -- /dev/null "$file"
      done
  ) | "${git_pager:-${PAGER:-less}}"


}


main "$@"
