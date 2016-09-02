#!/usr/bin/bash

filename="$1"
logfile=""

#run in Background?
declare -i background=0
#counter
declare -i logNumber=1
#logDownload?
declare -i logAll=0

downloadDir="newDownloadsYT"
logDir="logDL"



function scriptinfo
{
	echo -e "\nUsage of $0"
	echo "$0 arg1 "
	echo "argument must be a file with links to videos"
	echo "arg 1: filename"
	exit 1

}
function downloadLink
{
	if ((background == 1))
	then
		if ((logAll == 1))
		then
			logfile="$logDir/youtube-dl.log"
			(youtube-dl --no-playlist "$1" &> "$logfile.$logNumber.txt") &
		else
			(youtube-dl --no-playlist "$1" &> $logfile) &
		fi
	
		cmd_pid=$!
		echo -e "PID - $cmd_pid \nrunning in background..."
		((logNumber++))
	else

		youtube-dl --no-playlist "$1"

	fi

}

if [ -z "$filename" ]
then
	echo "empty filename, arg1"
	scriptinfo
fi



read -rp "Run in Background? y or n: " yn
case $yn in
    [Yy]* ) 
    	let background=1;;
    [Nn]* ) 
    	;;
    * ) echo "yes or no.";;
esac

if ((background == 1))
then

	read -rp "Log cmd? y or n: " yn
	case $yn in
	    [Yy]* ) 
		let logAll=1;;
	    [Nn]* ) 
		logfile="/dev/null";;
	    * ) echo "yes or no.";;
	esac

fi

if ! [ -d $downloadDir ]
then
	mkdir $downloadDir
fi

if ((background == 1)) && ((logAll == 1)) 
then
	cd "$downloadDir" || exit
	if ! [ -d $logDir ]
	then
		mkdir $logDir
	fi
	cd - || exit
fi

#backup list
cp "$filename" "$downloadDir/downloadList.backup.txt"

declare -i cdOnce=1
while read -r line
do
	if ((cdOnce == 1))
	then
		cd "$downloadDir" || exit
		let cdOnce=0
	fi
	name=$line
	echo "Name read from file - $name"
	downloadLink "$name"
done < "$filename"
