#!/bin/env bash

# reset color
COLOR_NONE="\033[0m"

BLACK="\033[0;30m" # text color black
BLACK_BOLD="\033[1;30m" # bold text color black
BLACK_UL="\033[4;30m" # text black underline
BLACK_BG="\033[40m" # text black background

RED="\033[0;31m"
RED_BOLD="\033[1;31m"
RED_UL="\033[4;31m"
RED_BG="\033[41m"

GREEN="\033[0;32m"   
GREEN_BOLD="\033[1;32m"
GREEN_UL="\033[4;32m"   
GREEN_BG="\033[42m"

YELLOW="\033[0;33m"     
YELLOW_BOLD="\033[1;33m"
YELLOW_UL="\033[4;33m"     
YELLOW_BG="\033[43m"

BLUE="\033[0;34m"     
BLUE_BOLD="\033[1;34m"
BLUE_UL="\033[4;34m"     
BLUE_BG="\033[44m"

PURPLE="\033[0;35m"     
PURPLE_BOLD="\033[1;35m"
PURPLE_UL="\033[4;35m"     
PURPLE_BG="\033[45m"

CYAN="\033[0;36m"     
CYAN_BOLD="\033[1;36m"
CYAN_UL="\033[4;36m"     
CYAN_BG="\033[46m"

WHITE="\033[0;37m"     
WHITE_BOLD="\033[1;37m"
WHITE_UL="\033[4;37m"     
WHITE_BG="\033[47m"


print_colored() {
  local cc=$1
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

  printf "\x1b[38;5;%im%s\x1b[0m]" "$cc" "$text"
}
printc() {
  print_colored "$@"
}
