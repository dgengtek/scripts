#!/bin/bash

bak() {
  source /home/gd/bin/bash/lib/libbackup_base.sh
  args=("$@")

  local -r p="Arch_bak/root"
  main "$p/etc/X11" "/etc/X11"
  main "$p" "/etc/fstab"

  print_message "Done Arch system files backup"
}

bak "$@"
