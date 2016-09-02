#!/bin/env python3
"""
Requires stow_dir_setup.sh to run
used to parse configuration for deployment of directory structure

"""
import configparser
import os
import sys
from functools import reduce

def main():
  # keys for stow setup in sections
  keys = [
      "path", 
      "pkgs",
      "exclude"
      ]

  parser = configparser.ConfigParser()
  main.config=""
  try:
    if sys.argv[1] in ["-h","help","--help"]:
        usage()
    main.config = sys.argv[1]
  except IndexError:
    main.config="setup.ini"
  if not os.path.isfile(main.config):
      print("No configuration file found")
      usage()
  if not parser.read(main.config):
    printexit("Configuration: {} not found.".format(config))
  main.config=os.path.abspath(main.config)

  sections = parser.sections()

  cmd = get_cmd_path("stow_dir_setup.sh")

  for section in sections:
    values = get_values(parser[section],keys)
    parse_path(values)
    run(cmd, values)

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
  print(string,file=sys.stderr)

def printexit(string):
  printerr(string)
  sys.exit(1)

def get_values(section, keys):
  d=dict()
  for key in keys:
    value = section.get(key)
    #if not value:
    #  printexit("Empty value for key:{} in section:{}".format(key,section))
    d.update({key:value})
  return d

def parse_path(values):
  path=values.get("path")
  parse_functions = {
      "~":parse_home
      
      }
  for key in parse_functions:
    if key in path:
      f = parse_functions.get(key)
      path = f(path)
  values.update({"path":path})

def parse_home(value):
  pos = value.find("~")
  suffix = value[pos+1:]
  return os.getenv("HOME") + suffix


def run(cmd, values):
  path = values.get("path")

  # get root path of configuration
  source = main.config.rfind("/")
  source = main.config[:source+1]

  args = list()
  args.append("setup_env.py")
  args.append("-d " + source)
  args.append("-t " + path)
  pkgs = values.get("pkgs")
  pkgs = pkgs.split(",")

  try:
    # get all packages from root directory, if globbed
    if pkgs[0] == "*":
      pkgs = os.listdir(source)
      excluded_packages = values.get("exclude")
      if excluded_packages:
        excluded_packages = excluded_packages.split(",")
        excluded_packages.append(".git")
        for p in excluded_packages:
          try:
            pkgs.remove(p)
          except ValueError:
            printerr("Package:" + p +" not found in pkgs")
  except IndexError:
    pass


  for p in pkgs:
    if not os.path.isdir(p):
      continue
    args.append("-p "+p)
  
  pid = os.fork()
  if pid == 0:
    os.execv(cmd,args)


def usage():
  hilfe="usage:  "+sys.argv[0]+" ini"
  print(hilfe)
  sys.exit(1)

if __name__ == "__main__":
  main()
