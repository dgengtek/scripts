#!/bin/env bash

get_active_branch() { git branch | awk '/^\*/ {print $2}'; }

get_branches() { git branch | sed 's/^[* ]*//'; }

check_branch_existing() {
  local branches=$(get_branches)
  echo "$branches" | grep -x "$branch" > /dev/null 2>&1
}

check_merge_allowed() {
  local rc=0
  [[ $branch_active =~ (no branch|master) ]] && rc=1
  for branch in "$@"; do
    if [[ "$branch" == "$branch_active" ]]; then
      rc=1
      break
    fi
  done
  return $rc
}

check_branches_conflict() {
  # check if branches supplied are all existing and in conflict(user perspective)
  local -i count=0
  for branch in "$@"; do
    if check_branch_existing "$branch"; then
      let count+=1
    fi
  done
  (($count == 1))
}

get_root_directory() { git rev-parse --show-toplevel; }


get_valid_branch() {
  local lookup_branches=
  for branch in "$@"; do
    lookup_branches="$lookup_branches|$branch"
  done
  get_branches | egrep -x "$lookup_branches"
}
