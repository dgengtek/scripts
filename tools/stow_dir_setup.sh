#!/bin/bash
usage() {
  cat << EOF
usage:  ${0##*/} [OPTIONS] [-- STOWOPTIONS]

  OPTIONS:
    -d directory      directory to link from
    -t target	      target directory to link to
    {-p pkg}	      package to stow, can be used repeatedly
    (-r | -m)	      -r, remove conflicting destination files |
		      -m, move all conflicting destination files to a backup folder 
		      (default home directory)
    -i		      prompt before applying actions
    -f		      dont prompt before overwriting
    -v		      verbose actions(mv,rm)
    -s		      simulate program execution
EOF
  exit 1
}
logger() {
  command logger -s --no-act "$@"
}
check_input() {
  local -ir conflict=$((mv_destination_files == 1 \
    && remove_destination_files == 1))
  if ((conflict == 1)); then
    usage
  elif ((mv_destination_files ==1 )); then
    if ! mkdir -p "$mv_dest"; then
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
  local -r optlist="rm:ht:d:p:vif"

  local -i target_set=0
  local -i remove_destination_files=0
  local -i mv_destination_files=0
  local -i enable_prompt=0
  local -i enable_verbose=0
  local -i force=0
  local -i simulate=0
  local mv_dest=""
  local tdir=""
  local ddir=""
  local -i selective_stow=0
  local -a pkgs
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
      p)
	let selective_stow=1
	pkgs+=("$OPTARG")
	;;
      t)
	tdir="$OPTARG"
	;;
      d)
	ddir="$OPTARG"
	;;
      v)
	let enable_verbose=1
	;;
      i)
	let enable_prompt=1
	;;
      f)
	let force=1
	;;
      s)
	let simulate=1
	;;
    esac
  done
  shift $((OPTIND - 1))


  local options="-t $tdir $@"
  if ! [ -z "$ddir" ]; then
    options="-d $ddir $options"
  fi

  local files=$(find . -mindepth 2 -maxdepth 2 -type f  -not \( -path \
  "./.git/*" -prune \) -printf "%f\n")

  check_input

  if ((selective_stow == 1)); then
    pkgs=${pkgs[@]}
  else
    pkgs=$(find . -maxdepth 1 -type d -regextype egrep -regex ".*/[^.]*" \
    -printf "%f\n")
  fi
  stow_pkgs $pkgs
}
stow_pkgs() {
  if ((simulate == 1)); then
    stow="echo stow"
  else
    stow="stow"
  fi

  for p in $@; do
    if ! $stow $options "$p"; then
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
  if ! [ -d "$mv_dest" ]; then
    return
  fi

  local options=""
  if ((enable_verbose == 1));  then
    options+=" -v"
  fi
  if ((enable_prompt == 1)); then
    options+=" -i"
  fi
  if ((force == 1)); then
    options+=" -f"
  fi
  # add options to cmd
  cmd="$cmd $options --"

  local target=""
  for f in "$@"; do
    target="$path/$f"
    if [ -e "$target" ]; then
      $cmd $target $mv_dest
    fi
  done
}
parse_cmd_options() {
  if [ -z "$cmd_options" ] || [ -z "$targets" ]; then
    echo "missing variables to parse cmd options"
  fi
  for opt in $@; do
    if [ $opt == "--" ]; then
      shift
      break
    fi
    options+=("$opt")
    shift
  done
  for t in $@; do
    target+="$t "
  done
}
mv() {
  local -a cmd_options
  local targets
  parse_cmd_options $@
  command mv ${cmd_options[@]} "$1" "$2"
}
rm() {
  local -a cmd_options
  local targets
  parse_cmd_options $@
  command rm ${cmd_options[@]} "$1"
}

main "$@"
