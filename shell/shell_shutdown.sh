#!/bin/bash
host=$(hostname)
mailto="admin"
msg="Done by: $(id)\n$(date)"
logger -s -t "$0" "$msg"
echo -e "$msg" | mail -s "Shutdown of $host" "$mailto"
shutdown -h now
