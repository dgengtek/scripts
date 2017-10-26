#!/bin/env python3
"""
Run disk io benchmarks
"""
import timeit
import subprocess
import argparse
import sys
import re
import itertools
import os
# TODO  improve latency execution
#       use small blocksize, eg 4096, to test latency of block access
# TODO  create a better total summary after modes are executed
# TODO  verbose output:
#           - progress of command with status=progress 
#           - no redirection of command output 
# TODO  add to output maximum and minimum recorded values

modes={
        "read":[
            "read",
            "r"
            ],
        "write":[
            "write",
            "w",
            ],
        "response":[
            "latency",
            "response",
            "l",
            ],
        }
def main():
    args = parse_args()

    selected_modes = filter_selected_modes(args.get("mode"))
    if "read" in selected_modes and os.geteuid() != 0:
        print("Error: User needs root permissions for running proper read benchmarks")
        sys.exit(2)

    try:
        blocksize = args.get("blocksize")
        count = args.get("count")
        rounds = args.get("rounds")
        del args["mode"]

        bytes_size = 1024
        size_count, unit, power = parse_power_of_unit(blocksize)

        bytes_size = bytes_size**power
        bytes_count = bytes_size * int(size_count) * int(count)

        for s in selected_modes:
            print("Running benchmark for: {}".format(s))
            run_benchmark(benchmark_factory(s, **args), 
                    unit,
                    bytes_count, 
                    bytes_size,
                    rounds)
    except Exception as e:
        print(e)
    finally:
        os.remove(args.get("destination"))


def usage():
    pass

def parse_args():
    summary="""
    Benchmark IO 

    default config uses a blocksize of 1M * 1024 = 1GB with 10 rounds

    """
    argparser = argparse.ArgumentParser(description=summary)

    argparser.add_argument("-v","--verbose",action="store_true")
    argparser.add_argument("-r","--rounds",type=int, default=10)
    argparser.add_argument("-s","--source",default="/dev/zero", 
            help="Data source for benchmark")
    argparser.add_argument("-c","--count",type=int, default=1024,
            help="count of blocksizes(default: 1024)")
    argparser.add_argument("-b","--blocksize", default="1M",
            help="blocksize in bytes with additional size as B,K,M,G,T(default: 1M)")

    global modes
    merged = list(itertools.chain(*modes.values()))
    argparser.add_argument("mode",choices=merged, nargs="*")
    argparser.add_argument("destination", default="tmp_benchmark_IO")
    del merged

    namespace = argparser.parse_args(sys.argv[1:])
    return vars(namespace)



def filter_selected_modes(selection):
    selected_modes = list()
    global modes
    for mode, aliases in modes.items():
        for s in selection:
            if s in aliases:
                selected_modes.append(mode)
                break
    selected_modes.sort(reverse=True)
    return selected_modes

def run_benchmark(benchmark, unit, bytes_count, bytes_size, rounds=10):
    avg_speed = 0
    avg_time = 0

    for i in range(rounds):
        start_time = timeit.default_timer()
        if benchmark().returncode is not 0:
            print("Unexptected returncode of process")
            sys.exit(2)
        timing = (timeit.default_timer() - start_time)
        avg_time += timing
        avg_speed += bytes_count / timing

        print('.', end="")
        sys.stdout.flush()
    avg_time = avg_time / rounds
    avg_speed = avg_speed / (rounds * bytes_size)


    output = []
    output.append("{} rounds".format(rounds))
    output.append("bytes processed: {} {}B".format(bytes_count / bytes_size, unit))
    output.append("avg. time: {} s".format(avg_time))
    output.append("avg. speed in {} {}B/s: ".format(avg_speed, unit))
    print("\n".join(output))

def parse_power_of_unit(input_unit):
    notations = {
            "K":1,
            "M":2,
            "G":3,
            "T":4,
            }
    pattern = r"([0-9]*)([A-Z])"
    matcher = re.compile(pattern)
    match = matcher.search(input_unit)
    unit = "K"
    power = 1
    if match:
        size, unit = match.groups()
        power = notations.get(unit, power)
    return size, unit, power

def benchmark_factory(mode, source, destination, blocksize, count, **kwargs):
    cmd = ["dd"]

    preparation_functions = list()

    if mode in modes.get("read"):
        check_destination = prepare_destination(
                source=source, 
                destination=destination, 
                blocksize=blocksize,
                count=count, **kwargs
                )
        preparation_functions.append(check_destination)
        preparation_functions.append(clear_disk_cache)
        source = destination
        destination = "/dev/zero"
    elif mode in modes.get("write"):
        cmd.append("conv=fdatasync,notrunc")
        pass
    elif mode in modes.get("response"):
        pass

    cmd.append("if={}".format(source))
    cmd.append("of={}".format(destination))
    cmd.append("bs={}".format(blocksize))
    cmd.append("count={}".format(str(count)))

    def run_benchmark():
        fns = preparation_functions
        for f in fns:
            f()
        return subprocess.run(cmd, stderr=subprocess.DEVNULL)
    return run_benchmark

def clear_disk_cache():
    with open("/proc/sys/vm/drop_caches","w") as f:
        f.write("3")


def prepare_destination(**kwargs):
    def check_destination():
        if not os.path.isfile(kwargs.get("destination")):
            args_copy = dict(kwargs)
            print("Creating temporary file. ", end="")
            sys.stdout.flush()
            f = benchmark_factory("write", **kwargs)
            f()
            print("Done.")

    return check_destination

def prepare_string(string):
    """
    Prepare string of command output as a list for parsing results
    """
    args = None
    try:
        string = string.decode("utf-8")
        args = string.split(",")
    except Exception:
        raise 
    return args

def parse_results(result):
    """
    Parse command result and return the number of bytes transferred
    """
    pattern=r"([0-9]*) bytes"

    matcher = re.compile(pattern)
    match = matcher.search(result)
    if match:
        result, = match.groups()
    else:
        result = None
    return int(result)


def benchmark_none():
    print("Empty benchmark")

if __name__ == "__main__":
    main()
