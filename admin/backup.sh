#!/bin/env bash
# TODO use fifos to synchronize ordered output or write to temporary files and
# merge when finished to output
# TODO add pretty result output
# TODO add option for archive destination path, relative to destination
usage() {
  cat >&2 << EOF
Usage: $0 [options] [<destination> <source>... [-- <rsync options>...]] 

options:
  -c, --config <file>   config file used to parse options if no arguments
                          supplied [default: stdin]
  -a, --archive         Archive and compress files(tar,gzip)
  -v, --verbose         Verbose output
  -p, --suffix <dir>    Suffix path onto destination, disables
                          relative path names options of rsync -R.
  -C, --change <dir>    Change to directory before running.
  -b, --batch <count>   Number of backup batches to run in
                          background.[default: 1]
EOF
}
log() {
  echo -n "$@" | logger -s -t ${0##*/}
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
# research to only allow logging for debug before it has been set
main() {
  trap catch_interrupt SIGINT SIGTERM


  local config=/dev/stdin
  # restrict config to be read once
  local -i singleton=0
  local -i enable_archiving=0
  local -i enable_backup=0
  local -i enable_verbose=0
  local -i enable_debug=0
  local destination=
  local destination_suffix=""

  # target to change to before running
  local target=""
  # cmd for copying
  local -r copy="rsync"
  # relative syncing to copy relative supplied paths
  local options="-aAzu"
  # final command string
  local copy_cmd=""
  # backup directory of old files
  local batch_count=1

  # declare rsync options
  local -r suffix="_bak"
  local args=
  local return_code=


  # TODO improve setup
  # run setup to possibly set debugging before parsing
  setup
  check_globals_existing

  run "$@"
}
run() {
  # reset args
  args=
  log "input \$@: $@" 2>&$fddebug
  parse_options "$@"
  if (($? == 9)); then
    parse_config
    exit 0
  fi

  # set input args
  set -- ${args[@]}
  unset -v args
  log "after parsing \$@: $@" 2>&$fddebug
  # reset changed verbosity
  setup

  if [[ $# < 2 ]] && ! [[ -s $config ]]; then
    usage
    error_exit 1 "No arguments."
  fi

  destination=$(realpath -m "${1}/$destination_suffix")
  shift
  # parse config
  # check, update environment
  update_options

  pushd "$target"
  start_backup "$@"
  popd

}
parse_config() {
  log "Parsing config." >&$fddebug
  while read -r line; do
    run $line
  done < "$config"
}
check_globals_existing() {
  [[ -z ${args+z} ]] && error_exit 1 "Args variable not set"
  [[ -z ${options+z} ]] && error_exit 1 "Args variable not set"
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
  wait || error_exit 50 "Failed waiting for background backup processes"
  IFS=$OLDIFS
}
start_worker() {
    run_sync "$1"
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
  # exit if no options left
  [[ -z $1 ]] && return 0
  log "parse \$1: $1" 2>&$fddebug

  local do_shift=0
  case $1 in
      -)
        if ! (($singleton)); then
          singleton=1
          return 9
        fi
        error_exit 5 "stdin is not allowed inside config."
        ;;
      -c|--config)
        if ! (($singleton)); then
          singleton=1
          config=$2
          log "Parsing config file $config for options instead." >&$fddebug
          return 9
        fi
        error_exit 5 "Recursive config option is not allowed inside config."
        ;;
      -a|--archive)
	enable_archiving=1
	;;
      -b|--backup)
	enable_backup=1
	;;
      -v|--verbose)
	enable_verbose=1
	;;
      -s|--suffix)
        destination_suffix=$2
        do_shift=2
	;;
      -b|--batch-count)
        batch_count=$2
        do_shift=2
	;;
      -C|--change)
        target=$2
        do_shift=2
        ;;
      --)
        do_shift=3
        ;;
      -*)
        usage
        error_exit 5 "$1 is not allowed."
	;;
      *)
        do_shift=1
	;;
  esac
  if (($do_shift == 1)) ; then
    args+=("$1")
  elif (($do_shift == 2)) ; then
    # got option with argument
    shift
  elif (($do_shift == 3)) ; then
    # got --, use all arguments left for rsync to process
    shift
    options="$options $@"
    return
  fi
  shift
  parse_options "$@"
}

update_options() {
  if ! (($enable_verbose)); then
    options+=" -q"
  else
    options+=" -v"
  fi
  if [[ -z $destination_suffix ]]; then
    # enable relative path names from sources
    options+=" -R"
  fi

  if ! is_absolute_path "$destination"; then
    destination=$(realpath -m "${PWD}/${destination}")
  fi

  ! [ -f "$destination" ] \
    && ! (($enable_debug)) \
    && mkdir -pv "$destination" >&$fdverbose

  if (($enable_backup)); then
    options+=" -b"
    # set backup dir to used destination suffix
    local -r backup_destination=$(basename "$destination")
    local -r backup_dir=$(realpath -m "${destination}/../bak/$backup_destination")
    options+=" --backup-dir=$backup_dir"
    options+=" --suffix=$suffix" 
  fi
  copy_cmd="$copy $options"
}


archive_dir() {
  if ! (($enable_archiving)); then
    return 
  fi
  archivename=$(basename "$destination")
  taroptions="-cz"
  if (($enable_verbose)); then
    taroptions+="v"
  fi
  taroptions+="f"
  tar "$taroptions" "$destination/../${archivename}_$(date +%d%m%y).tar.gz" -C \
"$destination/.." "$archivename" && rm -rfv "$destination"
}

run_sync() {
  local return_code=0
  local -r src=$1
  if (($enable_verbose == 1)); then
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
  # TODO allow message to be piped to display message only when script finishes
  # for a pretty final result
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
