#!/bin/bash

extension=""
outputfile=""
outputDir="convertedMP3s"
output=""


if ! [ -d $outputDir ]; then
  mkdir $outputDir
fi

function cleanup() {
  echo -en "\ncatched SIGINT, remove $output"
  rm $output
}



trap cleanup INT

OLDIFS=$IFS
IFS=$(echo -en "\n\b")

for file in $(ls -1); do
  outputfile=${file%.*}
  output="$outputDir/$outputfile.mp3"
  if [ -f "$file" ] && ! [ -e "$output" ]; then
    extension=${file##*.}
    if [ "$extension" = mp4 ] \
      || [ "$extension" = mkv ]	\
      || [ "$extension" = flv ]; then
    echo "converting - $file to mp3"
    ffmpeg -i "$file" -acodec mp3 -vn "$output"
  fi
else
  echo "SKIPPING - $outputfile already exists or not a file"
fi
done
IFS=$OLDIFS
