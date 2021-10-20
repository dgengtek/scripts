#!/usr/bin/env bash
# https://trac.ffmpeg.org/wiki/EncodingForStreamingSites

# stream without scaling output 
# ffmpeg -f alsa -ac 2 -i hw:0,0 -f x11grab -framerate 30 -video_size 1280x720 \
# -i :0.0+0,0 -c:v libx264 -preset veryfast -b:v 1984k -maxrate 1984k -bufsize 3968k \
# -vf "format=yuv420p" -g 60 -c:a aac -b:a 128k -ar 44100 \
# -f flv rtmp://live.twitch.tv/app/<stream key>

# with webcam overlay picture in picture, webcam overlay in top right
# ffmpeg -f x11grab -video_size 1680x1050 -framerate 30 -i :0.0 \
# -f v4l2 -video_size 320x240 -framerate 30 -i /dev/video0 \
# -f alsa -ac 2 -i hw:0,0 -filter_complex \
# "[0:v]scale=1024:-1,setpts=PTS-STARTPTS[bg]; \
 # [1:v]scale=120:-1,setpts=PTS-STARTPTS[fg]; \
 # [bg][fg]overlay=W-w-10:10,format=yuv420p[v]"
# -map "[v]" -map 2:a -c:v libx264 -preset veryfast \
# -b:v 3000k -maxrate 3000k -bufsize 4000k -c:a aac -b:a 160k -ar 44100 \
# -f flv rtmp://live.twitch.tv/app/<stream key>


# With webcam overlay and logo
# This will place your webcam overlay in the top right, and a logo in the bottom left:

# ffmpeg -f x11grab -video_size 1680x1050 -framerate 30 -i :0.0 \
# -f v4l2 -video_size 320x240 -framerate 30 -i /dev/video0 \
# -f alsa -ac 2 -i hw:0,0 -i logo.png -filter_complex \
# "[0:v]scale=1024:-1,setpts=PTS-STARTPTS[bg]; \
 # [1:v]scale=120:-1,setpts=PTS-STARTPTS[fg]; \
 # [bg][fg]overlay=W-w-10:10[bg2]; \
 # [bg2][3:v]overlay=W-w-10:H-h-10,format=yuv420p[v]"
# -map "[v]" -map 2:a -c:v libx264 -preset veryfast \
# -maxrate 3000k -bufsize 4000k -c:a aac -b:a 160k -ar 44100 \
# -f flv rtmp://live.twitch.tv/app/<stream key>



# Streaming a file

# ffmpeg -re -i input.mkv -c:v libx264 -preset veryfast -b:v 3000k -maxrate 3000k \
# -bufsize 6000k -pix_fmt yuv420p -g 50 -c:a aac -b:a 160k -ac 2 \
# -ar 44100 -f flv rtmp://live.twitch.tv/app/<stream key>


# Encoding a file for streaming

# If your computer is too slow to encode the file on-the-fly like the example above then you can re-encode it first:
# ffmpeg -i input.mkv -c:v libx264 -preset medium -b:v 3000k -maxrate 3000k -bufsize 6000k \
# -vf "scale=1280:-1,format=yuv420p" -g 50 -c:a aac -b:a 128k -ac 2 -ar 44100 file.flv

# Then stream copy it to the streaming service:
# ffmpeg -re -i file.flv -c copy -f flv rtmp://live.twitch.tv/app/<stream key>


# only video
# ffmpeg -f v4l2 -framerate 30 -video_size 1920x1080 -input_format mjpeg -i /dev/video0 -c copy output1.mkv
# audio and video
# ffmpeg -f v4l2 -input_format mjpeg -i /dev/video0 -f alsa -i hw:0 -pix_fmt mediacodec -level:v 4.1 -preset ultrafast -tune zerolatency -r 30 -b:v 128k -s 1920x1080 -strict -2 -ac 2 -ab 32k -ar 44100 -c copy output.mkv

if [[ -z "$1" ]]; then
  echo "output path required" >&2
  exit 1
fi

get_next_filename() {
  local filename=$1
  let count=1
  local new_filename="${filename}-${count}.mkv"
  while :; do
    if ! test -f "${new_filename}"; then
      break
    fi
    let count="$count + 1"
    new_filename="${filename}-${count}.mkv"
  done
  echo "$new_filename"
}

readonly name="${1}_$(date '+%Y%m%d')"
readonly filename=$(get_next_filename "$name")

echo "writing to \"${filename}\""

ffmpeg -f v4l2 -input_format mjpeg -thread_queue_size 32 \
  -i /dev/video0 \
  -f alsa -i sysdefault:CARD=Camcra \
  -pix_fmt mediacodec -level:v 4.1 -preset ultrafast -tune zerolatency \
  -b:v 1800k -s 1920x1080 -framerate 25 -g 50 \
  -ac 2 -ab 32k -ar 44100 \
  -maxrate 1800k -bufsize 1800k \
  -c copy \
  "${filename}"
