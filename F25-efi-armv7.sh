#!/bin/sh

name="fedora-25-efi"
repo="repos/fedora-25-armv7.repo"
rpms="grub2-efi"

arch="$(uname -m)"
tar="${IMAGEFISH_DESTDIR-.}/${name}-${arch}.tar.gz"
img="${IMAGEFISH_DESTDIR-.}/${name}-${arch}.qcow2"

echo ""
echo "###"
echo "### $name"
echo "###"

set -ex
rm -f "$tar" "$img"
scripts/install-redhat.sh --config "$repo" --tar "$tar" --packages "$rpms" --dnf
scripts/tar-to-image.sh --tar "$tar" --image "$img" --efi
scripts/config-systemd-network.sh "$img"
scripts/config-kraxel-repo.sh "$img"
