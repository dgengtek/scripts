#!/bin/bash
# TODO: implement function invocation with array parameters
# instead of recalling function with new paths.. use an array
# of paths which should be syncd and loop over the input
# while running rsync in background with run script
# TODO: refactor to python
catch_interrupt() {
  >&2  echo "Signal received: stopping backup" 
  exit 1
}

#add backup local bash script binaries
optlist=":avp"

usage() {
  echo "$0 [option] backuppath"
  echo "option:"
  echo "-a  archive and compress files"
  echo "-v  verbose output"
  echo "-p  progress"
  exit 1
}

declare -i enableArchiving=0
declare -i enableVerbose=0
declare -i enable_progress=0
while getopts $optlist opt; do
  case $opt in
    a)
      let enableArchiving=1
      ;;
    v)
      let enableVerbose=1
      ;;
    p)
      let enable_progress=1
      ;;
    *)
      usage
      ;;
  esac
done
shift $((OPTIND - 1))

if [ -z "$1" ]
then
  echo "no backuppath supplied"
  usage
fi
trap catch_interrupt SIGINT SIGTERM

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
options="$options --backup-dir=$backuppath"
options="$options --suffix=$suffix" 

synccmd="$copy $options"

updateVars() {

  destpath="$root/$1"
  backuppath="${destpath%/}/../old_bak"

  options="-aAzubR"
  if [[ $enableVerbose == 1 ]]; then
    options+="v"
  else
    options+="q"
  fi

  if [[ $enable_progress == 1 ]]; then
    options+=" --progress"
  fi
  options="$options --backup-dir=$backuppath"
  options="$options --suffix=$suffix" 

  synccmd="$copy $options"

  if [[ "$destpath" != /* ]]; then
    destpath="${PWD}/${destpath}"
  fi
  if ! [ -d "$destpath" ]
  then
	  mkdir -p "$destpath"
  elif [ -e "$destpath/../$ferror" ]
  then
	  rm "$destpath/../$ferror"
  fi


}

archiveDirectory() {
  if [[ $enableArchiving == 0 ]]; then
    return 
  fi
  archivename="${destpath%/}"
  archivename="${archivename##*/}"
  taroptions="-cz"
  if [[ $enableVerbose == 1 ]]; then
    taroptions+="v"
  fi
  taroptions+="f"
  tar "$taroptions" "$destpath/../${archivename}_$(date +%d%m%y).tar.gz" -C\
 "$destpath/.." "$archivename" && rm -rf "$destpath"
}

syncthis() {
  if [[ $enableVerbose == 1 ]]; then
    echo "Backup: $PWD/$1 to $destpath"
  fi
  $synccmd "$1" "$destpath"

  if [[ $? != 0 ]]; then
    echo "Error $copy returned $? for $(pwd)" >> "$destpath/../$ferror"
    return 1
  fi
  return 0	
}

# $1 is backup path
# $2 is location of files to be backed up
backupCmd() {
 updateVars "$1"
 cd "$2" || exit
 syncthis ./
 archiveDirectory
 cd ~ || exit
  
}

printMessage() {
if [[ $enableVerbose == 1 ]]; then
  echo -en "\n####################################
####################################\n"
  echo -n "$1"
  echo -en "\n####################################
####################################\n"
fi
exit 0
}
