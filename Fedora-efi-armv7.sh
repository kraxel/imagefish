#!/bin/sh

vers="${1-30}"
name="fedora-${vers}-efi-grub2"
repo="repos/fedora-${vers}-$(sh basearch.sh).repo"
rpms="grub2-efi grubby-deprecated -dracut-config-rescue dracut-config-generic"

arch="$(sh basearch.sh)"
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
#scripts/config-kraxel-repo.sh "$img"
