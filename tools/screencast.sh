#!/bin/env bash
# need to start pavucontrol after running to change recording device to monitor
# to record audio
filename=""
if [ -z $1 ]; then
  filename="${dates}output.mkv"
else
  filename=$1
fi
dates=$(date +%d%m%H%M)
screen_dev="DVI-0"
time_limit="-t hh:mm::ss"
res=$(xrandr | grep $screen_dev | cut -f 4 -d " " | cut -f 1 -d "+")
screen=":0.0+0,0"
audio="-f alsa -ac 2 -i pulse -codec:a pcm_s16le"
ffmpeg -video_size "$res" -framerate 25 -f x11grab -i "$screen" \
  $audio \
  -codec:v libx264 \
  -preset ultrafast \
  -qp 0 \
  "$filename"
