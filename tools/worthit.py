#!/usr/bin/env python3
from decimal import Decimal
import argparse


def main():
    """
    how much time can be invested automating a task before it
    is not worth it automating it
    """
    args = parse_args()
    year_in_days = Decimal("365")
    across_years = Decimal(args.across)
    across = year_in_days * across_years
    how_often_task_done_daily = Decimal(args.task_done_daily)
    how_much_time_saved_in_seconds = Decimal(args.time_saved)
    allowed_time_to_work_on_automating = (
        across * how_often_task_done_daily * how_much_time_saved_in_seconds
    )
    print("< within this time the task is worth automating")
    print("in s: {}".format(allowed_time_to_work_on_automating))
    print("in m: {}".format(allowed_time_to_work_on_automating / Decimal("60")))
    print("in h: {}".format(allowed_time_to_work_on_automating / Decimal("3600")))
    print(
        "in d: {}".format(
            allowed_time_to_work_on_automating / Decimal("3600") / Decimal("24")
        )
    )


def parse_args():
    """
    parse arguments and return result
    """
    parser = argparse.ArgumentParser(
        description="Program description.", epilog="Epilog of program.", add_help=True
    )
    # positional arguments
    parser.add_argument("task_done_daily", help="how often is the task done daily")
    parser.add_argument("time_saved", help="time saved in seconds")

    parser.add_argument(
        "--across", help="across how many years time saved", default="5", action="store"
    )  # default action

    return parser.parse_args()


if __name__ == "__main__":
    main()
