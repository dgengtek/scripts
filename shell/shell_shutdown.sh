#!/bin/bash
host=$(hostname)
mailto="admin@geng.noip.me"
echo -e "Done by: $(id)\n$(date)" | mail -s "Shutdown of $host" "$mailto"
shutdown -h now
