#!/usr/bin/env python3
"""
used to parse configuration for deployment of directory structure

"""

from configparser import ConfigParser
import os
import sys
import subprocess

import logging
from pathlib import Path

from argparse import ArgumentParser

_keys = {
    "path",
    "pkgs",
    "exclude",
    "directory",
}

_cmd = "stow"
# default config filename
_config_filename = {
    "setup.ini",
}

journalhandler = None
try:
    from systemd.journal import JournaldLogHandler

    journalhandler = JournaldLogHandler()
except ImportError:
    pass


class Logger:
    stream_handler = logging.StreamHandler()
    stream_handler.setLevel(logging.DEBUG)
    format_string = "%(asctime)s %(module)s %(name)s: [%(levelname)s] %(message)s"
    formatter = logging.Formatter(format_string)
    stream_handler.setFormatter(formatter)

    def __init__(self):
        pass

    @classmethod
    def get_logger(self, level=logging.WARNING):
        logger = logging.getLogger(__name__)
        logger.setLevel(level)
        logger.addHandler(self.stream_handler)
        if journalhandler:
            logger.addHandler(journalhandler)
        return logger


logger = Logger.get_logger()


def main():
    global _cmd
    _cmd = str(get_cmd_path(_cmd))

    parser = ConfigParser()

    global _config_filename
    main.config = ""

    input_args = parse_argv(sys.argv[1:])
    main.config = input_args.get("config", _config_filename)
    main.config = Path(main.config)
    if not main.config.is_file():
        logger.info("No configuration file found")

    if not parser.read(str(main.config)):
        printexit("Configuration: {} not found.".format(main.config))

    logger.debug("Parsing configuration file {}".format(main.config))
    sections = parser.sections()
    for section in sections:
        values = get_values(parser[section], _keys)
        path = Path(values.get("path"))
        values.update({"path": path})
        args = build_args(values, **input_args)
        print(args)
        # run(_cmd, args)
    logger.debug("Done")


def parse_argv(argv):
    argparser = get_argparser()
    namespace = argparser.parse_args(argv)

    if namespace.debug:
        logger.setLevel(logging.DEBUG)
    elif namespace.verbose:
        logger.setLevel(logging.INFO)

    # get dictionary of values
    return vars(namespace)


def get_argparser():
    summary = """
    stow installer wrap

    """
    from argparse import REMAINDER

    argparser = ArgumentParser(description=summary)

    argparser.add_argument("config", help="Ini configuration file")
    argparser.add_argument("-d", "--debug", action="store_true", help="verbose output")
    argparser.add_argument("-v", "--verbose", action="store_true", help="Debugging")
    argparser.add_argument(
        "args", nargs=REMAINDER, help="use remainder arguments to pass to stow"
    )
    return argparser


def get_cmd_path(cmd):
    # if on local path return
    cmd = Path(cmd)
    if cmd_exists(cmd):
        return cmd
    # try in tools
    elif cmd_exists(Path("tools", cmd)):
        return Path("tools/", cmd)

    path = os.environ["PATH"].split(os.pathsep)
    for p in path:
        ex = Path(p, cmd)
        if ex.is_file():
            return ex
    printexit("{} not found in PATH".format(cmd))


def cmd_exists(cmd):
    cmd = str(cmd)
    return os.path.isfile(cmd) and os.access(cmd, os.X_OK)


def printexit(string):
    logger.error(string)
    sys.exit(1)


def get_values(section, keys):
    d = dict()
    for key in keys:
        value = section.get(key)
        d.update({key: value})
    return d


def filter_packages(pkgs=None, exclude=None):
    if len(pkgs) == 0:
        raise RuntimeError("No packages supplied")
    return filter(lambda x: x not in exclude, pkgs)


def _get_absolute_path(path):
    path = path.expanduser()
    path = path.absolute()
    if not path.is_dir():
        path = path.parent
    return str(path)


def build_args(values, filter_pkgs=filter_packages, **kwargs):
    directory = values.get("directory", None)
    path = values.get("path")
    path = _get_absolute_path(path)

    # change directory to root location of config file
    source = main.config
    source = _get_absolute_path(source)
    os.chdir(source)

    args = list()
    args.extend(kwargs.get("args", []))
    if directory:
        args.extend(["-d", directory])
    args.extend(["-t", path])

    # get all packages
    pkgs = values.get("pkgs", "")
    if not pkgs or pkgs.startswith("*"):
        pkgs = os.listdir(source)
    else:
        pkgs = [x.strip() for x in pkgs.split(",")]

    # filter excluded
    excluded_packages = values.get("exclude", [])
    if excluded_packages:
        excluded_packages = [x.strip() for x in excluded_packages.split(",")]
    else:
        excluded_packages = list()

    # always filter git
    excluded_packages.append(".git")

    pkgs = filter_pkgs(pkgs, excluded_packages)

    for p in pkgs:
        # only stow directories
        if not os.path.isdir(p):
            continue
        args.append(p)
    return args


def run(cmd, args):
    if isinstance(cmd, Path):
        cmd = str(cmd)
    logger.debug("Running: {} {}".format(cmd, " ".join(args)))
    proc = subprocess.Popen(
        [cmd] + args, stderr=subprocess.PIPE, stdout=subprocess.PIPE
    )
    proc.wait()
    if proc.stdout.peek():
        out = [x.decode("UTF-8") for x in proc.stdout.readlines()]
        logger.info("\n".join(proc.stdout.readlines()))
    if proc.returncode > 0:
        out = [x.decode("UTF-8") for x in proc.stderr.readlines()]
        logger.error("\n".join(out))


if __name__ == "__main__":
    main()
