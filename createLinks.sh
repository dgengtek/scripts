#!/bin/bash
# TODO: new input to select only targets with specific
# suffix to be linked(Optional)


#script to link new scripts,programs with format name.whatever.* to name.whatever

target=$1
destination=$2

function scriptinfo
{
	echo -e "\nUsage of $0"
	echo "$0 arg1 arg2"
	echo "arguments must be directories"
	echo "arg 1: target to select"
	echo "arg 2: destination to copy create new links"
	exit 1

}

if [ -z "$target" ]
then
	echo "empty target"
	scriptinfo
fi
if [ -z "$destination" ]
then
	echo "empty destination"
	scriptinfo
fi


if ! [ -d "$target" ]
then 
	echo "target is no folder: $target"
	scriptinfo
fi
if ! [ -d "$destination" ]
then 
	echo "destination is no folder: $destination"
	scriptinfo
fi



# switch to target,get link list,switch back to destination
cd $target
# get absolute path if not given,no check
target=$(pwd)
linkList=$(ls -1)
cd $OLDPWD
cd $destination

OLDIFS=$IFS
IFS=$(echo -en "\n\b")


LINK=""
declare -i i=0
declare -i j=0
for lnname in $linkList
do
	LINK=${lnname%.*}
	if [ -e $LINK ] && ! [ -d $LINK ]
	then
		rm $LINK
		let i++
	fi
	let j++
	#echo "creating link of $LINK in $PWD"
	ln -s "$target/$lnname" "$LINK"
	
done

# find broken links
brokenLinks=$(find $destination -type l -xtype l | egrep -oh '([^/]*)$')

# delete broken links remaining
for lnname in $brokenLinks 
do
  rm $lnname
  let i++
done



IFS=$OLDIFS
echo "Removed $i links, created $j links."
exit 0
