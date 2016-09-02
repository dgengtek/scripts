#!/bin/env bash
# deprecated, found alternative application -> use gnu stow
# TODO: new input to select only targets with specific
# suffix to be linked(Optional)

# strip suffix and create links on destination

target=$1
destination=$2

function usage {
  echo "usage: ${0##*/} target destination"
  echo -e "  target,\tlocation to create links from"
  echo -e "  destination,\tdestination to create new links of targets"
  exit 1
}

if ! ([ -d "$target" ] || 
  [ -d "$destination" ]); then
  usage
fi

# switch to target,get link list,switch back to destination
cd "$target" || exit
# get absolute path if not given,no check
target=$(pwd)
linkList=$(ls -1)
cd "$OLDPWD" || exit
cd "$destination" || exit

OLDIFS=$IFS
IFS=$(echo -en "\n\b")


LINK=""
declare -i i=0
declare -i j=0
for lnname in $linkList
do
  LINK=${lnname%.*}
  if [ -e "$LINK" ]; then
    rm "$LINK"
    let i++
  fi
  if [ -d "$target/$lnname" ]; then
    continue
  fi
  let j++
  #echo "creating link of $LINK in $PWD"
  ln -s "$target/$lnname" "$LINK"

done

# find broken links
brokenLinks=$(find "$destination" -type l -xtype l | egrep -oh '([^/]*)$')

# delete broken links remaining
for lnname in $brokenLinks 
do
  rm "$lnname"
  let i++
done



IFS=$OLDIFS
echo "Removed $i links, created $j links."
