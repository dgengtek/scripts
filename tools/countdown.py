#!/usr/bin/env python3
"""
Not used anymore. Install from own pycount project

Usage:
    countdown.py [options] [<unit>]

Simple countdown

<unit>  default unit is seconds

Options:
    -m, --minute  count as minutes
    -h, --hour  count as hour

"""

import sys
from docopt import docopt
import logging
import time
import itertools
import functools
import pytest
import threading
import copy

# docopt(doc, argv=None, help=True, version=None, options_first=False))

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)


class Countdown:
    def __init__(self):
        self.__hour = 0
        self.__minute = 0
        self.__second = 0
        self._seconds = 0

    def _normalize_from_seconds(self):
        second = _get_second(self.seconds)
        minutes = _get_minutes(self.seconds)
        minute = _get_minute(minutes)
        hour = _get_hours(minutes)

        self.__hour = hour
        self.__minute = minute
        self.__second = second

    def _normalize_to_seconds(self):
        minutes = self.__hour * 60 + self.__minute
        self.seconds = minutes * 60 + self.__second

    def sync(self):
        self._normalize_from_seconds()

    def __str__(self):
        return "{:02}:{:02}:{:02}".format(self.__hour, self.__minute, self.__second)

    @property
    def __hour(self):
        """The hour property."""
        return self.___hour

    @__hour.setter
    def __hour(self, value):
        self.___hour = value

    @property
    def __minute(self):
        """The minute property."""
        return self.___minute

    @__minute.setter
    def __minute(self, value):
        self.___minute = value

    @property
    def __second(self):
        """The second property."""
        return self.___second

    @__second.setter
    def __second(self, value):
        self.___second = value

    @property
    def seconds(self):
        """The seconds property."""
        return self._seconds

    @seconds.setter
    def seconds(self, value):
        self._seconds = value
        self.sync()

    @seconds.deleter
    def seconds(self):
        del self._seconds

    @classmethod
    def from_seconds(cls, seconds):
        cd = cls()
        cd.seconds = seconds
        cd.sync()
        return cd

    @classmethod
    def from_minutes(cls, minutes):
        return cls.from_seconds(minutes * 60)

    @classmethod
    def from_hours(cls, hours):
        return cls.from_minutes(hours * 60)

    @classmethod
    def from_timestamp(cls, hour, minute, second):
        minutes = minute + hour * 60
        seconds = second + minutes * 60
        return cls.from_seconds(seconds)

    @classmethod
    def from_string(cls, string):
        """
        Expecting string in form of HH:MM:SS
        """
        timestamp = string.split(":")
        return cls.from_timestamp(
            timestamp[0],
            timestamp[1],
            timestamp[2],
        )

    def __eq__(self, cd2):
        return (
            self.__hour == cd2.__hour
            and self.__minute == cd2.__minute
            and self.__second == cd2.__second
        )


class Counter(threading.Thread):
    def __init__(self, countdown, delay=1, *args, **kwargs):
        threading.Thread.__init__(self, **kwargs)
        self.countdown = countdown
        self.name = "Counter of countdown: {}".format(self.countdown)
        self.__initial_seconds = self.countdown.seconds
        self._lock = threading.Lock()
        self.running = False
        self.finished = False
        self.paused = False
        self.pause_condition = threading.Condition(threading.Lock())
        self.exit_flag = threading.Event()
        self.__DELAY = delay

    def run(self):
        self.running = True
        while self:
            with self.pause_condition:
                while self.paused:
                    self.pause_condition.wait()
            if self._count():
                self.running = False
                break
            print("\r{}".format(self.countdown), end="", file=sys.stderr)
            self.exit_flag.wait(timeout=self.__DELAY)

        print()

    def pause(self):
        self.paused = True
        self.pause_condition.acquire()

    def resume(self):
        self.paused = False
        self.pause_condition.notify()
        self.pause_condition.release()

    def __bool__(self):
        return self.running

    def __call__(self):
        if self:
            self.stop()
        else:
            self.start()

    def _count(self, counter=1):
        if not self.countdown.seconds:
            self.finished = True
        else:
            self._lock.acquire()
            self.countdown.seconds -= counter
            self.countdown.sync()
            self._lock.release()

        return self.finished

    def stop(self):
        self.running = False
        self.finished = True
        self.exit_flag.set()
        self.join()

    def wait(self):
        self.join()

    def reset(self):
        self.countdown.seconds = self.__initial_seconds

    def restart(self):
        self.pause()
        self.reset()
        self.resume()

    def __str__(self):
        pass


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
    # print(opt)
    unit = opt.get("<unit>")
    counter = None
    if not unit:
        print(__doc__)
        sys.exit(1)

    countdown_from = Countdown.from_seconds
    if opt.get("--minute"):
        countdown_from = Countdown.from_minutes
    if opt.get("--hour"):
        countdown_from = Countdown.from_hours

    countdown = countdown_from(int(unit))

    try:
        counter = Counter(countdown)
        counter()
        counter.wait()
    except Exception as e:
        logger.error(e)
        counter.stop()
        sys.exit(1)
    except KeyboardInterrupt:
        print("\nbye", file=sys.stderr, end="")
        counter.stop()
        sys.exit(127)


@pytest.mark.parametrize(
    "seconds, expected",
    [
        (1, (0, 0, 1)),
        (59, (0, 0, 59)),
        (61, (0, 1, 1)),
        (121, (0, 2, 1)),
        (299, (0, 4, 59)),
        (300, (0, 5, 0)),
        (301, (0, 5, 1)),
        (3599, (0, 59, 59)),
        (3600, (1, 0, 0)),
        (3601, (1, 0, 1)),
        (3661, (1, 1, 1)),
    ],
)
def test_countdown_convert_from_seconds(seconds, expected):
    cd = Countdown.from_seconds(seconds)
    cdexpected = Countdown.from_timestamp(*expected)
    assert cd == cdexpected


def test_countdown_timer_string():
    cd = Countdown.from_seconds(1)
    assert str(cd) == "00:00:01"
    cd = Countdown.from_seconds(61)
    assert str(cd) == "00:01:01"
    cd = Countdown.from_seconds(3600)
    assert str(cd) == "01:00:00"
    cd = Countdown.from_seconds(3661)
    assert str(cd) == "01:01:01"
    cd = Countdown.from_seconds(360000)
    assert str(cd) == "100:00:00"


if __name__ == "__main__":
    main()
