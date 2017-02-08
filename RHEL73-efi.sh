#!/bin/sh

name="rhel-73-efi"
repo="repos/rhel-73.repo"
rpms="grub2-efi shim"

arch="$(uname -m)"
tar="${name}-${arch}.tar.gz"
img="${name}-${arch}.qcow2"
set -ex
rm -f "$tar" "$img"
scripts/install-redhat.sh --config "$repo" --tar "$tar" --packages "$rpms" --yum
scripts/tar-to-image.sh --tar "$tar" --image "$img" --efi
