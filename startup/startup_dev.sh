#!/usr/bin/env bash
exec 2>&1
exec 1>/dev/null
systemctl start libvirtd virtlogd virtlockd docker
shorewall reload
