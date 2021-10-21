#!/bin/sh
#
# prepare image as virt-builder template
#

# args
image="$1"

# config
scripts="$(dirname $0)"
info="${image%.qcow2}.info"

# checks
if test ! -f "$1"; then
    echo "usage: $0 <image>"
    exit 1
fi

# go!
set -ex
virt-sysprep -a "$image"
virt-sparsify --inplace "$image"
qemu-img info --output=json "$image" > "$info"
xz --verbose "$image"
$scripts/virt-builder-index.sh "$info"
