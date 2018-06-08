#!/bin/sh

name="rhel-8-alpha-efi"
repo="repos/rhel-8.repo"
rpms="grub2-efi shim efibootmgr -dracut-config-rescue dracut-config-generic"
#rpms="efibootmgr -dracut-config-rescue dracut-config-generic" # systemd-boot

arch="$(uname -m)"
tar="${IMAGEFISH_DESTDIR-.}/${name}-${arch}.tar.gz"
img="${IMAGEFISH_DESTDIR-.}/${name}-${arch}.qcow2"

echo ""
echo "###"
echo "### $name"
echo "###"

set -ex
rm -f "$tar" "$img"
scripts/install-redhat.sh --config "$repo" --tar "$tar" --packages "$rpms" --yum
scripts/tar-to-image.sh --tar "$tar" --image "$img" --efi-grub2
#scripts/tar-to-image.sh --tar "$tar" --image "$img" --efi-systemd
