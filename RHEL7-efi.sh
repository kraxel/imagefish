#!/bin/sh

vers="$1"
name="rhel-${vers}-efi"
repo="/mort/mirror/rhel/repo/el7/spunk-RHEL-${vers}-Server.repo"
rpms="grub2-efi shim -dracut-config-rescue dracut-config-generic"

arch="$(uname -m)"
tar="${IMAGEFISH_DESTDIR-.}/${name}-${arch}.tar.gz"
img="${IMAGEFISH_DESTDIR-.}/${name}-${arch}.qcow2"

echo ""
echo "###"
echo "### $name ($arch)"
echo "###"
echo "### $rpms"
echo "###"

set -ex
rm -f "$tar" "$img"
scripts/install-redhat.sh --config "$repo" --tar "$tar" --packages "$rpms" --yum
scripts/tar-to-image.sh --tar "$tar" --image "$img" --efi-grub2
virt-copy-in -a "$img" "$repo" /etc/yum.repos.d
