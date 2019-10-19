#!/usr/bin/env bash

usage() {
  echo "usage:  $0 db owner"
  exit 1

}

main () {
  if [ -z $1 ]; then
    usage
  fi
  local -r db="$1"
  local -r owner="$2"
  local user_admin="$owner"
  if [[ -z $owner ]]; then
    user_admin="${db}_admin"
  fi
  local -r grants_schema="CREATE, USAGE"


  local sql_file=$(mktemp -u)
  tee $sql_file << EOF 
CREATE USER $user_admin with password '$user_admin';
CREATE DATABASE $db WITH OWNER $user_admin;
BEGIN;

REVOKE ALL ON DATABASE $db FROM public;

COMMIT;

\c $db
BEGIN;

CREATE SCHEMA $db AUTHORIZATION $user_admin;
ALTER DATABASE $db SET search_path = $db;

ALTER ROLE $user_admin SET search_path = $db;
GRANT $grants_schema ON SCHEMA $db TO $user_admin;
GRANT CONNECT on DATABASE $db TO $user_admin;
ALTER DEFAULT PRIVILEGES IN SCHEMA $grants_schema GRANT ALL ON TABLES TO $user_admin;
ALTER DEFAULT PRIVILEGES IN SCHEMA $grants_schema GRANT ALL ON SEQUENCES TO $user_admin;

COMMIT;
EOF

  local -r host="pg"
  psql -h "$host" -U postgres -f "$sql_file"

  rm "$sql_file"

}

main "$@"
