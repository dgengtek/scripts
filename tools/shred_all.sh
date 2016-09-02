#!/bin/bash
#shred all files recursively inside directory
path=$1

if ! [ -d "$path" ]; then
  echo "no path supplied or is not a directory"
  exit 1;
fi
OLDIFS=$IFS
IFS=$(echo -en "\n\b")

for item in $(find "$path" -type f)
do
  shred -uz "$item"
  echo "shredded $item"
done
#cd -

echo -e "\nremoving $path"
rm -R "$path"
IFS=$OLDIFS
exit 0
