#!/usr/bin/env bash
# vim wrapper for editing multiple files from input
[[ -z "$1" ]] && exit 0
xargs "$@" bash -c '</dev/tty vim "$@"' ignoreme
