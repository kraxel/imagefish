#!/bin/sh

name="fedora-25-rpi2"
repo="repos/fedora-25.repo"
rpms="bcm283x-firmware uboot-images-armv7 extlinux-bootloader kernel"

arch="$(uname -m)"
tar="${name}-${arch}.tar.gz"
img="${name}-${arch}.raw"
set -ex
rm -f "$tar" "$img"
scripts/install-redhat.sh --config "$repo" --tar "$tar" --packages "$rpms" --dnf 
scripts/tar-to-image.sh --tar "$tar" --image "$img" --rpi32
