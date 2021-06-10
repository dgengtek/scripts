#!/usr/bin/env bash
# https://stackoverflow.com/a/23787928

readonly commit=${1:?Missing commit input}
set -ex
prompt_me.sh "Truncate the git history permanently before ${commit}?"

git checkout --orphan temp $commit # create a new branch without parent history
git commit -m "Truncated history" # create a first commit on this branch
git rebase --onto temp $commit master # now rebase the part of master branch that we want to keep onto this branch
git branch -D temp # delete the temp branch

# The following 2 commands are optional - they keep your git repo in good shape.
git prune --progress # delete all the objects w/o references
git gc --aggressive # aggressively collect garbage; may take a lot of time on large repos

prompt_me.sh "Remove all reflogs?"
git reflog expire --expire=now --expire-unreachable=now --all
