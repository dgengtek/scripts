#!/usr/bin/env bash
# vim wrapper for editing multiple files from input
xargs bash -c '</dev/tty vim "$@"' ignoreme
