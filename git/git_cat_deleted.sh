#!/bin/env bash
# view deleted file
git show $(git rev-list --max-count=1 --all -- $1)^:$1
