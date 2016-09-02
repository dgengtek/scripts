#!/bin/bash
usage() {
  echo -e "usage:\n  ${0##*/} [OPTIONS] [STOWOPTIONS]"
  echo -e "OPTIONS:"
  echo -e "\t-d,\tdirectory to link from"
  echo -e "\t-t,\ttarget directory to link to"
  echo -e "\t-r,\tremove conflicting destination files" 
  echo -e "\t-m,\tmove all conflicting destination files to a backup folder"
  echo -e "\tif no options passed, will install to home directory"
  exit 1
}
logger() {
  command logger -s --no-act "$@"
}
check_input() {
  exp=$((mv_destination_files == 1 \
    && remove_destination_files == 1))
  if ((exp==1)); then
    usage
  elif ((mv_destination_files ==1 )); then
    if ! mkdir -p $mv_dest; then
      exit 2
    fi
    cmd=mv
  elif ((remove_destination_files == 1)); then
    cmd=rm
  else
    return
  fi
  resolve_conflicts "$tdir" $cmd $files 
}

main() {
  local -r optlist=":rm:ht:d:"

  local -i target_set=0
  local -i remove_destination_files=0
  local -i mv_destination_files=0
  local mv_dest=""
  local tdir=""
  local ddir=""
  while getopts $optlist opt; do
    case $opt in
      r)
	let remove_destination_files=1
	;;
      m)
	let mv_destination_files=1
	mv_dest="$OPTARG"
	;;
      h)
	usage
	;;
      t)
	tdir="$OPTARG"
	;;
      d)
	ddir="$OPTARG"
	;;
      *)
	;;
    esac
  done
  shift $((OPTIND - 1))


  local options="-t $tdir $@"
  if ! [ -z $ddir ]; then
    options="-d $ddir $options"
  fi

  local files=$(find . -mindepth 2 -maxdepth 2 -type f  -not \( -path \
  "./.git/*" -prune \) -printf "%f\n")

  check_input


  local pkg=$(find . -maxdepth 1 -type d -regextype egrep -regex ".*/[^.]*" \
  -printf "%f\n")
  for p in $pkg; do
    if ! stow $options $p; then
      usage
    fi
  done

}
resolve_conflicts() {
  # remove last slash
  local path=${1%*/}
  shift 1

  local cmd=$1
  shift 1
  if ! ([ -e $mv_dest ] && [ -d $mv_dest ]); then
    return
  fi

  local target=""
  for f in "$@"; do
    target="$path/$f"
    if [ -e $target ]; then
      $cmd $target $mv_dest
    fi
  done
}
mv() {
  command mv -v $1 $2
}
rm() {
  command rm -v $1
}

main "$@"
