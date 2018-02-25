#!/usr/bin/env bash
usage() {
  cat << EOF
Usage:	${0##*/} [OPTIONS] command
  
OPTIONS:
  -h			  help
  option1		  description
EOF
  exit 1
}

main() {
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
  trap cleanup SIGKILL SIGTERM SIGABRT EXIT
  trap "" SIGINT
  local -r command_prefix=$1
  shift
  local -r prompt_symbol="> "

  cmd_exists "$command_prefix"
  local -r fifo="/tmp/fifo$RANDOM"
  local -r fifolock="/tmp/lock$RANDOM"

  local -i enable_verbose=0
  local -i enable_debug=0
  setup
  along "$@"
  cleanup
}

along()
{
  local prefix="$command_prefix $@"
  local prompt="$prefix $prompt_symbol"
  while pipe_exists "$fifo"; do 
    echo "inside along loop" >&$fddebug
    run_interpreter "$prefix" &
    run_prompt "$command_prefix"
  done
}

error_exit() {
  local -r exit_code=$1
  shift
  IFS=" "
  printf "%b\n" "$@" >&2
  kill $$
  exit $exit_code
}

setup() {
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
  mkfifo "$fifo" || error_exit 1 "Failed to create $fifo"
  mkfifo "$fifolock" || error_exit 1 "Failed to create $fifo"
}

run_prompt() {
  local IFS=
  echo "inside prompt" >&$fddebug
  if ! read -e -r -p "$prompt" args; then
    echo "exiting prompt" >&$fddebug
    printf "%s" "\q" > "$fifo"
    error_exit 1
  fi
  printf "%s" "$args" > "$fifo"
  mutex
  echo "ending prompt" >&$fddebug
}

pipe_exists() {
  [[ -p $1 ]]
}

run_interpreter() {
  prefix=$1

  # dirty double traps, research how to avoid
  #trap cleanup SIGKILL SIGTERM SIGABRT EXIT
  trap "" SIGINT

  echo "inside interpreter" >&$fddebug
  local input=$(cat < "$fifo")
  if ! parse "$input"; then
    echo "parsing failed" >&$fddebug
    return 1
  fi

  eval "$prefix $input"
  echo "$?"
  update_prompt "$prefix" "$?"
  mutex sync
  echo "ending interpret" >&$fddebug
}

parse() {
  local -r string=$1
  if [[ -z $string ]]; then
    return 1
  fi

  local constructed_string=""
  local ordinal=""
  echo "parsing now" >&$fddebug
  while read -n1 -r character; do
    constructed_string+="$character"
    ordinal=$(ord "$character")
    echo "got ordinal $ordinal - $character">&$fddebug

    # check if char is EOT
    (($ordinal == 4)) && error_exit 0

    if ! check_illegal_input "$constructed_string"; then
      return 1
    fi

    issue_instruction "$constructed_string"
  done < <(printf "%s" "$string")

}

check_illegal_input() {
  local return_code=1
  local -r string=$1
  case $string in
    "")
      echo "empty string ending parse" >&$fddebug
      ;;
    *)
      echo "no illegal input" >&$fddebug
      return_code=0
      ;;
  esac
  
  return $return_code
}

issue_instruction() {
  local -r string=$1
  echo "got string $string" >&$fddebug
  case $string in
    '\q')
      echo "exiting now" >&$fddebug
      error_exit 0
      ;;
    *)
      echo "no instruction" >&$fddebug
      ;;
  esac
}

mutex() {
  local -r cmd=$1
  if [[ $cmd == "sync" ]]; then
    local -r input=$(cat "$fifolock")
    if [[ $input == "sync" ]]; then
      return 0
    else
      return 1
    fi
  fi
  echo "sync" > "$fifolock"
}

update_prompt() {
  prefix="$1"
  shift
  prompt="$@ $prefix $prompt_symbol"
}

cmd_exists() {
  cmd=$1
  if ! hash "$1" 2> /dev/null; then
    error_exit 1 "Command '$cmd' does not exist."
  fi
}

eat_pipe() {
  local -r pipe=$1
  echo "eating pipe $pipe" >&$fddebug
  if ! pipe_exists "$pipe"; then
    return
  fi
  printf "" > $pipe &
  while read -r trash; do
    :
  done < $pipe
  rm -v "$pipe" >&$fdverbose 
}

cleanup() {
  trap - SIGKILL SIGTERM SIGABRT EXIT
  eat_pipe "$fifo"
  eat_pipe "$fifolock"
}

ord() {
  printf "%d" "'$1"
}

chr() {
  printf \\$(printf '%03o' $1)
}

main "$@"
