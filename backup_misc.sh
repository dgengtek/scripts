#!/bin/bash
#todo: cleanup

bak() {
  source /home/gd/bin/bash/lib/libbackup_base.sh
  args=("$@")

  local prefix="gd"
  main "$prefix/STUDIUM" "/mnt/hdd/bigX/gd/STUDIUM"
  main "$prefix/documents" "/mnt/hdd/bigX/gd/Documents"
  main "$prefix/music" "/mnt/hdd/bigX/gd/Music"
  main "$prefix/pictures" "/mnt/hdd/bigX/gd/pictures"
  main "$prefix/recordings" "/mnt/hdd/bigX/gd/recordings"
  main "$prefix/priv" "/mnt/hdd/bigX/gd/priv"

  prefix="hdd_sidekick"
  main "$prefix/e-books" "/mnt/hdd/bigX/e-books"
  main "$prefix/programming" "/mnt/hdd/bigX/a_Programmieren"

  print_message "Done personal files backup"
}

bak "$@"
