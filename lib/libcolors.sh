#!/usr/bin/env bash

# reset color
__CC_ANSI_NONE="\033[0m"

__CC_ANSI_BLACK="\033[0;30m" # text color black
__CC_ANSI_BLACK_BOLD="\033[1;30m" # bold text color black
__CC_ANSI_BLACK_UL="\033[4;30m" # text black underline
__CC_ANSI_BLACK_BG="\033[40m" # text black background

__CC_ANSI_RED="\033[0;31m"
__CC_ANSI_RED_BOLD="\033[1;31m"
__CC_ANSI_RED_UL="\033[4;31m"
__CC_ANSI_RED_BG="\033[41m"

__CC_ANSI_GREEN="\033[0;32m"   
__CC_ANSI_GREEN_BOLD="\033[1;32m"
__CC_ANSI_GREEN_UL="\033[4;32m"   
__CC_ANSI_GREEN_BG="\033[42m"

__CC_ANSI_YELLOW="\033[0;33m"     
__CC_ANSI_YELLOW_BOLD="\033[1;33m"
__CC_ANSI_YELLOW_UL="\033[4;33m"     
__CC_ANSI_YELLOW_BG="\033[43m"

__CC_ANSI_BLUE="\033[0;34m"     
__CC_ANSI_BLUE_BOLD="\033[1;34m"
__CC_ANSI_BLUE_UL="\033[4;34m"     
__CC_ANSI_BLUE_BG="\033[44m"

__CC_ANSI_PURPLE="\033[0;35m"     
__CC_ANSI_PURPLE_BOLD="\033[1;35m"
__CC_ANSI_PURPLE_UL="\033[4;35m"     
__CC_ANSI_PURPLE_BG="\033[45m"

__CC_ANSI_CYAN="\033[0;36m"     
__CC_ANSI_CYAN_BOLD="\033[1;36m"
__CC_ANSI_CYAN_UL="\033[4;36m"     
__CC_ANSI_CYAN_BG="\033[46m"

__CC_ANSI_WHITE="\033[0;37m"     
__CC_ANSI_WHITE_BOLD="\033[1;37m"
__CC_ANSI_WHITE_UL="\033[4;37m"     
__CC_ANSI_WHITE_BG="\033[47m"


readonly __CC_BOLD=$(tput bold)
readonly __CC_RESET=$(tput sgr0)
readonly __CC_BLACK=$(tput setaf 0)
readonly __CC_RED=$(tput setaf 1)
readonly __CC_GREEN=$(tput setaf 2)
readonly __CC_YELLOW=$(tput setaf 3)
readonly __CC_BLUE=$(tput setaf 4)
readonly __CC_MAGENTA=$(tput setaf 5)
readonly __CC_CYAN=$(tput setaf 6)
readonly __CC_WHITE=$(tput setaf 7)


__print_colored() {
  local cc=$1
  shift
  local -r text=$@

  cc=$(tr [A-Z] [a-z] <<< "$cc")
  case $cc in
    "black")
      cc=0
      ;;
    "red")
      cc=9
      ;;
    "green")
      cc=10
      ;;
    "yellow")
      cc=11
      ;;
    "blue")
      cc=12
      ;;
    "pink")
      cc=13
      ;;
    "cyan")
      cc=14
      ;;
    "white")
      cc=15
      ;;
    "purple")
      cc=93
      ;;
    "brown")
      cc=94
      ;;
    "orange")
      cc=202
      ;;
    *)
      if ! (($cc >= 0 && $cc <= 255 )); then
        cc=15
      fi
      ;;
  esac

  printf "\x1b[38;5;%im%s\x1b[0m" "$cc" "$text"
}

printc() {
  __color_string "$@"
}

printcbold() {
  __color_string_bold "$@"
}

__color_string() {
  printf "\001%s\002%s\001%s\002" "$1" "$2" "$__CC_RESET"
}

__color_string_bold() {
  __color_string "${__CC_BOLD}${1}" "$2"
}
