#!/usr/bin/env bash
main() {
  local -a commands=(
  "white_balance_temperature_auto=1"
  "power_line_frequency=0"
  "exposure_auto=3"
  "exposure_auto_priority=1"
  "focus_auto=0"
)
  local options_string=""
  for cmd in "${commands[@]}"; do
    options_string+=" --set-ctrl=$cmd"
  done
  v4l2-ctl --set-fmt-video=width=1600,height=896,pixelformat=MJPG
  #v4l2-ctl --set-fmt-video-out "width=1600,height=896,pixelformat=MJPG,hsv=256,quantization=default"
  v4l2-ctl $options_string
}
main "$@"
