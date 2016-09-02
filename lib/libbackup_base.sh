#!/bin/bash
# use this lib inside other scripts, by sourcing it beforehand

# Steps to run script:
# 1.  Source this script before using any of its functions
# 2.  Make sure to initialize global array 'args' with input args supplied
#     to the script 
# 3.  Run backup with main function
#     main(backup_suffix, [target]...)
#     target(s) for backup
# 4.  Targets shall be supplied to main function as array or string.
#     Relative supplied targets will be copied with 
#     its exact relative pathname.
#     To copy only contents of a folder, supply target with absolute pathname
usage() {
  cat << EOF
usage: $0 [option] target backuppath"

  option:
    -a		archive and compress files
    -v		verbose output
    -p		progress
EOF
  exit 1
}

# TODO: refactor to python

catch_interrupt() {
  >&2  echo "Signal received: stopping backup" 
  exit 1
}
trap catch_interrupt SIGINT SIGTERM


# passed in raw arguments
# will be set in other scripts to pass in 
# options + destination path
declare -a args=()

main() {

  local -ir length=$((${#args[@]}-1))

  # get last item
  # backup path supplied to script
  local -r root=${args[$length]%/}

  # array without last element
  # are the passed in options
  # exclusive
  local -a input_options=${args[@]:0:$length}


  # get the first argument passed to main
  local -r root_suffix="${1%/}"
  shift 1
  # pass in 
  execute "${input_options[@]}" "$@"
}

execute() {

  local optlist=":avpd"
  local -i enable_archiving=0
  local -i enable_verbose=0
  local -i enable_progress=0
  local -i enable_debug=0

  while getopts $optlist opt; do
    case $opt in
      a)
	let enable_archiving=1
	;;
      v)
	let enable_verbose=1
	;;
      p)
	let enable_progress=1
	;;
      d)
	let enable_debug=1
	;;
      *)
	usage
	;;
    esac
  done
  # remove parsed options from args
  shift $((OPTIND - 1))
  if [[ $# < 1 ]]; then
    usage
  fi
  # cmd for copying
  local -r copy="rsync"

  # declare paths
  # backup root path path/backup
  # dont use last slash
  local destpath="${root}/${root_suffix}"
  local backuppath="${destpath}/../old_bak"

  # declare rsync options
  local -r suffix="_bak"
  local -r ferror="sync.errors"

  # relative syncing to copy relative supplied paths
  local options="-aAzubR"

  local copy_cmd=""

  # check, update environment
  check_env

  # dont separate on space, only newline and backspace
  OLDIFS=$IFS
  IFS=$(echo -en "\n\b")
  # loop over supplied targets
  # except last arg
  for target in "$@"; do
    if is_absolute_path "$target" && 
      pushd "$target"; then
      run_sync ./*
      popd
    else
      run_sync $target
    fi
    archive_dir
  done
  IFS=$OLDIFS
}

check_env() {
  if [[ $enable_verbose == 1 ]]; then
    options+="v"
  else
    options+="q"
  fi
  if [[ $enable_progress == 1 ]]; then
    options+=" --progress"
  fi

  if ! is_absolute_path "$destpath"; then
    destpath="${PWD}/${destpath}"
    backuppath="${destpath}/../old_bak"
  fi
  if ! [ -f "$destpath" ]; then
    mkdir -p "$destpath"
  elif [ -e "$destpath/../$ferror" ]; then
    rm "$destpath/../$ferror"
  fi

  options+=" --backup-dir=$backuppath"
  options+=" --suffix=$suffix" 

  copy_cmd="$copy $options"
}


archive_dir() {
  if [[ $enable_archiving == 0 ]]; then
    return 
  fi
  archivename="${destpath%/}"
  archivename="${archivename##*/}"
  taroptions="-cz"
  if [[ $enable_verbose == 1 ]]; then
    taroptions+="v"
  fi
  taroptions+="f"
  tar "$taroptions" "$destpath/../${archivename}_$(date +%d%m%y).tar.gz" -C \
"$destpath/.." "$archivename" && rm -rf "$destpath"
}

run_sync() {
  if [[ $enable_verbose == 1 ]]; then
    echo "Backup: $1 to $destpath"
  fi
  local -r cmd_string="$copy_cmd $1 $destpath"

  if [[ $enable_debug == 1 ]]; then
    echo "$cmd_string"
  else
    eval "$cmd_string"
  fi

  if [[ $? != 0 ]]; then
    echo "Error $copy returned $? for $(pwd)" >> "$destpath/../$ferror"
    return 1
  fi
}

is_absolute_path() {
  if [[ "$1" == /* ]]; then
    return 0
  else
    return 1
  fi
}

print_message() {
  if [[ $enable_verbose == 1 ]]; then
    echo -e "\n####################################
    ####################################"
    echo "$1"
    echo "####################################
    ####################################"
  fi
}
pushd() {
  command pushd "$@" &> /dev/null
}
popd() {
  command popd &> /dev/null
}
