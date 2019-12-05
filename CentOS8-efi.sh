#!/bin/sh

vers="${1-8}"
name="centos-${vers}-efi"
repo="repos/centos-${vers}.repo"
rpms="shim -grubby -dracut-config-rescue dracut-config-generic"

rpms_x86_64="shim grub2-efi-x64 grub2-pc"
rpms_aarch64="shim grub2-efi-aa64"
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
scripts/install-redhat.sh --config "$repo" --tar "$tar" --packages "$rpms" \
	--platform el8 --dnf
scripts/tar-to-image.sh --tar "$tar" --image "$img" --efi-grub2
