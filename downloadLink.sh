#!/usr/bin/bash
# download links from a file

#worked 0, not 1
declare -i success=1
filename="$1";

if [ -z $filename ]
then
	echo "no filename supplied for arg1"
fi

cp $filename $filename.bak
while read -r line
do
    	name=$line;
    	echo "Name read from file - $name";
	let success=1
    	while (( $success ))
	do
    		wget -c "$name";
		if [ $? = "0" ]
		then
			echo "Successfull download."
			sed -i '1d' $filename;
			let success=0
		fi

	done
done < "$filename"
