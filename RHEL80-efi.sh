#!/bin/sh

name="rhel-80-beta-efi"
repo="/mort/mirror/rhel/repo/el8/spunk-RHEL-8.0-BaseOS.repo"
rpms="grub2-efi grub2-pc shim efibootmgr -grubby -dracut-config-rescue dracut-config-generic"

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
scripts/tar-to-image.sh --tar "$tar" --image "$img" --efi-grub2 --big --size 24G
virt-copy-in -a "$img" "$repo" /etc/yum.repos.d
