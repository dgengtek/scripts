#!/bin/env bash
# create user for specific db with usage rights to schema of db


#SELECT
#
#    Allows SELECT from any column, or the specific columns listed, of the specified table, view, or sequence. Also allows the use of COPY TO. This privilege is also needed to reference existing column values in UPDATE or DELETE. For sequences, this privilege also allows the use of the currval function. For large objects, this privilege allows the object to be read.
#INSERT
#
#    Allows INSERT of a new row into the specified table. If specific columns are listed, only those columns may be assigned to in the INSERT command (other columns will therefore receive default values). Also allows COPY FROM.
#UPDATE
#
#    Allows UPDATE of any column, or the specific columns listed, of the specified table. (In practice, any nontrivial UPDATE command will require SELECT privilege as well, since it must reference table columns to determine which rows to update, and/or to compute new values for columns.) SELECT ... FOR UPDATE and SELECT ... FOR SHARE also require this privilege on at least one column, in addition to the SELECT privilege. For sequences, this privilege allows the use of the nextval and setval functions. For large objects, this privilege allows writing or truncating the object.
#DELETE
#
#    Allows DELETE of a row from the specified table. (In practice, any nontrivial DELETE command will require SELECT privilege as well, since it must reference table columns to determine which rows to delete.)
#TRUNCATE
#
#    Allows TRUNCATE on the specified table.
#REFERENCES
#
#    To create a foreign key constraint, it is necessary to have this privilege on both the referencing and referenced columns. The privilege may be granted for all columns of a table, or just specific columns.
#TRIGGER
#
#    Allows the creation of a trigger on the specified table. (See the CREATE TRIGGER statement.)
#CREATE
#
#    For databases, allows new schemas to be created within the database.
#
#    For schemas, allows new objects to be created within the schema. To rename an existing object, you must own the object and have this privilege for the containing schema.
#
#    For tablespaces, allows tables, indexes, and temporary files to be created within the tablespace, and allows databases to be created that have the tablespace as their default tablespace. (Note that revoking this privilege will not alter the placement of existing objects.)
#CONNECT
#
#    Allows the user to connect to the specified database. This privilege is checked at connection startup (in addition to checking any restrictions imposed by pg_hba.conf).
#TEMPORARY
#TEMP
#
#    Allows temporary tables to be created while using the specified database.
#EXECUTE
#
#    Allows the use of the specified function and the use of any operators that are implemented on top of the function. This is the only type of privilege that is applicable to functions. (This syntax works for aggregate functions, as well.)
#USAGE
#
#    For procedural languages, allows the use of the specified language for the creation of functions in that language. This is the only type of privilege that is applicable to procedural languages.
#
#    For schemas, allows access to objects contained in the specified schema (assuming that the objects' own privilege requirements are also met). Essentially this allows the grantee to "look up" objects within the schema. Without this permission, it is still possible to see the object names, e.g. by querying the system tables. Also, after revoking this permission, existing backends might have statements that have previously performed this lookup, so this is not a completely secure way to prevent object access.
#
#    For sequences, this privilege allows the use of the currval and nextval functions.
#
#    For foreign-data wrappers, this privilege enables the grantee to create new servers using that foreign-data wrapper.
#
#    For servers, this privilege enables the grantee to create, alter, and drop his own user's user mappings associated with that server. Also, it enables the grantee to query the options of the server and associated user mappings.
#ALL PRIVILEGES
#
#    Grant all of the available privileges at once. The PRIVILEGES key word is optional in PostgreSQL, though it is required by strict SQL.

usage() {
  cat << EOF
usage:	${0##*/} [OPTIONS] db user pw 
  
  OPTIONS:
    -h			  help
    -a                    all grants
    -o                    grant

EOF
  exit 1
  exit 1

}
main () {
  local -ir ERROR_NO_GRANTS=2


  local -r optlist=":hao:"
  local -i enable_all_grants=0
  local -a grants=()
  while getopts $optlist opt; do
    case $opt in
      a)
        let enable_all_grants=1
	;;
      o)
        grants+=("$OPTARG")
	;;
      *)
	usage
	;;
    esac
  done
  shift $((OPTIND - 1))

  if [[ -z $1 ]] \
    || [[ -z $2 ]] \
    || [[ -z $3 ]] ; then
    usage
  fi

  local -r db="$1"
  local -r user="$2"
  local -r pw="$3"
  local grants_schema=""
  if [[ ${#grants[@]} == 0 ]]; then
    exit $ERROR_NO_GRANTS
  elif [[ ${#grants[@]} == 1 ]]; then
    grants_schema="${grants[0]}"
  else
    for i in ${grants[@]}; do
      grants_schema+="$i,"
    done
  fi

  local sql_file=$(mktemp -u)
  tee $sql_file << EOF 
BEGIN;

CREATE USER $user with encrypted password '$pw';

GRANT CONNECT on DATABASE $db TO $user;
GRANT $grants_schema ON SCHEMA $db TO $user;

COMMIT;
EOF

  local -r host="pg"
  psql -h $host -d $db -U postgres -f $sql_file

  rm $sql_file

}

main "$@"
