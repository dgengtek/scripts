#!/usr/bin/env bash
# force objects in repo to be dereferenced and garbage collected
set -e
git for-each-ref --format='delete %(refname)' refs/original \
  | git update-ref --stdin \
git reflog expire --expire=now --all
git gc --prune=now
set +e
