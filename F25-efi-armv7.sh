#!/bin/sh

name="fedora-25-efi"
repo="repos/fedora-25-armv7.repo"
rpms="grub2-efi shim"

arch="$(uname -m)"
tar="${name}-${arch}.tar.gz"
img="${name}-${arch}.qcow2"
set -ex
rm -f "$tar" "$img"
scripts/install-redhat.sh --config "$repo" --tar "$tar" --packages "$rpms" --dnf 
scripts/tar-to-image.sh --tar "$tar" --image "$img" --efi
