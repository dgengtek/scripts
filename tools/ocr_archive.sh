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

declare -ir SCAN_DPI=${SCAN_DPI:-300}
readonly SCAN_MODE="color"
readonly SCAN_FORMAT="tiff"
readonly VOLUME_TMP="/tmp"  # where temporary volume directory will be created
readonly OCRMYPDF_LANGUAGE="deu"
readonly OCRMYPDF_OUTPUT_TYPE="pdfa"
readonly DOCKER_IMAGE_NAME="ocrmypdf"
readonly DOCKER_CONTAINER_NAME="ocr"

readonly __SCRIPT_NAME="${BASH_SOURCE[0]##*/}"

usage() {
  cat >&2 << EOF
Usage: ${0##*/} [OPTIONS] <output filename> [<keywords>...] [-- [EXTRA]]
Usage with scan: ${0##*/} [OPTIONS] <input filename> <output filename> [<keywords>...] [-- [EXTRA]]

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

  --title <title>  required
  --subject <subject>  required
  --author <author>  required

  --batch-count <count>  how many batches to scan and convert to pdf
  --disable-scan  disable scanning an image beforehand
  --disable-tagging  disable tagging via tsmu
  --enable-batch-scan  enable scanning in batches until aborted
  --disable-canonize-filename  do not canonize output filename
  --disable-date-prefix  do not prefix date to output filename
  --disable-uuid-prefix  do not prefix uuid to output filename
  --disable-image-preview  disable image preview before converting after scanning
  --disable-pdf-preview  disable pdf preview after conversion finished
  --delete-original-scan  do not keep the original scan image
  --date  date prefixed and tagged for the archive
EOF
}


main() {
  local -a options
  local -a args
  local -i enable_batch_scan=0
  local -i enable_preview_image=1
  local -i enable_preview_pdf=1
  local -i enable_scan=1
  local -i disable_tagging=0
  local -i disable_canonize_filename=0
  local -i enable_date_prefix=1
  local -i enable_uuid_prefix=1
  local -i delete_original_scan=0
  local -i batch_count=0
  local title=""
  local subject=""
  local author=""

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
  if ! (($disable_canonize_filename)); then
    output_filename=$(filename_canonize.py -ln "$output_filename")
  fi
  shift
  echo "<<< Output filename: ${output_filename}.{pdf,txt} >>>" >&2

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
  local filename
  local -r volume_dir=$(mktemp -d "${VOLUME_TMP}/tmp.XXXXXXXXXX")
  local -a arr_date=(${input_date//-/ })
  local -r uuid=$(uuidgen)
  local image_batch_name_prefix="input_image_batch-"
  trap "sigh_cleanup_scan $volume_dir" SIGINT SIGQUIT SIGTERM EXIT

  if (($enable_scan)); then
    input_filename="input_image.${SCAN_FORMAT}"
    sudo -v
    if (($enable_batch_scan)); then
      input_filename="input_image.pdf"
      local -a batch_files
      local -i counter=1
      while true; do
        image_batch_name="${image_batch_name_prefix}${counter}.${SCAN_FORMAT}"
        read -p "Scanning in batches - $counter. Press RETURN to scan or enter [n|no|nein] to stop with scanning and continue with processing" read_input
        if [[ "$read_input" =~ ^(n|no|nein)$ ]]; then
          break
        fi
        scanimage -p --resolution $SCAN_DPI --format=$SCAN_FORMAT --mode $SCAN_MODE > "${volume_dir}/${image_batch_name}"
        if (($enable_preview_image)); then
          echo "scanned image: '${volume_dir}/${image_batch_name}'" >&2
          gpicview "${volume_dir}/${image_batch_name}"
        fi
        read -p "Do you want to rescan this batch? Press RETURN to continue with scanning or enter [y|yes|j|ja] to rescan this batch" read_input
        if [[ "$read_input" =~ ^(y|yes|j|ja)$ ]]; then
          continue
        fi
        batch_files+=("${volume_dir}/${image_batch_name}")
        let counter+=1
      done
      log_info "Converting batched images to pdf"
      convert "${batch_files[@]}" "${volume_dir}/${input_filename}"
      log_info "Done with batch scanning"

    elif (($batch_count > 0)); then
      input_filename="input_image.pdf"
      local -a batch_files
      for i in $(seq $batch_count); do
        image_batch_name="${image_batch_name_prefix}${i}.${SCAN_FORMAT}"
        read -p "Scanning in batches - $i of $batch_count. Press RETURN or abort now"
        scanimage -p --resolution $SCAN_DPI --format=$SCAN_FORMAT --mode $SCAN_MODE > "${volume_dir}/${image_batch_name}"
        if (($enable_preview_image)); then
          echo "scanned image: '${volume_dir}/${image_batch_name}'" >&2
          gpicview "${volume_dir}/${image_batch_name}"
        fi
        batch_files+=("${volume_dir}/${image_batch_name}")
      done
      log_info "Converting batched images to pdf"
      convert "${batch_files[@]}" "${volume_dir}/${input_filename}"
      log_info "Done with batch scanning"

    else
      read -p "Scanning once now. Press RETURN or abort now"
      scanimage -p --resolution $SCAN_DPI --format=$SCAN_FORMAT --mode $SCAN_MODE > "${volume_dir}/${input_filename}"
      if (($enable_preview_image)); then
        echo "scanned image: '${volume_dir}/${input_filename}'" >&2
        gpicview "${volume_dir}/${input_filename}"
      fi

    fi

    if (($enable_preview_image)); then
      read -p "Continue converting scanned images with ocr to pdf? Press RETURN or abort now"
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
      --deskew --clean \
      --output-type "$OCRMYPDF_OUTPUT_TYPE" \
      -l "$OCRMYPDF_LANGUAGE" \
      "/output/${input_filename}" "/output/${output_filename}.pdf"

  if (($enable_preview_pdf)); then
    zathura "${volume_dir}/${output_filename}.pdf"
    read -p "Continue moving results to current directory? Press RETURN or abort now"
  fi

  filename="$output_filename"
  if (($enable_uuid_prefix)); then
    filename="${uuid}_${filename}"
  fi
  if (($enable_date_prefix)); then
    filename="${input_date}_${filename}"
  fi

  if ! (($delete_original_scan)); then
    local filename_original="./${filename}-original.${SCAN_FORMAT}"
    if (($batch_count)) || (($enable_batch_scan)); then
      filename_original="./${filename}-original.pdf"
    fi
    cp -v "${volume_dir}/${input_filename}" "$filename_original"
    if ! (($disable_tagging)); then
      tmsu tag "$filename_original" \
        year=${arr_date[0]} month=${arr_date[1]} day=${arr_date[2]} \
        uuid=$uuid \
        original scan image ${SCAN_FORMAT} document unsorted "$@"
    fi
  fi

  mv -v "${volume_dir}/${output_filename}.pdf" "./${filename}.pdf"
  mv -v "${volume_dir}/${output_filename}.txt" "./${filename}.txt"
  if ! (($disable_tagging)); then
    tmsu tag "./${filename}.pdf" \
      year=${arr_date[0]} month=${arr_date[1]} day=${arr_date[2]} \
      uuid=$uuid \
      scan pdf ocr document unsorted "$@"
    tmsu tag "./${filename}.txt" \
      year=${arr_date[0]} month=${arr_date[1]} day=${arr_date[2]} \
      uuid=$uuid \
      scan txt ocr document unsorted "$@"
  fi

  trap - SIGINT SIGQUIT SIGTERM EXIT
  rm -vrf "$volume_dir"
}


check_dependencies() {
  hash scanimage
  hash docker
  hash tmsu  # tagging
  hash convert  # ImageMagick
  hash filename_canonize.py
}


check_input_args() {
  local -i exit_usage=0
  if [[ -z ${title:-""} ]]; then
    log_err "Title is required"
    exit_usage=1
  fi
  if [[ -z ${subject:-""} ]]; then
    log_err "Subject is required"
    exit_usage=1
  fi
  if [[ -z ${author:-""} ]]; then
    log_err "Author is required"
    exit_usage=1
  fi

  if (($exit_usage)); then
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
      --disable-pdf-preview)
        enable_preview_pdf=0
        ;;
      --title)
        title=$2
        do_shift=2
        ;;
      --subject)
        subject=$2
        do_shift=2
        ;;
      --author)
        author=$2
        do_shift=2
        ;;
      --disable-tagging)
        disable_tagging=1
        ;;
      --disable-canonize-filename)
        disable_canonize_filename=1
        ;;
      --enable-batch-scan)
        enable_batch_scan=1
        ;;
      --batch-count)
        batch_count=$2
        do_shift=2
        ;;
      --disable-scan)
        enable_scan=0
        ;;
      --delete-original-scan)
        delete_original_scan=1
        ;;
      --date)
        input_date=$2
        do_shift=2
        ;;
      --disable-date-prefix)
        enable_date_prefix=0
        ;;
      --disable-uuid-prefix)
        enable_uuid_prefix=0
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
