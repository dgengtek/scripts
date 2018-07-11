#!/usr/bin/env bash

cd /etc/openvpn || exit
echo -e "Start openvpn WLANFB02\n"
sudo openvpn wlanfb02.conf
