#!/usr/bin/env python3
"""
output some git relevant states as json
"""
import logging
import json
import subprocess
import sys

logger = logging.getLogger(__name__)


def run_cmd(command, delimiter=" "):
    args = command.split(delimiter)
    p = subprocess.Popen(args, stdout=subprocess.PIPE, stdin=subprocess.PIPE)
    p.wait()
    return p


def main():
    is_git_repo = run_cmd("git rev-parse --show-toplevel").returncode
    if bool(is_git_repo):
        print("Not a git repository.", file=sys.stderr)
        print("{}")
        sys.exit(is_git_repo)

    result = {}

    branch = run_cmd("git rev-parse --abbrev-ref HEAD")\
        .stdout.read().decode("utf-8").strip()
    remote = run_cmd("git config --get branch.{}.remote".format(
        branch)).stdout.read().decode("utf-8").strip()
    remote_branch = run_cmd("git config --get branch.{}.merge".format(
        branch)).stdout.read().decode("utf-8").strip()

    remote_branch.replace("refs/heads", "refs/remotes/{}".format(
        remote))
    commit_ahead = run_cmd("git rev-list --count {}..HEAD".format(
        remote_branch)).stdout.read().decode("utf-8").strip()
    commit_ahead = int(bool(commit_ahead))
    commit_behind = run_cmd("git rev-list --count HEAD..{}".format(
        remote_branch)).stdout.read().decode("utf-8").strip()
    commit_behind = int(bool(commit_behind))

    git_has_unstaged_items = int(bool(
        run_cmd("git diff --exit-code --quiet").returncode))

    git_has_untracked_items = run_cmd(
        "git ls-files \
--other \
--exclude-standard \
--directory \
--no-empty-directory").stdout.read().decode("utf-8").strip()
    git_has_untracked_items = int(bool(git_has_untracked_items))

    if not commit_ahead and not commit_behind:
        synced = True
    else:
        synced = False

    result.update({"branch": branch})
    result.update({"tracking": remote})
    result.update({"ahead": commit_ahead})
    result.update({"commit_behind": commit_behind})
    result.update({"synced": synced})
    result.update({"has_unstaged_items": git_has_unstaged_items})
    result.update({"has_untracked_items": git_has_untracked_items})

    print(json.dumps(result))


if __name__ == "__main__":
    main()
