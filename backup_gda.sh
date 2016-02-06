#!/bin/bash
source /home/gd/bin/bash/lib/libbackup_base.sh "$@"
#backup all config files and wiki

cd ~ || exit
updateVars "Arch_bak/root"
#per HOST own backup, probably create new bash script for this
#GD_A
#/etc/X11
syncthis "/etc/X11"
#/etc/fstab
syncthis "/etc/fstab"


#make packagelist backup
pacman -Qqe > "${destpath}/../packagelist_$(date +%d%m%y).txt"

archiveDirectory

printMessage "Done Arch system files backup"
