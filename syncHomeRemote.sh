#!/bin/bash
#sync with remote host
copy="rsync"

options="-azue ssh"

localpath="/mnt/hdd/bigX/linux"
localpath="$localpath/backupArch/files/"

user=""
host=""
destpath=""
if [ -z $1 ]
then
	user="gd"
else
	user=$1
fi

if [ -z $2 ]
then
	host="gdA_mob"
else
	host=$2
fi

remotehost="$user@$host:~/"

ferror="sync.errors"


synccmd="$copy $options "

cd ~/.ssh
idfile="id_rsa_home"
ssh-add $idfile

cd -

function syncthis {
	echo "Backup: $1\nto $remotehost"
	$synccmd $1 $remotehost
	if [[ $? != 0 ]]
	then
		echo "Error $copy:$? for $1" 
		return 1
	fi
	
	return 0	

}

#sync with remote host
syncthis $localpath
exit 0
