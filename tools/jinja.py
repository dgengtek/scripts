#!/usr/bin/env python3
"""
render a file from a jinja template
"""
import argparse
import sys
import yaml
import json
import jinja2
import logging

logger = logging.getLogger(__name__)


def main():
    args = parse_args()

    if args.json:
        data = json.load(args.data)
    elif args.yaml:
        data = yaml.safe_load(args.data)
    else:
        data = json.load(args.data)
    logger.debug("parsed data: {}".format(data))

    env = jinja2.Environment(
        loader=jinja2.FileSystemLoader(searchpath="."),
        trim_blocks=True,
        lstrip_blocks=True)

    template = open(args.template).read()
    template = env.from_string(template)
    print(template.render(data))


def parse_args():
    parser = argparse.ArgumentParser(
        description="render jinja",
        epilog="",
        add_help=True
        )
    # positional arguments
    parser.add_argument("template", help="jinja2 file to render")

    # optional input
    parser.add_argument(
        'data',
        nargs='?',
        type=argparse.FileType('r'),
        default=sys.stdin)

    # mutual exclusive, either foo or bar
    exclusive_group = parser.add_mutually_exclusive_group()
    exclusive_group.add_argument(
        '--json',
        help="(default) get data from json",
        action='store_false')
    exclusive_group.add_argument(
        '--yaml',
        help="get data from yaml",
        action='store_false')

    return parser.parse_args()


if __name__ == "__main__":
    main()
