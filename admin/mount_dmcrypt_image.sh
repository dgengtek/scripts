#!/usr/bin/env bash
# script mounts a dm-crypt image
#   and adds a transient service for cleanup on shutdown
#   cleanup ensures that even if the image is located on network share
#   that the shutdown will not be blocked

main() {
  readonly filename=${1:?Path to raw image is required}
  readonly mount_path=${2:-"${HOME}/mnt/private"}
  readonly crypt_device_name=${CRYPT_DEVICE_NAME:-"dgengprivate"}
  readonly service_umount="private_image_${USER}.service"
  readonly path_systemd_transient_service="/run/systemd/transient/"

  set -eu
  if ! test -f "$filename"; then
    echo "$filename is not a file or does not exist" >&2 
    exit 1
  fi
  if ! test -d "$mount_path"; then
    echo "$mount_path is not a directory or does not exist" >&2 
    exit 1
  fi

  readonly loop_device=$(sudo losetup -f --show "${filename}")

  if ! sudo cryptsetup \
          --cipher=aes-xts-plain64 \
          --offset=0 \
          --key-size=512 \
          open --type plain "$loop_device" "$crypt_device_name"; then
    
    echo "Unable to decrypt $crypt_device_name. Cleaning up loop device." >&2
    sudo losetup -d "$loop_device" 
    exit 1
  fi
  if ! sudo mount "/dev/mapper/$crypt_device_name" "$mount_path"; then
    sudo cryptsetup close "$crypt_device_name"
    sudo losetup -d "$loop_device" 
  fi

  # prepare mountpoint dependencies for shutdown cleanup
  local image_parent_mountpoint=$(realpath -e "$filename")
  image_parent_mountpoint=$(print_parent_mountpoint "$image_parent_mountpoint")
  local -r systemd_image_mountpoint=$(systemd-escape --path --suffix=mount "$image_parent_mountpoint")
  local -r systemd_device_mountpoint=$(systemd-escape --path --suffix=mount "$mount_path")

  sudo tee "${path_systemd_transient_service}/${service_umount}" >&/dev/null << EOF
[Unit]
Description=Cleanup encrypted mounted file for $USER
Before=shutdown.target multi-user.target
Conflicts=shutdown.target
Requires=sysinit.target
After=network.target nfs-client.target remote-fs.target local-fs.target sysinit.target $systemd_image_mountpoint $systemd_device_mountpoint
DefaultDependencies=no

[Service]
Type=oneshot
ExecStop=umount /dev/mapper/$crypt_device_name
ExecStop=cryptsetup close $crypt_device_name
ExecStop=losetup -d $loop_device
RemainAfterExit=yes

[Install]
WantedBy=multi-user.target
EOF

  sudo systemctl daemon-reload
  sudo systemctl start "$service_umount"
}

print_parent_mountpoint() {
  local directory=${1:?No directory given}
  while ! mountpoint "$directory" >&/dev/null; do
    directory=$(dirname "$directory")
  done
  echo -n "$directory"
}


main "$@"
