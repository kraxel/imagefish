#!/bin/sh

# args
match="$1"

# config
src="/vmdisk/hdd/pool-iso"
dst="/vmdisk/hdd/pool-disk"

iso="$(ls -t $src/Clover-*${match}*-X64.iso | head -1)"
img="${dst}${iso#$src}"
img="${img%.iso}.qcow2"

# rebuild clover image
set -x
rm -f "$img"
scripts/clover-image.sh --iso "$iso" --img "$img" --cfg "clover/config.plist"
