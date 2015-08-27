#!/bin/bash

#add backup local bash script binaries
input="$1"

. /home/gd/bin/bash/backup_Arch.sh $input
. /home/gd/bin/bash/backup_gdA.sh $input
. /home/gd/bin/bash/backup_misc.sh $input
