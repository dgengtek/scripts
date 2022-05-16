#!/usr/bin/env python3
"""
output some git relevant states as json for each branch
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

    branches = run_cmd("git for-each-ref --format %(refname)").stdout.readlines()

    for branch in branches:
        branch = branch.decode("utf-8").strip()
        # ignore remote refs branches
        if not branch.startswith("refs/heads/"):
            continue
        branch = branch.replace("refs/heads/", "")
        result.update({branch: get_branch_state(branch)})

    print(json.dumps(result))


def get_branch_state(branch):
    result = {}
    branch = (
        run_cmd("git rev-parse --abbrev-ref {}".format(branch))
        .stdout.read()
        .decode("utf-8")
        .strip()
    )
    remote = (
        run_cmd("git config --get branch.{}.remote".format(branch))
        .stdout.read()
        .decode("utf-8")
        .strip()
    )
    remote_branch = (
        run_cmd("git config --get branch.{}.merge".format(branch))
        .stdout.read()
        .decode("utf-8")
        .strip()
    )

    remote_branch = remote_branch.replace(
        "refs/heads", "refs/remotes/{}".format(remote)
    )
    commit_ahead = (
        run_cmd("git rev-list --count {}..{}".format(remote_branch, branch))
        .stdout.read()
        .decode("utf-8")
        .strip()
    )
    commit_ahead_of_head = (
        run_cmd("git rev-list --count HEAD..{}".format(branch))
        .stdout.read()
        .decode("utf-8")
        .strip()
    )
    commit_ahead = int(commit_ahead)
    commit_ahead_of_head = int(commit_ahead_of_head)

    commit_behind = (
        run_cmd("git rev-list --count {}..{}".format(branch, remote_branch))
        .stdout.read()
        .decode("utf-8")
        .strip()
    )
    commit_behind_of_head = (
        run_cmd("git rev-list --count {}..HEAD".format(branch))
        .stdout.read()
        .decode("utf-8")
        .strip()
    )
    commit_behind = int(commit_behind)
    commit_behind_of_head = int(commit_behind_of_head)

    git_has_unstaged_items = int(
        bool(run_cmd("git diff --exit-code --quiet").returncode)
    )

    git_has_untracked_items = (
        run_cmd(
            "git ls-files \
--other \
--exclude-standard \
--directory \
--no-empty-directory"
        )
        .stdout.read()
        .decode("utf-8")
        .strip()
    )
    git_has_untracked_items = int(bool(git_has_untracked_items))

    if not commit_ahead and not commit_behind:
        synced = True
    else:
        synced = False

    result.update({"tracking": remote})
    result.update({"ahead": commit_ahead})
    result.update({"behind": commit_behind})
    result.update({"ahead_of_head": commit_ahead_of_head})
    result.update({"behind_of_head": commit_behind_of_head})
    result.update({"synced": synced})
    result.update({"has_unstaged_items": git_has_unstaged_items})
    result.update({"has_untracked_items": git_has_untracked_items})

    return result


if __name__ == "__main__":
    main()
