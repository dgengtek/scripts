#!/usr/bin/env bash
# add a pending task to read a link

main() {
  hash url_get_title.py

  local -r url=${1:?URL is required}
  shift

  local title=$(url_get_title.py "$url")

  local -a tags=()
  for t in "$@"; do
    tags+=("+$t ")
  done

  task add +read +bookmark +link "${tags[*]}" -- "$title - $url" 
}

set -e
main "$@"
