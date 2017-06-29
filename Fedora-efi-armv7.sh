#!/bin/sh

vers="${1-25}"
name="fedora-${vers}-efi"
repo="repos/fedora-${vers}-armv7.repo"
rpms="grub2-efi -dracut-config-rescue dracut-config-generic"

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
scripts/tar-to-image.sh --tar "$tar" --image "$img" --efi-grub2
scripts/config-systemd-network.sh "$img"
scripts/config-kraxel-repo.sh "$img"
