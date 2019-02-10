#!/usr/bin/env bash
# ------------------------------------------------------------------------------
# script is intended to be run by a service manager or cron
# ------------------------------------------------------------------------------


readonly LOG_TAG="${0##/*}"


usage() {
  echo "usage: ${0##*/}"
}


main() {
  local -r date_added="$(date +%Y%m%dT%H%M)"
  local -r EDITOR=${EDITOR:-vim}
  # Freigabe, somit wann das Protokoll eingefügt wurde
  local date_released=""

  local protocol_dir="protocolling"
  local -r protocol_path="$HOME/vimwiki/$protocol_dir"
  local -r database="$protocol_path/protocolling.db"

  mkdir -p "$protocol_path"
  if ! create_db "$database"; then
    error "Failed to create sqlite3 database in $database"
    exit 1
  fi

  set_signal_handlers
  # open editor
  protocol_tmp=$(mktemp "/tmp/protocol_XXXXXXX_$date_added")
  if ! urxvt -e $EDITOR "$protocol_tmp"; then
    error "Failed to run $EDITOR on $protocol_tmp"
    exit 1
  fi
  if ! update_database "$database" "$protocol_tmp" "$date_added"; then
    error "Failed to update database $database with $protocol_tmp"
    exit 1
  fi
  unset_signal_handlers
}


update_database() {
  local -r db=$1
  local -r protocol_tmp=$2
  local -r date_added=$3

  log "updating database $db"
  local -r date_released="$(date +%Y%m%dT%H%M)"

  insert_entry "$db" "$protocol_tmp" "$date_added" "$date_released"

  sigh_cleanup "$protocol_tmp"
}


editor_running() {
  local -r pid=$1
  # if editor is stil open with the entry
  if [[ -e "/proc/$pid" ]] \
    && ps -p $pid -o args --no-headers | grep -q "^$EDITOR /tmp/protocol_.*"; then
    return 0
  fi
  return 1
}


insert_entry() {
  local -r db=$1
  local -r protocol_tmp=$2
  local -r date_added=$3
  local -r date_released=$4

  local -r text=$(cat "$protocol_tmp")
  if [[ -z "$text" ]]; then
    log "Skip insert. Entry empty"
    return
  fi
  log "running sql insert"
  sqlite3 "$db" << EOF
INSERT INTO protocol(
entry,
entry_added, 
entry_updated
)
 VALUES(
'$text',
'$date_added',
'$date_released'
)
;
EOF
  log "finished sql insert"

}


create_db() {
  local -r db=$1
  if [[ -e $db ]]; then
    return
  fi
  log "creating database:$db in $PWD"
  sqlite3 "$db" << EOF
CREATE TABLE protocol(
id INTEGER PRIMARY KEY AUTOINCREMENT,
entry TEXT NOT NULL,
entry_added DATE NOT NULL,
entry_updated DATE 
)
;
EOF
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
  trap "sigh_cleanup '$protocol_tmp'" SIGINT SIGQUIT SIGTERM EXIT
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
  local -r protocol_tmp=$1
  log "running cleanup"

  rm "$protocol_tmp"
  log "removed $protocol_tmp"

  trap - SIGINT SIGQUIT SIGTERM EXIT
  local active_jobs=$(jobs -p)
  for p in $active_jobs; do
    if [[ -e "/proc/$p" ]]; then
      kill "$p" >/dev/null 2>&1
      wait "$p"
    fi
  done
}


log() {
  logger -s -t "$LOG_TAG" "$@"
}


error() {
  log "==> ERROR: " "$@"
}


check_dependencies() {
  if ! hash sqlite3 >/dev/null; then
    error "${0##*/} requires sqlite3 installed"
    exit 1
  fi
}


check_dependencies
main "$@"
