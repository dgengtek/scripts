#!/usr/bin/env python3
# censor strings
# read from stdin if no args supplied

import sys
import random
import click
import string


@click.command()
@click.argument("input_string", nargs=-1)
@click.option(
        "character_filter",
        "-f",
        "--filter",
        help="Censor characters from the given string")
@click.option(
        'random_censor',
        '-r',
        '--random',
        is_flag=True,
        help="Replace characters randomly from its set of characters")
@click.option(
        '-h',
        '--hidden',
        is_flag=True,
        help="Replace characters with '*'")
@click.option(
        '-g',
        '--graph',
        'mode',
        flag_value='graph',
        default=True,
        help="censor mode: [default] All printable characters except whitespace")
@click.option(
        '-a',
        '--alnum',
        'mode',
        flag_value='alnum',
        help="censor mode: letters + digits")
@click.option(
        '-d',
        '--digits',
        'mode',
        flag_value='digits',
        help="censor mode: digits")
@click.option(
        '-p',
        '--printable',
        'mode',
        flag_value='printable',
        help="censor mode: All printable characters")
@click.option(
        '-l',
        '--letters',
        'mode',
        flag_value='letters',
        help="censor mode: letters")
def main(input_string, character_filter, random_censor, hidden, mode):
    set_alpha = set(string.ascii_letters)
    set_digits = set(string.digits)
    set_printable = set(string.printable)
    set_whitespace = set(string.whitespace)

    character_pool = None
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
    else:
        print("Invalid pool mode set.", file=sys.stderr)
        sys.exit(1)

    if not character_filter:
        character_filter = set()
    else:
        character_filter = set(character_filter)

    character_pool = character_pool.difference(character_filter)
    character_pool = "".join(character_pool)
    pool = CensorPool(character_pool, random_censor, hidden)

    if not input_string:
        input_string = sys.stdin.readlines()

    if len(input_string) > 1:
        endstring = '\n'
    else:
        endstring = ''

    for line in input_string:
        print(pool.censor(line), end=endstring)


class CensorPool():
    def __init__(self, character_pool, random_censor=False, hidden=False):
        self.character_pool = character_pool
        self.random_censor = random_censor
        self.hidden = hidden

    def censor(self, input_string):
        output = []
        for c in input_string:
            new_char = c
            if c in self.character_pool:
                if self.random_censor:
                    while True:
                        new_char = random.choice(self.character_pool)
                        if new_char != c:
                            break
                else:
                    new_char = self.censor_character(c)
            output.append(new_char)

        return "".join(output)

    def censor_character(self, input_character):
        if len(input_character) > 1:
            raise Exception("String to long to handle")
        if self.hidden:
            return "*"
        if input_character.isdigit():
            return "0"
        elif input_character.isalpha():
            return "A"
        elif input_character.isprintable():
            return "*"


def test_censorpool():
    pool = CensorPool(("a", "A", "b", "B", "0", "1", "2"))
    data = [
            ("AABB", "AAAA"),
            ("B", "A"),
            ("a", "A"),
            ("a1", "A0"),
            ("1", "0"),
            ("aCc41", "ACc40"),
            ]
    for input_string, censored_string in data:
        assert pool.censor(input_string) == censored_string


def test_censorpool_random():
    pool = CensorPool(("a", "A", "b", "B", "0", "1", "2"), random_censor=True)
    data = [
            ("AABB", "AAAA"),
            ("B", "A"),
            ("a", "A"),
            ("a1", "A0"),
            ("1", "0"),
            ("aCc41", "ACc40"),
            ]
    for input_string, censored_string in data:
        assert pool.censor(input_string) != input_string


def test_censorpool_hidden():
    pool = CensorPool(("a", "A", "b", "B", "0", "1", "2"), hidden=True)
    data = [
            ("AABB", "****"),
            ("B", "*"),
            ("a", "*"),
            ("a1", "**"),
            ("1", "*"),
            ("aCc41", "*Cc4*"),
            ]
    for input_string, censored_string in data:
        assert pool.censor(input_string) != input_string


def test_string_censor():
    character_pool = set(string.ascii_letters).union(set(string.digits))
    pool = CensorPool(character_pool)
    data = [
            ("My name is", "AA AAAA AA"),
            ("DE123182181293", "AA000000000000"),
            ]
    for input_string, censored_string in data:
        assert pool.censor(input_string) == censored_string


if __name__ == "__main__":
    main()
