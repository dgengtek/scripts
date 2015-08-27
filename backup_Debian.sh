#!/bin/bash
#duplicate of backup_Arch
#deprecated
#backup all config files and wiki

#add backup local bash script binaries

if [ -z "$1" ]
then
  echo "$0 \$1"
  echo "\$1 must be a legit backup path"
  exit 1
fi

copy="rsync"
#add option to backup old files to folder

# backup root path path/backup
# dont use last slash
root="${1%/}"

destpath="$root/noname/files"
backuppath="$destpath/../old_bak"

suffix="_bak"
ferror="sync.errors"

options="-azubvR"
options="$options --backup-dir=$backuppath"
options="$options --suffix=$suffix" 

synccmd="$copy $options"

function updateVars {

  destpath="$root/$1/files"
  backuppath="$destpath/../old_bak"

  options="-azubvR"
  options="$options --backup-dir=$backuppath"
  options="$options --suffix=$suffix" 

  synccmd="$copy $options"

  if ! [ -d $destpath ]
  then
	  mkdir -p $destpath
  elif [ -e "$destpath/../$ferror" ]
  then
	  rm "$destpath/../$ferror"
  fi


}

function syncthis {

	echo "Backup: $1 to $destpath"
	$synccmd $1 $destpath
	if [[ $? != 0 ]]
	then
	  echo "Error $copy:$? for $(pwd)" >> "$destpath/../$ferror"
		return 1
	fi
	
	return 0	
	

}

function backupCmd {
 updateVars $1
 cd $2
 syncthis ./
 cd ~
  
}

#/home/gd/vimwiki
syncthis "vimwiki"
#/home/gd/.vim
syncthis ".vim"
#.config/awesome
syncthis ".config/awesome"
#.config/ranger
syncthis ".config/ranger"
#.bash_aliases
syncthis ".bash_aliases"
#.bash_profile
syncthis ".bash_profile"
#.bashrc
syncthis ".bashrc"
#.rtorrentrc
syncthis ".rtorrent.rc"
#.fehbg
syncthis ".fehbg"
#.tmux.conf
syncthis ".tmux.conf"
#.vimrc
syncthis ".vimrc"
#.xinitrc
syncthis ".xinitrc"
#.Xresources
syncthis ".Xresources"
#.xscreensaver
syncthis ".xscreensaver"
#.zshrc
syncthis ".zshrc"
#.zshrc.zni
syncthis ".zshrc.zni"


#make packagelist backup



