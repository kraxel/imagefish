#!/bin/sh
image="$1"
if test "$image" = ""; then
	echo "usage: $0 <image>"
	exit 1
fi

base="$(dirname $0)"
edid="ACER-G226HQL-fixed.edid"
file="${base}/../edid/$edid"

WORK="${TMPDIR-/tmp}/${0##*/}-$$"
mkdir "$WORK" || exit 1
trap 'rm -rf "$WORK"' EXIT

cat <<EOF > "$WORK/script"

mkdir	/lib/firmware/edid
copy-in	$file /lib/firmware/edid

command "sed -i 's|append|append drm_kms_helper.edid_firmware=edid/$file| /boot/extlinux/extlinux.conf"

EOF

set -ex
virt-customize -a "$image" --no-network --commands-from-file "$WORK/script"
