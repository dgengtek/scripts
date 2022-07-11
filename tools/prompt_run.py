#!/usr/bin/env python3
"""
run the input args as a prefix command in a prompt which uses the user input as
args for the prefix command for execution
"""
import logging
import sys
import argparse
import atexit
import signal
import subprocess
import os
import shlex
import re
logger = logging.getLogger(__name__)


def main():
    atexit.register(cleanup, "Cleanup before exit")
    signal.signal(signal.SIGALRM, handler)

    args = parse_args()
    print(args)
    enable_formatting = args.format
    args = args.args
    if not args:
        die("Arguments for the prefix to execute are required")

    if enable_formatting:
        template = TemplatePrompt.check_valid(list(args))

    while True:
        if enable_formatting:
            call_args = template.get_call_args()
        else:
            call_args = list(args)
            user_input = simple_prompt(" ".join(args))
            if user_input is True:
                continue
            call_args.extend(shlex.split(user_input))

        subprocess.call(call_args)


class TemplatePrompt():
    def __init__(self, pattern, template_strings):
        self.pattern = pattern
        self.template_strings = list(template_strings)
        self.template_string = " ".join(self.template_strings)
        self.result = self.findall()
        self.count = len(self.result)

    def prompt(self):
        raise NotImplementedError()

    def findall(self):
        return re.findall(self.pattern, self.template_string)

    def is_valid(self):
        return self.count > 0

    def format(self, user_data):
        raise NotImplementedError()

    def get_call_args(self):
        prerr(self.template_string)
        user_data = self.prompt()
        result = self.format(user_data)
        return shlex.split(result)

    @classmethod
    def check_valid(cls, template_strings):
        template_pos = TemplatePromptPos(template_strings)
        template_keys = TemplatePromptKeys(template_strings)

        pos_valid = template_pos.is_valid()
        keys_valid = template_keys.is_valid()
        if (pos_valid and keys_valid) or (not pos_valid and not keys_valid):
            raise FormatException("Unable to proceed with given template string. Keys: {}, Pos: {}".format(template_keys.count, template_pos.count))

        template = template_pos
        if template.is_valid():
            return template
        template = template_keys
        if template.is_valid():
            return template


class TemplatePromptPos(TemplatePrompt):
    def __init__(self, template_strings):
        pattern = re.compile(r"{}")
        super().__init__(pattern, template_strings)

    def prompt(self):
        data = []
        count = list(reversed(range(self.count)))
        while count:
            i = count.pop()
            user_input = simple_prompt("Pos {}".format(i))
            if not user_input:
                prerr("Input for {} is empty. Repeat".format(i))
                count.append(i)
                continue
            data.append(user_input)
        return data

    def format(self, user_data):
        return self.template_string.format(*user_data)


class TemplatePromptKeys(TemplatePrompt):
    def __init__(self, template_strings):
        pattern = re.compile(r"{(.[^{}]*)}")
        super().__init__(pattern, template_strings)

    def prompt(self):
        data = {}
        count = list(reversed(self.result))
        while count:
            k = count.pop()
            user_input = simple_prompt("Key {}".format(k))
            if not user_input:
                prerr("Input for {} is empty. Repeat".format(k))
                count.append(k)
                continue
            data.update({k: user_input})
        return data

    def format(self, user_data):
        return self.template_string.format(**user_data)


def simple_prompt(prompt_prefix):
    try:
        user_input = input("{} > ".format(prompt_prefix))
    except EOFError:
        sys.exit(0)
    except KeyboardInterrupt:
        print()
        return True
    return user_input


def usage():
    """
    usage method for help
    """


def parse_args():
    """
    parse arguments and return result
    """
    parser = argparse.ArgumentParser(
            description="Program description.",
            epilog="Epilog of program.",
            add_help=True
            )

    parser.add_argument(
        'args',
        nargs=argparse.REMAINDER)

    parser.add_argument(
            "-f", "--format",
            help="format the input string either with key=value key2=value or positional with space delimiter $1 $2 provided in the prompt",
            action="store_true")

    return parser.parse_args()


def cleanup(description):
    # prerr(description)
    pass


def handler(signum, frame):
    print('Signal handler called with signal', signum, file=sys.stderr)


def prerr(msg):
    print(msg, file=sys.stderr)


def die(msg, exit_code=1):
    print(msg, file=sys.stderr)
    sys.exit(exit_code)


def check_env(var):
    res = os.environ.get(var)
    if res is None:
        prerr("env '{}' is not set".format(var))
    elif res == "":
        prerr("env '{}' is empty".format(var))
    else:
        return True
    return False


class FormatException(Exception):
    pass


if __name__ == "__main__":
    main()
