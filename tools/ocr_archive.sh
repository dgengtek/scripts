#!/usr/bin/env bash
# ------------------------------------------------------------------------------
# scan and output an archive pdf via ocrmypdf
# ------------------------------------------------------------------------------
# 
set -u # error on unset variables or parameters
set -e # exit on unchecked errors
set -b # report status of background jobs
# set -m # monitor mode - enable job control
# set -n # read commands but do not execute
# set -p # privileged mode - constrained environment
# set -v # print shell input lines
# set -x # expand every command
set -o pipefail # fail on pipe errors
# set -C # bash does not overwrite with redirection operators

declare -i ENABLE_VERBOSE=0
declare -i ENABLE_QUIET=0
declare -i ENABLE_DEBUG=0

declare -ir SCAN_DPI=300
readonly SCAN_MODE="color"
readonly SCAN_FORMAT="png"
readonly VOLUME_TMP="/tmp"  # where temporary volume directory will be created
readonly OCRMYPDF_LANGUAGE="deu"
readonly OCRMYPDF_OUTPUT_TYPE="pdfa"
readonly DOCKER_IMAGE_NAME="ocrmypdf"
readonly DOCKER_CONTAINER_NAME="ocr"

readonly __SCRIPT_NAME="${BASH_SOURCE[0]##*/}"

usage() {
  cat >&2 << EOF
Usage: ${0##*/} [OPTIONS] <output filename> <title> <subject> <author> [<keywords>...] [-- [EXTRA]]
Usage with scan: ${0##*/} [OPTIONS] <input filename> <output filename> <title> <subject> <author> [<keywords>...] [-- [EXTRA]]

command
  run a custom function defined as _command

arguments
  <input filename>  full path to input filename
  <output filename>  name of output file without extension
  <title>  document title
  <subject>  document subject
  <author>  document author
  <keywords>...  document keywords and tags to apply to file

  
OPTIONS:
  -h  help
  -v  verbose
  -q  quiet
  -d  debug
  --disable-scan  disable scanning an image beforehand
  --disable-date-prefix  do not prefix date to output filename
  --disable-image-preview  disable image preview before converting after scanning
  --delete-original-scan  do not keep the original scan image
  --date  date prefixed and tagged for the archive
  -p,--path <directory>  some directory
EOF
}


main() {
  local -a options
  local -a args
  local -i enable_preview_image=1
  local -i enable_scan=1
  local -i enable_date_prefix=1
  local -i delete_original_scan=0

  local input_date=$(date '+%F')

  check_dependencies
  # parse input args 
  parse_options "$@"
  # set leftover options parsed local input args
  set -- "${args[@]}"
  # remove args array
  unset -v args
  check_input_args "$@"

  if ! (($enable_scan)); then
    local path_input_file=${1:?"Input filename is required since scan is not enabled"}
    if ! [[ -f "$path_input_file" ]]; then
      log_err "Input filename is not a file"
      exit 1
    fi
    shift
  fi
  local output_filename=${1:?"Output filename is required"}
  local title=${2:?"Document title not given"}
  local subject=${3:?"Document subject not given"}
  local author=${4:?"Document author not given"}
  shift 4

  set_signal_handlers
  prepare_env
  pre_run
  run "$@"
  post_run 
  unset_signal_handlers
}


################################################################################
# script internal execution functions
################################################################################

run() {
  local -r volume_dir=$(mktemp -d "${VOLUME_TMP}/tmp.XXXXXXXXXX")
  local -a arr_date=(${input_date//-/ })
  trap "sigh_cleanup_scan $volume_dir" SIGINT SIGQUIT SIGTERM EXIT

  if (($enable_scan)); then
    input_filename="input_image.png"
    sudo -v
    scanimage -p --resolution $SCAN_DPI --format=$SCAN_FORMAT --mode $SCAN_MODE > "${volume_dir}/${input_filename}"
    if (($enable_preview_image)); then
      gpicview "${volume_dir}/${input_filename}" 
      read -p "Continue conversion? Press any key or abort now"
    fi
  else
    input_filename=$(basename "$path_input_file")
    cp "$path_input_file" "${volume_dir}/"
  fi

  sudo docker run \
    --rm -v $volume_dir:/output \
    --name "$DOCKER_CONTAINER_NAME" "$DOCKER_IMAGE_NAME" \
      --sidecar "/output/${output_filename}.txt" \
      --title "$title" \
      --subject "$subject" \
      --author "$author" \
      --keywords "$*" \
      --image-dpi $SCAN_DPI \
      --remove-background --deskew --clean \
      --output-type "$OCRMYPDF_OUTPUT_TYPE" \
      -l "$OCRMYPDF_LANGUAGE" \
      "/output/${input_filename}" "/output/${output_filename}.pdf"

  if (($enable_date_prefix)); then
    filename="${input_date}_${output_filename}"
  else
    filename="$output_filename"
  fi
  if ! (($delete_original_scan)); then
    cp -v "${volume_dir}/${input_filename}" "./${filename}-original.${SCAN_FORMAT}"
    tmsu tag "./${filename}-original.${SCAN_FORMAT}" \
      year=${arr_date[0]} month=${arr_date[1]} day=${arr_date[2]} \
      original scan image ${SCAN_FORMAT} document unsorted "$@"
  fi
  mv -v "${volume_dir}/${output_filename}.pdf" "./${filename}.pdf"
  mv -v "${volume_dir}/${output_filename}.txt" "./${filename}.txt"
  tmsu tag "./${filename}.pdf" \
    year=${arr_date[0]} month=${arr_date[1]} day=${arr_date[2]} \
    scan pdf ocr document unsorted "$@"
  tmsu tag "./${filename}.txt" \
    year=${arr_date[0]} month=${arr_date[1]} day=${arr_date[2]} \
    scan txt ocr document unsorted "$@"

  trap - SIGINT SIGQUIT SIGTERM EXIT
  rm -vrf "$volume_dir"
}


check_dependencies() {
  hash scanimage
  hash docker
  hash tmsu  # tagging
}


check_input_args() {
  if [[ -z ${1:-""} ]]; then
    usage
    exit 1
  fi
}


prepare_env() {
  set_descriptors
}


prepare() {
  export PATH_USER_LIB=${PATH_USER_LIB:-"$HOME/.local/lib/"}
  set_descriptors
}


source_libs() {
  source "${PATH_USER_LIB}libutils.sh"
  source "${PATH_USER_LIB}libcolors.sh"
}


set_descriptors() {
  if (($ENABLE_VERBOSE)); then
    exec {fdverbose}>&2
  else
    exec {fdverbose}>/dev/null
  fi
  if (($ENABLE_DEBUG)); then
    set -xv
    exec {fddebug}>&2
  else
    exec {fddebug}>/dev/null
  fi
}


pre_run() {
  :
}


post_run() {
  :
}


parse_options() {
  # exit if no options left
  [[ -z ${1:-""} ]] && return 0
  log "parse \$1: $1" 2>&$fddebug

  local do_shift=0
  case $1 in
      -d|--debug)
        ENABLE_DEBUG=1
        ;;
      -v|--verbose)
	ENABLE_VERBOSE=1
	;;
      -q|--quiet)
        ENABLE_QUIET=1
        ;;
      -h|--help)
        usage
        exit 0
        ;;
      --disable-image-preview)
        enable_preview_image=0
        ;;
      --disable-scan)
        enable_scan=0
        ;;
      --delete-original-scan)
        delete_original_scan=0
        ;;
      --date)
        input_date=$2
        do_shift=2
        ;;
      --disable-date-prefix)
        enable_date_prefix=0
        ;;
      --)
        do_shift=3
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
    # got --, use all arguments left as options for other commands
    shift
    options+=("$@")
    return
  fi
  shift
  parse_options "$@"
}


################################################################################
# signal handlers
#-------------------------------------------------------------------------------


set_signal_handlers() {
  trap sigh_abort SIGABRT
  trap sigh_alarm SIGALRM
  trap sigh_hup SIGHUP
  trap sigh_cont SIGCONT
  trap sigh_usr1 SIGUSR1
  trap sigh_usr2 SIGUSR2
  trap sigh_cleanup SIGINT SIGQUIT SIGTERM EXIT
}


unset_signal_handlers() {
  trap - SIGABRT
  trap - SIGALRM
  trap - SIGHUP
  trap - SIGCONT
  trap - SIGUSR1
  trap - SIGUSR2
  trap - SIGINT SIGQUIT SIGTERM EXIT
}



sigh_abort() {
  trap - SIGABRT
}


sigh_alarm() {
  trap - SIGALRM
}


sigh_hup() {
  trap - SIGHUP
}


sigh_cont() {
  trap - SIGCONT
}


sigh_usr1() {
  trap - SIGUSR1
}


sigh_usr2() {
  trap - SIGUSR2
}


sigh_cleanup() {
  trap - SIGINT SIGQUIT SIGTERM EXIT
  local active_jobs=$(jobs -p)
  for p in $active_jobs; do
    if [[ -e "/proc/$p" ]]; then
      kill "$p" >/dev/null 2>&1
      wait "$p"
    fi
  done
}


sigh_cleanup_scan() {
  trap - SIGINT SIGQUIT SIGTERM EXIT
  local active_jobs=$(jobs -p)
  for p in $active_jobs; do
    if [[ -e "/proc/$p" ]]; then
      kill "$p" >/dev/null 2>&1
      wait "$p"
    fi
  done
  rm -vrf "$volume_dir"
  exit 130
}


log() {
  logger -s -t "$__SCRIPT_NAME" "$@"
}

for level in emerg err warning info debug; do
  printf -v functext -- 'log_%s() { log -p user.%s -- "$@" ; }' "$level" "$level"
  eval "$functext"
done


################################################################################
# custom functions
#-------------------------------------------------------------------------------
# add here
example_function() {
  :
}
_example_command() {
  :
}


#-------------------------------------------------------------------------------
# end custom functions
################################################################################


prepare
main "$@"
