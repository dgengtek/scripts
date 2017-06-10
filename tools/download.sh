#!/bin/env bash
usage() {
  cat >&2 << EOF
Usage:	${0##*/} [OPTIONS] (FILENAME | URL...)

OPTIONS:
  -v
  -d
  -q
EOF
}
main() {
  check_dependencies

  local -i enable_verbose=0
  local -i enable_quiet=0
  local -i enable_debug=0


  trap cleanup SIGINT SIGTERM
  prepare

  local -a options=
  local -a args=
  # parse input args 
  parse_options "$@"
  # set leftover options parsed local input args
  set -- ${args[@]}
  # remove args array
  unset -v args
  check_input_args "$@"


  local -a failed_items=()
  local -i success_count=0
  local -i failures_count=0
  #local downloader="curl -sS -O -J -L"
  local downloader="http --download --follow --body"

  setup
  run "$@"
}

check_dependencies() {
  hash prompt_me.sh || die "Could not find prompt_me.sh"
}

check_input_args() {
  if [[ -z $1 ]]; then
    usage
    exit 1
  fi
}

prepare() {
  set -e
  source "${MYLIBS}libutils.sh"
  source "${MYLIBS}libcolors.sh"
  set +e
}

setup() {
  :
}

run() {
  if [[ -f $1 ]]; then
    process_file "$1"
  elif [[ -n $1 ]]; then
    process_urls "$@"
  fi
  cat >&2 << EOF
Processed from $@
  success_count: $success_count
  failures_count: $failures_count
  total: $(($success_count + $failures_count))

EOF
  if [[ -n ${failed_items[0]} ]]; then
    echo "Failed items:" >&2
    for item in "${failed_items[@]}"; do 
      echo " $item" >&2
    done
  fi

  if ! (($failures_count)); then
    return 0
  fi

  if prompt_me.sh "Do you want to repeat with failed links?"; then
    run "${failed_items[@]}"
    break
  fi
}

parse_options() {
  # exit if no options left
  [[ -z $1 ]] && return 0

  local do_shift=0
  case $1 in
      -)
        if ! (($singleton)); then
          singleton=1
          return 9
        fi
        error_exit 5 "stdin is not allowed inside config."
        ;;
      -v|--verbose)
	enable_verbose=1
	;;
      -q|--quiet)
        enable_quiet=1
        ;;
      -d|--debug)
        enable_debug=1
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
    options+=("$@")
    return
  fi
  shift
  parse_options "$@"
}

get_uri_filename() {
  local result=$(http --header --follow "$1" \
    | awk -F';' '/filename/ {print $2;}' \
    | cut -d '=' -f 2 \
    | sed -e 's/^"//' -e 's/".*$//')
  echo "$result"
}

check_duplicate_file() {
  local -r filename=$1
  [[ -z $filename ]] && return 1
  if [[ -f $filename ]]; then
    echo_e "${RED}==> ERROR: file exists already: ${filename}${COLOR_NONE}"
    if [[ -n $PS1 ]] && prompt_me.sh "Remove file?"; then
      rm "$filename"
    else
      return 1
    fi
  fi
}

process() {
  local -r input=$1
  echo_e "${BLUE_BG}URL read - $input${COLOR_NONE}"
  local -r filename=$(get_uri_filename "$input")
  
  if check_duplicate_file "$filename" && $downloader "$input"; then
    echo_e "${GREEN}+ $input${COLOR_NONE}"
    success_count=$(($success_count + 1))
  else
    echo_e "${RED}- ${input}${COLOR_NONE}"
    failed_items+=("$input")
    failures_count=$(($failures_count + 1))
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

cleanup() {
  trap - SIGINT SIGTERM
  exit 1
}
main "$@"
