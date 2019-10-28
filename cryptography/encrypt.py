#!/usr/bin/env python3
"""
Encrypt password with salt for unix
Usage:
    encrypt.py [options] [--rounds <count>] [--sha512 | --sha256 | --md5 | --crypt] [<salt>]

Options:
    --sha512
    --sha256
    --md5
    --crypt
    -r, --rounds <count>  rounds[default: 100000]
"""

import sys
import crypt
from getpass import getpass
from docopt import docopt

# docopt(doc, argv=None, help=True, version=None, options_first=False))


default_flag = "--sha512"

methods = {
        "--sha512" : {
            "method": crypt.METHOD_SHA512,
            "id": "6",
            },
        "--sha256" : {
            "method": crypt.METHOD_SHA256,
            "id": "5",
            },
        "--md5" : {
            "method": crypt.METHOD_MD5,
            "id": "1",
            },
        "--crypt" : {
            "method": crypt.METHOD_CRYPT,
            "id": "",
            },
        }

def get_method(opt, default=default_flag):
    for key in methods.keys():
        if opt.get(key, False):
            return methods.get(key)
    return methods.get(default_flag)


def main():
    opt = docopt(__doc__, sys.argv[1:])

    rounds = opt.get("--rounds")
    methods = get_method(opt)
    method = methods.get("method")
    id_prefix = methods.get("id")
    

    salt = opt.get("<salt>")
    if not salt:
        salt = crypt.mksalt(method)
    else:
        salt = "${}$rounds={}${}$".format(id_prefix, rounds, salt)

    password = ""
    if not sys.stdin.isatty():
        password = sys.stdin.readline()
    else:
        password = getpass()
    if not password:
        sys.exit(1)

    shadow = crypt.crypt(password, salt)
    print(shadow)

def usage():
    pass

if __name__ == "__main__":
    main()
