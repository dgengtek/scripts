#!/bin/bash

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

destpath="$root/noname"
backuppath="$destpath/old_bak"

suffix="_bak"
ferror="sync.errors"

options="-azubR"
# options="-azubvR"
options="$options --backup-dir=$backuppath"
options="$options --suffix=$suffix" 

synccmd="$copy $options"

function updateVars {

  destpath="$root/$1"
  backuppath="$destpath/old_bak"

  options="-azubR"
# options+="v"
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

  echo "Backup: $PWD/$1 to $destpath"
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


#. /home/gd/bin/bash/tmp/backup_Arch.sh
#. /home/gd/bin/bash/tmp/backup_gdA.sh
#. /home/gd/bin/bash/tmp/backup_misc.sh
