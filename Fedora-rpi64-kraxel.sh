#!/bin/sh

vers="${1-25}"
name="fedora-${vers}-rpi3-kraxel"
repo="repos/fedora-${vers}-aarch64.repo"
rpms="bcm283x-firmware uboot-images-armv8 extlinux-bootloader dracut-config-generic"
krnl="kernel-main"

arch="$(uname -m)"
tar="${IMAGEFISH_DESTDIR-.}/${name}-${arch}.tar.gz"
img="${IMAGEFISH_DESTDIR-.}/${name}-${arch}.raw"

echo ""
echo "###"
echo "### $name"
echo "###"

set -ex
rm -f "$tar" "$img"
scripts/install-redhat.sh --config "$repo" --tar "$tar" --packages "$rpms" --kernel "$krnl" --dnf 
scripts/tar-to-image.sh --tar "$tar" --image "$img" --rpi64
scripts/config-systemd-network.sh "$img"
scripts/config-kraxel-repo.sh "$img"
