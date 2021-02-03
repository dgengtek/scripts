#!/usr/bin/env python3
import requests
import sys
import time

# symbols sep by ','
STOCK_API_URL = "https://query1.finance.yahoo.com/v7/finance/quote?lang=en-US&region=US&corsDomain=finance.yahoo.com&symbols={symbol}"

STOCK_KEYS = [
    "regularMarketPrice",
    "postMarketPrice",
    ]

# symbols to watch
SYMBOLS = [
        "GME",
        ]


def main():
    args = parse_args()
    symbol = args.symbol
    api_url = args.url
    if not api_url:
        api_url = STOCK_API_URL.format(symbol=symbol)
    else:
        api_url = api_url.format(symbol=symbol)
    
    while True:
        r = requests.get(api_url)
        data = r.json().get("quoteResponse")
        response_error = data.get("error")
        if response_error:
            print("Error in response: {}".format(response_error))
            sys.exit(1)
        data = data.get("result")
        send_alarm = False
        for r in data:
            for k in STOCK_KEYS:
                value = r.get(k)
                if value >= args.alert_range:
                    print("{} reached alarm limit @{} {}".format(
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
            help="required value store",
            required=True,
            type=int,
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
