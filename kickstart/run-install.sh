#!/bin/sh

# args
disk="$1"
repo="$2"
size="${3-4}"
kick="${4-el8.ks}"

# go!
name="$(basename $disk .qcow2)"

rm -f "$disk"
exec virt-install \
	--virt-type kvm \
	--os-variant rhel8.0 \
	--arch x86_64 \
	--memory 4096 \
	--nographics \
	--transient \
	--network user \
	--name "virt-install-${name}" \
	--disk "bus=scsi,format=qcow2,sparse=yes,size=${size},path=${disk}" \
	--initrd-inject "${kick}" \
	--extra-args "console=ttyS0 ks=file:/${kick##*/}" \
	--location "$repo"
