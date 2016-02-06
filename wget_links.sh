#!/usr/bin/bash
# download links from a file
source /home/gd/bin/bash/lib/libcolors.sh

filename="$1"
options="$2"

if [ -z "$filename" ]
then
	echo -e "${RED}no filename supplied${NC}"
	echo "$0 filename [options...]"
	exit 1
fi

cp "$filename" "$filename~"
failedList="failed_${filename}"
while read -r line
do
    	name="$line";
    	echo -e "${BLUE}Name read from file - $name${NC}";
	wget "$options" -c "$name";
	if [[ $? == 0 ]];then
	  echo -e "${GREEN}Successfull download.${NC}"
	  sed -i '1d' "$filename";
	else
	  echo -e "${RED}Failed download of ${line}${NC}" >> "$failedList"
	fi
done < "$filename"
rm "$filename"
