#!/usr/bin/env python3

import bs4
import urllib.request
import sys


if len(sys.argv) != 2:
    print("URL is required.", file=sys.stderr)
    sys.exit(1)

print(bs4.BeautifulSoup(
    urllib.request.urlopen(sys.argv[1]),
    features="html5lib").title.text)
