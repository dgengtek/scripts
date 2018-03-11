#!/bin/env python3
# generate passwords

# TODO: generate passwords first then build aligned output table format
import sys
import random
import click
import string


@click.command("pwgen.py")
@click.argument("length", default=16)
@click.option("character_filter", "-f","--filter", help="Filter characters from the given string")
@click.option("-c","--count",  default=30, help="Password count")
@click.option("-i","--inverse", is_flag=True, help="Inverse filter. Only show characters from the given filter")
@click.option('-b', '--bits', is_flag=True, help="Use bits instead of length to determine password length")
@click.option('-g', '--graph', 'mode', flag_value='graph', default=True, help="mode: [default] All printable characters except whitespace")
@click.option('-a', '--alnum', 'mode', flag_value='alnum', help="mode: letters + digits")
@click.option('-d', '--digits', 'mode', flag_value='digits', help="mode: digits")
@click.option('-p', '--printable', 'mode', flag_value='printable', help="mode: All printable characters")
@click.option('-l', '--letters', 'mode', flag_value='letters', help="mode: letters")
def main(length, character_filter, count, inverse, bits, mode):
    set_alpha = set(string.ascii_letters)
    set_digits = set(string.digits)
    set_printable = set(string.printable)
    set_whitespace = set(string.whitespace)

    if bits:
        length = 256 // 8

    character_pool = None
    if mode == "graph":
        character_pool = set_printable - set_whitespace
    if mode == "alnum":
        character_pool = set_alpha.union(set_digits)
    if mode == "letters":
        character_pool = set_alpha
    if mode == "digits":
        character_pool = set_digits
    if mode == "printable":
        character_pool = set_printable

    if not character_filter:
        character_filter = set()
    else:
        character_filter = set(character_filter)

    character_pool = character_pool.difference(character_filter)
    character_pool = "".join(character_pool)

    passwords = [ generate_password(character_pool, length) for i in range(1, count+1)]
    print_passwords(passwords)

def print_passwords(passwords):
    if len(passwords) == 1:
        password = passwords[0]
        print(password, end="")
        return

    for i,password in enumerate(passwords, 1):
        print(password, end="\t")
        if i % 3 == 0:
            print()


def generate_password(pool, size):
    return "".join([ random.choice(pool) for x in range(size) ])

if __name__ == "__main__":
    main()
