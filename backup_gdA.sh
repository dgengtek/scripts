#!/bin/bash
source /home/gd/bin/bash/backup_base.sh $1
#backup all config files and wiki

cd ~
updateVars "Arch_bak/root"
#per HOST own backup, probably create new bash script for this
#GD_A
#/etc/X11
syncthis "/etc/X11"
#/etc/fstab
syncthis "/etc/fstab"


#make packagelist backup
pacman -Qqe > $destpath/../packagelist.$(date +%F).txt



echo -en "\n####################################"
echo "####################################"
echo "Done Arch system files backup"
echo "####################################"
echo -en "####################################\n\n"
