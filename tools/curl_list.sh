#!/usr/bin/bash
# download links from a file
source ~/lib/libcolors.sh

filename="$1"

if [ -z "$filename" ]
then
	echo -e "${COLORS_RED}no filename supplied${COLORS_NONE}"
	echo "$0 filename"
	exit 1
fi

cp "$filename" "$filename~"
failedList="failed_${filename}"
while read -r line
do
    	name="$line";
    	echo -e "\n${COLORS_BLUE}Name read from file - $name${COLORS_NONE}";
	curl -O -J -L "$name";
	if [[ $? == 0 ]];then
	  echo -e "${COLORS_GREEN}Successfull download.${COLORS_NONE}"
	  sed -i '1d' "$filename";
	else
	  echo -e "${COLORS_RED}Failed download of ${line}${COLORS_NONE}" >> "$failedList"
	fi
done < "$filename"
rm "$filename"
