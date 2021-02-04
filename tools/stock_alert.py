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

    limits = args.alert_range.split("-")
    if len(limits) != 2:
        print(
            "Alert range must be noted within a single '-' \
like 15-45. Input: {}".format(args.alert_range),
            file=sys.stderr)
        sys.exit(1)

    lower_limit = Decimal(limits[0])
    upper_limit = Decimal(limits[1])

    retries = 0
    max_retries = 10

    while True:
        if max_retries >= 10:
            print("Maximum retries reached. Aborting now.", file=sys.stderr)
            sys.exit(1)

        try:
            r = requests.get(api_url)
        except (OSError, requests.ConnectionError, requests.ConnectTimeout):
            retries += 1
            time.sleep(3)

        retries = 0

        data = r.json().get("quoteResponse")
        response_error = data.get("error")
        if response_error:
            print(
                "Error in response: {}".format(response_error),
                file=sys.stderr)
            sys.exit(1)
        data = data.get("result")
        send_alarm = False
        for r in data:
            for k in STOCK_KEYS:
                value = r.get(k, "")
                if value == "":
                    continue

                if value <= lower_limit or value >= upper_limit:
                    print("{} reached alert limit @{} {}".format(
                        r.get("longName"),
                        value,
                        k), file=sys.stderr)
                    send_alarm = True
                else:
                    print("{} @{} {}".format(
                        r.get("longName"),
                        value,
                        k), file=sys.stderr)

        if send_alarm:
            sys.exit(1)
        time.sleep(args.sleep)


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
            help="range to alert eg. 30-80, exit if <=30 and >=80",
            required=True,
            action="store")

    # optional arguments
    parser.add_argument(
            "--url",
            nargs='?',
            help="optional value with different metavar",
            metavar="api_url")
    parser.add_argument(
            "--sleep",
            nargs='?',
            help="optional value with different metavar",
            default=5, type=int,
            metavar="seconds")

    return parser.parse_args()


def usage():
    pass


if __name__ == "__main__":
    main()
