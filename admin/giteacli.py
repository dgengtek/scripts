#!/usr/bin/env python3
import click
import requests
import json
import sys
import os
# http://click.pocoo.org/5/options/

# https://try.gitea.io/api/swagger#/
# or GITEA_URL/api/swagger
GITEA_URL = "https://git"


@click.group("template")
@click.option(
    "--url",
    default="",
    help="gitea url")
@click.option(
    "--user",
    help="basic auth username")
@click.option(
    '--password',
    help="basic auth password")
@click.option(
    "-l",
    "--loglevel",
    type=click.Choice(["info", "debug", "warning"]))
@click.option(
    "-t",
    "--token",
    help="api access token")
@click.pass_context
def main(ctx, url, user, password, loglevel, token):
    d = dict()
    if not token:
        token = os.environ.get("GITEA_TOKEN", "")
    if not url:
        url = os.environ.get("GITEA_URL", GITEA_URL)
    if not token:
        print(
            "GITEA_TOKEN, token or password required.",
            file=sys.stderr)
        sys.exit(1)
    if not url:
        print(
            "GITEA_URL required.",
            file=sys.stderr)
        sys.exit(1)

    d["api"] = "{}/api/v1".format(url)
    d["user"] = user
    d["password"] = password
    d["token"] = token
    ctx.obj = d


@click.group("repos")
@click.pass_context
def repos(ctx, args=None):
    pass


@click.group("user")
@click.pass_context
def user(ctx, args=None):
    pass


@click.group("users")
@click.pass_context
def users(ctx, args=None):
    pass


@click.group("add")
@click.pass_context
def repos_add(ctx, args=None):
    pass


@click.group("hook")
@click.pass_context
def repos_hook(ctx, args=None):
    pass


@repos_add.command("collaborator")
@click.argument("owner", required=True)
@click.argument("repo", required=True)
@click.argument("collaborator", required=True)
@click.argument("permission", required=True)
@click.pass_obj
def repos_add_collaborator(d, owner, repo, collaborator, permission):
    url = "{}/repos/{}/{}/collaborators/{}".format(
        d["api"],
        owner,
        repo,
        collaborator)
    if d["token"]:
        url = "{}?access_token={}".format(
            url, d["token"])
        response = requests.put(
            url,
            data={"permission": permission})
    else:
        response = requests.put(
            url,
            data={"permission": permission},
            auth=(d["user"], d["password"]))

    if response.status_code == 204:
        print((
            "Added collaborator {}"
            " to repo '{}'"
            " of owner '{}'"
            " with permission '{}'").format(
                collaborator,
                repo,
                owner,
                permission))
    else:
        print(response.text)
        sys.exit(1)


@repos.command("list")
@click.argument("org", required=True)
@click.pass_obj
def repos_list(d, org):
    url = "{}/orgs/{}/repos".format(
        d["api"],
        org)
    if d["token"]:
        url = "{}?access_token={}".format(
            url, d["token"])
        response = requests.get(url)
    else:
        response = requests.get(url, auth=(d["user"], d["password"]))

    if response.status_code == 200:
        print(json.dumps(response.json()))
    else:
        print(response.text)
        sys.exit(1)


@repos.command("edit")
@click.argument("owner", required=True)
@click.argument("repo", required=True)
@click.argument("properties", required=True)
@click.pass_obj
def repos_edit(d, owner, repo, properties):
    url = "{}/repos/{}/{}".format(
        d["api"],
        owner,
        repo)
    properties = json.loads(properties)
    headers = {
            "accept": "application/json",
            "Content-Type": "application/json",
            }

    if d["token"]:
        url = "{}?access_token={}".format(
            url, d["token"].strip())
        response = requests.patch(
            url,
            headers=headers,
            json=properties)
    else:
        response = requests.patch(
            url,
            headers=headers,
            json=properties,
            auth=(d["user"], d["password"]),
            )

    if response.status_code == 200:
        print((
            "Edited repo {}"
            " of owner '{}'"
            " with properties '{}'").format(
                repo,
                owner,
                properties))
    elif response.status_code == 403:
        print("APIForbiddenError: {}".format(
            response.text))
    elif response.status_code == 422:
        print("APIValidationError: {}".format(
            response.text))
    else:
        print(response.status_code)
        print(response.text)
        sys.exit(1)


@user.command("repos")
@click.option("--json", "output_json", is_flag=True, help="json output")
@click.option(
    "-k",
    "--key",
    default="full_name",
    type=click.Choice(["full_name", "html_url", "ssh_url", "name"]))
@click.pass_obj
def user_repos(d, output_json, key):
    """
    List all repositories an authenticated user has access to
    """

    results = []
    page = 1
    while True:
        url = "{}/user/repos?page={}".format(
            d["api"],
            page)
        url = "{}&access_token={}".format(
            url, d["token"])
        headers = {
                "accept": "application/json",
                }
        response = requests.get(url, headers=headers)

        if response.status_code != 200:
            print(response.status_code)
            sys.exit(1)
        result = response.json()
        if len(result) == 0:
            break
        results.extend(result)
        page += 1

    if output_json:
        print(json.dumps(result))
        sys.exit(0)
    for repo in results:
        print(repo.get(key))


@users.command("repos")
@click.argument("user", required=True)
@click.option("--json", "output_json", is_flag=True, help="json output")
@click.option(
    "-k",
    "--key",
    default="full_name",
    type=click.Choice(["full_name", "html_url", "ssh_url", "name"]))
@click.pass_obj
def users_repos(d, user, output_json, key):
    """
    List the repos owned by the given user
    """
    url = "users/{}/repos".format(user)
    headers = {
            "accept": "application/json",
            }
    response = get_response(d, url, headers)

    if response.status_code != 200:
        print(response.text)
        sys.exit(1)

    result = response.json()
    if output_json:
        print(json.dumps(result))
        sys.exit(0)

    for repo in result:
        print(repo.get(key))


@repos_hook.command("list")
@click.argument("owner", required=True)
@click.argument("repo", required=True)
@click.option("--json", "output_json", is_flag=True, help="json output")
@click.pass_obj
def repos_hook_list(d, owner, repo, output_json):
    """
    list the hooks in a repository
    """
    result = get_repo_hooks(d, owner, repo)
    if output_json:
        print(json.dumps(result))
        sys.exit(0)
    return result


@repos_hook.command("create")
@click.argument("owner", required=True)
@click.argument("repo", required=True)
@click.argument("target_url", required=True)
@click.option("--deactivate", is_flag=True, help="disable hook")
@click.option("--create-nonunique", is_flag=True, help="create the hook even if it already exists as the set of url, events and type")
@click.option("--fail-nonunique", is_flag=True, help="exit with error if the hook already exists in its set")
@click.option(
    "-t",
    "--hook-type",
    default="gitea",
    type=click.Choice(["gitea", "matrix"]))
@click.option(
    '--branch-filter',
    default="*",
    help="Branch whitelist for push, branch creation and branch deletion events, specified as glob pattern. If empty or *, events for all branches are reported")
@click.option(
    '--events',
    multiple=True,
    required=True,
    help="trigger on event",
    type=click.Choice([
      "create",
      "delete",
      "fork",
      "push",
      "issues",
      "issue_assign",
      "issue_label",
      "issue_milestone",
      "issue_comment",
      "pull_request",
      "pull_request_assign",
      "pull_request_label",
      "pull_request_milestone",
      "pull_request_comment",
      "pull_request_review_approved",
      "pull_request_review_rejected",
      "pull_request_review_comment",
      "pull_request_sync",
      "repository",
      "release"
    ]))
@click.pass_obj
def repos_hook_create(d, owner, repo, target_url, deactivate, create_nonunique, fail_nonunique, hook_type, branch_filter, events):
    """
    create a hook only if the hook is unique
    """
    url = "{}/repos/{}/{}/hooks".format(
        d["api"],
        owner,
        repo)
    deactivate = not deactivate
    events = list(events)
    data = {
            "active": deactivate,
            "branch_filter": branch_filter,
            "events": events,
            "type": hook_type,
            "config": {
                "content_type": "json",
                "http_method": "post",
                "url": target_url,
            },
    }
    headers = {
            "accept": "application/json",
            "Content-Type": "application/json",
            }

    new_hook_set = get_hook_set(data)
    for hook in get_repo_hooks(d, owner, repo):
        hook_set = get_hook_set(hook)
        if hook_set == new_hook_set:
            print("Hook {} already exists".format(new_hook_set), file=sys.stderr)
            if fail_nonunique:
                sys.exit(1)
            if create_nonunique:
                break
            else:
                sys.exit(0)

    if d["token"]:
        url = "{}?access_token={}".format(
            url, d["token"])
        response = requests.post(
            url,
            headers=headers,
            data=json.dumps(data))
    else:
        response = requests.post(
            url,
            headers=headers,
            data=json.dumps(data),
            auth=(d["user"], d["password"]))

    if response.status_code == 201:
        print((
            "Added hook {}"
            " to repo '{}'"
            " of owner '{}'"
            " with events '{}'").format(
                target_url,
                repo,
                owner,
                ", ".join(events)))
    else:
        print("{} {}".format(response.status_code, response.text),
                file=sys.stderr)
        sys.exit(1)


user.add_command(user_repos)
users.add_command(users_repos)
repos.add_command(repos_add)
repos.add_command(repos_hook)

main.add_command(repos)
main.add_command(user)
main.add_command(users)


def get_response(d, url, headers):
    url = "{}/{}".format(
        d["api"], url)
    if d["token"]:
        url = "{}?access_token={}".format(
            url, d["token"])
        response = requests.get(
                url,
                headers=headers)
    else:
        response = requests.get(
                url,
                headers=headers,
                auth=(d["user"], d["password"]))
    return response


def get_hook_set(hook_data):
    return (hook_data["type"], hook_data["config"]["url"], set(hook_data["events"]))


def get_repo_hooks(d, owner, repo):
    url = "repos/{}/{}/hooks".format(
        owner,
        repo)
    headers = {
            "accept": "application/json",
    }
    response = get_response(d, url, headers)

    if response.status_code != 200:
        print(response.text)
        sys.exit(1)

    return response.json()


if __name__ == "__main__":
    main()  # pylint: disable=no-value-for-parameter
