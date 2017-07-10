#!/bin/sh

vers="${1-25}"
name="fedora-${vers}-rpi2"
repo="repos/fedora-${vers}-$(sh basearch.sh).repo"
rpms="bcm283x-firmware uboot-images-armv7 extlinux-bootloader -dracut-config-rescue dracut-config-generic"
krnl="kernel kernel-modules"

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
scripts/tar-to-image.sh --tar "$tar" --image "$img" --rpi32
scripts/config-systemd-network.sh "$img"
scripts/config-kraxel-repo.sh "$img"
