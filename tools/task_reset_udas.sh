#!/bin/env bash
# ------------------------------------------------------------------------------
# reset user defined attributes for all or by filter
# do not use for revisiting a uda
# ------------------------------------------------------------------------------
# 

usage() {
  cat >&2 << EOF
Usage:	${0##*/} [OPTIONS] [ID] -- [EXTRA]
  
OPTIONS:
  -h			  help
  -v			  verbose
  -q			  quiet
  -d			  debug

EXTRA
  Additional options passed for other purposes
EOF
}

main() {
  # flags
  local -i enable_verbose=0
  local -i enable_quiet=0
  local -i enable_debug=0

  local -a options=
  local -a args=

  local -r udas=$(task udas | sed '1,3d' | head -n -2)
  local -r labels=($(echo "$udas" | awk '{print $1}'))
  local -r defaults=($(echo "$udas" | awk '{print $5}'))
  local cmd=
  local -i skip_id=0
  local -i skip_value=0

  check_dependencies
  # parse input args 
  parse_options "$@"
  # set leftover options parsed local input args
  set -- ${args[@]}
  # remove args array
  unset -v args
  check_input_args "$@"

  prepare_env
  setup
  run "$@"
}

print_array_list() {
  local count=0
  while [[ -n $1 ]]; do
    command echo "$count ==> '$1'"
    shift
    count=$(($count + 1))
  done
  command echo
}

choose_value() {
  local -r OLDIFS=$IFS
  local answer=
  IFS=","
  local arr=($@)
  IFS=$OLDIFS
  print_array_list ${arr[@]}
  read -n 1 -p "> " answer 
  echo
  value=
  case $answer in
    x)
      skip_id=1
      ;;
    s)
      skip_value=1
      ;;
    l)
      task $id gd
      prompt_me
      return 1
      ;;
    r)
      task $id delete
      skip_id=1
      ;;
    d)
      if prompt_me; then
        task $id "done"
        skip_id=1
      fi
      ;;
    n)
      $(reset_id $id)
      skip_id=1
      ;;
    [0-9]*)
      if (($answer >= 0)) && (($answer < ${#arr[@]})); then
        value=${arr[$answer]}
        [[ -n $value ]] && task "$id" modify ${labels[$i-1]}:"$value"
        return 0
      else
        return 1
      fi
      ;;
    *)
      echo "--"
      echo "Choose again."
      echo "--"
      sleep 1
      return 1
      ;;
  esac
}

interactive_usage() {
  cat << EOF

  s to skip value
  x to skip id
  l to display info
  r to delete
  d to set done
  n to choose values anew for current id

EOF

}

reset_id() {
  local value=
  local id=${1:?No id supplied.}
  for i in $(seq 1 ${#labels}); do
    while :; do
      clear
      task $id gd
      interactive_usage
      echo "Choose value for ${labels[$i-1]}"
      if choose_value ${defaults[$i-1]}; then
        break
      fi
    done
    if (($skip_id)); then
      skip_id=0
      break
    elif (($skip_value)); then
      skip_value=0
      continue
    fi
  done
}

reset_udas() {
  echo "Are you sure you want to reset ALL user defined parameters to its default value?"
  if ! prompt_me; then
    return 1
  fi
  # create arrays
  local -r id_count=$(task status:pending count)
  local value=
  for id in $(seq 1 $id_count); do
    reset_id "$id"
  done
}

check_dependencies() {
  :
}

check_input_args() {
  :
}

prepare_env() {
  :
}

prompt_me() {
  local input=
  read -n 1 -p "Continue?[y/n] > " input
  input=$(printf %s "$input" | tr [a-z] [A-Z])
  echo
  case $input in
    "Y"|"YES")
      return 0
      ;;
    *)
      return 1
      ;;
  esac
}

prepare() {
  export MYLIBS="$HOME/.local/lib/"
  source "${MYLIBS}libutils.sh"
  source "${MYLIBS}libcolors.sh"
  set_descriptors
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

setup() {
  trap cleanup SIGHUP SIGINT SIGTERM EXIT
  set_descriptors
}

run() {
  if [[ -z $1 ]]; then
    reset_udas
  else
    reset_id $1
  fi
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

cleanup() {
  trap - SIGHUP SIGINT SIGTERM EXIT

  exit 0
}

prepare
main "$@"
