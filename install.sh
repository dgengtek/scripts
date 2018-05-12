#!/bin/env bash
# Install scripts

usage() {
  cat >&2 << EOF
Usage:	${0##*/} [OPTIONS] [<configuration file>]]
  
OPTIONS:
  -h			  help
EOF
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


  trap cleanup SIGINT SIGTERM EXIT
  local installer="tools/install.py"
  ! command -v "$installer" && installer="install.py"
  ! command -v "$installer" && error "Could not find $installer in PATH." && exit 1
  prepare

  local setup_config="setup.ini"
  [[ -n $1 ]] && setup_config=$1

  python3 "$installer" "$setup_config" || exit 1
  trap - SIGINT SIGTERM EXIT
}

check_dependencies() {
  if ! hash stow 2>&1 | logger -t install -p user.info; then
    error "'stow' is required for installation."
  fi
}

cleanup() {
  trap - SIGINT SIGTERM EXIT
  pushd "$HOME"
  rmdir -p .local/{bin,lib}
  popd
  exit 1
}

prepare() {
  pushd "$HOME"
  mkdir -p .local/{bin,lib}
  popd
}

mkdir() {
  ! [[ -e $1 ]] && command mkdir "$@"
}

export PATH="$PATH:$HOME/.local/bin/:$HOME/.bin/"
export PATH_USER_LIB="$HOME/.local/lib/"

source ./lib/libutils.sh || source "${PATH_USER_LIB}libutils.sh"
if [[ $(type -t error) != "function" ]]; then
echo() ( 
  IFS=" " 
  printf '%s\n' "$*"
)
out() { echo "$1 $2" "${@:3}"; }
error() { out "==> ERROR:" "$@"; } >&2
fi

# silence output
exec > /dev/null

main "$@"
