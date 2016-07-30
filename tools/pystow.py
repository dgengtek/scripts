#!/bin/env python3
"""
Requires stow_dir_setup.sh to run
used to parse configuration for deployment of directory structure

"""
from configparser import ConfigParser
import os
import sys

# TODO improve logging
import logging

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
_configuration_filenames = [
        "pystow.cfg",
        ]
_logger = logging.getLogger(sys.argv[0])
_logger.setLevel(logging.INFO)
_ch = logging.StreamHandler()
_formatter = logging.Formatter('%(asctime)s - %(name)s - %(levelname)s - %(message)s')
_ch.setFormatter(_formatter)
_logger.addHandler(_ch)
# default config filename
_config_filename = "setup.ini"

def main():
    # keys for stow setup in sections
    parser = ConfigParser()

    global _config_file
    main.config=""

    input_args = parse_argv(sys.argv[1:])
    main.config = input_args.get("file",_config_filename)
    if not main.config:
        main.config = _config_filename
    if not os.path.isfile(main.config):
        print("No configuration file found")
        usage()
    if not parser.read(main.config):
        printexit("Configuration: {} not found.".format(config))
    main.config = os.path.abspath(main.config)

    sections = parser.sections()
    cmd = get_cmd_path("stow_dir_setup.sh")

    for section in sections:
        values = get_values(parser[section],_keys)
        path = build_path(values.get("path"))
        values.update({"path":path})
        args = build_args(values, **input_args)
        run(cmd, args)

def usage():
    hilfe="usage:  "+sys.argv[0]+" ini"
    cmd = get_cmd_path("stow_dir_setup.sh")
    os.execv(cmd,["-h"])
    print(hilfe)
    sys.exit(1)

def parse_argv(argv):
    argparser = get_argparser()
    namespace = argparser.parse_args(argv)

    # get dictionary of values
    return vars(namespace)

def get_argparser():
    summary="""
    Pystow

    """
    argparser = ArgumentParser(description=summary)

    argparser.add_argument("-v","--verbose",action="store_true",
            help="")
    argparser.add_argument("-d","--destination",
            help="")
    argparser.add_argument("-f","--file",
            help="Configuration file")
    argparser.add_argument("-s","--simulate",action="store_true", 
            help="Simulate")
    argparser.add_argument("-t","--target", 
            help="Target")
    return argparser

def get_cmd_path(cmd):
    # if on local path return 
    if cmd_exists(cmd):
        return cmd
    # try in tools
    elif cmd_exists("tools/"+cmd):
        return "tools/"+cmd

    path = os.environ["PATH"].split(os.pathsep)
    for p in path:
        ex = p + "/" + cmd
        if cmd_exists(ex):
          return ex
    printexit("stow wrapper not found in env PATH")

def cmd_exists(cmd):
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
        #if not value:
        #  printexit("Empty value for key:{} in section:{}".format(key,section))
        d.update({key:value})
    return d

def build_path(path, check_valid=True):
    parse_functions = [
            parse_home,
            parse_real,
        ]
    if check_valid:
        parse_functions.append(path_check)

    for function in parse_functions:
        result = function(path)
        if result:
            path = result
    return path

def path_check(path):
    _logger.info("Check path: {}".format(path))
    if not path_valid(path):
        raise NotADirectoryError("Path: {} is invalid".format(path))

def path_valid(path):
    return os.path.isdir(path) and os.access(path, os.X_OK)

def parse_home(path):
    if "~" not in path:
        return 
    pos = path.find("~")
    suffix = path[pos+1:]
    return os.getenv("HOME") + suffix

def parse_real(path):
    if path.startswith("/"):
        return
    return os.path.realpath(path)

def filter_packages(pkgs=[], exclude=[]):
    if len(pkgs) is 0:
        raise RuntimeError("No packages supplied")
    for p in pkgs:
        if p not in exclude:
            yield p


def build_args(values, filter_pkgs=filter_packages, **kwargs):
    path = values.get("path")

    source = os.getcwd()
    args = list()
    # $0
    args.append(sys.argv[0])
    # $1 ...
    args.append("-d " + source)
    args.append("-t " + path)
    for key, value in kwargs.items():
        if key == "simulate":
            args.append("-s")
    pkgs = values.get("pkgs", "")
    if not pkgs or pkgs.startswith("*"):
      pkgs = os.listdir(source)
    else:
      pkgs = pkgs.split(",")

    excluded_packages = values.get("exclude", "")
    if excluded_packages:
        excluded_packages = excluded_packages.split(",")
    else:
        excluded_packages = list()
    excluded_packages.append(".git")
    pkgs = filter_pkgs(pkgs, excluded_packages)

    for p in pkgs:
        if not os.path.isdir(p):
          continue
        args.append("-p "+p)
    return args

def run(cmd, args):
    pid = os.fork()
    if pid == 0:
        os.execv(cmd,args)


if __name__ == "__main__":
    main()
