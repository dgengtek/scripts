#!/bin/env python3
"""
Encrypt password with salt for unix
Usage:
    encrypt.py [options] [--sha512 | --sha256 | --md5 | --crypt] [salt] <password>

Options:
    --sha512
    --sha256
    --md5
    --crypt
"""

import sys
import crypt
from docopt import docopt

# docopt(doc, argv=None, help=True, version=None, options_first=False))


default_flag = {"--sha512":True}

methods = {
        "--sha512" : crypt.METHOD_SHA512,
        "--sha256" : crypt.METHOD_SHA256,
        "--md5" : crypt.METHOD_MD5,
        "--crypt" : crypt.METHOD_CRYPT,
        }

def get_method(opt):
    for key in methods.keys():
        if opt.get(key, False):
            return methods.get(key)


def main():
    opt = docopt(__doc__, sys.argv[1:])

    method = get_method(opt)

    salt = crypt.mksalt(method)
    password = opt.get("<password>")

    shadow = crypt.crypt(password, salt)
    print(shadow)

def usage():
    pass

if __name__ == "__main__":
    main()
