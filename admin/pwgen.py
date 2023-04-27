#!/usr/bin/env python3
# generate passwords

# TODO: generate passwords first then build aligned output table format
import sys
import random
import click
import string
import binascii


@click.command("pwgen.py")
@click.argument("length", default=16)
@click.option(
    "character_filter", "-f", "--filter", help="Filter characters from the given string"
)
@click.option("single_line", "--single-line", is_flag=True, help="print one per line")
@click.option("-c", "--count", default=30, help="Password count")
@click.option(
    "-i",
    "--inverse",
    is_flag=True,
    help="Inverse filter. Only show characters from the given filter",
)
@click.option(
    "-b",
    "--bits",
    is_flag=True,
    help="Use bits instead of length to determine password length. Hex representation where suitable by default.",
)
@click.option(
    "-g",
    "--mode-graph",
    "mode",
    flag_value="graph",
    default=True,
    help="mode: [default] All printable characters except whitespace",
)
@click.option(
    "-a", "--mode-alnum", "mode", flag_value="alnum", help="mode: letters + digits"
)
@click.option(
    "--mode-salt-crypt",
    "mode",
    flag_value="salt_crypt",
    help="mode: salt with character set [a-zA-Z0-9./] for crypt - length 16",
)
@click.option("-d", "--mode-digits", "mode", flag_value="digits", help="mode: digits")
@click.option(
    "-l", "--mode-letters", "mode", flag_value="letters", help="mode: letters"
)
@click.option(
    "-p",
    "--mode-printable",
    "mode",
    flag_value="printable",
    help="mode: All printable characters",
)
@click.option(
    "--print-hex",
    "representation",
    flag_value="hex",
    default=True,
    help="only when using --bits: repr: [default] display as hex",
)
@click.option(
    "--print-binary",
    "representation",
    flag_value="binary",
    help="only when using --bits: repr: binary representation",
)
@click.option(
    "--print-base64",
    "representation",
    flag_value="base64",
    help="only when using --bits: repr: base64",
)
@click.option(
    "--print-qp",
    "representation",
    flag_value="qp",
    help="only when using --bits: repr: qp",
)
def main(
    length,
    character_filter,
    single_line,
    count,
    inverse,
    bits,
    mode,
    representation,
):
    set_alpha = set(string.ascii_letters)
    set_digits = set(string.digits)
    set_printable = set(string.printable)
    set_whitespace = set(string.whitespace)

    character_pool = None
    bit_mode = noop
    if mode == "graph":
        character_pool = set_printable - set_whitespace
    elif mode == "alnum":
        character_pool = set_alpha.union(set_digits)
    elif mode == "letters":
        character_pool = set_alpha
    elif mode == "digits":
        character_pool = set_digits
    elif mode == "printable":
        character_pool = set_printable
    elif mode == "salt_crypt":
        character_pool = set_alpha.union(set_digits).union({".", "/"})
        length = 16
    else:
        print("Invalid pool mode set.", file=sys.stderr)
        sys.exit(1)

    if representation == "hex":
        bit_mode = b2hex
    elif representation == "binary":
        bit_mode = b2binary
    elif representation == "qp":
        bit_mode = b2qp
    elif representation == "base64":
        bit_mode = b2base64

    if not character_filter:
        character_filter = set()
    else:
        character_filter = set(character_filter)

    character_pool = character_pool.difference(character_filter)
    character_pool = "".join(character_pool)

    if bits:
        passwords = [bit_mode(random.getrandbits(length)) for i in range(0, count)]
    else:
        passwords = [generate_password(character_pool, length) for i in range(0, count)]
    print_passwords(passwords, single_line)


def noop(i):
    return i


def b2binary(i):
    return bin(i)[2:]


def b2hex(i):
    return binascii.b2a_hex(bigint_to_bytes(i)).decode("UTF-8").strip()


def b2base64(i):
    return binascii.b2a_base64(bigint_to_bytes(i)).decode("UTF-8").strip()


def b2qp(i):
    """
    printable characters
    """
    return binascii.b2a_qp(bigint_to_bytes(i)).decode("UTF-8").strip()


def print_passwords(passwords, single_line):
    if len(passwords) == 1:
        password = passwords[0]
        print(password, end="")
        return

    for i, password in enumerate(passwords, 1):
        if single_line:
            print(password)
            continue

        print(password, end="\t")
        if i % 3 == 0:
            print()


def generate_password(pool, size):
    return "".join([random.choice(pool) for x in range(size)])


def bigint_to_bytes(i):
    ba = bytearray()
    while i:
        ba.append(i & 0xFF)
        i >>= 8
    return ba


if __name__ == "__main__":
    main()
