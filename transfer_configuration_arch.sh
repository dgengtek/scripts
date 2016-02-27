#!/bin/bash
optlist=":fe"

function usage {
echo "$0 [-fe] backuppath"
echo "-f force move of files after sync"
echo "-e use ssh"
exit 1
}

mvoptions=""
declare -i enableSSH=0
while getopts $optlist opt; do
  case $opt in
    f)
      mvoptions="-f"
      ;;
    e)
      let enableSSH=1
      ;;
    *)
      usage
      ;;
  esac
done
shift $((OPTIND -1))

if [ -z $1 ]; then
  usage
fi
destpath="${1%*/}"

function pushd {
  command pushd "$@" > /dev/null
}

function popd {
  command popd "$@" > /dev/null
}

function restructure_local {
  mkdir -p "$2"
  mv $mvoptions "${1}"* "${destpath}/$2"
  rm -rf $1
}
function restructure_remote {
  ssh $destpath mkdir -p "$2"
  rsync -azue ssh "$1" "${destpath}:~/$2"
  rm -rf $1
}
restructure=""


if [ -e ~/bin/bash/backup_arch.sh ]; then
  if [[ $enableSSH == 1 ]]; then
    restructure=restructure_remote
  else
    restructure=restructure_local
  fi
else
  echo "backup_arch script does not exist"
  exit 1
fi
tmppath="/tmp"
sh ~/bin/bash/backup_arch.sh $tmppath

shopt -s dotglob
pushd $tmppath

infix="Arch_bak"
pushd $infix
$restructure "home/"
popd
rmdir "Arch_bak"

infix="hdd_sidekick/scripting"
pushd $infix
$restructure "bash/" "bin/bash/"
$restructure "fcrontab/" "bin/fcrontab/"
$restructure "vimscripts/" "bin/vimscripts/"
popd
rmdir -p "$infix"
popd
shopt -u dotglob
