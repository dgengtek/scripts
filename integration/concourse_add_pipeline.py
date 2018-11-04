#!/usr/bin/env python3
import configparser
import os
import sys
import subprocess

METADATA = "metadata-concourse.ini"
CONCOURSE_PIPELINE = "concourse.yml"

# argv 1 path to metadata + concourse

def main():
    global METADATA
    global CONCOURSE_PIPELINE

    config = configparser.ConfigParser()
    if len(sys.argv) > 1:
        relative_path = os.path.dirname(sys.argv[1])
    if relative_path:
        os.chdir(relative_path)
    with open(METADATA) as f:
        config.read_file(f)
    post_receive = config["post-receive"]
    pipeline_name = post_receive["pipeline_name"]
    target = post_receive["target"]

    concourse_fly = ["fly", "-t"]
    concourse_fly.append(target)

    run(*concourse_fly,
        "set-pipeline",
        "-p",
        pipeline_name,
        "-c",
        CONCOURSE_PIPELINE)
    run(*concourse_fly,
        "unpause-pipeline",
        "-p",
        pipeline_name)


def run(*args):
    return subprocess.run(args)


if __name__ == "__main__":
    main()
