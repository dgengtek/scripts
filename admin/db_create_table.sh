#!/bin/env bash

# create user for specific db with usage rights to schema of db

usage() {
  echo "usage:  $0 db user pw"
  exit 1

}

main () {
  if [ -z $1 ] \
    || [ -z $2 ] \
    || [ -z $3 ] ; then
    usage
  fi

  local -r db="$1"
  local -r user="$2"
  local -r pw="$3"
  local -r grants_schema="USAGE"


  local sql_file=$(mktemp -u)
  tee $sql_file << EOF 
BEGIN;

CREATE USER $user with encrypted password '$pw';

GRANT CONNECT on DATABASE $db TO $user;
GRANT $grants_schema ON SCHEMA $db TO $user;

COMMIT;
EOF

  local -r host="pg"
  psql -h "$host" -d "$db" -U postgres -f "$sql_file"

  rm "$sql_file"
}

main "$@"
