#!/bin/bash

defaultGateway=$(ip route|cut -d " "  -f 3|grep 192)
echo $defaultGateway


