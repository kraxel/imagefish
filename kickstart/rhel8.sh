#!/bin/sh

# config
name="rhel8"
arch="x86_64"
size="4"
base="http://spunk.home.kraxel.org/mirror/rhel/redhat/rhel-8/rel-eng/RHEL-8"

kick="$(pwd)/${name}.ks"
disk="$(pwd)/${name}-${arch}.qcow2"
repo="${base}/latest-RHEL-8.1.0/compose/BaseOS/$arch/os/"

# install
rm -f "$disk"
(set -x; virt-install \
	--virt-type kvm \
	--os-variant rhel8.0 \
	--arch "${arch}" \
	--name "virt-install-${name}" \
	--memory 4096 \
	--nographics \
	--transient \
	--network user \
	--disk "bus=scsi,format=qcow2,sparse=yes,size=${size},path=${disk}" \
	--initrd-inject "${kick}" \
	--extra-args "console=ttyS0 ks=file:/${kick##*/} inst.repo=$repo" \
	--location "$repo" ) || exit 1
