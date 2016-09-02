#!/usr/bin/bash
# download links from a file
source /home/gd/lib/libcolors.sh

filename="$1"

if [ -z "$filename" ]
then
	echo -e "${RED}no filename supplied${NC}"
	echo "$0 filename"
	exit 1
fi

cp "$filename" "$filename~"
failedList="failed_${filename}"
while read -r line
do
    	name="$line";
    	echo -e "\n${BLUE}Name read from file - $name${NC}";
	curl -O -J -L "$name";
	if [[ $? == 0 ]];then
	  echo -e "${GREEN}Successfull download.${NC}"
	  sed -i '1d' "$filename";
	else
	  echo -e "${RED}Failed download of ${line}${NC}" >> "$failedList"
	fi
done < "$filename"
rm "$filename"
