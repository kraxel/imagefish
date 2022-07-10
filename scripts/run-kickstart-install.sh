#!/bin/sh

# args
disk="$1"
repo="$2"
kick="${3-el8.ks}"
size="${4-4}"

# go!
name="$(basename $disk .qcow2)"
xterm-title "kickstart install: $name"

case "$kick" in
    *efi*)
        extra="--boot uefi"
        ;;
    *)
        extra=""
        ;;
esac

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
	--extra-args "console=ttyS0 inst.ks=file:/${kick##*/}" \
	--location "$repo" \
	$extra
