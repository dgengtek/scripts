#!/bin/env bash
usage() {
  cat >&2 << EOF
Usage: ${0##*/} [PGOPTIONS <database>]

Drop connections to <database>

<host> defaults to localhost

EOF

}

main() {
  local -r host=localhost
  local -r database=$BASH_ARGV
  [[ -z $database ]] && usage && exit 1
  shift
  psql -h "$host" "$@" << EOF
SELECT pg_terminate_backend(pg_stat_activity.pid)
FROM pg_stat_activity
WHERE pg_stat_activity.datname = '$database'
AND pid <> pg_backend_pid();
EOF
}

main "$@"
