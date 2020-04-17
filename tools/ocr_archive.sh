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

  # scanimage -p --resolution 300 --format=png --mode color > filename.png
  # sudo docker run --rm -v $(pwd)/test:/test --name ocr ocrmypdf --sidecar /test/order1.txt --image-dpi 300 --remove-background --deskew --clean --output-type pdfa -l deu /test/order1 /test/order1.pdf

readonly __SCRIPT_NAME="${BASH_SOURCE[0]##*/}"

usage() {
  cat >&2 << EOF
Usage: ${0##*/} [OPTIONS] <output filename> [-- [EXTRA]]

command
  run a custom function defined as _command

arguments
  <output filename>  without extension

  
OPTIONS:
  -h  help
  -v  verbose
  -q  quiet
  -d  debug
  -p,--path <directory>  some directory


EXTRA
  Additional options passed for other purposes. Accessable via \$options array variable
EOF
}


main() {
  local -a options
  local -a args

  local input_date=$(date '+%F')

  check_dependencies
  # parse input args 
  parse_options "$@"
  # set leftover options parsed local input args
  set -- "${args[@]}"
  # remove args array
  unset -v args
  check_input_args "$@"

  local output_filename=${1:?"Output filename is required"}
  shift

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
  local -r scan_output="input_image.png"

  set -e
  set -x
  sudo -v
  scanimage -p --resolution $SCAN_DPI --format=$SCAN_FORMAT --mode $SCAN_MODE > "${volume_dir}/${scan_output}"
  sudo docker run \
    --rm -v $volume_dir:/output \
    --name "$DOCKER_CONTAINER_NAME" "$DOCKER_IMAGE_NAME" \
      --sidecar "/output/${output_filename}.txt" \
      --image-dpi $SCAN_DPI \
      --remove-background --deskew --clean \
      --output-type "$OCRMYPDF_OUTPUT_TYPE" \
      -l "$OCRMYPDF_LANGUAGE" \
      "/output/${scan_output}" "/output/${output_filename}.pdf"
  mv -v "${volume_dir}/${output_filename}.pdf" "./${output_filename}.pdf"
  mv -v "${volume_dir}/${output_filename}.txt" "./${output_filename}.txt"
  tmsu tag "./${output_filename}.pdf" \
    year=${arr_date[0]} month=${arr_date[1]} day=${arr_date[2]} \
    scanned pdf ocr document unsorted
  tmsu tag "./${output_filename}.txt" \
    year=${arr_date[0]} month=${arr_date[1]} day=${arr_date[2]} \
    scanned txt ocr document unsorted
  rm -vrf "$volume_dir"
  set +e
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

  set -e
  source_libs
  set +e

  set_descriptors
  set -u
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
      -p|--path)
        path=$2
        do_shift=2
        ;;
      -d|--date)
        input_date=$2
        do_shift=2
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
