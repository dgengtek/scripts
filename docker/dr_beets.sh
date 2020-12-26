#!/usr/bin/env bash
readonly config_plugins="/tmp/config_beets_plugins.yaml"
cat > "$config_plugins" << EOF
plugins:
  - chroma
  - lastgenre
  - convert
EOF

sudo docker run \
  --rm \
  -it \
  --name "beets" \
  --mount type=bind\
,source="$HOME/.config/beets/config.yaml"\
,destination=/home/beetu/.config/beets/config.yaml,readonly \
  --mount type=bind\
,source="$HOME/.config/beets/state.pickle"\
,destination=/home/beetu/.config/beets/state.pickle \
  --mount type=bind\
,source="$config_plugins"\
,destination=/home/beetu/.config/beets/plugins_config.yaml,readonly \
  --mount type=bind\
,source=/mnt/nfs/homes/dgeng/music\
,destination=/oldmusic,readonly \
  --mount type=bind\
,source=/mnt/hdd/bigX/unsorted/beets\
,destination=/mnt/hdd/bigX/unsorted/beets\
  beets --config "/home/beetu/.config/beets/plugins_config.yaml" "$@"
