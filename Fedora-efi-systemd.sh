#!/bin/sh

source ./Fedora-setup.sh

name="fedora-${vers}-efi-systemd"
rpms="-grubby -dracut-config-rescue dracut-config-generic"

rpms_i686="grub2-pc"
rpms_x86_64="grub2-pc"
rpms_armhfp=""
rpms_aarch64=""
eval "rpms=\"\$rpms \$rpms_$(uname -m)\""

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
scripts/install-redhat.sh --config "$repo" --tar "$tar" --packages "$rpms" --dnf
scripts/tar-to-image.sh --tar "$tar" --image "$img" --efi-systemd
