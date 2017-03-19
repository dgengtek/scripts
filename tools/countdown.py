#!/bin/env python3
"""
Usage:
    countdown [options] [<datestring>]

Options:
"""

"""
This example uses docopt with the built in cmd module to demonstrate an
interactive command application.
Usage:
    my_program tcp <host> <port> [--timeout=<seconds>]
    my_program serial <port> [--baud=<n>] [--timeout=<seconds>]
    my_program (-i | --interactive)
    my_program (-h | --help | --version)
Options:
    -i, --interactive  Interactive Mode
    -h, --help  Show this screen and exit.
    --baud=<n>  Baudrate [default: 9600]
<arguements>, ARGUMENTS -> list
--options, words with dash(-) , or --input=FILE or -i FILE
commands, dont follow above

Pattern constructs:
    [](brackets) optional elements
    ()(parentheses) required elements, everything not put in [] also required
    |(pipe) mutually exclusive elements. Group with () or []
    ...(ellipsis) one or more elements, e.g. my_program.py FILE ..., one ore
        more FILE s accepted, for zero or more use [FILE ...]
    [options](case sensitive) shortcut for options, defined in options below
    "[--]" used by convetntion to separate positional arguements
    "[-]" by conevntion signify stdin is used instead of a file
    [-v | -vv | -vv] countable flags, args["-v"] will be nr of occ

    Options:
      --verbose   # GOOD
      -o FILE     # GOOD
    Other: --bad  # BAD, line does not start with dash "-"

    -o FILE --output=FILE       # without comma, with "=" sign
    -i <file>, --input <file>   # with comma, without "=" sing

    Use two spaces to separate options with their informal description
	--verbose More text.   # BAD, will be treated as if verbose option had
			       # an argument "More", so use 2 spaces instead
	-q        Quit.        # GOOD
	-o FILE   Output file. # GOOD
	--stdout  Use stdout.  # GOOD, 2 spaces

    If you want to set a default value for an option with an argument, 
    put it into the option-description, in form [default: <my-default-value>]:
	--coefficient=K  The K coefficient [default: 2.95]
	--output=FILE    Output file [default: test.txt]
	--directory=DIR  Some directory [default: ./]

    for git like sub commands use, options_first parameter 

     args = docopt(__doc__,
                  version='git version 1.7.4.4',
                  options_first=True)
    print('global arguments:')
    print(args)
    print('command arguments:')

    argv = [args['<command>']] + args['<args>']
    if args['<command>'] == 'add':
        # In case subcommand is implemented as python module:
        import git_add
    print(docopt(git_add.__doc__, argv=argv))

"""


import sys
from docopt import docopt
import logging
import time
import pytest

# docopt(doc, argv=None, help=True, version=None, options_first=False))

class Countdown:
    def __init__(self):
        self.hour = 0
        self.minute = 0
        self.second = 0
        self.seconds= 0
        self.finished = False


    def _normalize_from_seconds(self):
        second = _get_second(self.seconds)
        minutes = _get_minutes(self.seconds)
        minute = _get_minute(minutes)
        hour = _get_hours(minutes)

        self.hour = hour
        self.minute = minute
        self.second = second

    def _normalize_to_seconds(self):
        minutes = self.hour*60 + self.minute
        self.seconds = minutes*60 + self.second

    def sync(self):
        self._normalize_from_seconds()

    def __str__(self):
        return "{:02}:{:02}:{:02}".format(self.hour, self.minute, self.second)

    @classmethod
    def from_seconds(cls, seconds):
        cd = cls()
        cd.seconds = seconds
        cd.sync()
        return cd

    @classmethod
    def from_minutes(cls, minutes):
        return cls.from_seconds(minutes*60)

    @classmethod
    def from_hours(cls, hours):
        return cls.from_minutes(hours*60)

    @classmethod
    def from_stamp(cls, hour, minute, second):
        cd = cls()
        cd.hour = hour
        cd.minute = minute
        cd.second = second
        cd._normalize_to_seconds()
        return cd

    def __eq__(cd, cd2):
        return cd.hour == cd2.hour \
            and cd.minute == cd2.minute \
            and cd.second == cd2.second

def _get_second(seconds):
    "return leftover second"
    return seconds % 60

def _get_minute(minutes):
    "return leftover minute"
    return minutes % 60

def _get_minutes(seconds):
    "return total minutes"
    return seconds // 60

def _get_hours(minutes):
    "return total hour"
    return minutes // 60


def main():
    opt = docopt(__doc__, sys.argv[1:])
    #print(opt)
    seconds = opt.get("<seconds>")
    if seconds:
        cd = Countdown.from_seconds(int(seconds))
        counter(cd)

    else:
        while True:
            pomodoro()

def pomodoro(minutes=25, rest=5):
    working = Countdown.from_minutes(minutes)
    resting = Countdown.from_minutes(rest)

    for cd in working, resting:
        counter(cd)

def counter(cd):
    while True:
        print("\r{}                    ".format(cd), end="")
        if not countdown(cd):
            break
        time.sleep(1)

def countdown(cd, counter=1):
    if not cd.seconds:
        cd.finished = True
    else:
        cd.seconds -= counter
        cd.sync()
    
    # while looping with true more accustomed habit
    return not cd.finished



@pytest.mark.parametrize("seconds, expected", [
            (1, (0,0,1)),
            (59, (0,0,59)),
            (61, (0,1,1)),
            (121, (0,2,1)),
            (299, (0,4,59)),
            (300, (0,5,0)),
            (301, (0,5,1)),
            (3599, (0,59,59)),
            (3600, (1,0,0)),
            (3601, (1,0,1)),
            (3661, (1,1,1)),
            ])
def test_countdown_convert_from_seconds(seconds, expected):
    cd = Countdown.from_seconds(seconds)
    cdexpected = Countdown.from_stamp(*expected)
    assert cd == cdexpected

def test_countdown_timer_string():
    cd = Countdown.from_seconds(61)
    assert str(cd) == "00:01:01"
    cd = Countdown.from_seconds(1)
    assert str(cd) == "00:00:01"
    cd = Countdown.from_seconds(3600)
    assert str(cd) == "01:00:00"
    cd = Countdown.from_seconds(360000)
    assert str(cd) == "100:00:00"



if __name__ == "__main__":
    main()
