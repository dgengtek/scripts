#!/usr/bin/env bash

usage() {
	cat >&2 <<EOF
Usage: ${0##*/}
display host information
EOF
}

main() {
	printf "CPU: "
	grep "model name" /proc/cpuinfo | head -1 | awk '{ for (i = 4; i <= NF;i++) printf "%s ", $i }'
	echo
	cat /etc/issue
	uname -a | awk '{ printf "Kernel: %s " , $3 }'
	uname -m | awk '{ printf "%s | " , $1 }'
	echo
	uptime | awk '{ printf "Uptime: %s %s %s", $3, $4, $5 }' | sed 's/,//g'
	echo
	sensors | grep Core | head -1 | awk '{ printf "%s %s %s\n", $1, $2, $3 }'
	sensors | grep Core | tail -1 | awk '{ printf "%s %s %s\n", $1, $2, $3 }'
	[ -d /sys/firmware/efi/efivars ] && echo "UEFI" || echo "Legacy"
	#cputemp | awk '{ printf "%s %s", $1 $2 }'
	# system_info
	w
	who -a
	# hddtable
	sfdisk -l
	# block_devices
	lsblk -f
	# fs_usage
	df -h
	# lv_info
	lvdisplay -m
	# processes
	pstree -aclup
	# mounts
	mount
	# pci_devices
	lspci
	# drivers in use
	lspci -nnk
	# hardware
	lshw
	# scheduled_jobs
	crontab -u root -l
	# iptables.rules
	iptables-save
	# services
	systemctl --all
	# service_units
	systemctl list-unit-files
	# listening_ports
	ss -snatpl
	# network
	ip addr
	# routes.dump
	ip route save
	# routes
	ip route list table all
	sysctl -a
	# logins disabled?
	ls -l /var/run/nologin /etc/nologin
	# hardware unique address
	sudo cat /sys/class/dmi/id/product_uuid
	# max supported files
	cat /proc/sys/fs/file-max
	# show irqs
	cat /proc/interrupts

	# report processor related statistics for all processors
	mpstat -P all
	# get last fsck for each mounted filesystem
	mount -l | egrep 'type ext(2|3|4)' | awk '{print $1}' | xargs -I {} bash -c 'echo -n "{} ==> "; sudo tune2fs -l {} | grep checked'
	# get all mounted filesystems
	mount -l | egrep 'type ext(2|3|4)' | awk '{print $1}'

	# is nested virtualization supported?
	cat /sys/module/kvm_intel/parameters/nested /sys/module/kvm_amd/parameters/nested

	# get list of deleted files in use
	lsof -nP | rg '(deleted)'

}

main "$@"
