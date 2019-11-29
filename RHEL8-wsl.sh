#!/bin/sh

vers="$1"
name="rhel-${vers}-wsl"
repo="/mort/mirror/rhel/repo/el8/mirror-RHEL-${vers}-BaseOS.repo"
rpms="-kernel* -microcode_ctl"

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
