#!/bin/bash

source /home/gd/bin/bash/lib/libbackup_base.sh "$@"
# needs to be imported by backup_base.sh
#add backup local bash script binaries


#backup all config files and wiki

cd ~ || exit
dest="Arch_bak/home"

updateVars "$dest"
#.bash_aliases
syncthis ".bash_aliases"
#.bash_profile
syncthis ".bash_profile"
#.bashrc
syncthis ".bashrc"

#.zshrc
syncthis ".zshrc"
#.zshrc.zni
syncthis ".zshrc.zni"

#/home/gd/.vim
syncthis ".vim"
#.vimrc
syncthis ".vimrc"
#/home/gd/vimwiki
syncthis "vimwiki"

#.config/awesome
syncthis ".config/awesome"
#.config/ranger
syncthis ".config/ranger"

#.rtorrentrc
syncthis ".rtorrent.rc"
#.fehbg
syncthis ".fehbg"

#.tmux.conf
syncthis ".tmux.conf"

#.xinitrc
syncthis ".xinitrc"
#.Xresources
syncthis ".Xresources"
#.xscreensaver
syncthis ".xscreensaver"

# archive all into tarball
archiveDirectory

prefix="hdd_sidekick/scripting"
dest=$prefix
# bash scripts
#syncthis "bin/bash/"
backupCmd "$dest/bash" "/home/gd/bin/bash"

# fcron scripts
#syncthis "bin/fcrontab/"
backupCmd "$dest/fcrontab" "/home/gd/bin/fcrontab"

# vim scripts
#syncthis "bin/vimscripts/"
backupCmd "$dest/vimscripts" "/home/gd/bin/vimscripts"

printMessage "Done Arch config files backup"
