#!/bin/bash

bak() {
  source /home/gd/bin/bash/lib/libbackup_base.sh
  # set args in lib
  args=("$@")

  #backup all config files and wiki
  cd ~ || exit

  local -r p="Arch_bak/home"

  declare -ar files=(
  ".bash_aliases"
  ".bash_profile"
  ".bash_exports"
  ".bash_prompt"
  ".bashrc"
  ".inputrc"
  ".zshrc"
  ".zshrc.zni"
  ".vim"
  ".vimrc"
  "vimwiki"
  ".config/awesome"
  ".config/ranger"
  ".rtorrent.rc"
  ".fehbg"
  ".tmux.conf"
  ".xinitrc"
  ".Xresources"
  ".xscreensaver"
  )
  main "$p" "${files[@]}" 


  prefix="hdd_sidekick/scripting"
  main "$prefix/bash" "/home/gd/bin/bash"
  main "$prefix/cron" "/home/gd/bin/cron"
  main "$prefix/vimscripts" "/home/gd/bin/vimscripts"

  print_message "Arch config files backup done"
}

bak "$@"
