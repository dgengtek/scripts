#!/usr/bin/env python3
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

# common OUI
#    00:16:3E -- Xen
#    00:18:51 -- OpenVZ
#    00:50:56 -- VMware (manually generated)
#    52:54:00 -- QEMU/KVM
#    AC:DE:48 -- PRIVATE

import random
import sys
import click


@click.command("mac_generate.py")
@click.option(
    "-o",
    "--oui",
    type=click.Choice(
        ["xen", "openvz", "vmware", "lxc", "lxd", "qemu", "kvm", "private", "none"]
    ),
    default="none",
    help="Choose MAC OUI. \
            none will generate a random MAC defined by gl, um, bits flags",
)
@click.option(
    "-g",
    "--global",
    "gl",
    flag_value="global",
    help="for globally unique (OUI enforced) MAC",
)
@click.option(
    "-l",
    "--local",
    "gl",
    flag_value="local",
    default=True,
    help="for locally administered MAC",
)
@click.option(
    "-u",
    "--unicast",
    "um",
    flag_value="unicast",
    help="for unicast transmission to collision domain",
)
@click.option(
    "-m",
    "--multicast",
    "um",
    flag_value="multicast",
    default=True,
    help="for one time multicast transmission",
)
@click.option(
    "-b",
    "--bits",
    type=click.Choice(["48", "64"]),
    default="48",
    help="Only MAC-48 implemented",
)
@click.option("-s", "--separator", default=":")
@click.option("-n", "--dryrun", is_flag=True)
@click.option("-v", "--verbose", is_flag=True)
def main(oui, gl, um, bits, separator, dryrun, verbose):
    oui_mapping = {
        "xen": MACXen,
        "lxc": MACXen,
        "lxd": MACXen,
        "openvz": MACOpenVZ,
        "vmware": MACVMware,
        "qemu": MACKVM,
        "kvm": MACKVM,
        "private": MACPrivate,
        "none": MAC,
    }

    local = gl
    multicast = um
    builder = oui_mapping.get(oui, "")
    if not builder:
        print("Chosen OUI invalid.", file=sys.stderr)
        sys.exit(1)

    mac = None
    if builder == MAC:
        mac = builder(separator, local, multicast)
    else:
        mac = builder(separator)
    print(mac, end="")


class MAC:
    def __init__(self, separator=":", local=True, multicast=True, randomize_all=True):
        self.__init_array()
        self.separator = separator

        if randomize_all:
            self.randomize_mac()
        else:
            self.randomize_nic()

        if local:
            self.set_oui_local()
        else:
            self.set_oui_global()

        if multicast:
            self.set_oui_multicast()
        else:
            self.set_oui_unicast()

    def randomize_nic(self):
        for i in range(3):
            self.__randomize_octet(i + 3)

    def randomize_oui(self):
        for i in range(3):
            self.__randomize_octet(i)

    def randomize_mac(self):
        for i in range(self.records):
            self.__randomize_octet(i)

    def __init_array(self):
        self.records = 48 >> 3
        self.array = bytearray(self.records)

    def set_octet_bit(self, octet, bit):
        """ """
        record = self.array[octet]
        offset = bit & 7
        mask = 1 << offset
        record |= mask
        self.array[octet] = record

    def clear_octet_bit(self, octet, bit):
        """ """
        record = self.array[octet]
        offset = bit & 7
        mask = ~(1 << offset)
        record &= mask
        self.array[octet] = record

    def __randomize_octet(self, octet):
        self.array[octet] = random.randint(0, 2**8 - 1)

    def check_octet_bit(self, octet, bit):
        record = self.array[octet]
        offset = bit & 7
        mask = 1 << offset
        record &= mask
        return record != 0

    def set_oui_local(self):
        self.set_octet_bit(0, 1)

    def set_oui_global(self):
        self.clear_octet_bit(0, 1)

    def set_oui_multicast(self):
        self.set_octet_bit(0, 0)

    def set_oui_unicast(self):
        self.clear_octet_bit(0, 0)

    def get_oui(self):
        return self.array[:3]

    def get_nic(self):
        return self.array[3:]

    def set_octet_from_hex(self, octet, hexstring):
        self.array[octet] = int(hexstring, 16)

    def hex(self):
        return self.array.hex()

    def to_string(self, separator=None):
        if not separator:
            separator = self.separator
        hexstring = self.hex()
        output = list()
        for i in range(0, len(hexstring), 2):
            output.append(hexstring[i : i + 2])

        return separator.join(output)

    def __str__(self):
        return self.to_string()


class MACXen(MAC):
    def __init__(self, separator=":"):
        super().__init__(separator=separator, randomize_all=False)
        self.set_octet_from_hex(0, "00")
        self.set_octet_from_hex(1, "16")
        self.set_octet_from_hex(2, "3E")


class MACOpenVZ(MAC):
    def __init__(self, separator=":"):
        super().__init__(separator=separator, randomize_all=False)
        self.set_octet_from_hex(0, "00")
        self.set_octet_from_hex(1, "18")
        self.set_octet_from_hex(2, "51")


class MACVMware(MAC):
    def __init__(self, separator=":"):
        super().__init__(separator=separator, randomize_all=False)
        self.set_octet_from_hex(0, "00")
        self.set_octet_from_hex(1, "50")
        self.set_octet_from_hex(2, "56")


class MACKVM(MAC):
    def __init__(self, separator=":"):
        super().__init__(separator=separator, randomize_all=False)
        self.set_octet_from_hex(0, "52")
        self.set_octet_from_hex(1, "54")
        self.set_octet_from_hex(2, "00")


class MACPrivate(MAC):
    def __init__(self, separator=":"):
        super().__init__(separator=separator, randomize_all=False)
        self.set_octet_from_hex(0, "AC")
        self.set_octet_from_hex(1, "DE")
        self.set_octet_from_hex(2, "48")


def check_bit(array_name, bit_num):
    record = bit_num >> 3
    offset = bit_num & 7
    mask = 1 << offset
    return record & mask != 0


def set_bit(array_name, bit_num):
    record = bit_num >> 3
    offset = bit_num & 7
    mask = 1 << offset
    array_name[record] |= mask


def clear_bit(array_name, bit_num):
    record = bit_num >> 3
    offset = bit_num & 7
    mask = ~(1 << offset)
    array_name[record] &= mask


if __name__ == "__main__":
    main()
