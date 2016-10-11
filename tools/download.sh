#!/bin/env bash
usage() {
  cat >&2 << EOF
Usage:	${0##*/} [OPTIONS] (FILENAME | URL...)

OPTIONS:
EOF
}
main() {
  if [[ -z $1 ]]; then
    usage
    exit 1
  fi

  source "${MYLIBS}libcolors.sh"

  local -r failed_links="failed_downloads_$RANDOM"
  local -i success=0
  local -i failures=0
  local -r downloader="curl -O -J -L -C -"

  if [[ -f $1 ]]; then
    process_file "$1"
  elif [[ -n $1 ]]; then
    process_urls "$@"
  fi
  cat << EOF
Processed from $@
  success: $success
  failures: $failures
  total: $(($success + $failures))
EOF
  (($failures)) && echo "Failures saved in $failed_links."
}
process() {
  local -r input=$1
  echo -e "${BLUE_BG}URL read - $input${COLOR_NONE}"
  $downloader "$input"
  if [[ $? == 0 ]]; then
    echo -e "${GREEN}Successfull download.${COLOR_NONE}"
    success=$(($success + 1))
  else
    echo -e "${RED}Failed download of ${input}${COLOR_NONE}" >&2
    echo "$input" >> "$failed_links"
    failures=$(($failures + 1))
  fi
}
process_file() {
  local -r file=$1
  while read -r line; do
    process "$line"
  done < "$file"
}
process_urls() {
  IFS=" "
  while [[ -n $1 ]]; do
    process "$1"
    shift
  done
}
main "$@"
