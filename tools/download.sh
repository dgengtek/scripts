#!/bin/env bash
usage() {
  cat >&2 << EOF
Usage:	${0##*/} [OPTIONS] filename

OPTIONS:
EOF
}
main() {
  source "${MYLIBS}libcolors.sh"

  local -r filename="$1"

  if [[ -z $filename ]]; then
    echo -e "${RED}no filename supplied${NONE}" >&2
    usage
    exit 1
  fi
  local -r failed_links="${filename}_failed_links_$RANDOM"
  local -i success=0
  local -i failures=0
  local downloader="curl -O -J -L"
  while read -r line; do
    echo -e "${BLUE}Name read from file - $line${NONE}"
    $downloader "$line"
    if [[ $? == 0 ]]; then
      echo -e "${GREEN}Successfull download.${NONE}"
      success=$(($success + 1))
    else
      echo -e "${RED}Failed download of ${line}${NONE}" >&2
      echo "$line" >> "$failed_links"
      failures=$(($failures + 1))
    fi
  cat << EOF
Processed from $filename
  success: $success
  failures: $failures
  total: $(wc $filename)
EOF
  done < "$filename"
}
main "$@"
