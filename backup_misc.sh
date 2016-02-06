#!/bin/bash
#todo: cleanup

source /home/gd/bin/bash/lib/libbackup_base.sh "$@"
#add backup local bash script binaries

# updateVars "gd/STUDIUM"
# syncthis "/mnt/hdd/bigX/gd/STUDIUM"
backupCmd "gd/STUDIUM" "/mnt/hdd/bigX/gd/STUDIUM"

#updateVars "gd/documents"
#syncthis .
backupCmd "gd/documents" "/mnt/hdd/bigX/gd/Documents"

# updateVars "hdd_sidekick/e-books"
# syncthis "/mnt/hdd/bigX/e-books"
backupCmd "hdd_sidekick/e-books" "/mnt/hdd/bigX/e-books"

# updateVars "hdd_sidekick/programming"
# syncthis "/mnt/hdd/bigX/a_Programmieren"
backupCmd "hdd_sidekick/programming" "/mnt/hdd/bigX/a_Programmieren"

# updateVars "gd/music"
# syncthis "/mnt/hdd/bigX/gd/Music"
backupCmd "gd/music" "/mnt/hdd/bigX/gd/Music"

# updateVars "gd/pictures"
# syncthis "/mnt/hdd/bigX/gd/pictures"
backupCmd "gd/pictures" "/mnt/hdd/bigX/gd/pictures"

# updateVars "gd/recordings"
# syncthis "/mnt/hdd/bigX/gd/recordings"
backupCmd "gd/recordings" "/mnt/hdd/bigX/gd/recordings"

# updateVars "gd/priv"
# syncthis "/mnt/hdd/bigX/gd/priv"
backupCmd "gd/priv" "/mnt/hdd/bigX/gd/priv"

printMessage "Done personal files backup"
