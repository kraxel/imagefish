#!/bin/sh

name="centos-8-efi"
repo="repos/centos-8.repo"
rpms="shim -grubby -dracut-config-rescue dracut-config-generic"

rpms_x86_64="shim grub2-efi grub2-pc"
rpms_aarch64="shim grub2-efi"
eval "rpms=\"\$rpms \$rpms_$(sh basearch.sh)\""

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
