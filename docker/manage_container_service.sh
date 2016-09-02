#!/bin/bash
usage() {
  cat << EOF
usage:  ${0##*/} mode config

  mode			  (start | stop | restart | reload | remove)
  config		  configuration file for the container
EOF
  exit 1
}
main() {
  mode=$1
  config=$2
  if [ -z "$mode" ] || [ -z "$config" ]; then
    usage
  fi

  local -r docker_bin="/usr/bin/docker"
  # source configuration file
  # if input starts with ./path/to/name.cfg
  # do nothing
  # if input is name.cfg use default path to cfgs
  if [[ $(dirname "$config") == "." ]]; then
    config="/usr/local/etc/$config"
  fi
  source "$config"
  # read only config vars
  local -r container_name=$container_name
  local -r image_name=$image_name
  local -a run_cmd_args=${run_cmd_args[@]}
  local -a entrypoint_args=${entrypoint_args[@]}
  echo $$ > /run/"$(basename $2).pid"

  local -r SYSLOG_TAG="${0##*/}@$container_name"

  run_mode "$1"
}
_setup() {
  if _container_exists; then
    return 1
  fi
  if exec $docker_bin run \
    --name "$container_name" \
    ${run_cmd_args[@]} \
    "$image_name"; then
    exit 0
  else
    exit 1
  fi 

}
logger() {
  command logger -s -t "$SYSLOG_TAG" "$@"
}
_container_exists() {
  if docker inspect -f {{.State.Running}} "$container_name" > /dev/null; then
    return 0
  else
    return 1
  fi
}
_container_running() {
  if [[ $(docker inspect -f {{.State.Running}} $container_name > /dev/null) == "true" ]]; then
    echo "Container $container_name is running"
    return 0
  else
    logger "Container $container_name is not running"
    return 1
  fi
}
_start() {
  echo "Starting container $container_name."
  if ! exec $docker_bin start -a "$container_name";then
    logger "Container start failed"
  fi
}
_stop() {
  echo "Stopping container $container_name."
  if ! $docker_bin stop "$container_name"; then
    logger "Container did not stop successfully."
    _kill
  fi
}
_kill() {
  if $docker_bin kill "$container_name"; then
    logger "Sending kill to container $container_name was successfull"
  else
    logger "Sending kill to container $container_name was not killed"
  fi
}
_reload() {
  echo "Reload container $container_name."
  #docker exec $container_name $arg
  exit 0
}
_restart() {
  echo "Restart container $container_name."
  _stop
  _start
}
_remove() {
  echo "Remove container $container_name."
  $docker_bin rm "$container_name"
}

run_mode() {
  case $1 in 
    start)
      _setup
      _start
      ;;
    stop)
      _stop
      ;;
    reload)
      _reload
      ;;
    restart)
      _restart
      ;;
    remove)
      _remove
      ;;
    *)
      usage
      ;;
  esac
}

main "$@"