#!/bin/env python3
# first three octet identify organization
# organizationally unique identifier(OUI)

# following three(MAC-48 and EUI-48) or
# five (EUI-64) octets are assigned by that
# organization - arbitrarily

# locally administered addresses do not contain OUI's

# difference of universal/local, setting the second
# least significant bit of the most significant byte
# of the address -> U/L bit
# 0 -> universal
# 1 -> local

# if least significant bit of most significant octet is
# set to 0(zero), frame is meant to reach only ONE receiving NIC
# -> unicast
# unicast frame is sent to all nodes within collision domain
# ends at switch,router ...
# if it is set to 1 the frame will be sent only once, however
# NICs will choose to accept based on criteria other than matching MAC

# MAC-48 for network hardware, EUI-48 to identify other devices and software
# EUI-64 for IPv6, FireWire
# default MAC-48
# MAC-48
# 3 bytes OUI, 3bytes Network Interface Controller(NIC) specific
# first byte:
# 8bits
# b8 b7 b6 b5 b4 b3 b2 b1
# b1: 0 - unicast, 1 - multicast
# b2: 0 - globally unique(OUI enforced), 1 - locally administered

import sys
import getopt
import random

# TODO change mappings of um and gl to a single boolean...

def usage():
  h="usage:\t"+sys.argv[0]
  h+=" [-(u|m)] [-(g|l)]"
  h+=" [-b bits] [-h] [-s separator]\n"
  h+="\t-u\tunicast\n"
  h+="\t-m\tmulticast (default)\n"
  h+="\t-g\tglobal\n"
  h+="\t-l\tlocal (default)\n"
  h+="\t-b bits\tbits, either 48(default) or 64\n"
  h+="\t-h\thelp\n"
  h+="\t-s separator\t(default='-')\n"
  print(h)
  sys.exit(2)


def double_selection(optionlist,unique):
    selected_once=False
    for o in optionlist:
        o=o.replace("-","")
        if o in unique:
            if selected_once:
                return True
            selected_once=True
    return False

def set_variable(mapping, option):
  var=mapping[option]



# either only one of these
unique_list=["um","gl"]

options="umglb:hs"
opts, args = getopt.getopt(sys.argv[1:], options)

raw_options=options.replace(":","")

mapped_options= {
    "um":
    {
      "u":False,
      "m":True 
      },
    "gl":
    {
      "g":False,
      "l":True
      },
    "b":48,
    "s":"-"
    }

option_keys=[o for o,v in opts]

for uniques in unique_list:
    if double_selection(option_keys, uniques):
        usage()

keys=mapped_options.keys()
for opt,value in opts:
    opt=opt.replace("-","").strip()
    if "h" in opt:
        usage()

    for key in keys:
        if opt in key and key in unique_list:
            mapped_options[key][opt]=True
            reversed_key=key.replace(opt,"")
            mapped_options[key][reversed_key]= not \
                mapped_options[key][reversed_key]
        elif "b" in opt: 
            mapped_options[opt]=value 

bits=int(mapped_options.get("b",48))
mac=random.randint(2**(bits-1),(2**bits)-1)

def generate_bit_operation(mask):
    mask=2**mask
    def gen_func(func, nr):
        return func(nr, mask)
    return gen_func

# define bit operations
bit_set_function=lambda x,y: x|y
bit_unset_function=lambda x,y: x&~y

bit_operation=generate_bit_operation(bits-8)
# bit nr 1 of first octet
if mapped_options["um"]["m"]:
    mac=bit_operation(bit_set_function, mac)
else:
    mac=bit_operation(bit_unset_function, mac)
# bit nr 2 of first octet
bit_operation=generate_bit_operation(bits-7)
if mapped_options["gl"]["l"]:
    mac=bit_operation(bit_set_function, mac)
else:
    mac=bit_operation(bit_unset_function, mac)

separator=mapped_options["s"]
mac=hex(mac)[2:]
result=""
for i,c in enumerate(mac):
    result+=c
    if not (i+1)%2 and \
        (i+1) < len(mac):
        result+=separator
print(result)
