#!/bin/env bash
usage() {
  cat >&2 << EOF
Usage:	${0##*/} [OPTIONS] target destination
  
OPTIONS:
  -h			  help
  option1		  description
EOF
}
main() {
  echo "Script template"

  local -r optlist="abcdefgh"
  while getopts $optlist opt; do
    case $opt in
      a)
	;;
      b)
	;;
      *)
	usage
	;;
    esac
  done
  shift $((OPTIND - 1))
  if [[ -z $1 ]]; then
    usage
    exit 1
  fi
  extension=""
  outputfile=""
  outputDir="convertedMP3s"
  output=""


  if ! [ -d $outputDir ]; then
    mkdir $outputDir
  fi

  trap cleanup SIGINT SIGTERM SIGKILL EXIT

  OLDIFS=$IFS
  IFS=$(echo -en "\n\b")
  for file in $(find .); do
    outputfile=${file%.*}
    output="$outputDir/$outputfile.mp3"
    echo $outputfile
    if [ -f "$file" ] && ! [ -e "$output" ]; then
      extension=${file##*.}
      if [ "$extension" = mp4 ] \
        || [ "$extension" = mkv ]	\
        || [ "$extension" = flv ]; then
      echo "converting - $file to mp3"
      ffmpeg -i "$file" -acodec mp3 -vn "$output"
      fi
    else
      echo "SKIPPING - $outputfile already exists or not a file"
    fi
  done
  IFS=$OLDIFS
}
cleanup() {
  trap - SIGINT SIGTERM SIGKILL EXIT
  echo -en "\ncatched SIGINT, remove $output"
  rm $output
  exit 1
}
main "$@"
