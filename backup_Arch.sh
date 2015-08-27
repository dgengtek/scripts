#!/bin/bash

source /home/gd/bin/bash/backup_base.sh $1
# needs to be imported by backup_base.sh
#add backup local bash script binaries


#backup all config files and wiki

cd ~
updateVars "Arch_bak/home"

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


prefix="hdd_sidekick/scripting"
# bash scripts
#syncthis "bin/bash/"
backupCmd "$prefix/bash" "/home/gd/bin/bash"


# fcron scripts
#syncthis "bin/fcrontab/"
backupCmd "$prefix/fcrontab" "/home/gd/bin/fcrontab"

# vim scripts
#syncthis "bin/vimscripts/"
backupCmd "$prefix/vimscripts" "/home/gd/bin/vimscripts"

echo -en "\n####################################"
echo "####################################"
echo "Done Arch config files backup"
echo "####################################"
echo -en "####################################\n\n"
