#!/bin/bash
deploy() {
  path="$1"
  shift 1
  for f in $@; do
    cp -v "$f" "$path"
  done
}
set -e

OLDIFS=$IFS
IFS=$(echo -en "\n\b")

cfg_files=$(ls ../services/*.cfg)

IFS=$OLDIFS

service_template="dcon@"
echo "Deploy service template ${service_template}.service"
cp "${service_template}.service" "/etc/systemd/system/"
echo "Deploy service cfg's"
deploy "/usr/local/etc/" "$cfg_files"

echo "Enable services"
for s in $cfg_files; do
  s=$(basename -s .cfg $s) 
  echo "Enable service for $s"
  systemctl enable "${service_template}${s}.service"
done
