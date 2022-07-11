#!/bin/sh

vers="${1-8}"
name="centos-${vers}-wsl"
repo="repos/centos-${vers}-stream.repo"
rpms="-kernel* -microcode_ctl -*-firmware git-core"

tar="${IMAGEFISH_DESTDIR-.}/${name}.tar"

echo ""
echo "###"
echo "### $name"
echo "###"
echo "### $rpms"
echo "###"

set -ex
rm -f "$tar"
scripts/install-redhat.sh --config "$repo" --tar "$tar" --packages "$rpms" \
	--kernel "" --platform el8 --dnf
