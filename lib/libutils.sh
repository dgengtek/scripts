#!/usr/bin/env bash
ord() { printf "%d" "'$1"; }
chr() { printf \\$(printf '%03o' $1); }

# quiet hash
hashq() { hash "$@" >/dev/null 2>&1; }

echo() (
  IFS=" "
  printf '%s\n' "$*"
)

echo_n() (
  IFS=" "
  printf %s "$*"
)

echo_e() (
  IFS=" "
  printf '%b\n' "$*"
)

log() { echo "$@" | logger -s -t ${0##*/}; }
out() { echo "$1 $2" "${@:3}"; }

info() { log "==> INFO:" "$@"; } >&2
error() { log "==> ERROR:" "$@"; } >&2
warning() { log "==> WARNING:" "$@"; } >&2
critical() { log "==> CRITICAL:" "$@"; } >&2
errorq() { log "$@" 2>/dev/null; }

msg() { log "==>" "$@"; }
msg2() { log "  ->" "$@"; }

# generate a system logging function log_* for every level
for level in emerg err warning info debug; do
  printf -v functext -- 'log_%s() { logger --stderr -p user.%s -t %s -- "$@" ; }' "$level" "$level" "${0##*/}"
  eval "$functext"
done

error_exit() {
  error_code=$1
  shift
  error "$@"
  exit $error_code
}
die() { error_exit 1 "$@"; }
