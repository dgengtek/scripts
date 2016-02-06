#!/bin/bash

#add backup local bash script binaries
optlist=":a"

function usage {
  echo "$0 [-a] backuppath"
  echo "-a  archive and compress files"
  exit 1
}

declare -i enableArchiving=0
while getopts $optlist opt; do
  case $opt:
    a)
      let enableArchiving=1
      ;;
    *)
      usage
  esac
done



if [ -z "$1" ]
then
  echo "no backuppath supplied"
  exit 1
fi

copy="rsync"
#add option to backup old files to folder

# backup root path path/backup
# dont use last slash
root="${1%/}"

destpath="$root/noname"
backuppath="$destpath/../old_bak"

suffix="_bak"
ferror="sync.errors"

options="-azubR"
# options="-azubvR"
options="$options --backup-dir=$backuppath"
options="$options --suffix=$suffix" 

synccmd="$copy $options"

function updateVars {

  destpath="$root/$1"
  backuppath="${destpath%/}/../old_bak"

  options="-azubR"
# options+="v"
  options="$options --backup-dir=$backuppath"
  options="$options --suffix=$suffix" 

  synccmd="$copy $options"

  if ! [ -d "$destpath" ]
  then
	  mkdir -p "$destpath"
  elif [ -e "$destpath/../$ferror" ]
  then
	  rm "$destpath/../$ferror"
  fi


}

function archiveDirectory {
  # remove trailing slash
  # remove front
  if ! [[ $enableArchiving ]]; then
    return
  fi
  archivename="${destpath%/}"
  archivename="${archivename##*/}"
  tar -cvzf "$destpath/../${archivename}_$(date +%d%m%y).tar.gz" -C\
 "$destpath/.." "$archivename" && rm -rf "$destpath"
}

function syncthis {
  echo "Backup: $PWD/$1 to $destpath"
  $synccmd "$1" "$destpath"
  if [[ $? != 0 ]]; then
    echo "Error $copy returned $? for $(pwd)" >> "$destpath/../$ferror"
    return 1
  fi
  return 0	
}

# $1 is backup path
# $2 is location of files to be backed up
function backupCmd {
 updateVars "$1"
 cd "$2" || exit
 syncthis ./
 archiveDirectory
 cd ~ || exit
  
}

function printMessage {
  echo -en "\n####################################
####################################\n"
  echo -n "$1"
  echo -en "\n####################################
####################################\n"
}
