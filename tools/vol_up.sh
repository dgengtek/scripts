#!/bin/env bash

amixer -D hw:0 -s -q << EOF
set Master 10%+ 
set Headphone 10%+ 
set Front 10%+ 
EOF

