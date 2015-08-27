#!/bin/bash


cd ~/vimwiki


OLDIFS=$IFS
IFS=$(echo -en "\n\b")

PS3='select vimwiki diary to open: '
select selection in $(ls -1)
do
	if [ -n $selection ]
	then	
		cd $selection
		if [ ! -d diary ] 
		then
			echo "no diary dir"
			mkdir diary
		fi
		cd diary
		break
	else
		echo "invalid selection"
		exit 1
	fi
done
IFS=$OLDIFS

eval "urxvt -e vim -S \
  ~/bin/vimscripts/generate_diary_links.vim diary.wiki"
