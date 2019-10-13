#!/usr/bin/env bash
branch=""
remote=""
remote_branch=""
has_commit=""
declare -i commit_ahead=0
declare -i commit_behind=0
declare -i synced=0
if ! git rev-parse --show-toplevel >& /dev/null; then
  echo "Not a git directory." >&2
  exit 128
fi

branch=$(\git rev-parse --abbrev-ref HEAD)
if [[ -z "$branch" ]]; then
  echo "No branch found" >&2
  exit 1
fi
remote="$(\git config --get branch.${branch}.remote 2>/dev/null)"
if [[ -z "$remote" ]]; then
  echo "No tracked remote found for branch $branch" >&2
  exit 1
fi
remote_branch="$(\git config --get branch.${branch}.merge)"
if [[ -z "$remote_branch" ]]; then
  echo "No remote branch to merge found for branch $branch" >&2
  exit 1
fi
remote_branch=${remote_branch/refs\/heads/refs\/remotes\/$remote}
commit_ahead="$(\git rev-list --count $remote_branch..HEAD 2>/dev/null)"
commit_behind="$(\git rev-list --count HEAD..$remote_branch 2>/dev/null)"
if ((commit_ahead==0)) && ((commit_behind==0)); then
  synced=1
else
  synced=0
fi
printf "{\"branch\": \"$branch\", \"tracking\": \"$remote\", \"ahead\": $commit_ahead, \"behind\": $commit_behind, \"is_synced\": $synced}\n"
