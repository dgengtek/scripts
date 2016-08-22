#!/bin/env bash
# TODO use stdin to read in configuration through readline, user input 
# or config file
# TODO use fifos to synchronize ordered output or write to temporary files and
# merge when finished to output
usage() {
  cat >&2 << EOF
usage: $0 [options] DESTINATION [BACKUPSRC ...] -- [rsync options]

options:
  --archive, -a		            archive and compress files
  --verbose, -v		            verbose output
  --suffix dir, -p dir              suffix path onto destination
  --change dir, -C dir              change to directory before running
  --batch-count count, -b count     number of backup batches run in background
  --content, -c                     copy only content to destination
EOF
  error_exit 1 ""
}
log() {
  logger -s -t ${0##*/} "$@"
}
error_exit() {
  error_code=$1
  shift
  log "$@"
  exit $error_code
}

catch_interrupt() {
  trap - SIGINT SIGTERM
  kill $$
  error_exit 1 "Signal received: stopping backup" 
}

# TODO allow debugging via argument?
# best way to only allow logging for debug before its even set?
main() {
  trap catch_interrupt SIGINT SIGTERM

  local -i enable_archiving=0
  local -i enable_verbose=0
  local -i enable_debug=0
  local -i enable_copy_content=0
  local destination_suffix=""
  setup

  # cmd for copying
  local -r copy="rsync"

  # target to change to before running
  local target=""
  # backup directory of old files
  local backup_dir=""
  local batch_count=4

  # declare rsync options
  local -r suffix="_bak"

  # relative syncing to copy relative supplied paths
  local options="-aAzubR"
  # leftover options for rsync after --
  local rsync_input_options=""

  # final build command
  local copy_cmd=""

  local -a args
  local return_code=
  log "input \$@: $@" 2>&$fddebug
  while [[ -n $1 ]]; do
    log "parse \$1: $1" 2>&$fddebug
    parse_options "$@"
    return_code=$?

    if (($return_code == 1)) ; then
      args+=("$1")
    elif (($return_code == 2)) ; then
      # got option with argument
      shift
    elif (($return_code == 3)) ; then
      # got --
      shift
      rsync_input_options=$@
      break
    fi
    shift
  done
  # set input args
  set -- ${args[@]}
  unset -v args
  log "after parsing \$@: $@" 2>&$fddebug
  # reset changed verbosity
  setup

  # remove parsed options from args
  if [[ $# < 2 ]]; then
    log "Not enough arguments supplied."
    usage
  fi
  # clean path
  destination_suffix=${destination_suffix%/}
  destination="${1%/}/$destination_suffix"
  shift

  # check, update environment
  update_environment
  pushd "$target"
  start_backup "$@"
  popd
}
start_backup() {
  # dont separate on space, only newline and backspace
  local -r OLDIFS=$IFS
  local IFS=" "
  # loop over supplied targets
  # except last arg
  local count=0
  while [[ -n $1 ]]; do
    start_worker "$1" &
    shift
    let count+=1
    if (($count%$batch_count == 0)); then
      wait || error_exit 50 "Failed waiting for background backup processes"
    fi
  done
  IFS=$OLDIFS
}
start_worker() {
    if is_absolute_path "$1" \
      && pushd "$1"; then
      run_sync ./* 
      popd
    else
      run_sync "$1"
    fi
    archive_dir >&$fdverbose
}
setup() {
  if ! (($enable_debug)); then
    exec {fddebug}>/dev/null
  else
    exec {fddebug}>&1
    exec 2>&$fddebug
    set -xv
  fi
  if ! (($enable_verbose)); then
    exec {fdverbose}>/dev/null
  elif (($enable_verbose)) || (($enable_debug)); then
    exec {fdverbose}>&1
  fi
}
parse_options() {
  local return_code=0
  case $1 in
      -a|--archive)
	enable_archiving=1
	;;
      -v|--verbose)
	enable_verbose=1
	;;
      -c|--content)
	enable_copy_content=1
	;;
      -s|--suffix)
        destination_suffix=$2
        return_code=2
	;;
      -b|--batch-count)
        batch_count=$2
        return_code=2
	;;
      -C|--change)
        target=$2
        return_code=2
        ;;
      -*)
        usage
	;;
      --)
        return_code=3
        ;;
      *)
        return_code=1
	;;
  esac
  return $return_code
}

update_environment() {
  if ! ((enable_verbose)); then
    options+="q"
  else
    options+="v"
  fi

  if ! is_absolute_path "$destination"; then
    destination="${PWD}/${destination}"
    backup_dir="${destination}/../old_bak"
  fi

  ! [ -f "$destination" ] \
    && ! (($enable_debug)) \
    && mkdir -pv "$destination" >&$fdverbose

  options+=" --backup-dir=$backup_dir"
  options+=" --suffix=$suffix" 

  copy_cmd="$copy $options"
}


archive_dir() {
  if ! ((enable_archiving)); then
    return 
  fi
  archivename="${destination%/}"
  archivename="${archivename##*/}"
  taroptions="-cz"
  if ((enable_verbose)); then
    taroptions+="v"
  fi
  taroptions+="f"
  tar "$taroptions" "$destination/../${archivename}_$(date +%d%m%y).tar.gz" -C \
"$destination/.." "$archivename" && rm -rfv "$destination"
}

run_sync() {
  local return_code=0
  local src=${1%/}
  if ((enable_copy_content)); then
    src="${src}/"
  fi
  if ((enable_verbose == 1)); then
    log "Backup: $src to $destination"
  fi
  local -r cmd_string="$copy_cmd $src $destination"

  if ! (($enable_debug)); then
    eval "$cmd_string"
    echo
    return_code=$?
  else
    printf "%s\n" "$cmd_string"
  fi

  if (($return_code)); then
    log "Error, $copy returned $? for $PWD" 
    return $return_code
  fi
  print_message "Backup finished from $@ to $destination"
}

is_absolute_path() {
  [[ "$1" == /* ]]
}

print_message() {
  if (($enable_verbose)); then
    printf '=%.0s' {1..10}
    echo "> $1"
  fi
}
pushd() {
  command pushd "$@" >&$fddebug 2>&1
}
popd() {
  command popd >&$fddebug 2>&1
}
main "$@"
