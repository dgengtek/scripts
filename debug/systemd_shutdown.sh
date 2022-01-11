#!/bin/env bash
# remember to boot with following kernel options before running this script
#   systemd.log_level=debug systemd.log_target=kmsg log_buf_len=1M printk.devkmsg=on enforcing=0
# move this script to 
#   /usr/lib/systemd/system-shutdown/debug.sh
[[ $UID != 0 ]] && echo "Requires root permissions to run." >&2 && exit 1

systemd_shutdown_path=/usr/lib/systemd/system-shutdown
script="$systemd_shutdown_path/debug.sh"
cat > "$script"<< EOF
#!/bin/env sh
mount -o remount,rw /
dmesg > /systemd_shutdown.log
mount -o remount,ro /
EOF
chmod +x "$script"
