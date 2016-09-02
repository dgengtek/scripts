#!/bin/bash
# TODO: create new images with install by pxe or urls

usage() {
  echo -e "\n${0##*/} [options] domainname diskpath [virt-install options]..."
  echo -e "\noptions:"
  echo -e "  -h,\t\tuse host arch"
  echo -e "  -o os,\tuse specified os"
  echo -e "  -n network,\tattach to network"
  echo -e "  -c cpus,\tnr or cpus, less than host"
  echo -e "  -p pool,\tuse pool name"
  echo -e "  -s size,\tcreate size in GiB"
  exit 1
}

main() {
  local name=""
  local disk_path=""
  local cpus=1
  local network_name="default"
  local disk_size="2"
  local pool_name="images"
  local os="centos7.0"

  optlist=":oc:n:hs:p:"
  local -i use_backing_store=0
  local -i use_host_arch=0
  while getopts $optlist opt; do
    case $opt in 
      s)
      	size=$OPTARG
	;;
      p)
      	pool_name=$OPTARG
	;;
      o)
      	os=$OPTARG
	;;
      c)
	cpus=$OPTARG
	;;
      n)
	network_name=$OPTARG
	;;
      h)
	use_host_arch=1
	;;
      *)
	usage
	;;
    esac
  done
  shift $((OPTIND - 1))
  if [[ $# < 2 ]]; then
    usage
  fi
  local name="$1"
  local memory=256
  local arch="--arch i386"
  #local arch="--arch x86_64"
  if [[ $use_host_arch == 1 ]]; then
    arch=""
  fi
  # qemu
  #local virtualization=" --hvm"
  # xen
  #local virtualization=" --paravirt"
  #local virtualization=" --virt-type qemu"


  ########## disk ##########
  # either use disk_path to import
  # or backing store and label to make new snap

  disk_path="$(pwd)/${2##*/}"
  local disk_format="qcow2"
# is in GiB

  local disk_options=" --disk"
  disk_options+=" path=$disk_path"
  #disk_options+="pool=$pool_name,size=$disk_size"
  #disk_options+="pool=$pool_name"

  ########## network ##########
  local network_options=" --network"
  network_options+=" network=$network_name"

  ########## graphics ##########
  local graphics_type="vnc"
#  local graphics_type="none"

  # port to assing for vnc connections
  #local graphics_port=55111
  # password for vnc connections

  local graphics_password=""
  local graphics_options=" --graphics $graphics_type --noautoconsole"

  # get additional options
  shift 2
  options="$@"
  virt-install -n $name --memory $memory \
    --vcpus $cpus --cpu host \
    --import --os-variant $os \
    $options \
    $arch \
    $disk_options \
    $graphics_options \
    $network_options \
    $virtualization
}


main "$@"


