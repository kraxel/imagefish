#!/bin/sh

image="$1"
edid="${2-1920x1080.bin}"

if test "$image" = ""; then
	echo "usage: $0 <image> [ <edid> ]"
	exit 1
fi

base="$(dirname $0)"
file="${base}/../edid/$edid"

set -ex
virt-customize -a "$image" --no-network		\
	--mkdir "/lib/firmware/edid"		\
	--copy-in "$file:/lib/firmware/edid"	\
	--write "/etc/modprobe.d/edid-fixup.conf:options drm_kms_helper edid_firmware=edid/$edid"
