#!/bin/env sh
# remember to boot with following kernel options before running this script
#   systemd.log_level=debug systemd.log_target=kmsg log_buf_len=1M printk.devkmsg=on enforcing=0
mount -o remount,rw /
dmesg > /systemd_shutdown.log
mount -o remount,ro /
