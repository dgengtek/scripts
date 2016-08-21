#!/bin/env python3

def main():
    args = parse_args()
    print(args)
def usage():
    pass

def parse_args():
    import argparse
    parser = argparse.ArgumentParser(
            description="Program description.",
            epilog="Epilog of program.",
            add_help=True
            )
    # positional arguments
    parser.add_argument("target", help="target directory")
    parser.add_argument("destination", help="destination directory")

    # required
    parser.add_argument("--require",
            help="required value store",
            action="store")
    #optional arguments
    parser.add_argument("--optional",
            help="optional value with different metavar",
            metavar="METAVAROPTIONAL")
    parser.add_argument("--stored",
            help="store with different key in namespace of result",
            dest="newkeystored")
    # store boolean
    parser.add_argument("-v","--verbosity", 
            help="increase output verbosity",
            type=int,
            choices=[0,1,2])
    parser.add_argument("-k",
            help="k store true",
            action="store_true")
    # store value
    parser.add_argument("-l",
            action="store") # default action
    # store const value
    parser.add_argument("-t",
            help="store constant value when set",
            action="store_const", 
            const="stored const value")
    # append to a list, allow multiple uses of arg
    parser.add_argument("-a",
            help="append to a list",
            action="append")
    # count, count occurences of keyword argument, -uuu
    parser.add_argument("-u",
            help="count occurences of arg used",
            action="count")
    # use nargs with, N, ?, *, +, argparse.REMAINDER - catches all remaining args
    # arguments gathered into list, -c value1 value2
    parser.add_argument("-c",
            help="use different count args required to pass to a key",
            nargs=2)

    import sys
    # optional input
    parser.add_argument('infile', nargs='?', type=argparse.FileType('r'),
            default=sys.stdin)
    # optional output
    parser.add_argument('outfile', nargs='?', type=argparse.FileType('w'),
            default=sys.stdout)

    # mutual exclusive, either foo or bar
    exclusive_group = parser.add_mutually_exclusive_group()
    exclusive_group.add_argument('--foo', action='store_true')
    exclusive_group.add_argument('--bar', action='store_false')

    return parser.parse_args()

if __name__ == "__main__":
    main()
