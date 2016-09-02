#!/bin/bash
mkvfilename=$(mktemp -u /tmp/tmp.XXXXXXXXX.mkv)
sh screencast.sh "$mkvfilename"
# make frames
frames_dir=$(mktemp -d)
ffmpeg -i $mkvfilename -vf scale=320:-1:flags=lanczos,fps=10 \
  ${frames_dir}/ffout%03d.png
convert -loop 0 ${frames_dir}/ffout*.png output.gif

rm $mkvfilename
rm -rf $frames_dir

