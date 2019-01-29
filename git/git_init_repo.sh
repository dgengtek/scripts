#!/usr/bin/env bash
# ------------------------------------------------------------------------------
# init git repo
# ------------------------------------------------------------------------------
# 
usage() {
  cat >&2 << EOF
Usage:	${0##*/} [<options>] <destination>

Init a git repo with TODO.wiki, README.adoc, LICENCE and a 'dev,release,stage' branch.
  
options:
  -r                    add a remote repo
  -g                    add branches(release, stage) based on master
  -h			help
  -n                    no commit
  -d                    debug
  --mit                 add MIT licence
  -a, --author name     add author to licence
  -x,--exclude  do not add any files
  -h			  help
  -v			  verbose
  -q			  quiet
  -d			  debug

EOF
}

main() {
  # flags
  local -i enable_verbose=0
  local -i enable_quiet=0
  local -i enable_debug=0

  local -a options
  local -a args

  local -i init_remote=0
  local -r optlist="rp:"
  local author="github.com/dgengtek"
  local add_mit_licence=0
  local add_files=1
  local add_git_workflow=0
  local -i commit=1

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
  git_init_repo "$@"
}

check_dependencies() {
  if ! hash git_init_remote_origin.sh >/dev/null 2>&1; then
    error 1 "git_init_remote_origin.sh not found."
  fi
  if ! hash git_init_workflow.sh >/dev/null 2>&1; then
    error 1 "git_init_remote_origin.sh not found."
  fi
}

check_input_args() {
  if [[ -z $1 ]]; then
    usage
    exit 1
  fi
}

prepare_env() {
  :
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

setup() {
  set_descriptors
}

parse_options() {
  # exit if no options left
  [[ -z $1 ]] && return 0
  log "parse \$1: $1" 2>&$fddebug

  local do_shift=0
  case $1 in
      -d|--debug)
        enable_debug=1
        ;;
      -v|--verbose)
	enable_verbose=1
	;;
      -q|--quiet)
        enable_quiet=1
        ;;
      -h|--help)
        usage
        exit 1
        ;;
      -r)
        init_remote=1
	;;
      -g)
        add_git_workflow=1
	;;
      --MIT|--mit)
        add_mit_licence=1
        ;;
      -n)
        commit=0
        ;;
      -x|--exclude)
        add_files=0
        ;;
      -a|--author)
        author=$2
        shift
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
    if ps -p $p >/dev/null 2>&1; then
      kill -SIGINT $p >/dev/null 2>&1
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

git_init_repo() {
  local path
  local git_root
  if ! path=$(realpath ${1:-.}); then
    error 1 "$path is not valid."
  fi
  local -r base=$(basename "$path")
  local -r version_date=$(date +%Y.%m)
  mkdir -p "$path"
  pushd "$path" >/dev/null 2>&1 || error 1 "$path push failed."
  git init || error 1 "Git repo init failed."
  (($add_files)) && touch TODO.wiki
  (($add_files)) && cat > README.adoc << EOF
= Inititial repository commit for $(basename $path)
$author
$version_date
EOF
  ! [[ -f .gitignore ]] && cat > .gitignore << EOF
*.swp
EOF

  (($add_files)) && _gen_licence

  git add .
  (($commit)) && git commit -m "Initial commit of $base"
  if (($add_git_workflow)); then
    git_init_workflow.sh
  else
    git_init_branches
  fi
  if (($init_remote == 1)); then
    git_init_remote_origin.sh
  fi
  popd >/dev/null 2>&1

}

git_init_branches() {
  git checkout -b dev || git checkout dev
}

_gen_licence() {
  if (($add_mit_licence)); then
    _gen_licence_mit
  else
    touch LICENSE
  fi
}

_gen_licence_mit() {
  if [[ -f LICENCE ]]; then
    echo "LICENCE already exists." >&2
    return 1
  fi
  cat > LICENCE << EOF
MIT License

Copyright (c) $(date +%Y) ${author:-"github.com/dgengtek"}

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
EOF
}


#-------------------------------------------------------------------------------
# end custom functions
################################################################################

prepare
main "$@"
