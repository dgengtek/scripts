#!/bin/env bash
declare -i break_loop=0
catch_signal() {
  let break_loop=1
}
trap catch_signal SIGINT SIGHUP SIGKILL


screen="DVI-0"
# in s
time_delay="0.1"
prefix="/image_"
suffix="png"
delay="20"

size=$(xrandr | grep $screen | cut -f 3 -d " ")

frames_dir=$(mktemp -d)
declare -i nr=1
while ((break_loop == 0)); do
  filename=$(printf '%s%s%09d.%s\n' ${frames_dir} "$prefix" ${nr} ${suffix})
  import -window root -crop $size $filename
  nr=$((nr+1))
  sleep $time_delay
done


echo "Convert images to gif"
convert -delay $delay -loop 0 ${frames_dir}/${prefix}*.$suffix output.gif

rm -rf $frames_dir

