#!/bin/sh

vers="${1-29}"
name="fedora-${vers}-wsl"
repo="repos/fedora-${vers}-$(sh basearch.sh).repo"
rpms=""

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
