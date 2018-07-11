#!/usr/bin/env bash
main () { 
  shredall "$@"
} 

shredall() {
  #shred all files recursively inside directory
  local -r path=$1
  if ! [[ -d $path ]]; then
    echo "No path supplied or is not a directory." >&2
    return 1;
  fi
  echo "Shredding all of $path." >&2
  find "$path" -type f -print0 | xargs -0 -I {} shred -uvz {} \
    && find "$path" -depth -type d -print0 | xargs -0 -I {} rmdir "$path"
}
main "$@"
