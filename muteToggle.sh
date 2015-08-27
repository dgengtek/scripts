#!/bin/bash

amixer -D hw:0 -s -q << EOF
sset Master toggle 
sset Headphone toggle 
sset Front toggle 
EOF

