#!/bin/sh

vers="${1-28}"
name="fedora-${vers}-rpi3"
repo="repos/fedora-${vers}-$(sh basearch.sh).repo"
krnl="kernel kernel-modules"

rpms=""
rpms="$rpms bcm283x-firmware uboot-images-armv8 grub2-efi"
rpms="$rpms -dracut-config-rescue dracut-config-generic"
rpms="$rpms wpa_supplicant links"

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
