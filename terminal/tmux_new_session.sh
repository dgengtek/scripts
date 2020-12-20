#!/usr/bin/env bash
# ------------------------------------------------------------------------------
# create a new tmux session if none exists
# ------------------------------------------------------------------------------
# 
readonly STARTUP_SHELL=alacritty

usage() {
cat >&2 << EOF
Usage: ${0##*/} [OPTIONS] [<session name>]

will start session in a new shell if the the creation errors first

OPTIONS:
-p,--path <directory>  start session in <directory>
-d,--detach  detach session
-n,--never-new-shell  never start session in a new shell
-h  help
-v  verbose
-q  quiet
EOF
}

main() {
  # flags
  local -i enable_verbose=0
  local -i enable_quiet=0
  local -i enable_debug=0
  local -i disable_startup_shell=0
  local -i tmux_detach=0
  local tmux_start_directory=""

  local -a options
  local -a args

  check_dependencies
  # parse input args 
  parse_options "$@"
  # set leftover options parsed local input args
  set -- "${args[@]}"
  # remove args array
  unset -v args
  check_input_args "$@"

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
  local session=$1
  shift 1
  local -r directory="$tmux_start_directory"
  if [[ -n "$directory" ]]; then
    if [[ -d "$directory" ]]; then
      cd "$directory"
    else
      echo "Not a directory: $directory" >&2
      exit 1
    fi
  fi

  if [[ -z "$session" ]]; then
    session=$(basename "$PWD")
  fi

  local -a tmux_options=()
  if tmux has-session -t "$session"; then
    echo "Session $session already exists." >&2
    exit 1
  fi
  (($tmux_detach)) && tmux_options+=("-d")
  local -r command="tmux new-session -s $session ${tmux_options[*]} $*"
  if [[ -z "$TMUX" ]]; then
    $command
  else
    if (($disable_startup_shell)); then
      echo "Startup in a new shell is disabled and command is being run in a TMUX session already." >&2
      exit 1
    fi
    run.sh -n -q \
      -- $STARTUP_SHELL -e "$command"
  fi

}

check_dependencies() {
  if ! hash $STARTUP_SHELL >&/dev/null; then
    echo "$STARTUP_SHELL not found." >&2
    exit 1
  fi
}

check_input_args() {
  :
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
}

source_libs() {
  source "${PATH_USER_LIB}libutils.sh"
  source "${PATH_USER_LIB}libcolors.sh"
}

set_descriptors() {
  if (($enable_verbose)); then
    exec {fdverbose}>&2
  else
    exec {fdverbose}>/dev/null
  fi
  if (($enable_debug)); then
    set -xv
    exec {fddebug}>&2
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

pre_run() {
  :
}
post_run() {
  :
}

parse_options() {
  # exit if no options left
  [[ -z $1 ]] && return 0
  log "parse \$1: $1" 2>&$fddebug

  local do_shift=0
  case $1 in
      -x|--debug)
        enable_debug=1
        ;;
      -v|--verbose)
	enable_verbose=1
	;;
      -q|--quiet)
        enable_quiet=1
        ;;
      -n|--never-new-shell)
        disable_startup_shell=1
        ;;
      -p|--path)
        tmux_start_directory=$2
        do_shift=2
        ;;
      -h|--help)
        usage
        exit 0
        ;;
      -d|--detach)
        tmux_detach=1
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
