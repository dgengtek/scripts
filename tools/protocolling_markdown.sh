#!/usr/bin/env bash
# ------------------------------------------------------------------------------
# script is intended to be run by a service manager or cron
# this blocks synchronisly 
#   will fail if there is already an instance writing to an existing entry
# ------------------------------------------------------------------------------


usage() {
  echo "usage: ${0##*/} [<message>]..."
}


main() {
  local protocol_dir="protocol_admin"
  local protocol_path="$HOME/vimwiki/$protocol_dir"

  protocol_path="$protocol_path/$(date +%Y%m%d).wiki"
  if ! prepare_entry "$protocol_path"; then
    echo "Failed to prepare entry." >&2 
    exit 1
  fi

  urxvt -e $EDITOR "$protocol_path"
}


prepare_entry() {
  # log entry filename
  local file="$1"
  local file_path=$(dirname "$1")
  local message="$2"
  local date_now=$(date +%H:%M)
  # no entries exist skip
  if ! [ -f "$file" ]; then
    touch "$file"
  fi
  if ! [ -d "$file_path" ];then
    mkdir -p "$file_path"
  fi

  grep -q "$date_now" "$file" && return

  # prepare new headers
entry=$(cat <<EOF
= Entry $date_now =

$message
EOF
)
  local tmp=$(mktemp "/tmp/protocolling_markdown_$UID.XXXXXX")
  # copy temporary buffer
  cp "$file" "$tmp"
  # paste to beginning
  echo "$entry" > "$file"
  # add leftovers
  cat "$tmp" >> "$file"
  rm "$tmp"
}


main "$@"
