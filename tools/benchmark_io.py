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
log_file = "benchmark_IO_log"
error_file = "benchmark_IO_error_log"
args = None

def main():
    parse_args()

def usage():
    pass

def parse_args():
    summary="""
    Benchmark IO 

    """
    argparser = argparse.ArgumentParser(description=summary)

    argparser.add_argument("-v","--verbose",action="store_true")
    argparser.add_argument("-r","--rounds",type=int, default=10)
    argparser.add_argument("-s","--source",default="/dev/zero", 
            help="Data source for benchmark")
    argparser.add_argument("-t","--total-size", 
            help="Total size of written file in size(B,K,M,G,T)")
    argparser.add_argument("-c","--count",type=int, default=1024,
            help="count of blocksizes(default: 1024)")
    argparser.add_argument("-b","--blocksize", default="1M",
            help="blocksize in bytes with additional size as B,K,M,G,T(default: 1M)")

    global modes
    merged = list(itertools.chain(*modes.values()))
    argparser.add_argument("mode",choices=merged, nargs="*")
    argparser.add_argument("destination")
    del merged

    if len(sys.argv) is 1:
        argparser.print_help()
        sys.exit(1)

    namespace = argparser.parse_args(sys.argv[1:])
    # get dictionary of values
    global args 
    args = vars(namespace)
    selected_modes = filter_selected_modes(args.get("mode"))
    if "read" in selected_modes and os.geteuid() != 0:
        print("Error: User needs root permissions for running proper read benchmarks")
        sys.exit(2)

    for s in selected_modes:
        print("Running benchmark for: ",s)
        run_benchmark(benchmark_factory(s, args),  args.get("rounds"))
    cleanup()


def filter_selected_modes(selection):
    selected_modes = list()
    global modes
    for m in modes:
        mode = modes.get(m)
        for s in selection:
            if s in mode:
                selected_modes.append(m)
                break
    selected_modes.sort(reverse=True)
    return selected_modes

def run_benchmark(benchmark,rounds=10):

    avg_time = 0
    for i in range(rounds):
        start_time = timeit.default_timer()
        if benchmark().returncode is not 0:
            print("Unexptected returncode of process")
            sys.exit(2)
        avg_time += (timeit.default_timer() - start_time)
        print('.', end="")
        sys.stdout.flush()
    avg_time = avg_time / rounds

    global args
    blocksize = args.get("blocksize")
    count = args.get("count")
    size = 1024
    power = 1
    pattern = r"[0-9]*([A-Z])"
    matcher = re.compile(pattern)
    match = matcher.search(blocksize)
    if match:
        power, = match.groups()
        power = get_power_to_byte(power)
    bytes_count = count * (size**power)
    speed = bytes_count / avg_time
    speed = speed / (1024**2)

    output = "{} rounds\n".format(rounds)
    output += "bytes processed: {}\n".format(bytes_count)
    output += "avg. time: {}\n".format(avg_time)
    output += "avg. speed: {} MB/s\n".format(speed)
    print(output)
def get_power_to_byte(notation):
    notations = {
            "K":1,
            "M":2,
            "G":3,
            "T":4,
            }
    return notations.get(notation,1)

def benchmark_factory(mode ,args , log_file="benchmark_IO_log"):
    cmd = "dd"
    source = args.get("source")
    destination = args.get("destination")
    blocksize = args.get("blocksize")
    count = args.get("count")

    preparation_functions = list()

    if mode in modes.get("read"):
        preparation_functions.append(destination_exists)
        preparation_functions.append(clear_disk_cache)
        source = destination
        destination = "/dev/zero"
    elif mode in modes.get("write"):
        cmd += " conv=fdatasync,notrunc"
        pass
    elif mode in modes.get("response"):
        pass

    cmd += " if=" + source
    cmd += " of=" + destination
    cmd += " bs=" + blocksize
    cmd += " count=" + str(count)

    def run_benchmark():
        fns = preparation_functions
        for f in fns:
            f()
        dd_command = cmd.split()
        return subprocess.run(dd_command, stderr=subprocess.DEVNULL)
    return run_benchmark

def clear_disk_cache():
    with open("/proc/sys/vm/drop_caches","w") as f:
        f.write("3")
def cleanup():
    global args
    os.remove(args.get("destination"))

def destination_exists():
    global args
    filename = args.get("destination")
    if not os.path.isfile(filename):
        args_copy = dict(args)
        args_copy["count"] = 1
        args_copy["blocksize"] = "1G"
        print("Creating temporary file.")
        f = benchmark_factory("write", args_copy)
        f()

def prepare_string(string):
    """
    Prepare string of command output as a list for parsing results
    """
    args = None
    try:
        string = string.decode("utf-8")
        args = string.split(",")
    except Exception:
        # rethrow
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
