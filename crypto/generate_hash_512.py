#!/bin/env python3
# generate password mac for dovecot

import sys
import os
import getopt
from cryptography.hazmat.backends import default_backend
from cryptography.hazmat.primitives import hashes
import base64
import binascii

def usage():
    h="usage:\t"+sys.argv[0]
    h+=" [-s salt] password"
    print(h)
    sys.exit(2)

password=""
salt=""

options="s:p:h"
opts, args = getopt.getopt(sys.argv[1:], options)
if len(args) is 1:
    password=args[0]
else:
    usage()

    

raw_options=options.replace(":","")

        
option_keys=[o for o,v in opts]

if "-h" in option_keys:
    usage()

for opt,value in opts:
    opt=opt.replace("-","").strip()
    if "s" in opt:
        salt=value

password=password.encode("utf8")
if salt:
    salt=binascii.a2b_hex(salt)
else:
    salt=os.urandom(16)



digest=hashes.Hash(hashes.SHA512(),backend=default_backend())
digest.update(password)
digest.update(salt)
hash_raw=digest.finalize()

hash_and_salt=hash_raw+salt

hash_base64=binascii.b2a_base64(hash_and_salt)

dovecot="{SSHA512}"+hash_base64.decode("utf-8")
print(dovecot)


