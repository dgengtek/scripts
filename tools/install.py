#!/bin/env python3
"""
used to parse configuration for deployment of directory structure

"""
from configparser import ConfigParser
import os
import sys

# TODO improve logging
import logging
from pathlib import Path

# TODO use glob(from pathlib with Path("path/to/dir").glob("ew*"), and pathlib
# for linux and nt

import pathlib

from argparse import ArgumentParser
from functools import reduce
_keys = [
  "path", 
  "pkgs",
  "exclude"
  ]
_logger = logging.getLogger(sys.argv[0])
_logger.setLevel(logging.INFO)
_ch = logging.StreamHandler()
_formatter = logging.Formatter('%(asctime)s - %(name)s - %(levelname)s - %(message)s')
_ch.setFormatter(_formatter)
_logger.addHandler(_ch)
_cmd = "stow"
# default config filename
_config_filename = { "setup.ini", }

def main():
    global _cmd
    _cmd = str(get_cmd_path(_cmd))

    # keys for stow setup in sections
    parser = ConfigParser()

    global _config_file
    main.config=""

    input_args = parse_argv(sys.argv[1:])
    main.config = input_args.get("config",_config_filename)
    main.config = Path(main.config)
    if not main.config.is_file():
        print("No configuration file found")
        usage()

    if not parser.read(str(main.config)):
        printexit("Configuration: {} not found.".format(config))

    sections = parser.sections()
    for section in sections:
        values = get_values(parser[section],_keys)
        path = Path(values.get("path"))
        values.update({"path":path})
        args = build_args(values, **input_args)
        run(_cmd, args)
    os.wait()

def usage():
    global _cmd
    cmd = get_cmd_path(_cmd)
    os.execv(cmd,["-h"])
    sys.exit(1)

def parse_argv(argv):
    argparser = get_argparser()
    namespace = argparser.parse_args(argv)

    # get dictionary of values
    return vars(namespace)

def get_argparser():
    summary="""
    stow installer wrap

    """
    argparser = ArgumentParser(description=summary)

    argparser.add_argument("config", help="Ini configuration file")
    return argparser

def get_cmd_path(cmd):
    # if on local path return 
    cmd = Path(cmd)
    if cmd_exists(cmd):
        return cmd
    # try in tools
    elif cmd_exists(Path("tools", cmd)):
        return Path("tools/",cmd)

    path = os.environ["PATH"].split(os.pathsep)
    for p in path:
        ex = Path(p ,cmd)
        if ex.is_file():
          return ex
    printexit("{} not found in PATH".format(cmd))

def cmd_exists(cmd):
    cmd = str(cmd)
    return os.path.isfile(cmd) and os.access(cmd, os.X_OK)

def printerr(string):
    _logger.warning(string)

def printexit(string):
    _logger.error(string)
    sys.exit(1)

def get_values(section, keys):
    d=dict()
    for key in keys:
        value = section.get(key)
        d.update({key:value})
    return d


def filter_packages(pkgs=[], exclude=[]):
    if len(pkgs) is 0:
        raise RuntimeError("No packages supplied")
    for p in pkgs:
        if p not in exclude:
            yield p

def _get_absolute_path(path):
    path = path.expanduser()
    path = path.absolute()
    while not path.is_dir():
        path = path.parent
    return str(path)

def build_args(values, filter_pkgs=filter_packages, **kwargs):
    global _cmd

    path = values.get("path")
    path = _get_absolute_path(path)

    # change directory to root location of config file
    source = main.config
    source = _get_absolute_path(source)
    os.chdir(source)

    args = list()
    args.append(_cmd)
    #args.extend(["-d", source])
    args.extend(["-t", path])

    # get all packages
    pkgs = values.get("pkgs", "")
    if not pkgs or pkgs.startswith("*"):
      pkgs = os.listdir(source)
    else:
      pkgs = pkgs.split(",")

    # filter excluded
    excluded_packages = values.get("exclude", [])
    if excluded_packages:
        excluded_packages = excluded_packages.split(",")
    else:
        excluded_packages = list()

    # always filter git
    excluded_packages.append(".git")

    pkgs = filter_pkgs(pkgs, excluded_packages)

    for p in pkgs:
        # only stow directories
        if not os.path.isdir(p):
          continue
        args.extend(["-p", p])
    return args

def run(cmd, args):
    if isinstance(cmd, Path):
        cmd = str(cmd)
    pid = os.fork()
    if pid == 0:
        os.execv(cmd ,args)


if __name__ == "__main__":
    main()
