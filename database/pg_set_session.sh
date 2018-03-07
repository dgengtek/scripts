#!/bin/env bash

main() {
  echo "Setup a postgres environment: "
  set -a
  pg_set_session
  set_defaults
  set +a
  bash --rcfile <(echo "source $HOME/.bashrc;PS1='>[$PGUSER@$PGHOST:$PGPORT]#PGENV $ ';clear;echo '==> POSTGRES ENVIRONMENT';env|grep ^PG") -i
}
pg_set_session() {
  read -p "PGDATABASE[postgres]: " PGDATABASE
  read -p "PGHOST[localhost]: " PGHOST
  read -p "PGOPTIONS: " PGOPTIONS
  read -p "PGPORT[5432]: " PGPORT
  read -p "PGUSER[postgres]: " PGUSER
}
set_defaults() {
  [[ -z $PGHOST ]] && PGHOST=localhost
  [[ -z $PGPORT ]] && PGPORT=5432
  [[ -z $PGUSER ]] && PGUSER=postgres
}

main "$@"
