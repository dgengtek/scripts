#!/usr/bin/env bash
usage() {
  cat >&2 << EOF
Usage:	${0##*/} <source> <destination>

source  where files to find for conversion
destination  where to copy results
EOF
}
main() {
  local source=${1:?Source path required}
  local destination${2:?Destination path required}

  if ! test -d "$source" || ! test -d "$destination"; then
    echo "Either $source or $destination is not a directory." >&2
    exit 1
  fi
  pushd "$destination"
  find "$source" -type f | parallel ffmpeg -i {} -c libmp3lame -aq 3 {/.}.mp3
  popd
}
main "$@"
