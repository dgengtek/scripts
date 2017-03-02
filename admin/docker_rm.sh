#!/bin/env bash
# ------------------------------------------------------------------------------
# remove dangling docker images
# ------------------------------------------------------------------------------
main() {
  run
} 

__docker_running() {
  local error=
  if ! error=$(docker info 2>&1 >/dev/null); then
    printf "%s\n" "$error" >&2
    return 1
  fi
}

run() {
  if ! __docker_running; then
    return 1
  fi

  docker rmi $(docker images -f dangling=true --format="{{.ID}}")
}
main "$@"
