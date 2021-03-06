#!/bin/sh

source ./Fedora-setup.sh

name="fedora-${vers}-efi-grub2"
rpms="-grubby -dracut-config-rescue dracut-config-generic"

rpms_i686="grub2-efi-ia32 grub2-pc"
rpms_x86_64="shim grub2-efi-x64 grub2-pc"
rpms_armhfp="grub2-efi-arm grub2-tools"		# fedora
#rpms_armhfp="grub2-efi grubby-deprecated"	# kraxel
rpms_aarch64="shim grub2-efi-aa64"
eval "rpms=\"\$rpms \$rpms_$(sh basearch.sh)\""

arch="$(sh basearch.sh)"
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
scripts/tar-to-image.sh --tar "$tar" --image "$img" --efi-grub2
