#!/bin/env bash
# ------------------------------------------------------------------------------
# bookmark favourite paths
# ------------------------------------------------------------------------------
# 
# TODO: add dir lock

usage() {
  cat >&2 << EOF
Usage:	${0##*/} [OPTIONS] <command>
${0##*/} [OPTIONS] add <directory>
${0##*/} [OPTIONS] del <directory>
${0##*/} [OPTIONS] cat
${0##*/} [OPTIONS] ls
${0##*/} [OPTIONS] clear

add  add a bookmarked path
del  delete bookmarked path
cat  display file content
ls  list file path of bookmarks
clear | rm  remove database file

OPTIONS:
  -h			  help
  -v			  verbose
  -q			  quiet
  -d			  debug
EOF
}

main() {
  # flags
  local PATH_BOOKMARKS=${PATH_BOOKMARKS:-"${HOME}/.local/share/"}
  local TMP=${TMP:-"/tmp/"}
  local -r FSBOOKMARKS="${PATH_BOOKMARKS}fsbookmarks.db.txt"
  local -i enable_verbose=0
  local -i enable_quiet=0
  local -i enable_debug=0

  local -a options=
  local -a args=

  check_dependencies
  # parse input args 
  parse_options "$@"
  # set leftover options parsed local input args
  set -- ${args[@]}
  # remove args array
  unset -v args
  check_input_args "$@"

  prepare_env
  set_signal_handlers
  setup
  run "$@"
  unset_signal_handlers
}

################################################################################
# script internal execution functions
################################################################################

run() {
  subcommand=$1
  shift
  cmd_${subcommand} "$@"
  local -r rc=$?
  if (($rc == 127)); then
    error_exit 127 "Subcommand '$subcommand' is invalid."
  fi

}


check_dependencies() {
  :
}

check_input_args() {
  if [[ -z $1 ]]; then
    usage
    exit 1
  fi
}

prepare_env() {
  if ! [[ -d $PATH_BOOKMARKS ]]; then
    mkdir -p "$PATH_BOOKMARKS" || error_exit 1 "Failed to create bookmarks directory: '$PATH_BOOKMARKS'"
  fi
  if ! touch "$FSBOOKMARKS"; then
    error_exit 1 "Failed to create bookmarks database: '$FSBOOKMARKS'."
  fi
}

prepare() {
  export MYLIBS=${MYLIBS:-"$HOME/.local/lib/"}

  set -e
  source_libs
  set +e

  set_descriptors
}

source_libs() {
  source "${MYLIBS}libutils.sh"
  source "${MYLIBS}libcolors.sh"
}

set_descriptors() {
  if (($enable_verbose)); then
    exec {fdverbose}>&1
  else
    exec {fdverbose}>/dev/null
  fi
  if (($enable_debug)); then
    set -xv
    exec {fddebug}>&1
  else
    exec {fddebug}>/dev/null
  fi
}

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

setup() {
  set_descriptors
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
      -d|--debug)
        enable_debug=1
        ;;
      -v|--verbose)
	enable_verbose=1
	;;
      -q|--quiet)
        enable_quiet=1
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
    # got --, use all arguments left as options for other commands
    shift
    options+=("$@")
    return
  fi
  shift
  parse_options "$@"
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
    if ps -p $p >/dev/null 2>&1; then
      kill -SIGINT $p >/dev/null 2>&1
    fi
  done
  exit 0
}

################################################################################
# custom functions
#-------------------------------------------------------------------------------
cmd_add() {
  if read -t 0; then
    input=$(cat)
  else
    input="$@"
  fi
  
  if ! { input=$(realpath "$input") && [[ -d "$input" ]]; }; then
    error_exit 1 "Input is either not a directory or does not exist. Input: '$input'"
  fi
  info "input: $input"
  if grep -n -F "$input" "$FSBOOKMARKS"; then
    error_exit 1 "The path '$input' has already been added."
  fi
  info "a'$INPUT'"
  echo "$input" >> "$FSBOOKMARKS"
}
cmd_clear() {
  rm -i "$FSBOOKMARKS"
}
cmd_del() {
  if read -t 0; then
    input=$(cat)
  else
    input="$@"
  fi
  info "input: $input"
  local line_number=
  if ! line_number=$(grep -n "$input" "$FSBOOKMARKS" | awk -F: '{print $1}'); then
    info "Input not found in booksmarks."
  fi
  if (($(echo "$line_number" | wc -l) > 1)); then
    error_exit 1 "Query unspecific. Too many results"
  fi
  info "d:$line_number:'$input'"
  sed -i "$line_number d" "$FSBOOKMARKS"
}
cmd_cat() {
  cat "$FSBOOKMARKS"
}
cmd_rm() {
  cmd_clear
}
cmd_ls() {
  ls "$FSBOOKMARKS"
}

#-------------------------------------------------------------------------------
# end custom functions
################################################################################

prepare
main "$@"
