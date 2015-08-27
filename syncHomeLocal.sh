#!/bin/bash
#deprecated
#sync with localhost
copy="rsync"

options="-azue ssh"

localpath="/mnt/hdd/bigX/linux"
localpath="$localpath/backupArch/files/"

destpath=""
if [ -z $1 ]
then
	destpath="/home/gd/"
elif [ -d $1 ]
then
	destpath=$1
fi


ferror="sync.errors"


synccmd="$copy $options "

function syncthis {
	echo "Backup: $1\nto $destpath"
	$synccmd $1 $destpath
	if [[ $? != 0 ]]
	then
		echo "Error $copy:$? for $1" 
		return 1
	fi
	
	return 0	

}

if ! [ -d $destpath ]
then
	echo "Error no $destpath"
	exit 1
fi

#sync with remote host
syncthis $localpath
exit 0
