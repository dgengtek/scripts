#!/bin/bash
device=$1
ip link set dev "$device" down
macchanger -r "$device"
ip link set dev "$device" up
dhcpcd -k "$device" && dhcpcd "$device"
