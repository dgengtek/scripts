#!/bin/env bash
find "$1" -xtype l -print0 | xargs -0 rm -v
