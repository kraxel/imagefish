#!/bin/sh

source ./Fedora-setup.sh

name="fedora-${vers}-wsl"
rpms="git-core"

tar="${IMAGEFISH_DESTDIR-.}/${name}.tar"

echo ""
echo "###"
echo "### $name"
echo "###"
echo "### $rpms"
echo "###"

set -ex
rm -f "$tar"
scripts/install-redhat.sh --config "$repo" --tar "$tar" --packages "$rpms" --kernel "" --dnf
