#!/bin/env bash
# TODO add different output type
# TODO filter to only use specific input file types
# TODO fix race condition counting by using fifos
usage() {
  cat >&2 << EOF
Usage:	${0##*/} [OPTIONS] target destination
  
OPTIONS:
  -h	    help
  -b count  batch counts
  -f        force overwrite
  -v        verbose ffmpeg output
EOF
}
main() {
  local -r optlist="fvb:"
  local -i enable_overwrite=0
  local -i enable_verbose=0
  local -i batch_count=4
  source ${MYLIBS}libcolors.sh

  while getopts $optlist opt; do
    case $opt in
      f)
        enable_overwrite=1
	;;
      b)
        batch_count=$OPTARG
        ;;
      v)
        enable_verbose=1
	;;
      *)
	usage
	;;
    esac
  done
  shift $((OPTIND - 1))
  [[ -z $1 ]] && usage && exit 1
  local -r target="$(realpath $1)"
  [[ -z $target ]] && echo "target must exist" && usage && exit 1
  local destination="mp3"
  [[ -n $2 ]] && destination=$2
  destination=$(realpath -m $target/$destination)

  local extension=
  local outputfile=
  local global_options=
  # not implemented
  local output_type="mp3"
  set_options

  mkdir -p "$destination"
  trap cleanup SIGINT SIGTERM SIGKILL EXIT

  local -i success=0
  local -i failed=0
  local -i processed=0
  OLDIFS=$IFS
  IFS=
  local batch_index=0
  while read -d $'\0' -r file; do
    suffix=${file##*.}
    outputfile=$(basename "$file" "$suffix")
    outputfile="$(realpath -m ${destination}/${outputfile}mp3)"
    if [[ -f "$file" ]] && { ! [[ -e "$outputfile" ]] || (($enable_overwrite)); }; then
      extension=${file##*.}
      if ! is_extension_valid "$extension"; then
        continue
      fi
      batch_index=$(($batch_index + 1))
      convert "$file" "$outputfile" &
      if (($batch_index%$batch_count == 0)); then
        wait || exit 5
      fi
    fi
    processed=$(($processed + 1))
  done < <(find "$target" -maxdepth 1 -print0)
  # wait for remaining background processes left after looping through list
  wait || exit 5
  IFS=$OLDIFS

  report
}
report() {
  echo -e "Processed: $processed"
  echo -e "Success: ${GREEN}$success${NONE}"
  echo -e "Failed: ${RED}$failed${NONE}"
  echo -e "Total count of valid input $(($failed + $success))"
}
convert() {
  local -r file=$1
  local -r outputfile=$2
  local output="mp3 # $file"
  if ffmpeg ${global_options[@]} -i "$file" -acodec mp3 -vn "$outputfile" 2>&1 >&3; then
    echo -e "${GREEN}+ $output${NONE}"
    success=$(($success + 1))
  else
    echo -e "${RED}- $output${NONE}"
    failed=$(($failed + 1))
  fi
}
is_extension_valid() {
  local -r extension=$1
  [[ $extension == * ]] || [[ $extension == * ]]
}
set_options() {
  loglevel="error"
  global_options+=(-nostdin)
  global_options+=(-loglevel $loglevel)
  (($enable_overwrite)) && global_options+=(-y)

  exec 3>/dev/null
  if (($enable_verbose)); then
    exec 3>&1
  fi
}
cleanup() {
  trap - SIGINT SIGTERM SIGKILL EXIT
  rmdir $destination
  exit 1
}
main "$@"
