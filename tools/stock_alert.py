#!/usr/bin/env python3
import requests
import sys
import time
from fractions import Decimal

# symbols sep by ','
STOCK_API_URL = "https://query1.finance.yahoo.com/v7/finance/quote?lang=en-US&region=US&corsDomain=finance.yahoo.com&symbols={symbol}"

STOCK_KEYS = [
    "preMarketPrice",
    "regularMarketPrice",
    "postMarketPrice",
    ]


def main():
    args = parse_args()
    symbol = args.symbol
    api_url = args.url
    if not api_url:
        api_url = STOCK_API_URL.format(symbol=symbol)
    else:
        api_url = api_url.format(symbol=symbol)

    limits = args.alert_range.split(":")
    lower_limit = Decimal(limits[0])
    upper_limit = Decimal(limits[1])

    rates_of_change = dict()

    max_memory_required = 0

    if not args.roc:
        args.roc = list()
    for roc in args.roc:
        roc_split = roc.split("=")

        if len(roc_split) > 2:
            print(
                "Rate of change must be noted within a single '=' \
                        like 5=15:45. Input: {}".format(roc),
                file=sys.stderr)
            sys.exit(1)

        rate = roc_split[0]
        max_memory_required = max(
                [int(rate.lstrip("avg")), max_memory_required])
        roc_split = roc_split[1].split(":")
        if len(roc_split) > 2:
            print(
                "Range over the rate of change must be noted within a single ':' \
                        like 5=15:45. Input: {}".format(roc),
                file=sys.stderr)
            sys.exit(1)

        rates_of_change[rate] = {
                "lower_limit": Decimal(roc_split[0]),
                "upper_limit": Decimal(roc_split[1]),
                }

    if len(limits) != 2:
        print(
            "Alert range must be noted within a single '-' \
like 15-45. Input: {}".format(args.alert_range),
            file=sys.stderr)
        sys.exit(1)

    retries = 0
    max_retries = 10

    # keep list of last values for the current stock price
    memory = list()
    # how many should be held in the list
    while True:
        if retries >= max_retries:
            print("Maximum retries reached. Aborting now.", file=sys.stderr)
            sys.exit(1)

        try:
            r = requests.get(api_url)
        except (OSError, requests.ConnectionError, requests.ConnectTimeout):
            retries += 1
            time.sleep(3)
            continue

        data = r.json().get("quoteResponse", "")
        response_error = data.get("error", "")
        if response_error or not data:
            print(
                "Error in response: {}".format(response_error),
                file=sys.stderr)
            retries += 1
            time.sleep(3)
            continue

        retries = 0

        data = data.get("result")
        send_alarm = False
        for r in data:
            value = ""
            premarket = r.get("preMarketPrice", "")
            postmarket = r.get("postMarketPrice", "")
            market = r.get("regularMarketPrice", "")

            # use the value of the current active market price
            if premarket:
                value = premarket
            elif postmarket:
                value = postmarket
            else:
                value = market
            value = Decimal(str(value))

            # first check alert limits before checking rates
            stock_name = r.get("longName")
            if alert_on_limit_range(
                    value, lower_limit, upper_limit, stock_name):
                send_alarm = True

            # if no rates of change have been supplied print and skip
            if not rates_of_change:
                print("{} @{}".format(
                    stock_name,
                    value), file=sys.stderr)
                continue

            if len(memory) >= max_memory_required:
                memory = memory[1:]

            rate_string = []
            for requested_items, rate_options in rates_of_change.items():
                use_average = False
                if requested_items.startswith("avg"):
                    use_average = True
                requested_items = int(requested_items.lstrip("avg"))

                # get only last items for rate from memory
                #   and compare to latest value
                last_items = memory[-requested_items:]

                rate_lower_limit = rate_options.get("lower_limit")
                rate_upper_limit = rate_options.get("upper_limit")

                if use_average:
                    rate_of_change_over_items = \
                        get_average_rate_of_change_over_x(last_items, value)
                    rate_string.append("avgroc{}@{}%".format(
                        requested_items, round(rate_of_change_over_items, 2)))
                else:
                    rate_of_change_over_items = \
                        get_rate_of_change_over_x(last_items, value)
                    rate_string.append("roc{}@{}%".format(
                        requested_items, round(rate_of_change_over_items, 2)))
                if alert_on_limit_range(
                        rate_of_change_over_items,
                        rate_lower_limit,
                        rate_upper_limit,
                        stock_name):
                    send_alarm = True

            print("{} @{} {}".format(
                stock_name,
                round(value, 2),
                " ".join(rate_string)), file=sys.stderr)

            if send_alarm:
                break

            memory.append(value)

        if send_alarm:
            sys.exit(1)
        time.sleep(args.sleep)


def alert_on_limit_range(value, lower_limit, upper_limit, name):
    if value <= lower_limit or value >= upper_limit:
        print("{} reached alert limit @{}".format(
            name,
            value), file=sys.stderr)
        return True
    return False


def get_average_rate_of_change_over_x(items, new_value):
    if len(items) == 0:
        return 0
    # average rate
    memory_average = get_average(items)
    difference_of_change_over_average = new_value - memory_average
    return (difference_of_change_over_average
            / memory_average) * Decimal("100")


def get_rate_of_change_over_x(items, new_value):
    if len(items) == 0:
        return 0
    # rate of last value and first in memory
    first_memory = items[0]
    difference_of_change = new_value - first_memory
    return (difference_of_change / first_memory) * Decimal("100")


def get_average(values):
    return sum(values)/len(values)


def parse_args():
    import argparse
    parser = argparse.ArgumentParser(
            description="Stock price alert.",
            epilog="Epilog of program.",
            add_help=True
            )
    # positional arguments
    parser.add_argument("symbol", help="stock symbol from yahoo finance")

    # required
    parser.add_argument(
            "--alert-range",
            help="range to alert eg. '30:80', exit if <=30 and >=80",
            required=True,
            action="store")

    # allow rate of change alerts
    parser.add_argument(
        '--roc',
        help="Rate of change example \
'5=-3:10'  \
or 'avg5=-3:10' for average rate \
# use last 5 items and alert if in range of -3% to 10%",
        nargs='*',
    )

    # optional arguments
    parser.add_argument(
            "--url",
            nargs='?',
            help="url to query stock prices from(expects yahoo finance)",
            metavar="api_url")
    parser.add_argument(
            "--sleep",
            nargs='?',
            help="sleep time until next query",
            default=5, type=int,
            metavar="seconds")

    return parser.parse_args()


def usage():
    pass


if __name__ == "__main__":
    main()
